import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Week 11 Day 1: logs the SHAPE of every request, never its contents.
///
/// Logged: the method, the path (ids included), the status, how long it
/// took, and an error's correlationId. Never logged: headers (the token
/// arrives in one tomorrow), cookies, bodies (names, ID numbers, marks,
/// amounts) or query values (a search term is personal too).
///
/// Dio's own LogInterceptor prints request headers by default, so it isn't
/// used here.
class SafeLogInterceptor extends Interceptor {
  /// Creates the interceptor. Tests pass [log] to capture the lines.
  new({void Function(String line)? log}) : _log = log ?? debugPrint;

  final void Function(String line) _log;
  final Map<RequestOptions, Stopwatch> _timers = {};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _timers[options] = Stopwatch()..start();
    handler.next(options);
  }

  @override
  void onResponse(
    Response<Object?> response,
    ResponseInterceptorHandler handler,
  ) {
    _log(
      describe(
        response.requestOptions,
        response.statusCode,
        _stop(response.requestOptions),
      ),
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final data = err.response?.data;
    final correlationId = data is Map<String, Object?>
        ? data['correlationId']
        : null;
    final line = describe(
      err.requestOptions,
      err.response?.statusCode,
      _stop(err.requestOptions),
    );
    _log(
      correlationId == null
          ? '$line ${err.type.name}'
          : '$line ref $correlationId',
    );
    handler.next(err);
  }

  Duration _stop(RequestOptions options) =>
      _timers.remove(options)?.elapsed ?? Duration.zero;

  /// One log line. Public so a test can prove what it leaves out.
  static String describe(RequestOptions options, int? status, Duration took) =>
      // uri.path drops the query string, and with it any search term.
      '${options.method} ${options.uri.path} → ${status ?? 'no answer'} '
      '(${took.inMilliseconds} ms)';
}
