import 'dart:async';

import 'package:matric_compass/app/app_config.dart';
import 'package:matric_compass/app/app_config_provider.dart';
import 'package:matric_compass/app/data_source.dart';
import 'package:matric_compass/core/errors/failure.dart';
import 'package:matric_compass/core/errors/result.dart';
import 'package:matric_compass/core/network/access_token.dart';
import 'package:matric_compass/core/network/session_tokens.dart';
import 'package:matric_compass/core/network/token_claims.dart';
import 'package:matric_compass/features/auth/data/fake_personas.dart';
import 'package:matric_compass/features/auth/data/session.dart';
import 'package:matric_compass/features/auth/domain/app_user.dart';
import 'package:matric_compass/features/auth/domain/auth_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_controller.g.dart';

/// Week 10 Day 3: the sign-in state. The router listens to it, so the
/// redirect runs again whenever someone signs in or out.
///
/// Week 11 Day 2: the real session. On launch it starts as [Restoring] and
/// asks the API whether the stored refresh token is still good.
///
/// keepAlive: the session must outlive every screen.
@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  bool get _onFakes => ref.read(dataSourceProvider) == DataSource.fake;

  @override
  AuthState build() {
    // Week 10's fakes have no sessions to restore.
    if (_onFakes) return const SignedOut();
    // After build returns: build itself must not change the state.
    unawaited(Future.microtask(restore));
    return const Restoring();
  }

  /// Restores the session from secure storage: one refresh on every
  /// launch, because the access token never survives the app being killed.
  Future<void> restore() async {
    state = const Restoring();
    final outcome = await ref.read(sessionProvider).refresh();
    if (!ref.mounted) return;
    state = switch (outcome) {
      Refreshed(:final token) => _signedInAs(token),
      SessionEnded() => const SignedOut(),
      // No network is not "signed out": keep the session and wait.
      RefreshUnavailable() => const Restoring(offline: true),
    };
  }

  /// Signs in with [email] and [password].
  ///
  /// On Week 10's fakes (whole-app tests) it switches persona by email and
  /// ignores the password. A wrong password, a 429 or no API all come back
  /// as Err.
  Future<Result<AppUser>> signIn(String email, String password) async {
    final wanted = email.trim().toLowerCase();
    if (_onFakes) {
      for (final persona in FakePersonas.all) {
        if (persona.email == wanted) {
          state = SignedIn(persona);
          return Ok(persona);
        }
      }
      return const Err(UnauthorizedFailure());
    }

    switch (await ref.read(sessionProvider).signIn(wanted, password)) {
      case Err(:final failure):
        return Err(failure);
      case Ok(value: final token):
        final signedIn = _signedInAs(token);
        if (signedIn case SignedIn(:final user)) {
          state = signedIn;
          return Ok(user);
        }
        // A token the app can't read: don't keep half a session.
        await ref.read(sessionProvider).signOut();
        return const Err(ServerFailure());
    }
  }

  /// Signs out, and leaves nothing of the person behind.
  ///
  /// The state changes at once: every user-scoped provider watches this
  /// one, so their data goes with it, and the redirect moves to sign-in.
  /// The session then wipes the tokens and tells the API.
  Future<void> signOut() async {
    if (_onFakes) {
      state = const SignedOut();
      return;
    }
    final ending = ref.read(sessionProvider).signOut();
    state = const SignedOut();
    await ending;
  }

  /// The API refused a refresh in the middle of a session: sign in again.
  /// The redirect remembers the address they were on.
  void sessionEnded() {
    if (state is! SignedOut) state = const SignedOut();
  }

  /// Dev flavour only: spoils the access token's signature, so the next
  /// requests get a 401, as after the API restarts with a new key. Used to
  /// show single-flight refresh without waiting five minutes.
  void spoilAccessTokenForDemo() {
    _devOnly();
    if (ref.read(accessTokenProvider) case final token?) {
      ref
          .read(accessTokenProvider.notifier)
          .save('${token.value}x', expiresAt: token.expiresAt);
    }
  }

  /// Dev flavour only: makes the access token look about to expire, so the
  /// next request refreshes first, with no 401 at all.
  void expireAccessTokenForDemo() {
    _devOnly();
    if (ref.read(accessTokenProvider) case final token?) {
      ref
          .read(accessTokenProvider.notifier)
          .save(token.value, expiresAt: DateTime.now());
    }
  }

  void _devOnly() {
    if (ref.read(appConfigProvider).flavor != Flavor.dev) {
      throw StateError('Demo tools exist in the dev flavour only.');
    }
  }

  // Who the token says is signed in. Read for the shell and "my" data;
  // the API checks the token itself on every request.
  AuthState _signedInAs(SessionToken token) {
    final claims = claimsOf(token.value);
    if (claims == null) return const SignedOut();
    final role = Role.values.where((r) => r.label == claims.role).firstOrNull;
    if (role == null) return const SignedOut();
    return SignedIn(
      AppUser(
        email: claims.email,
        displayName: claims.email,
        role: role,
        studentId: claims.studentId,
      ),
    );
  }
}
