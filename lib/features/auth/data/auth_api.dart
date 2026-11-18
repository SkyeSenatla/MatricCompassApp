import 'package:dio/dio.dart';
import 'package:matric_compass/core/api/generated/models/login_request.dart';
import 'package:matric_compass/core/api/generated/models/token_response.dart';
import 'package:matric_compass/core/network/access_token.dart';
import 'package:matric_compass/core/network/refresh_cookie.dart';

/// Week 11 Day 2: an access token, and the refresh token that came with it.
typedef SessionTokensPair = ({SessionToken access, String refreshToken});

/// Week 11 Day 2: the three auth calls, with the refresh cookie by hand.
///
/// Not the generated AuthClient: it returns only the body, and the refresh
/// token arrives in a Set-Cookie header. So these three calls use Dio
/// directly, with the generated request and response models.
///
/// The Dio passed in must have NO session interceptor: a refresh that went
/// through it would wait in the queue behind the very error that started it.
final class AuthApi {
  /// Creates the API over a Dio, with the API's refresh cookie [cookieName].
  const new(this._dio, {required this.cookieName});

  final Dio _dio;

  /// The refresh cookie's name, from the flavour's config.
  final String cookieName;

  /// Signs in with [email] and [password].
  Future<SessionTokensPair> signIn(String email, String password) async =>
      _pair(
        await _dio.post<Map<String, Object?>>(
          '/api/v1/auth/login',
          data: LoginRequest(email: email, password: password).toJson(),
        ),
      );

  /// Swaps [refreshToken] for a new pair. The old refresh token is spent:
  /// presenting it again ends the whole session on the API.
  Future<SessionTokensPair> refresh(String refreshToken) async => _pair(
    await _dio.post<Map<String, Object?>>(
      '/api/v1/auth/refresh',
      options: _withCookie(refreshToken),
    ),
  );

  /// Ends the session on the API. 204, even with no cookie.
  Future<void> signOut(String refreshToken) => _dio.post<void>(
    '/api/v1/auth/logout',
    options: _withCookie(refreshToken),
  );

  // The cookie a browser would have sent, sent by hand, and only here.
  Options _withCookie(String refreshToken) =>
      Options(headers: {'Cookie': '$cookieName=$refreshToken'});

  SessionTokensPair _pair(Response<Map<String, Object?>> response) {
    final body = TokenResponse.fromJson(response.data ?? const {});
    final refreshToken = refreshCookieFrom(
      response.headers['set-cookie'],
      cookieName,
    );
    if (refreshToken == null) {
      // A contract break, not a user error: the guard makes it a
      // ServerFailure with nothing personal in it.
      throw StateError('The API sent no $cookieName cookie.');
    }
    return (
      access: (value: body.accessToken, expiresAt: body.expiresAt),
      refreshToken: refreshToken,
    );
  }
}
