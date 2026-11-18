@Tags(['live'])
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matric_compass/app/app_config.dart';
import 'package:matric_compass/app/app_config_provider.dart';
import 'package:matric_compass/app/network/dio_provider.dart';
import 'package:matric_compass/core/errors/failure.dart';
import 'package:matric_compass/core/errors/result.dart';
import 'package:matric_compass/core/network/access_token.dart';
import 'package:matric_compass/core/network/refresh_token_store.dart';
import 'package:matric_compass/features/auth/data/auth_api.dart';
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
///   --dart-define=SEED_PASSWORD=(SEED_USERS_PASSWORD from the API's .env)
/// ```
///
/// API_BASE_URL defaults to the laptop's own API; this runs on the laptop,
/// not on an emulator, so it is localhost and not 10.0.2.2.
///
/// Week 11 Day 2: five sign-ins in all, the API's limit per minute. Run it
/// once, not twice in a row.
void main() {
  const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5146',
  );
  const password = String.fromEnvironment('SEED_PASSWORD');

  late ProviderContainer container;
  late _CountingStore store;

  setUp(() {
    store = _CountingStore();
    container = ProviderContainer.test(
      overrides: [
        appConfigProvider.overrideWithValue(
          const AppConfig(flavor: Flavor.dev, apiBaseUrl: baseUrl),
        ),
        // No Keystore on the laptop: the session's store, in memory.
        refreshTokenStoreProvider.overrideWithValue(store),
      ],
      retry: (retryCount, error) => null,
    );
  });

  Future<void> signIn(String email) async {
    final result = await container
        .read(authControllerProvider.notifier)
        .signIn(email, password);
    _ok(result);
  }

  // Week 11 Day 2: the session against the real API.
  group('the session', () {
    test(
      'three requests with a spoiled token: one refresh, all answered',
      () async {
        await signIn('thandiwe@matric-compass.test');
        final writesAfterSignIn = store.writes;
        final token = container.read(accessTokenProvider)!;
        container
            .read(accessTokenProvider.notifier)
            .save('${token.value}x', expiresAt: token.expiresAt);

        final careers = container.read(careersRepositoryProvider);
        final results = await Future.wait([
          container.read(dashboardRepositoryProvider).fetchDashboard(),
          careers.fetchAptitudeTests(),
          careers.fetchTertiaryApplications(),
        ]);

        for (final result in results) {
          expect(result, isA<Ok<Object?>>());
        }
        // One refresh: one new refresh token stored.
        expect(store.writes - writesAfterSignIn, 1);
        expect(container.read(authControllerProvider), isA<SignedIn>());
      },
    );

    test('a spent refresh token, presented again, ends the session', () async {
      await signIn('thandiwe@matric-compass.test');
      final first = (await store.read())!;
      final api = AuthApi(
        container.read(bareDioProvider),
        cookieName: 'refresh_token',
      );

      final second = (await api.refresh(first)).refreshToken;
      // The app presenting the spent one: what two parallel refreshes do.
      await expectLater(api.refresh(first), throwsA(isA<DioException>()));
      // Reuse detection revoked the newer token too.
      await expectLater(api.refresh(second), throwsA(isA<DioException>()));
    });

    test('after sign-out, the old refresh token is dead', () async {
      await signIn('thandiwe@matric-compass.test');
      final stored = (await store.read())!;

      await container.read(authControllerProvider.notifier).signOut();

      expect(await store.read(), isNull);
      expect(container.read(accessTokenProvider), isNull);
      final api = AuthApi(
        container.read(bareDioProvider),
        cookieName: 'refresh_token',
      );
      await expectLater(api.refresh(stored), throwsA(isA<DioException>()));
    });
  });

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
        refreshTokenStoreProvider.overrideWithValue(_CountingStore()),
      ],
    );
    final result = await offline
        .read(authControllerProvider.notifier)
        .signIn('thandiwe@matric-compass.test', password);
    expect(_err(result), isA<OfflineFailure>());
  });
}

/// An in-memory store that counts writes: one write per refresh.
class _CountingStore implements RefreshTokenStore {
  final _inner = InMemoryRefreshTokenStore();
  int writes = 0;

  @override
  Future<String?> read() => _inner.read();

  @override
  Future<void> write(String token) {
    writes++;
    return _inner.write(token);
  }

  @override
  Future<void> delete() => _inner.delete();
}
