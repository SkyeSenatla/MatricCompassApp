import 'package:dio/dio.dart';

/// Week 11 Day 1: puts the signed-in person's access token on every request.
///
/// A stand-in until Day 2. It reads the token through a function, so it
/// always sends the current one, and it reports a 401 so the app can send
/// the person back to sign-in. Day 2 replaces the 401 handling with a
/// single-flight refresh, and the stored token with secure storage.
class AccessTokenInterceptor extends Interceptor {
  /// Creates the interceptor.
  new({required this._readToken, required this._onUnauthorized});

  final String? Function() _readToken;
  final void Function() _onUnauthorized;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_readToken() case final token?) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // The 5-minute token ran out. Today: sign in again. Day 2: refresh.
    if (err.response?.statusCode == 401) _onUnauthorized();
    handler.next(err);
  }
}
