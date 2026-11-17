// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/login_request.dart';
import '../models/token_response.dart';

part 'auth_client.g.dart';

@RestApi()
abstract class AuthClient {
  factory AuthClient(Dio dio, {String? baseUrl}) = _AuthClient;

  /// Signs in with email and password.
  @POST('/api/v1/auth/login')
  Future<TokenResponse> postApiV1AuthLogin({
    @Body() required LoginRequest body,
  });

  /// Swaps the refresh-token cookie for a new access token and a new refresh token.
  @POST('/api/v1/auth/refresh')
  Future<TokenResponse> postApiV1AuthRefresh();

  /// Signs out: revokes this session's refresh tokens and clears the cookie.
  @POST('/api/v1/auth/logout')
  Future<void> postApiV1AuthLogout();
}
