import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matric_compass/core/network/safe_log_interceptor.dart';

import '../../support/fake_http_adapter.dart';

void main() {
  // Week 11 Day 1: the log line has the shape of the request, nothing more.
  test('a log line leaves out the query, headers and body', () async {
    final lines = <String>[];
    final dio = Dio(BaseOptions(baseUrl: 'http://api.test'))
      ..httpClientAdapter = FakeHttpAdapter(
        (_) => FakeHttpAdapter.json(200, {'fullName': 'Thandiwe Nkosi'}),
      )
      ..interceptors.add(SafeLogInterceptor(log: lines.add));

    await dio.get<Object?>(
      '/api/v1/Students',
      queryParameters: {'search': 'Thandiwe'},
      options: Options(headers: {'Authorization': 'Bearer secret-token'}),
    );

    expect(lines, hasLength(1));
    expect(lines.single, startsWith('GET /api/v1/Students → 200'));
    for (final secret in ['Thandiwe', 'secret-token', 'Bearer', 'search']) {
      expect(lines.single, isNot(contains(secret)));
    }
  });

  test("an error's line carries its reference", () async {
    final lines = <String>[];
    final dio = Dio(BaseOptions(baseUrl: 'http://api.test'))
      ..httpClientAdapter = FakeHttpAdapter(
        (_) => FakeHttpAdapter.json(404, {
          'status': 404,
          'detail': 'Bursary application x was not found.',
          'correlationId': 'abc123',
        }, problem: true),
      )
      ..interceptors.add(SafeLogInterceptor(log: lines.add));

    await expectLater(
      dio.get<Object?>('/api/v1/bursary-applications/x'),
      throwsA(isA<DioException>()),
    );

    expect(lines.single, contains('→ 404'));
    expect(lines.single, endsWith('ref abc123'));
    // The detail can name a person or an amount: it is never logged.
    expect(lines.single, isNot(contains('was not found')));
  });
}
