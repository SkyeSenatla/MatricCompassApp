import 'package:matric_compass/features/auth/domain/app_user.dart';

/// Week 10 Day 3: signed in or not. Sealed, so the redirect has to decide
/// both cases.
sealed class AuthState {
  const new();
}

/// Nobody is signed in.
final class SignedOut extends AuthState {
  /// Creates the signed-out state.
  const new();
}

/// [user] is signed in.
final class SignedIn extends AuthState {
  /// Creates the signed-in state.
  const new(this.user);

  /// Who it is.
  final AppUser user;
}
