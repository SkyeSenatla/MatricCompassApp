import 'package:dio/dio.dart';
import 'package:matric_compass/core/network/session_tokens.dart';

/// Week 11 Day 2: puts the access token on every request, refreshes it a
/// minute before it runs out, and on a 401 refreshes once and sends the
/// request again, once.
///
/// A QueuedInterceptor: Dio hands it one request, and one error, at a time,
/// so two requests that fail together don't both start a refresh. Queued is
/// not merged, though: the second 401 still arrives, after the first one's
/// refresh. That's why [SessionTokens.refresh] is told which token the
/// failed request carried: if it's no longer the current one, the request
/// is simply sent again with the new token, and the refresh token the first
/// refresh just spent is never presented again.
class SessionInterceptor extends QueuedInterceptor {
  /// Creates the interceptor.
  ///
  /// retryWith sends a request again. It must be a Dio WITHOUT this
  /// interceptor: retrying through this one would put the retry's own error
  /// in the queue behind the error we're still handling, and wait forever.
  new({
    required this._session,
    required this._retryWith,
    required this._onSessionEnded,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final SessionTokens _session;
  final Dio _retryWith;
  final void Function() _onSessionEnded;
  final DateTime Function() _clock;

  /// How long before expiry a request refreshes first, as web-next does.
  static const refreshMargin = Duration(minutes: 1);

  // Marks a request that has already been sent again, so a second 401
  // can't start a loop.
  static const _retried = 'session.retried';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    var token = _session.current;
    // Nearly expired: refresh first, and spare the network a request that
    // would fail. The expiry is the API's expiresAt, not a guess.
    if (token != null && token.expiresAt.difference(_clock()) < refreshMargin) {
      switch (await _session.refresh(sentToken: token.value)) {
        case Refreshed(token: final fresh):
          token = fresh;
        case SessionEnded():
          token = null;
          _onSessionEnded();
        case RefreshUnavailable():
          // Offline: send the old token. It may still have a minute left.
          break;
      }
    }
    if (token != null) {
      options.headers['Authorization'] = 'Bearer ${token.value}';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    // Only a 401 is about the session. A 403 means "known, but not
    // allowed": never a reason to refresh, and never to sign out.
    if (err.response?.statusCode != 401 || options.extra[_retried] == true) {
      handler.next(err);
      return;
    }

    switch (await _session.refresh(sentToken: _bearer(options))) {
      case Refreshed(:final token):
        options.headers['Authorization'] = 'Bearer ${token.value}';
        options.extra[_retried] = true;
        try {
          handler.resolve(await _retryWith.fetch<Object?>(options));
        } on DioException catch (retryError) {
          handler.next(retryError);
        }
      case SessionEnded():
        // The refresh token was spent, expired or revoked: sign in again.
        _onSessionEnded();
        handler.next(err);
      case RefreshUnavailable():
        // No network for the refresh: still signed in, just offline.
        handler.next(err);
    }
  }

  static String? _bearer(RequestOptions options) {
    final header = options.headers['Authorization'];
    return header is String && header.startsWith('Bearer ')
        ? header.substring('Bearer '.length)
        : null;
  }
}
