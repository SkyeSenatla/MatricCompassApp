import 'package:matric_compass/app/app_config.dart';
import 'package:matric_compass/app/app_config_provider.dart';
import 'package:matric_compass/app/network/dio_provider.dart';
import 'package:matric_compass/core/api/generated/models/login_request.dart';
import 'package:matric_compass/core/errors/failure_mapping.dart';
import 'package:matric_compass/core/errors/result.dart';
import 'package:matric_compass/core/network/access_token.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dev_sign_in.g.dart';

/// Week 11 Day 1: a TEMPORARY sign-in, for the dev flavour only, so today's
/// demo can call the real API. Day 2 deletes this file.
///
/// It signs in as a seeded account with the seed password, passed in at
/// run time (`--dart-define=DEV_PASSWORD=...`) and never committed. It keeps
/// no refresh token, so after 5 minutes the API answers 401 and the app
/// sends the person back to sign-in. That pain is Day 2's lesson.
class DevSignIn {
  /// Creates the stand-in.
  const new(this._ref);

  final Ref _ref;

  static const _password = String.fromEnvironment('DEV_PASSWORD');

  /// Signs in to the API as [email] and returns the access token.
  Future<Result<SessionToken>> tokenFor(String email) {
    if (_ref.read(appConfigProvider).flavor != Flavor.dev) {
      throw StateError('Dev sign-in exists in the dev flavour only.');
    }
    if (_password.isEmpty) {
      throw StateError(
        'Run with --dart-define=DEV_PASSWORD=<the seed password from the '
        "API's .env>",
      );
    }
    final api = _ref.read(matricCompassApiProvider);
    return guard(() async {
      final response = await api.auth.postApiV1AuthLogin(
        body: LoginRequest(email: email, password: _password),
      );
      return (value: response.accessToken, expiresAt: response.expiresAt);
    });
  }
}

/// Week 11 Day 1: the stand-in, for the auth controller.
@Riverpod(keepAlive: true)
DevSignIn devSignIn(Ref ref) => DevSignIn(ref);
