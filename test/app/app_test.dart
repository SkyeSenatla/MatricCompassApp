import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matric_compass/app/app.dart';
import 'package:matric_compass/app/app_config.dart';
import 'package:matric_compass/app/retry_policy.dart';
import 'package:matric_compass/app/router/router_provider.dart';
import 'package:matric_compass/app/theme/status_colors.dart';
import 'package:matric_compass/core/fakes/fake_latency_provider.dart';
import 'package:matric_compass/core/fakes/seed.dart';
import 'package:matric_compass/features/auth/data/fake_personas.dart';
import 'package:matric_compass/features/auth/presentation/auth_controller.dart';

const _phone = Size(400, 800);
const _tabletUpright = Size(700, 1000);
const _tabletOnItsSide = Size(1000, 700);

/// Week 10 Day 3: the whole app, on fakes with no delay. [deepLink] is the
/// address the platform starts the app at: a cold start from a link.
Future<ProviderContainer> _pumpApp(
  WidgetTester tester, {
  String? signedInAs,
  String? deepLink,
  Size size = _phone,
  double textScale = 1,
  Brightness brightness = Brightness.light,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  tester.platformDispatcher
    ..textScaleFactorTestValue = textScale
    ..platformBrightnessTestValue = brightness;
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  if (deepLink != null) {
    tester.platformDispatcher.defaultRouteNameTestValue = deepLink;
  }

  final container = ProviderContainer.test(
    overrides: [fakeLatencyProvider.overrideWithValue(Duration.zero)],
    // The app's own policy, as main() uses it.
    retry: appRetryPolicy,
  );
  if (signedInAs != null) {
    container.read(authControllerProvider.notifier).signIn(signedInAs);
  }
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MatricCompassApp(
        config: AppConfig(flavor: Flavor.prod, apiBaseUrl: 'https://x'),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

String _location(ProviderContainer container) => container
    .read(routerProvider)
    .routerDelegate
    .currentConfiguration
    .uri
    .toString();

Future<void> _go(
  WidgetTester tester,
  ProviderContainer container,
  String location,
) async {
  container.read(routerProvider).go(location);
  await tester.pumpAndSettle();
}

Finder _tab(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

const _nsfas = '/bursaries/${Seed.nsfasId}';
const _thandiweAsStaff = '/staff/students/${Seed.thandiweId}';

void main() {
  group('the gate', () {
    testWidgets('signed out, the app opens on sign-in', (tester) async {
      await _pumpApp(tester);

      expect(find.text('Choose an account'), findsOneWidget);
    });

    testWidgets('a link opened while signed out still arrives', (tester) async {
      final container = await _pumpApp(tester, deepLink: _nsfas);
      expect(find.text('Choose an account'), findsOneWidget);

      await tester.tap(find.text(Seed.thandiweName));
      await tester.pumpAndSettle();

      expect(_location(container), _nsfas);
      expect(find.text('Bursary application'), findsOneWidget);
      expect(find.text('NSFAS'), findsOneWidget);
    });

    testWidgets("a learner can't reach the staff shell", (tester) async {
      final container = await _pumpApp(
        tester,
        signedInAs: FakePersonas.thandiwe.email,
      );

      await _go(tester, container, '/staff/students');

      expect(_location(container), '/home');
      expect(find.text('Hello, ${Seed.thandiweName}'), findsOneWidget);
    });

    testWidgets('a counsellor lands in the staff shell', (tester) async {
      final container = await _pumpApp(tester);

      await tester.tap(find.text('Counsellor'));
      await tester.pumpAndSettle();

      expect(_location(container), '/staff/students');
      expect(_tab('Applications'), findsOneWidget);
      expect(find.text('Ayanda Zulu'), findsOneWidget);
    });

    testWidgets('signing out goes back to sign-in', (tester) async {
      final container = await _pumpApp(
        tester,
        signedInAs: FakePersonas.thandiwe.email,
      );
      await tester.tap(_tab('Profile'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();

      expect(Uri.parse(_location(container)).path, '/sign-in');
      expect(find.text('Choose an account'), findsOneWidget);
    });
  });

  group('addresses', () {
    testWidgets('a cold start at a detail builds the list underneath', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        signedInAs: FakePersonas.thandiwe.email,
        deepLink: _nsfas,
      );
      expect(find.text('Bursary application'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      // Back shows her bursaries, not a closed app.
      expect(find.text('Funza Lushaka'), findsOneWidget);
      expect(_tab('Bursaries'), findsOneWidget);
    });

    testWidgets("another learner's application is just not found", (
      tester,
    ) async {
      final container = await _pumpApp(
        tester,
        signedInAs: FakePersonas.thandiwe.email,
      );

      await _go(tester, container, '/bursaries/${Seed.siphoApplicationId}');
      final notYours = find.text('Application not found.');
      expect(notYours, findsOneWidget);

      await _go(tester, container, '/bursaries/never-existed');
      // Exactly the same words: the app doesn't confirm Sipho's id is real.
      expect(find.text('Application not found.'), findsOneWidget);
      expect(find.textContaining('access'), findsNothing);
    });

    testWidgets('not found shows at once: it is never retried', (tester) async {
      final container = await _pumpApp(
        tester,
        signedInAs: FakePersonas.thandiwe.email,
      );

      container
          .read(routerProvider)
          .go('/bursaries/${Seed.siphoApplicationId}');
      // A few frames, no settling: a retried error would still be loading.
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('Application not found.'), findsOneWidget);
    });

    testWidgets('an address with no screen is a page, not a crash', (
      tester,
    ) async {
      final container = await _pumpApp(
        tester,
        signedInAs: FakePersonas.thandiwe.email,
      );

      await _go(tester, container, '/bursary/typo');
      expect(find.text('Page not found.'), findsOneWidget);

      await tester.tap(find.text('Go home'));
      await tester.pumpAndSettle();
      expect(_location(container), '/home');
    });

    testWidgets('each tab keeps its own stack', (tester) async {
      await _pumpApp(tester, signedInAs: FakePersonas.thandiwe.email);

      await tester.tap(_tab('Bursaries'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('NSFAS'));
      await tester.pumpAndSettle();
      expect(find.text('Bursary application'), findsOneWidget);

      await tester.tap(_tab('Careers'));
      await tester.pumpAndSettle();
      await tester.tap(_tab('Bursaries'));
      await tester.pumpAndSettle();

      // NSFAS is still open on the Bursaries tab.
      expect(find.text('Bursary application'), findsOneWidget);
    });
  });

  group('adaptive', () {
    testWidgets('a phone gets a bottom bar, a tablet a rail', (tester) async {
      await _pumpApp(tester, signedInAs: FakePersonas.thandiwe.email);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);

      tester.view.physicalSize = _tabletUpright;
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsNothing);
      expect(find.byType(NavigationRail), findsOneWidget);
    });

    testWidgets('840 dp and wider: list and detail side by side', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        signedInAs: FakePersonas.counsellor.email,
        deepLink: _thandiweAsStaff,
        size: _tabletOnItsSide,
      );

      expect(find.text('Ayanda Zulu'), findsOneWidget);
      expect(find.text('Bursary applications'), findsOneWidget);
      // Selected in the list, and shown in the detail.
      expect(find.text(Seed.thandiweName), findsNWidgets(2));
    });

    testWidgets('a phone shows the same address as the detail alone', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        signedInAs: FakePersonas.counsellor.email,
        deepLink: _thandiweAsStaff,
      );

      expect(find.text('Ayanda Zulu'), findsNothing);
      expect(find.text('Bursary applications'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Ayanda Zulu'), findsOneWidget);
    });

    testWidgets('turning the tablet upright keeps the student', (tester) async {
      final container = await _pumpApp(
        tester,
        signedInAs: FakePersonas.counsellor.email,
        deepLink: _thandiweAsStaff,
        size: _tabletOnItsSide,
      );
      expect(find.text('Ayanda Zulu'), findsOneWidget);

      tester.view.physicalSize = _tabletUpright;
      await tester.pumpAndSettle();

      expect(_location(container), _thandiweAsStaff);
      expect(find.text('Ayanda Zulu'), findsNothing);
      expect(find.text('Bursary applications'), findsOneWidget);
    });

    for (final (persona, tabs) in [
      (FakePersonas.thandiwe, ['Home', 'Bursaries', 'Careers', 'Profile']),
      (FakePersonas.counsellor, ['Students', 'Applications', 'Profile']),
    ]) {
      testWidgets('${persona.role.label}: 360 dp at 200% text, no overflow', (
        tester,
      ) async {
        await _pumpApp(
          tester,
          signedInAs: persona.email,
          size: const Size(360, 780),
          textScale: 2,
        );
        for (final tab in tabs) {
          await tester.tap(_tab(tab));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: tab);
        }
      });
    }
  });

  testWidgets('Careers: her tests and applications, in the learner shell', (
    tester,
  ) async {
    final container = await _pumpApp(
      tester,
      signedInAs: FakePersonas.thandiwe.email,
    );

    await tester.tap(_tab('Careers'));
    await tester.pumpAndSettle();

    expect(_location(container), '/careers');
    expect(find.text('Career Interest Inventory'), findsOneWidget);
    expect(find.text('University of Pretoria'), findsOneWidget);
  });

  testWidgets('dark mode reads the dark status colours', (tester) async {
    await _pumpApp(
      tester,
      signedInAs: FakePersonas.thandiwe.email,
      brightness: Brightness.dark,
    );
    await tester.tap(_tab('Bursaries'));
    await tester.pumpAndSettle();

    final draft = tester.widget<Text>(find.text('Draft'));
    expect(draft.style?.color, StatusColors.dark.draft.foreground);
  });
}
