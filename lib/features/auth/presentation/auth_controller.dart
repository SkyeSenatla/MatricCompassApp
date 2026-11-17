import 'package:matric_compass/app/data_source.dart';
import 'package:matric_compass/core/errors/failure.dart';
import 'package:matric_compass/core/errors/result.dart';
import 'package:matric_compass/core/network/access_token.dart';
import 'package:matric_compass/features/auth/data/dev_sign_in.dart';
import 'package:matric_compass/features/auth/data/fake_personas.dart';
import 'package:matric_compass/features/auth/domain/app_user.dart';
import 'package:matric_compass/features/auth/domain/auth_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_controller.g.dart';

/// Week 10 Day 3: the sign-in state. The router listens to it, so the
/// redirect runs again whenever someone signs in or out.
///
/// keepAlive: the session must outlive every screen. Week 11 Day 2 replaces
/// the body with the real session; the router doesn't change.
@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  @override
  AuthState build() => const SignedOut();

  /// Signs in as the persona with [email].
  ///
  /// Week 11 Day 1: on the API, the dev stand-in signs in for real and keeps
  /// the access token. On fakes (tests), it switches persona as in Week 10.
  /// An unknown email, a wrong password or no API all come back as Err.
  Future<Result<AppUser>> signIn(String email) async {
    final wanted = email.trim().toLowerCase();
    AppUser? persona;
    for (final candidate in FakePersonas.all) {
      if (candidate.email == wanted) persona = candidate;
    }
    if (persona == null) return const Err(NotFoundFailure());

    if (ref.read(dataSourceProvider) == DataSource.api) {
      switch (await ref.read(devSignInProvider).tokenFor(persona.email)) {
        case Err(:final failure):
          return Err(failure);
        case Ok(value: final token):
          ref
              .read(accessTokenProvider.notifier)
              .save(token.value, expiresAt: token.expiresAt);
      }
    }
    state = SignedIn(persona);
    return Ok(persona);
  }

  /// Signs out: forgets the token first, so no request after this carries
  /// it. The redirect then sends the app to sign-in.
  void signOut() {
    ref.read(accessTokenProvider.notifier).clear();
    state = const SignedOut();
  }
}
