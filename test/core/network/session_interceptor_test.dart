import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matric_compass/core/network/access_token.dart';
import 'package:matric_compass/core/network/refresh_token_store.dart';
import 'package:matric_compass/core/network/session_interceptor.dart';
import 'package:matric_compass/features/auth/data/auth_api.dart';
import 'package:matric_compass/features/auth/data/session.dart';

import '../../support/fake_auth_server.dart';

/// Week 11 Day 2: the app's real interceptor and session against a server
/// with the API's rules, and no network.
class _Rig {
  new() : server = FakeAuthServer() {
    store = InMemoryRefreshTokenStore();
    final bare = Dio(BaseOptions(baseUrl: 'http://api.test'))
      ..httpClientAdapter = server;
    session = Session(
      api: AuthApi(bare, cookieName: 'refresh_token'),
      store: store,
      readAccess: () => access,
      writeAccess: (token) => access = token,
    );
    dio = Dio(BaseOptions(baseUrl: 'http://api.test'))
      ..httpClientAdapter = server
      ..interceptors.add(
        SessionInterceptor(
          session: session,
          retryWith: bare,
          onSessionEnded: () => ended++,
        ),
      );
  }

  final FakeAuthServer server;
  late final InMemoryRefreshTokenStore store;
  late final Session session;
  late final Dio dio;
  SessionToken? access;
  int ended = 0;

  static SessionToken token(
    String value, {
    Duration life = const Duration(minutes: 5),
  }) => (value: value, expiresAt: DateTime.now().add(life));
}

void main() {
  test('three requests, one expired token: exactly one refresh', () async {
    final rig = _Rig();
    final stored = rig.server.startSession();
    await rig.store.write(stored);
    // The access token in memory is no longer accepted: 401 for everyone.
    rig.access = _Rig.token('expired');

    final responses = await Future.wait([
      rig.dio.get<Object?>('/api/v1/me/dashboard'),
      rig.dio.get<Object?>('/api/v1/aptitude-tests'),
      rig.dio.get<Object?>('/api/v1/tertiary-applications'),
    ]);

    expect(responses.map((r) => r.statusCode), [200, 200, 200]);
    expect(rig.server.refreshCalls, 1);
    expect(rig.server.revoked, isFalse);
    // Rotation: the stored token is the new one.
    expect(await rig.store.read(), isNot(stored));
    expect(rig.ended, 0);
  });

  test('a token about to expire is refreshed first: no 401 at all', () async {
    final rig = _Rig();
    await rig.store.write(rig.server.startSession());
    rig.access = _Rig.token(
      rig.server.currentAccess!,
      life: const Duration(seconds: 30),
    );

    final response = await rig.dio.get<Object?>('/api/v1/me/dashboard');

    expect(response.statusCode, 200);
    expect(rig.server.refreshCalls, 1);
    expect(rig.server.statuses, isNot(contains(401)));
    expect(rig.server.requests.map((r) => r.path), [
      '/api/v1/auth/refresh',
      '/api/v1/me/dashboard',
    ]);
  });

  test('a refresh the API refuses ends the session, once', () async {
    final rig = _Rig();
    rig.server.startSession();
    // A refresh token the server has never issued, or has revoked.
    await rig.store.write('revoked');
    rig.access = _Rig.token('expired');

    await expectLater(
      Future.wait([
        rig.dio.get<Object?>('/api/v1/me/dashboard'),
        rig.dio.get<Object?>('/api/v1/aptitude-tests'),
      ]),
      throwsA(isA<DioException>()),
    );

    expect(rig.server.refreshCalls, 1);
    expect(rig.ended, greaterThanOrEqualTo(1));
    expect(await rig.store.read(), isNull);
    expect(rig.access, isNull);
  });

  test('no network for the refresh: still signed in', () async {
    final rig = _Rig();
    final stored = rig.server.startSession();
    await rig.store.write(stored);
    rig.access = _Rig.token('expired');
    rig.server.offlinePaths.add('/api/v1/auth/refresh');

    await expectLater(
      rig.dio.get<Object?>('/api/v1/me/dashboard'),
      throwsA(isA<DioException>()),
    );

    expect(rig.ended, 0);
    expect(await rig.store.read(), stored);
  });

  test('a 403 is never a reason to refresh, or to sign out', () async {
    final rig = _Rig();
    await rig.store.write(rig.server.startSession());
    rig.access = _Rig.token(rig.server.currentAccess!);

    await expectLater(
      rig.dio.get<Object?>('/api/v1/Students'),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'status',
          403,
        ),
      ),
    );

    expect(rig.server.refreshCalls, 0);
    expect(rig.ended, 0);
  });

  // What the deck's "without the queue" card shows: each 401 refreshes on
  // its own. The first spends the token; the others present it again; the
  // API's reuse detection ends the session for everyone.
  test('without single flight, reuse detection signs her out', () async {
    final rig = _Rig();
    await rig.store.write(rig.server.startSession());
    final bare = Dio(BaseOptions(baseUrl: 'http://api.test'))
      ..httpClientAdapter = rig.server;
    final api = AuthApi(bare, cookieName: 'refresh_token');
    final naive = Dio(BaseOptions(baseUrl: 'http://api.test'))
      ..httpClientAdapter = rig.server
      ..interceptors.add(_NaiveRefresh(api, rig.store, bare));

    final results = await Future.wait([
      for (final path in ['/api/v1/me/dashboard', '/api/v1/aptitude-tests'])
        naive
            .get<Object?>(
              path,
              options: Options(headers: {'Authorization': 'Bearer expired'}),
            )
            .then((r) => r.statusCode, onError: (Object _) => 401),
    ]);

    expect(rig.server.refreshCalls, 2);
    expect(rig.server.revoked, isTrue);
    expect(results, contains(401));
  });
}

/// The bug, on purpose: a plain interceptor that refreshes for every 401
/// with whatever token is stored, at the same moment as the others.
class _NaiveRefresh extends Interceptor {
  new(this._api, this._store, this._retry);

  final AuthApi _api;
  final RefreshTokenStore _store;
  final Dio _retry;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) return handler.next(err);
    try {
      final pair = await _api.refresh((await _store.read())!);
      await _store.write(pair.refreshToken);
      final options = err.requestOptions
        ..headers['Authorization'] = 'Bearer ${pair.access.value}';
      handler.resolve(await _retry.fetch<Object?>(options));
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}
