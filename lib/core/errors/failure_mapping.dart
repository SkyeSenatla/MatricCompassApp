import 'dart:async';

import 'package:dio/dio.dart';
import 'package:matric_compass/core/errors/failure.dart';
import 'package:matric_compass/core/errors/result.dart';

/// Week 11 Day 1: the ONE place an error becomes a [Failure].
///
/// Every API repository calls the API through [guard], so a DioException,
/// a ProblemDetails body, an HTML page from a proxy or a parse error all
/// arrive above the data layer as a Failure. Plain Dart: the test table in
/// test/core/errors/failure_mapping_test.dart needs no network.
Future<Result<T>> guard<T>(Future<T> Function() call) async {
  try {
    return Ok(await call());
  } on Object catch (error) {
    return Err(failureFrom(error));
  }
}

/// Turns anything thrown while calling the API into a [Failure].
Failure failureFrom(Object error) {
  if (error is Failure) return error;
  // Week 10 Day 4's lesson: two calls awaited together with `.wait` throw a
  // ParallelWaitError, with each call's error in a record. Unwrap the first,
  // so a 404 from either call is still a NotFoundFailure.
  if (error is ParallelWaitError) {
    final first = switch (error.errors) {
      (final AsyncError? a, final AsyncError? b) => a ?? b,
      (final AsyncError? a, final AsyncError? b, final AsyncError? c) =>
        a ?? b ?? c,
      _ => null,
    };
    return first == null ? const ServerFailure() : failureFrom(first.error);
  }
  if (error is! DioException) {
    // A body the generated models couldn't read: a captive portal's HTML,
    // or a contract that drifted. The app can't recover; support can.
    return const ServerFailure();
  }
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
    case DioExceptionType.connectionError:
      return const OfflineFailure();
    case DioExceptionType.badResponse:
      final response = error.response;
      if (response == null) return const ServerFailure();
      return _fromResponse(response);
    case DioExceptionType.cancel:
    case DioExceptionType.badCertificate:
    case DioExceptionType.unknown:
      // unknown is usually a SocketException underneath: no answer at all.
      return const OfflineFailure();
  }
}

Failure _fromResponse(Response<Object?> response) {
  // ProblemDetails is a JSON object. A 502 from a proxy is an HTML string,
  // and some errors have no body at all: those still map, with less detail.
  final body = switch (response.data) {
    final Map<String, Object?> map => map,
    _ => const <String, Object?>{},
  };
  final correlationId = body['correlationId'] as String?;
  final detail = body['detail'] as String?;

  return switch (response.statusCode ?? 0) {
    400 => ValidationFailure(
      fieldErrors: _fieldErrors(body['errors']),
      correlationId: correlationId,
    ),
    401 => UnauthorizedFailure(correlationId: correlationId),
    403 => ForbiddenFailure(correlationId: correlationId),
    404 => NotFoundFailure(correlationId: correlationId),
    409 => ConflictFailure(detail: detail, correlationId: correlationId),
    422 => RuleFailure(detail: detail, correlationId: correlationId),
    429 => RateLimitedFailure(
      retryAfter: _retryAfter(response.headers.value('retry-after')),
      correlationId: correlationId,
    ),
    _ => ServerFailure(correlationId: correlationId),
  };
}

/// `errors` is camelCase field name → messages, on validation 400s only.
Map<String, List<String>> _fieldErrors(Object? errors) => switch (errors) {
  final Map<String, Object?> map => {
    for (final MapEntry(:key, :value) in map.entries)
      if (value case final List<Object?> messages)
        key: [for (final message in messages) '$message'],
  },
  _ => const {},
};

/// Retry-After in seconds, as the API sends it.
Duration? _retryAfter(String? header) => switch (int.tryParse(header ?? '')) {
  final seconds? => Duration(seconds: seconds),
  null => null,
};
