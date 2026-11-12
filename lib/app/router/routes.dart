import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:matric_compass/app/router/app_shell.dart';
import 'package:matric_compass/features/auth/presentation/profile_screen.dart';
import 'package:matric_compass/features/auth/presentation/sign_in_screen.dart';
import 'package:matric_compass/features/bursaries/presentation/bursaries_screen.dart';
import 'package:matric_compass/features/bursaries/presentation/bursary_detail_screen.dart';
import 'package:matric_compass/features/careers/presentation/careers_screen.dart';
import 'package:matric_compass/features/dashboard/presentation/dashboard_screen.dart';
import 'package:matric_compass/features/students/presentation/applications_screen.dart';
import 'package:matric_compass/features/students/presentation/student_detail_page.dart';
import 'package:matric_compass/features/students/presentation/students_screen.dart';

part 'routes.g.dart';

// Week 10 Day 3: every screen has an address, and every address is a class.
// A mistyped path or a missing id is a compile error, not a "page not
// found" on someone's phone. go_router_builder writes routes.g.dart.
//
// The detail routes sit under their lists, so going to a detail's address
// builds the list underneath it: back has somewhere sensible to go, even
// after a cold start from a deep link.

/// Sign-in. [from] is where the person was going when the redirect stopped
/// them; the redirect only ever goes on to an address inside the app.
@TypedGoRoute<SignInRoute>(path: '/sign-in')
class SignInRoute extends GoRouteData with $SignInRoute {
  /// Creates the route.
  const new({this.from});

  /// The address to go on to after sign-in.
  final String? from;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const SignInScreen();
}

/// The learner's shell: Home, Bursaries, Careers and Profile, each tab
/// with its own navigator, so each keeps its own stack.
@TypedStatefulShellRoute<LearnerShellRoute>(
  branches: [
    TypedStatefulShellBranch<ShellBranch>(
      routes: [TypedGoRoute<HomeRoute>(path: '/home')],
    ),
    TypedStatefulShellBranch<ShellBranch>(
      routes: [
        TypedGoRoute<BursariesRoute>(
          path: '/bursaries',
          routes: [TypedGoRoute<BursaryDetailRoute>(path: ':id')],
        ),
      ],
    ),
    TypedStatefulShellBranch<ShellBranch>(
      routes: [TypedGoRoute<CareersRoute>(path: '/careers')],
    ),
    TypedStatefulShellBranch<ShellBranch>(
      routes: [TypedGoRoute<ProfileRoute>(path: '/profile')],
    ),
  ],
)
class LearnerShellRoute extends StatefulShellRouteData {
  /// Creates the shell.
  const new();

  @override
  Widget builder(
    BuildContext context,
    GoRouterState state,
    StatefulNavigationShell navigationShell,
  ) => AppShell(
    navigationShell: navigationShell,
    destinations: learnerDestinations,
  );
}

/// The counsellor's and admin's shell: Students, Applications and Profile.
/// A separate route tree, so a learner's link can't reach these screens in
/// the app. The API refuses a learner with a 403 either way.
@TypedStatefulShellRoute<StaffShellRoute>(
  branches: [
    TypedStatefulShellBranch<ShellBranch>(
      routes: [
        TypedGoRoute<StudentsRoute>(
          path: '/staff/students',
          routes: [TypedGoRoute<StudentDetailRoute>(path: ':id')],
        ),
      ],
    ),
    TypedStatefulShellBranch<ShellBranch>(
      routes: [
        TypedGoRoute<ApplicationsRoute>(
          path: '/staff/applications',
          routes: [TypedGoRoute<StaffApplicationRoute>(path: ':id')],
        ),
      ],
    ),
    TypedStatefulShellBranch<ShellBranch>(
      routes: [TypedGoRoute<StaffProfileRoute>(path: '/staff/profile')],
    ),
  ],
)
class StaffShellRoute extends StatefulShellRouteData {
  /// Creates the shell.
  const new();

  @override
  Widget builder(
    BuildContext context,
    GoRouterState state,
    StatefulNavigationShell navigationShell,
  ) => AppShell(
    navigationShell: navigationShell,
    destinations: staffDestinations,
  );
}

/// One tab of a shell. Nothing to configure, so every tab shares it.
class ShellBranch extends StatefulShellBranchData {
  /// Creates the branch.
  const new();
}

/// The learner's tabs, in branch order.
const learnerDestinations = [
  ShellDestination(
    label: 'Home',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
  ),
  ShellDestination(
    label: 'Bursaries',
    icon: Icons.request_page_outlined,
    selectedIcon: Icons.request_page,
  ),
  ShellDestination(
    label: 'Careers',
    icon: Icons.explore_outlined,
    selectedIcon: Icons.explore,
  ),
  ShellDestination(
    label: 'Profile',
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
  ),
];

/// The staff tabs, in branch order.
const staffDestinations = [
  ShellDestination(
    label: 'Students',
    icon: Icons.groups_outlined,
    selectedIcon: Icons.groups,
  ),
  ShellDestination(
    label: 'Applications',
    icon: Icons.fact_check_outlined,
    selectedIcon: Icons.fact_check,
  ),
  ShellDestination(
    label: 'Profile',
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
  ),
];

/// The learner's dashboard: /home.
class HomeRoute extends GoRouteData with $HomeRoute {
  /// Creates the route.
  const new();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const DashboardScreen();
}

/// The learner's applications: /bursaries.
class BursariesRoute extends GoRouteData with $BursariesRoute {
  /// Creates the route.
  const new();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const BursariesScreen();
}

/// One of the learner's applications: /bursaries/:id. The screen needs only
/// the id; it fetches the rest, so a cold start has nothing missing.
class BursaryDetailRoute extends GoRouteData with $BursaryDetailRoute {
  /// Creates the route for application [id].
  const new({required this.id});

  /// The application's id.
  final String id;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      BursaryDetailScreen(id: id);
}

/// Careers: /careers. Day 4 builds it.
class CareersRoute extends GoRouteData with $CareersRoute {
  /// Creates the route.
  const new();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const CareersScreen();
}

/// The learner's profile: /profile.
class ProfileRoute extends GoRouteData with $ProfileRoute {
  /// Creates the route.
  const new();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const ProfileScreen();
}

/// The counsellor's students: /staff/students.
class StudentsRoute extends GoRouteData with $StudentsRoute {
  /// Creates the route.
  const new();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const StudentsScreen();
}

/// One student: /staff/students/:id. One address, two layouts: the detail
/// on its own on a phone, list and detail together at 840 dp and wider.
class StudentDetailRoute extends GoRouteData with $StudentDetailRoute {
  /// Creates the route for student [id].
  const new({required this.id});

  /// The student's id: the address says what is selected.
  final String id;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      StudentDetailPage(id: id);
}

/// Applications waiting for review: /staff/applications.
class ApplicationsRoute extends GoRouteData with $ApplicationsRoute {
  /// Creates the route.
  const new();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const ApplicationsScreen();
}

/// One application, as staff see it: /staff/applications/:id.
class StaffApplicationRoute extends GoRouteData with $StaffApplicationRoute {
  /// Creates the route for application [id].
  const new({required this.id});

  /// The application's id.
  final String id;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      BursaryDetailScreen(id: id, forLearner: false);
}

/// The staff profile: /staff/profile.
class StaffProfileRoute extends GoRouteData with $StaffProfileRoute {
  /// Creates the route.
  const new();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const ProfileScreen();
}
