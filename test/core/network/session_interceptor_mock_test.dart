import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matric_compass/core/errors/failure.dart';
import 'package:matric_compass/core/network/session_interceptor.dart';
import 'package:matric_compass/core/network/session_tokens.dart';
import 'package:mocktail/mocktail.dart';

/// Week 12 Day 1: the session the interceptor talks to, mocked. Week 11's
/// test ran the real session against a fake server; this one isolates the
/// interceptor's own decisions: when it refreshes, what it sends again,
/// and when it gives up.
class MockSessionTokens extends Mock implements SessionTokens;

/// The network, scripted: answers 401 to the old token and 200 to the new
/// one, and remembers every Authorization header it saw. No server.
final class _ScriptedAdapter implements HttpClientAdapter {
  final sent = <String?>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final header = options.headers['Authorization'] as String?;
    sent.add(header);
    final ok = header == 'Bearer new';
    return ResponseBody.fromString(
      jsonEncode(ok ? {'ok': true} : {'title': 'Unauthorized'}),
      ok ? 200 : 401,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

typedef _Token = ({String value, DateTime expiresAt});

_Token _token(String value) =>
    (value: value, expiresAt: DateTime.now().add(const Duration(minutes: 5)));

void main() {
  late MockSessionTokens session;
  late _ScriptedAdapter network;
  late Dio dio;
  late int ended;

  setUp(() {
    session = MockSessionTokens();
    network = _ScriptedAdapter();
    ended = 0;
    // The retry goes through a Dio without the interceptor, as in the app.
    final bare = Dio(BaseOptions(baseUrl: 'http://api.test'))
      ..httpClientAdapter = network;
    dio = Dio(BaseOptions(baseUrl: 'http://api.test'))
      ..httpClientAdapter = network
      ..interceptors.add(
        SessionInterceptor(
          session: session,
          retryWith: bare,
          onSessionEnded: () => ended++,
        ),
      );
    when(() => session.current).thenReturn(_token('old'));
  });

  test('a 401 refreshes once, then sends the request again', () async {
    when(() => session.refresh(sentToken: any(named: 'sentToken')))
        .thenAnswer((_) async => Refreshed(_token('new')));

    final response = await dio.get<Object?>('/api/v1/me/dashboard');

    expect(response.statusCode, 200);
    expect(network.sent, ['Bearer old', 'Bearer new']);
    // It told the session which token failed: the single-flight check.
    verify(() => session.refresh(sentToken: 'old')).called(1);
    expect(ended, 0);
  });

  test('a refused refresh ends the session, and nothing is retried', () async {
    when(() => session.refresh(sentToken: any(named: 'sentToken')))
        .thenAnswer((_) async => const SessionEnded());

    await expectLater(
      dio.get<Object?>('/api/v1/me/dashboard'),
      throwsA(isA<DioException>()),
    );
    expect(network.sent, ['Bearer old']);
    expect(ended, 1);
  });

  test('no signal for the refresh is not a sign-out', () async {
    when(() => session.refresh(sentToken: any(named: 'sentToken')))
        .thenAnswer((_) async => const RefreshUnavailable(OfflineFailure()));

    await expectLater(
      dio.get<Object?>('/api/v1/me/dashboard'),
      throwsA(isA<DioException>()),
    );
    expect(ended, 0);
  });

  test('a 403 is not about the session: no refresh at all', () async {
    final forbidden = Dio(BaseOptions(baseUrl: 'http://api.test'))
      ..httpClientAdapter = _Forbidden()
      ..interceptors.add(
        SessionInterceptor(
          session: session,
          retryWith: Dio(),
          onSessionEnded: () => ended++,
        ),
      );

    await expectLater(
      forbidden.get<Object?>('/api/v1/students'),
      throwsA(isA<DioException>()),
    );
    verifyNever(() => session.refresh(sentToken: any(named: 'sentToken')));
    expect(ended, 0);
  });
}

final class _Forbidden implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString('', 403);

  @override
  void close({bool force = false}) {}
}
