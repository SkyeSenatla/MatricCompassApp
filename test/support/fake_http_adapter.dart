import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Week 11 Day 1: answers Dio's requests from a function instead of the
/// network, so an API repository is tested with the real generated client,
/// the real JSON decoding and the real failure mapping, and no server.
class FakeHttpAdapter implements HttpClientAdapter {
  /// Creates the adapter; [respond] answers every request.
  new(this.respond);

  /// Builds the answer to one request.
  final ResponseBody Function(RequestOptions options) respond;

  /// Every request that arrived, in order.
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return respond(options);
  }

  @override
  void close({bool force = false}) {}

  /// A JSON answer. [problem] sends it as application/problem+json, as the
  /// API sends every error.
  static ResponseBody json(
    int status,
    Object body, {
    bool problem = false,
    Map<String, List<String>> headers = const {},
  }) => ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [
        if (problem) 'application/problem+json' else 'application/json',
      ],
      ...headers,
    },
  );

  /// A non-JSON answer, such as a proxy's HTML error page.
  static ResponseBody html(int status, String body) => ResponseBody.fromString(
    body,
    status,
    headers: {
      Headers.contentTypeHeader: ['text/html'],
    },
  );
}
