import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matric_compass/core/api/generated/matric_compass_api.dart';
import 'package:matric_compass/core/errors/failure.dart';
import 'package:matric_compass/core/errors/result.dart';
import 'package:matric_compass/core/money/cents.dart';
import 'package:matric_compass/features/bursaries/data/api_bursary_repository.dart';
import 'package:matric_compass/features/bursaries/domain/bursary_application.dart';
import 'package:matric_compass/features/bursaries/domain/bursary_status.dart';

import '../../support/fake_http_adapter.dart';

/// The NSFAS Draft exactly as the API sent it on a fresh seed.
const Map<String, Object?> _nsfasJson = {
  'id': '3d9f5b7e-d625-4451-aa7c-e7c64a6e1245',
  'studentId': 'dbd6c7b6-6b71-4d52-bab3-969207e0a5a9',
  'funder': 'NSFAS',
  'amountInCents': 4500000,
  'deadline': '2027-01-16T09:54:22.079909Z',
  'status': 'Draft',
  'requiredDocuments': ['Certified ID Copy', 'Proof of Household Income'],
  'submittedAt': null,
  'version': 777,
};

/// The repository over the real generated client, answered by [adapter].
ApiBursaryRepository _repository(FakeHttpAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'http://api.test'))
    ..httpClientAdapter = adapter;
  return ApiBursaryRepository(MatricCompassApi(dio));
}

void main() {
  // Week 11 Day 1: the generated types stop in data. What comes out is the
  // domain type Week 10 built, with our enum, Cents and the version kept.
  test('an application becomes the domain type', () async {
    final adapter = FakeHttpAdapter(
      (_) => FakeHttpAdapter.json(200, _nsfasJson),
    );

    final result = await _repository(adapter)
        .fetchById(_nsfasJson['id']! as String);

    final application = (result as Ok<BursaryApplication>).value;
    expect(application.status, BursaryStatus.draft);
    expect(application.amount, const Cents(4500000));
    expect(application.version, 777);
    expect(application.deadline.isUtc, isTrue);
    expect(
      adapter.requests.single.path,
      '/api/v1/bursary-applications/${_nsfasJson['id']}',
    );
  });

  test('a status the app has never heard of is unknown, not a crash', () async {
    final adapter = FakeHttpAdapter(
      (_) => FakeHttpAdapter.json(200, {..._nsfasJson, 'status': 'Withdrawn'}),
    );

    final result = await _repository(adapter).fetchById('x');

    expect(
      (result as Ok<BursaryApplication>).value.status,
      BursaryStatus.unknown,
    );
  });

  test("someone else's application is Err(NotFoundFailure)", () async {
    final adapter = FakeHttpAdapter(
      (_) => FakeHttpAdapter.json(404, {
        'status': 404,
        'detail': 'Bursary application x was not found.',
        'correlationId': '17d48e5da9182e78b2d9d428ab2ae967',
      }, problem: true),
    );

    final result = await _repository(adapter).fetchById('x');

    expect((result as Err).failure, isA<NotFoundFailure>());
  });

  test("submitting twice: the 409 carries the API's sentence", () async {
    final adapter = FakeHttpAdapter(
      (_) => FakeHttpAdapter.json(409, {
        'status': 409,
        'detail': 'This application is already submitted.',
        'correlationId': 'd9122cfb783d6481918ae79744f7e824',
      }, problem: true),
    );

    final result = await _repository(adapter).submit('x');

    final failure = (result as Err).failure;
    expect(failure, isA<ConflictFailure>());
    expect(failure.message, 'This application is already submitted.');
    expect(adapter.requests.single.method, 'POST');
  });

  test("a proxy's HTML error page is a ServerFailure", () async {
    final adapter = FakeHttpAdapter(
      (_) => FakeHttpAdapter.html(502, '<html><body>Bad Gateway</body></html>'),
    );

    final result = await _repository(adapter).fetchById('x');

    expect((result as Err).failure, isA<ServerFailure>());
  });

  test('the review list asks the server for each status', () async {
    final adapter = FakeHttpAdapter(
      (options) => FakeHttpAdapter.json(200, {
        'items': [
          {..._nsfasJson, 'status': options.queryParameters['Status']},
        ],
        'nextPageToken': '',
      }),
    );

    final result = await _repository(adapter).fetchForReview();

    expect(
      (result as Ok<List<BursaryApplication>>).value.map((a) => a.status),
      [BursaryStatus.submitted, BursaryStatus.underReview],
    );
    expect(adapter.requests.map((r) => r.queryParameters['Status']), [
      'Submitted',
      'UnderReview',
    ]);
  });
}
