import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matric_compass/core/network/access_token_interceptor.dart';

import '../../support/fake_http_adapter.dart';

void main() {
  test('every request carries the current token', () async {
    var token = 'first';
    final adapter = FakeHttpAdapter((_) => FakeHttpAdapter.json(200, {}));
    final dio = Dio(BaseOptions(baseUrl: 'http://api.test'))
      ..httpClientAdapter = adapter
      ..interceptors.add(
        AccessTokenInterceptor(readToken: () => token, onUnauthorized: () {}),
      );

    await dio.get<Object?>('/api/v1/me');
    token = 'second';
    await dio.get<Object?>('/api/v1/me');

    expect(adapter.requests.map((r) => r.headers['Authorization']), [
      'Bearer first',
      'Bearer second',
    ]);
  });

  // Week 11 Day 1: the 5-minute token ran out. Today the app signs out;
  // Day 2 refreshes instead.
  test(
    'a 401 reports itself, so the app can send the person to sign-in',
    () async {
      var unauthorized = 0;
      final dio = Dio(BaseOptions(baseUrl: 'http://api.test'))
        ..httpClientAdapter = FakeHttpAdapter(
          (_) => FakeHttpAdapter.json(401, {'status': 401}, problem: true),
        )
        ..interceptors.add(
          AccessTokenInterceptor(
            readToken: () => 'expired',
            onUnauthorized: () => unauthorized++,
          ),
        );

      await expectLater(
        dio.get<Object?>('/api/v1/me'),
        throwsA(isA<DioException>()),
      );

      expect(unauthorized, 1);
    },
  );

  test('a 403 is not a reason to sign anyone out', () async {
    var unauthorized = 0;
    final dio = Dio(BaseOptions(baseUrl: 'http://api.test'))
      ..httpClientAdapter = FakeHttpAdapter(
        (_) => FakeHttpAdapter.json(403, {'status': 403}, problem: true),
      )
      ..interceptors.add(
        AccessTokenInterceptor(
          readToken: () => 'valid',
          onUnauthorized: () => unauthorized++,
        ),
      );

    await expectLater(
      dio.get<Object?>('/api/v1/Students'),
      throwsA(isA<DioException>()),
    );

    expect(unauthorized, 0);
  });
}
