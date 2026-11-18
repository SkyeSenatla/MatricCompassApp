import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Week 11 Day 2: the Matric Compass API's auth rules, played by Dio's
/// adapter: tokens rotate on every refresh, a spent refresh token revokes
/// the whole session (reuse detection), every other endpoint wants the
/// current access token, and nothing answers until [latency] has passed, so
/// requests sent together really overlap.
///
/// Measured against the real API on 17 November 2026: the same cookie, the
/// same 401 for a reused token, the same 204 for logout with no cookie.
class FakeAuthServer implements HttpClientAdapter {
  /// Creates the server.
  new({this.latency = const Duration(milliseconds: 20)});

  /// How long each answer takes.
  final Duration latency;

  /// Every request, in the order it arrived.
  final List<RequestOptions> requests = [];

  /// Every status sent back, in order.
  final List<int> statuses = [];

  /// Paths that answer as if there were no network.
  final Set<String> offlinePaths = {};

  /// How many refreshes reached the server.
  int get refreshCalls =>
      requests.where((r) => r.path == '/api/v1/auth/refresh').length;

  /// True once a reused refresh token has ended the session.
  bool get revoked => _revoked;

  String? _access;
  String? _refresh;
  final Set<String> _spent = {};
  bool _revoked = false;
  int _issued = 0;

  /// The access token the server would accept now.
  String? get currentAccess => _access;

  /// Starts a session without signing in, as a stored token would: returns
  /// the refresh token to put in the store.
  String startSession() {
    _issue();
    return _refresh!;
  }

  /// A JWT-shaped access token whose middle part holds real claims.
  static String accessToken(int n, {String role = 'Learner'}) {
    String part(Map<String, Object?> json) =>
        base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
    return [
      part({'alg': 'HS256', 'typ': 'JWT'}),
      part({
        'email': 'thandiwe@matric-compass.test',
        'role': role,
        'student_id': 'student-1',
      }),
      'signature-$n',
    ].join('.');
  }

  void _issue() {
    _issued++;
    _access = accessToken(_issued);
    _refresh = 'refresh-$_issued';
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    await Future<void>.delayed(latency);
    if (offlinePaths.contains(options.path)) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'No network',
      );
    }
    final response = _answer(options);
    statuses.add(response.statusCode);
    return response;
  }

  ResponseBody _answer(RequestOptions options) {
    switch (options.path) {
      case '/api/v1/auth/login':
        final body = options.data as Map<String, Object?>;
        if (body['password'] != 'right password') return _problem(401);
        _revoked = false;
        _issue();
        return _tokens();
      case '/api/v1/auth/refresh':
        final presented = _cookie(options);
        if (presented != null && presented == _refresh) {
          _spent.add(presented);
          _issue();
          return _tokens();
        }
        if (presented != null && _spent.contains(presented)) {
          // Reuse detection: the server can't tell the thief from the app,
          // so it ends the session for both.
          _revoked = true;
          _access = null;
          _refresh = null;
          return _problem(
            401,
            detail: 'Refresh token was already used. Please sign in again.',
          );
        }
        return _problem(401);
      case '/api/v1/auth/logout':
        if (_cookie(options) == _refresh) {
          _access = null;
          _refresh = null;
        }
        return ResponseBody.fromString('', 204);
      case '/api/v1/Students':
        // A learner on a staff endpoint: known, but not allowed.
        return _problem(403);
      default:
        final bearer = options.headers['Authorization'];
        if (_access == null || bearer != 'Bearer $_access') {
          return _problem(401);
        }
        return ResponseBody.fromString(
          jsonEncode({'ok': true}),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        );
    }
  }

  static String? _cookie(RequestOptions options) {
    final header = options.headers['Cookie'];
    if (header is! String || !header.startsWith('refresh_token=')) return null;
    return header.substring('refresh_token='.length);
  }

  // The cookie exactly as the API sets it, with our token in it.
  String get _setCookie =>
      'refresh_token=$_refresh; expires=Tue, 24 Nov 2026 10:35:38 GMT; '
      'path=/api/v1/auth; secure; samesite=strict; httponly';

  ResponseBody _tokens() => ResponseBody.fromString(
    jsonEncode({
      'accessToken': _access,
      'expiresAt': DateTime.now()
          .toUtc()
          .add(const Duration(minutes: 5))
          .toIso8601String(),
    }),
    200,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
      'set-cookie': [_setCookie],
    },
  );

  static ResponseBody _problem(int status, {String? detail}) =>
      ResponseBody.fromString(
        jsonEncode({
          'status': status,
          'detail': ?detail,
          'correlationId': '4bf92f3577b34da6a3ce929d0e0e4736',
        }),
        status,
        headers: {
          Headers.contentTypeHeader: ['application/problem+json'],
        },
      );

  @override
  void close({bool force = false}) {}
}
