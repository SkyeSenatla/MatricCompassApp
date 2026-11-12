import 'package:matric_compass/features/auth/data/fake_personas.dart';
import 'package:matric_compass/features/auth/domain/auth_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_controller.g.dart';

/// Week 10 Day 3: the fake sign-in state. The router listens to it, so the
/// redirect runs again whenever someone signs in or out.
///
/// keepAlive: the session must outlive every screen. Week 11 Day 2 replaces
/// the body with the real session; the router doesn't change.
@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  @override
  AuthState build() => const SignedOut();

  /// Signs in as the persona with [email]. Returns false for an unknown
  /// email, and stays signed out.
  bool signIn(String email) {
    final wanted = email.trim().toLowerCase();
    for (final persona in FakePersonas.all) {
      if (persona.email == wanted) {
        state = SignedIn(persona);
        return true;
      }
    }
    return false;
  }

  /// Signs out. The redirect then sends the app to sign-in.
  void signOut() => state = const SignedOut();
}
