@Tags(['live'])
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matric_compass/app/app_config.dart';
import 'package:matric_compass/app/app_config_provider.dart';
import 'package:matric_compass/core/errors/failure.dart';
import 'package:matric_compass/core/errors/result.dart';
import 'package:matric_compass/features/auth/domain/auth_state.dart';
import 'package:matric_compass/features/auth/presentation/auth_controller.dart';
import 'package:matric_compass/features/bursaries/data/bursary_repository_provider.dart';
import 'package:matric_compass/features/careers/data/careers_repository_provider.dart';
import 'package:matric_compass/features/dashboard/data/dashboard_repository_provider.dart';
import 'package:matric_compass/features/students/data/students_repository_provider.dart';

/// The value of an Ok, or the test fails with the Failure.
T _ok<T>(Result<T> result) => switch (result) {
  Ok(:final value) => value,
  Err(:final failure) => fail('Expected Ok, got $failure'),
};

/// The Failure of an Err, or the test fails.
Failure _err<T>(Result<T> result) => switch (result) {
  Err(:final failure) => failure,
  Ok() => fail('Expected Err, got Ok'),
};

/// Week 11 Day 1: the app's own providers against the real API, on a fresh
/// database (`docker compose down -v`, then `up`). Not run by CI.
///
/// ```text
/// flutter test --run-skipped --tags live \
///   --dart-define=DEV_PASSWORD=(SEED_USERS_PASSWORD from the API's .env)
/// ```
///
/// API_BASE_URL defaults to the laptop's own API; this runs on the laptop,
/// not on an emulator, so it is localhost and not 10.0.2.2.
void main() {
  const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5146',
  );

  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer.test(
      overrides: [
        appConfigProvider.overrideWithValue(
          const AppConfig(flavor: Flavor.dev, apiBaseUrl: baseUrl),
        ),
      ],
      retry: (retryCount, error) => null,
    );
  });

  Future<void> signIn(String email) async {
    final result = await container
        .read(authControllerProvider.notifier)
        .signIn(email);
    _ok(result);
  }

  test('the learner, the counsellor, and every failure on the way', () async {
    // The counsellor finds Sipho's application: Thandiwe must not see it.
    await signIn('counsellor@matric-compass.test');
    final students = await container
        .read(studentsRepositoryProvider)
        .fetchAll();
    final sipho = _ok(students)
        .firstWhere((s) => s.fullName == 'Sipho Dlamini');
    final profile = await container
        .read(studentsRepositoryProvider)
        .fetchById(sipho.id);
    final siphoApplicationId = _ok(profile).applications.first.id;

    // Thandiwe's dashboard: the seeded NSFAS Draft, mapped to our types.
    await signIn('thandiwe@matric-compass.test');
    final dashboard = await container
        .read(dashboardRepositoryProvider)
        .fetchDashboard();
    final nsfas = _ok(dashboard).bursaryApplications.single;
    expect(nsfas.funder, 'NSFAS');
    printOnFailure('NSFAS ${nsfas.id}');

    // Careers, scoped by her token.
    final tests = await container
        .read(careersRepositoryProvider)
        .fetchAptitudeTests();
    expect(_ok(tests).single.recommendedCareers, hasLength(3));

    // 404: Sipho's application is simply not found for her.
    final notHers = await container
        .read(bursaryRepositoryProvider)
        .fetchById(siphoApplicationId);
    final notFound = _err(notHers);
    expect(notFound, isA<NotFoundFailure>());
    expect(notFound.correlationId, hasLength(32));

    // 422: submitting without documents names the missing ones.
    final submit = await container
        .read(bursaryRepositoryProvider)
        .submit(nsfas.id);
    expect(_err(submit), isA<RuleFailure>());
    expect(
      _err(submit).message,
      'Upload these documents first: Certified ID Copy, '
      'Proof of Household Income.',
    );

    // 403: a staff endpoint for a learner. A message; she stays signed in.
    final staffOnly = await container
        .read(studentsRepositoryProvider)
        .fetchAll();
    expect(_err(staffOnly), isA<ForbiddenFailure>());
    expect(container.read(authControllerProvider), isA<SignedIn>());
  });

  test('a wrong address is OfflineFailure, not a crash', () async {
    final offline = ProviderContainer.test(
      overrides: [
        appConfigProvider.overrideWithValue(
          const AppConfig(flavor: Flavor.dev, apiBaseUrl: 'http://localhost:1'),
        ),
      ],
    );
    final result = await offline
        .read(authControllerProvider.notifier)
        .signIn('thandiwe@matric-compass.test');
    expect(_err(result), isA<OfflineFailure>());
  });
}
