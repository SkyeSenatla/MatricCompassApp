import 'package:flutter_test/flutter_test.dart';
import 'package:matric_compass/app/router/redirect.dart';
import 'package:matric_compass/app/router/routes.dart';
import 'package:matric_compass/features/auth/data/fake_personas.dart';
import 'package:matric_compass/features/auth/domain/app_user.dart';
import 'package:matric_compass/features/auth/domain/auth_state.dart';

void main() {
  const signedOut = SignedOut();
  const learner = SignedIn(FakePersonas.thandiwe);
  const counsellor = SignedIn(FakePersonas.counsellor);
  const admin = SignedIn(FakePersonas.admin);

  String? go(AuthState auth, String location) =>
      redirectFor(auth, Uri.parse(location));

  group('signed out', () {
    test('any address goes to sign-in, remembering it', () {
      final result = Uri.parse(go(signedOut, '/bursaries/abc')!);
      expect(result.path, '/sign-in');
      expect(result.queryParameters['from'], '/bursaries/abc');
    });

    test('sign-in itself stays', () {
      expect(go(signedOut, '/sign-in'), isNull);
    });

    test('the root goes to sign-in with nothing to remember', () {
      expect(go(signedOut, '/'), '/sign-in');
    });

    test('a deep link as a whole URI keeps only the in-app path', () {
      final result = Uri.parse(
        go(signedOut, 'matriccompass-dev://app/bursaries/abc')!,
      );
      expect(result.queryParameters['from'], '/bursaries/abc');
    });
  });

  group('signing in', () {
    test('goes on to where the learner was going', () {
      final from = const BursaryDetailRoute(id: 'abc').location;
      expect(go(learner, SignInRoute(from: from).location), from);
    });

    test('with nowhere remembered, goes to the role home', () {
      expect(go(learner, '/sign-in'), '/home');
      expect(go(counsellor, '/sign-in'), '/staff/students');
      expect(go(admin, '/sign-in'), '/staff/students');
    });

    for (final unsafe in [
      '//evil.example/bursaries',
      'https://evil.example/bursaries',
      r'/\evil.example',
      'bursaries/abc',
    ]) {
      test('never follows an address from outside: $unsafe', () {
        expect(go(learner, SignInRoute(from: unsafe).location), '/home');
      });
    }

    test("never follows into the other role's shell", () {
      expect(
        go(learner, const SignInRoute(from: '/staff/students').location),
        '/home',
      );
      expect(
        go(counsellor, const SignInRoute(from: '/bursaries/abc').location),
        '/staff/students',
      );
    });
  });

  group('signed in', () {
    test("a learner's own screens stay", () {
      expect(go(learner, '/bursaries/abc'), isNull);
      expect(go(learner, '/home'), isNull);
    });

    test("the wrong role's screens go to the role home", () {
      expect(go(learner, '/staff/students/abc'), '/home');
      expect(go(counsellor, '/bursaries/abc'), '/staff/students');
    });

    test('the root goes to the role home', () {
      expect(go(learner, '/'), '/home');
      expect(go(admin, '/'), '/staff/students');
    });
  });

  test('every typed route sits in the right shell', () {
    final learnerRoutes = [
      const HomeRoute().location,
      const BursariesRoute().location,
      const BursaryDetailRoute(id: 'x').location,
      const CareersRoute().location,
      const ProfileRoute().location,
    ];
    final staffRoutes = [
      const StudentsRoute().location,
      const StudentDetailRoute(id: 'x').location,
      const ApplicationsRoute().location,
      const StaffApplicationRoute(id: 'x').location,
      const StaffProfileRoute().location,
    ];
    for (final location in learnerRoutes) {
      expect(isSafeFor(Role.learner, location), isTrue, reason: location);
      expect(isStaffPath(location), isFalse, reason: location);
    }
    for (final location in staffRoutes) {
      expect(isSafeFor(Role.counsellor, location), isTrue, reason: location);
      expect(isLearnerPath(location), isFalse, reason: location);
    }
  });
}
