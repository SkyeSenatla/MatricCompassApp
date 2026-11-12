import 'package:matric_compass/app/router/routes.dart';
import 'package:matric_compass/features/auth/domain/app_user.dart';
import 'package:matric_compass/features/auth/domain/auth_state.dart';

/// Week 10 Day 3: the one gate every navigation passes. A pure function of
/// the sign-in state and the address, so a plain test can check every rule.
/// It returns the address to go to instead, or null to stay.
///
/// A courtesy, not security: the API still refuses a learner on a staff
/// endpoint with a 403, whatever the app does.
String? redirectFor(AuthState auth, Uri location) {
  final path = location.path;
  final signIn = const SignInRoute().location;

  switch (auth) {
    case SignedOut():
      if (path == signIn) return null;
      if (path.isEmpty || path == '/') return signIn;
      // Remember where they were going, as a path inside the app only.
      return SignInRoute(from: _inApp(location)).location;

    case SignedIn(:final user):
      final home = homeFor(user.role);
      if (path == signIn) {
        // Go on to where they were going, if it's safe and theirs.
        final from = location.queryParameters['from'];
        return from != null && isSafeFor(user.role, from) ? from : home;
      }
      if (path.isEmpty || path == '/') return home;
      // The wrong role's screens: their own shell's first tab instead.
      if (user.role.isStaff && isLearnerPath(path)) return home;
      if (!user.role.isStaff && isStaffPath(path)) return home;
      return null;
  }
}

/// The first tab of [role]'s shell.
String homeFor(Role role) =>
    role.isStaff ? const StudentsRoute().location : const HomeRoute().location;

/// The learner shell's addresses.
bool isLearnerPath(String path) => const [
  '/home',
  '/bursaries',
  '/careers',
  '/profile',
].any((prefix) => _under(path, prefix));

/// The staff shell's addresses.
bool isStaffPath(String path) => _under(path, '/staff');

/// True when [from] may be followed after sign-in: a path inside the app,
/// in [role]'s own shell. The same rule as Week 9's ?next=: never an
/// address taken whole from outside.
bool isSafeFor(Role role, String from) {
  if (!from.startsWith('/') || from.startsWith('//') || from.contains(r'\')) {
    return false;
  }
  final uri = Uri.tryParse(from);
  if (uri == null || uri.hasScheme || uri.hasAuthority) return false;
  return role.isStaff ? isStaffPath(uri.path) : isLearnerPath(uri.path);
}

bool _under(String path, String prefix) =>
    path == prefix || path.startsWith('$prefix/');

// A deep link may arrive as a whole URI (scheme, host and all). Keep only
// the path and query: that's the in-app address.
String _inApp(Uri location) => Uri(
  path: location.path,
  query: location.hasQuery ? location.query : null,
).toString();
