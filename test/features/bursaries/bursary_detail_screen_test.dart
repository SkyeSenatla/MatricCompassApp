import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matric_compass/app/theme/app_theme.dart';
import 'package:matric_compass/core/errors/failure.dart';
import 'package:matric_compass/core/errors/result.dart';
import 'package:matric_compass/core/fakes/seed.dart';
import 'package:matric_compass/features/bursaries/data/bursary_repository_provider.dart';
import 'package:matric_compass/features/bursaries/data/fake_bursary_repository.dart';
import 'package:matric_compass/features/bursaries/domain/bursary_application.dart';
import 'package:matric_compass/features/bursaries/domain/bursary_repository.dart';
import 'package:matric_compass/features/bursaries/presentation/bursary_detail_screen.dart';
import 'package:matric_compass/features/dashboard/data/dashboard_repository_provider.dart';
import 'package:matric_compass/features/dashboard/data/fake_dashboard_repository.dart';

/// Shows a Draft, then answers Submit with [answer]: the API's decision.
class _AnswersSubmit implements BursaryRepository {
  new(this.answer);

  final Failure answer;
  final _fake = FakeBursaryRepository(latency: Duration.zero);

  @override
  Future<Result<BursaryApplication>> fetchById(String id) =>
      _fake.fetchById(id);

  @override
  Future<Result<List<BursaryApplication>>> fetchForReview() =>
      _fake.fetchForReview();

  @override
  Future<Result<BursaryApplication>> submit(String id) async => Err(answer);
}

Future<void> _pumpDetail(WidgetTester tester, BursaryRepository repository) =>
    tester.pumpWidget(
      ProviderScope(
        overrides: [
          bursaryRepositoryProvider.overrideWithValue(repository),
          dashboardRepositoryProvider.overrideWithValue(
            FakeDashboardRepository(latency: Duration.zero),
          ),
        ],
        retry: (retryCount, error) => null,
        child: MaterialApp(
          // The app's theme: the status chip reads our tokens from it.
          theme: AppTheme.light(),
          home: const BursaryDetailScreen(id: Seed.nsfasId),
        ),
      ),
    );

void main() {
  // Week 11 Day 1: Submit calls the repository, and the API decides.
  testWidgets('a Draft submits, and the screen shows the new status', (
    tester,
  ) async {
    await _pumpDetail(tester, FakeBursaryRepository(latency: Duration.zero));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
    await tester.pumpAndSettle();

    expect(find.text('Submitted. Your counsellor will review it.'), findsOne);
    // Fetched again after the submit: it isn't a Draft any more.
    expect(find.widgetWithText(FilledButton, 'Submit'), findsNothing);
  });

  testWidgets("a 422 shows the API's list of missing documents", (
    tester,
  ) async {
    await _pumpDetail(
      tester,
      _AnswersSubmit(
        const RuleFailure(
          detail:
              'Upload these documents first: Certified ID Copy, '
              'Proof of Household Income.',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Upload these documents first'), findsOneWidget);
  });

  testWidgets('a server failure shows a reference that stays', (tester) async {
    await _pumpDetail(
      tester,
      _AnswersSubmit(const ServerFailure(correlationId: 'abc123')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
    await tester.pumpAndSettle();
    // Four seconds would hide an ordinary SnackBar. This one stays.
    await tester.pump(const Duration(minutes: 1));

    expect(find.textContaining('Reference abc123'), findsOneWidget);
    expect(find.widgetWithText(SnackBarAction, 'Copy'), findsOneWidget);
  });

  testWidgets("someone else's application is simply not found", (tester) async {
    await _pumpDetail(
      tester,
      FakeBursaryRepository(latency: Duration.zero, ownerId: 'someone-else'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Application not found.'), findsOneWidget);
    expect(find.textContaining('permission'), findsNothing);
  });
}
