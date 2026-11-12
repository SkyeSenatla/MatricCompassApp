import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matric_compass/app/theme/app_theme.dart';
import 'package:matric_compass/app/theme/status_colors.dart';
import 'package:matric_compass/core/fakes/seed.dart';
import 'package:matric_compass/features/careers/data/careers_repository_provider.dart';
import 'package:matric_compass/features/careers/data/fake_careers_repository.dart';
import 'package:matric_compass/features/careers/domain/aptitude_test.dart';
import 'package:matric_compass/features/careers/domain/careers_repository.dart';
import 'package:matric_compass/features/careers/domain/tertiary_application.dart';
import 'package:matric_compass/features/careers/presentation/careers_screen.dart';

/// Fails every call: the failure state.
class _FailingRepository implements CareersRepository {
  @override
  Future<List<AptitudeTest>> fetchAptitudeTests() =>
      Future.error(Exception('The network is down'));

  @override
  Future<List<TertiaryApplication>> fetchTertiaryApplications() =>
      Future.error(Exception('The network is down'));
}

/// Pumps the Careers screen, [width] wide, with [repository] behind the
/// provider. The app's own theme, because the chips read our status tokens
/// from it: without the extension they have no colours to read.
Future<void> _pumpCareers(
  WidgetTester tester,
  CareersRepository repository, {
  double width = 400,
  double textScale = 1,
}) async {
  tester.view
    ..physicalSize = Size(width, 800)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [careersRepositoryProvider.overrideWithValue(repository)],
      retry: (retryCount, error) => null,
      child: MaterialApp(theme: AppTheme.light(), home: const CareersScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

FakeCareersRepository _thandiwe() =>
    FakeCareersRepository(ownerId: Seed.thandiweId, latency: Duration.zero);

void main() {
  testWidgets('shows her test with the careers the API recommends', (
    tester,
  ) async {
    await _pumpCareers(tester, _thandiwe());

    expect(find.text('Career Interest Inventory'), findsOneWidget);
    expect(find.textContaining('Score 82 out of 100'), findsOneWidget);
    for (final career in ['Computer Science', 'Accounting', 'Architecture']) {
      expect(find.text(career), findsOneWidget);
    }
  });

  testWidgets('each application shows its stage in words, coloured', (
    tester,
  ) async {
    await _pumpCareers(tester, _thandiwe());

    expect(find.text('University of Pretoria'), findsOneWidget);
    expect(find.text('Researching'), findsOneWidget);
    expect(find.text('Offered'), findsOneWidget);
    expect(find.text('Status not recognised'), findsOneWidget);
    expect(find.text('University of Johannesburg'), findsNothing);

    final offered = tester.widget<Text>(find.text('Offered'));
    expect(offered.style?.color, StatusColors.light.underReview.foreground);
  });

  testWidgets('a new learner sees the empty state', (tester) async {
    await _pumpCareers(
      tester,
      FakeCareersRepository(ownerId: 'new-learner', latency: Duration.zero),
    );

    expect(
      find.textContaining('No aptitude tests or university applications yet'),
      findsOneWidget,
    );
  });

  testWidgets('a failure shows a way to try again', (tester) async {
    await _pumpCareers(tester, _FailingRepository());

    expect(find.text("We couldn't load your careers."), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('a narrow pane stacks the lists', (tester) async {
    await _pumpCareers(tester, _thandiwe());

    final tests = tester.getTopLeft(find.text('Aptitude tests'));
    final applications = tester.getTopLeft(
      find.text('University applications'),
    );
    expect(applications.dy, greaterThan(tests.dy));
    expect(applications.dx, tests.dx);
  });

  testWidgets('a wide pane puts them side by side', (tester) async {
    await _pumpCareers(tester, _thandiwe(), width: 1000);

    final tests = tester.getTopLeft(find.text('Aptitude tests'));
    final applications = tester.getTopLeft(
      find.text('University applications'),
    );
    expect(applications.dy, tests.dy);
    expect(applications.dx, greaterThan(tests.dx));
  });

  testWidgets('360 dp at 200% text: nothing overflows', (tester) async {
    await _pumpCareers(tester, _thandiwe(), width: 360, textScale: 2);

    expect(tester.takeException(), isNull);
  });
}
