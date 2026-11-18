import 'package:matric_compass/features/auth/domain/app_user.dart';

/// Week 10 Day 3: signed in or not. Sealed, so the redirect has to decide
/// every case.
///
/// Week 11 Day 2: a third case. On launch the app has a refresh token but
/// doesn't yet know whether the session is still good; that takes a call
/// to the API. With only two cases the app flashed the sign-in screen first.
sealed class AuthState {
  const new();
}

/// The session is being restored on launch. If [offline], the refresh
/// couldn't reach the API: the person is NOT signed out, just waiting.
final class Restoring extends AuthState {
  /// Creates the restoring state.
  const new({this.offline = false});

  /// True when the API couldn't be reached.
  final bool offline;
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
