import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matric_compass/core/errors/failure.dart';
import 'package:matric_compass/core/errors/failure_mapping.dart';
import 'package:matric_compass/core/errors/result.dart';

/// A DioException for an error response, as Dio builds one.
DioException _response(
  int status, {
  Object? body,
  Map<String, List<String>> headers = const {},
}) {
  final options = RequestOptions(path: '/api/v1/x');
  return DioException.badResponse(
    statusCode: status,
    requestOptions: options,
    response: Response<Object?>(
      requestOptions: options,
      statusCode: status,
      data: body,
      headers: Headers.fromMap(headers),
    ),
  );
}

Map<String, Object?> _problem(int status, {String? detail}) => {
  'type': 'https://api.matric-compass.co.za/errors/X',
  'title': 'X',
  'status': status,
  'detail': ?detail,
  'correlationId': 'ref-$status',
};

void main() {
  // Week 11 Day 1: one row per status the API sends, each to one Failure.
  group('each status becomes one Failure', () {
    test('400 with errors is a ValidationFailure with its fields', () {
      final failure = failureFrom(
        _response(
          400,
          body: {
            ..._problem(400, detail: 'One or more fields are invalid.'),
            'errors': {
              'amountInCents': ['Must be more than zero.'],
            },
          },
        ),
      );
      expect(failure, isA<ValidationFailure>());
      expect((failure as ValidationFailure).fieldErrors, {
        'amountInCents': ['Must be more than zero.'],
      });
    });

    test('401, 403 and 404 keep their reference', () {
      expect(
        failureFrom(_response(401, body: _problem(401))),
        isA<UnauthorizedFailure>(),
      );
      expect(
        failureFrom(_response(403, body: _problem(403))),
        isA<ForbiddenFailure>(),
      );
      final notFound = failureFrom(_response(404, body: _problem(404)));
      expect(notFound, isA<NotFoundFailure>());
      expect(notFound.correlationId, 'ref-404');
    });

    test("409 and 422 carry the API's own sentence", () {
      final conflict = failureFrom(
        _response(
          409,
          body: _problem(409, detail: 'This application is already submitted.'),
        ),
      );
      expect(conflict.message, 'This application is already submitted.');

      final rule = failureFrom(
        _response(
          422,
          body: _problem(
            422,
            detail:
                'Upload these documents first: Certified ID Copy, '
                'Proof of Household Income.',
          ),
        ),
      );
      expect(rule, isA<RuleFailure>());
      expect(rule.message, startsWith('Upload these documents first'));
    });

    test('429 says how long to wait, from Retry-After', () {
      final failure = failureFrom(
        _response(
          429,
          body: _problem(429),
          headers: {
            'retry-after': ['42'],
          },
        ),
      );
      expect(
        (failure as RateLimitedFailure).retryAfter,
        const Duration(seconds: 42),
      );
      expect(failure.message, contains('42 seconds'));
    });

    test('500 is a ServerFailure that shows its reference', () {
      final failure = failureFrom(_response(500, body: _problem(500)));
      expect(failure, isA<ServerFailure>());
      expect(failure.showsReference, isTrue);
      expect(failure.correlationId, 'ref-500');
    });
  });

  group('not every failure is ProblemDetails', () {
    test("a proxy's HTML 502 still maps, with no reference", () {
      final failure = failureFrom(
        _response(502, body: '<html>Bad Gateway</html>'),
      );
      expect(failure, isA<ServerFailure>());
      expect(failure.correlationId, isNull);
    });

    test('no answer at all is OfflineFailure', () {
      final options = RequestOptions(path: '/api/v1/x');
      for (final type in [
        DioExceptionType.connectionError,
        DioExceptionType.connectionTimeout,
        DioExceptionType.receiveTimeout,
      ]) {
        expect(
          failureFrom(DioException(requestOptions: options, type: type)),
          isA<OfflineFailure>(),
          reason: type.name,
        );
      }
    });

    test("a body the models can't read is a ServerFailure, not a crash", () {
      expect(
        failureFrom(const FormatException('Unexpected <')),
        isA<ServerFailure>(),
      );
    });

    test('two calls awaited together: the 404 inside still wins', () async {
      final both = (
        Future<int>.error(_response(404, body: _problem(404))),
        Future<int>.value(1),
      ).wait;
      final failure = await both.then<Failure?>(
        (_) => null,
        onError: failureFrom,
      );
      expect(failure, isA<NotFoundFailure>());
    });
  });

  test('guard turns a throw into Err, and a value into Ok', () async {
    expect(await guard(() async => 7), isA<Ok<int>>());
    final err = await guard<int>(
      () async => throw _response(404, body: _problem(404)),
    );
    expect((err as Err<int>).failure, isA<NotFoundFailure>());
  });
}
