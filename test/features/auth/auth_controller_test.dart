import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matric_compass/app/app_config.dart';
import 'package:matric_compass/app/app_config_provider.dart';
import 'package:matric_compass/app/database/app_database.dart';
import 'package:matric_compass/app/network/dio_provider.dart';
import 'package:matric_compass/core/errors/failure.dart';
import 'package:matric_compass/core/errors/result.dart';
import 'package:matric_compass/core/network/access_token.dart';
import 'package:matric_compass/core/network/refresh_token_store.dart';
import 'package:matric_compass/features/auth/domain/app_user.dart';
import 'package:matric_compass/features/auth/domain/auth_state.dart';
import 'package:matric_compass/features/auth/presentation/auth_controller.dart';

import '../../support/fake_auth_server.dart';
import '../../support/test_database.dart';

/// Week 11 Day 2: the real auth controller and session, on the API data
/// source, against a server with the API's rules.
///
/// Week 11 Day 3: with the app's database in memory, read back through
/// appDatabaseProvider.
ProviderContainer _container(FakeAuthServer server, RefreshTokenStore store) =>
    ProviderContainer.test(
      overrides: [
        inMemoryDatabase,
        appConfigProvider.overrideWithValue(
          const AppConfig(flavor: Flavor.dev, apiBaseUrl: 'http://api.test'),
        ),
        refreshTokenStoreProvider.overrideWithValue(store),
        bareDioProvider.overrideWithValue(
          Dio(BaseOptions(baseUrl: 'http://api.test'))
            ..httpClientAdapter = server,
        ),
      ],
      retry: (retryCount, error) => null,
    );

/// The auth state once the launch-time restore has finished.
Future<AuthState> _restored(ProviderContainer container) {
  final done = Completer<AuthState>();
  container.listen<AuthState>(authControllerProvider, (_, next) {
    final stillRestoring = next is Restoring && !next.offline;
    if (!stillRestoring && !done.isCompleted) done.complete(next);
  }, fireImmediately: true);
  return done.future;
}

void main() {
  group('on launch', () {
    test('a stored session is restored as the person in the token', () async {
      final server = FakeAuthServer();
      final store = InMemoryRefreshTokenStore(server.startSession());
      final container = _container(server, store);

      expect(container.read(authControllerProvider), isA<Restoring>());
      final state = await _restored(container);

      final user = (state as SignedIn).user;
      expect(user.role, Role.learner);
      expect(user.studentId, 'student-1');
      expect(server.refreshCalls, 1);
      expect(await store.read(), 'refresh-2');
    });

    test('nothing stored: signed out, and the API is never asked', () async {
      final server = FakeAuthServer();
      final container = _container(server, InMemoryRefreshTokenStore());

      expect(await _restored(container), isA<SignedOut>());
      expect(server.requests, isEmpty);
    });

    test('a revoked session: signed out, and the store emptied', () async {
      final server = FakeAuthServer()..startSession();
      final store = InMemoryRefreshTokenStore('revoked');
      final container = _container(server, store);

      expect(await _restored(container), isA<SignedOut>());
      expect(await store.read(), isNull);
    });

    test('offline: not signed out, and the token is kept', () async {
      final server = FakeAuthServer()..offlinePaths.add('/api/v1/auth/refresh');
      final store = InMemoryRefreshTokenStore(server.startSession());
      final container = _container(server, store);

      final state = await _restored(container);

      expect(state, isA<Restoring>().having((s) => s.offline, 'offline', true));
      expect(await store.read(), 'refresh-1');
    });

    // Week 11 Day 3: the taxi. The access token died with the app, but the
    // phone remembers who it was, so it opens as her, on cached data.
    test('offline, after a sign-in on this phone: open as her', () async {
      final server = FakeAuthServer();
      final store = InMemoryRefreshTokenStore();
      final container = _container(server, store);
      await _restored(container);
      await container
          .read(authControllerProvider.notifier)
          .signIn('thandiwe@matric-compass.test', 'right password');
      // The app is killed (the access token goes) and opened with no signal.
      container.read(accessTokenProvider.notifier).clear();
      server.offlinePaths.add('/api/v1/auth/refresh');

      await container.read(authControllerProvider.notifier).restore();

      final user = (container.read(authControllerProvider) as SignedIn).user;
      expect(user.email, 'thandiwe@matric-compass.test');
      expect(user.studentId, 'student-1');
      expect(await store.read(), isNotNull, reason: 'still a session');
    });
  });

  group('signing in and out', () {
    test('sign-in keeps the refresh token in the store, and the access token '
        'only in memory', () async {
      final server = FakeAuthServer();
      final store = InMemoryRefreshTokenStore();
      final container = _container(server, store);
      await _restored(container);

      final result = await container
          .read(authControllerProvider.notifier)
          .signIn('Thandiwe@Matric-Compass.test ', 'right password');

      expect(result, isA<Ok<AppUser>>());
      expect(container.read(authControllerProvider), isA<SignedIn>());
      expect(await store.read(), 'refresh-1');
      expect(container.read(accessTokenProvider)?.value, server.currentAccess);
    });

    test('a wrong password stays signed out and stores nothing', () async {
      final server = FakeAuthServer();
      final store = InMemoryRefreshTokenStore();
      final container = _container(server, store);
      await _restored(container);

      final result = await container
          .read(authControllerProvider.notifier)
          .signIn('thandiwe@matric-compass.test', 'wrong');

      expect(
        result,
        isA<Err<AppUser>>().having(
          (e) => e.failure,
          'failure',
          isA<UnauthorizedFailure>(),
        ),
      );
      expect(container.read(authControllerProvider), isA<SignedOut>());
      expect(await store.read(), isNull);
    });

    test('sign-out leaves nothing, and tells the API', () async {
      final server = FakeAuthServer();
      final store = InMemoryRefreshTokenStore();
      final container = _container(server, store);
      await _restored(container);
      await container
          .read(authControllerProvider.notifier)
          .signIn('thandiwe@matric-compass.test', 'right password');

      await container.read(authControllerProvider.notifier).signOut();

      expect(container.read(authControllerProvider), isA<SignedOut>());
      expect(container.read(accessTokenProvider), isNull);
      expect(await store.read(), isNull);
      expect(server.requests.last.path, '/api/v1/auth/logout');
      expect(server.currentAccess, isNull);
    });

    // Week 11 Day 3: the family phone, now with a cache.
    test('sign-out empties the database: nothing of hers is left', () async {
      final server = FakeAuthServer();
      final container = _container(server, InMemoryRefreshTokenStore());
      await _restored(container);
      await container
          .read(authControllerProvider.notifier)
          .signIn('thandiwe@matric-compass.test', 'right password');
      final database = container.read(appDatabaseProvider);
      expect(await database.sessionUserDao.read(), isNotNull);

      await container.read(authControllerProvider.notifier).signOut();

      expect(await database.sessionUserDao.read(), isNull);
      expect(await database.dashboardDao.read(), isNull);
    });

    test('sign-out works with no network at all', () async {
      final server = FakeAuthServer();
      final store = InMemoryRefreshTokenStore();
      final container = _container(server, store);
      await _restored(container);
      await container
          .read(authControllerProvider.notifier)
          .signIn('thandiwe@matric-compass.test', 'right password');
      server.offlinePaths.add('/api/v1/auth/logout');

      await container.read(authControllerProvider.notifier).signOut();

      expect(container.read(authControllerProvider), isA<SignedOut>());
      expect(await store.read(), isNull);
    });

    test('a refresh that lands after sign-out signs nobody back in', () async {
      final server = FakeAuthServer(latency: const Duration(milliseconds: 80));
      final store = InMemoryRefreshTokenStore(server.startSession());
      final container = _container(server, store)..read(authControllerProvider);
      // The launch-time refresh is on its way to the server.
      await Future<void>.delayed(const Duration(milliseconds: 20));

      await container.read(authControllerProvider.notifier).signOut();
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(container.read(authControllerProvider), isA<SignedOut>());
      expect(container.read(accessTokenProvider), isNull);
      expect(await store.read(), isNull);
    });
  });
}
