import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matric_compass/app/theme/app_theme.dart';
import 'package:matric_compass/core/errors/failure.dart';
import 'package:matric_compass/core/errors/result.dart';
import 'package:matric_compass/core/fakes/seed.dart';
import 'package:matric_compass/core/money/cents.dart';
import 'package:matric_compass/features/bursaries/data/bursary_repository_provider.dart';
import 'package:matric_compass/features/bursaries/data/fake_bursary_repository.dart';
import 'package:matric_compass/features/bursaries/domain/bursary_application.dart';
import 'package:matric_compass/features/bursaries/domain/bursary_repository.dart';
import 'package:matric_compass/features/bursaries/presentation/bursary_detail_screen.dart';
import 'package:matric_compass/features/dashboard/data/dashboard_repository_provider.dart';
import 'package:matric_compass/features/dashboard/data/fake_dashboard_repository.dart';

import '../../support/test_database.dart';

/// Shows a Draft, then answers Submit with [submitAnswer] and an edit with
/// [editAnswer]: the API's decisions.
class _Answers implements BursaryRepository {
  new({this.submitAnswer, this.editAnswer});

  final Failure? submitAnswer;
  final Failure? editAnswer;
  final _fake = FakeBursaryRepository(latency: Duration.zero);

  @override
  Future<Result<BursaryApplication>> fetchById(String id) =>
      _fake.fetchById(id);

  @override
  Future<Result<List<BursaryApplication>>> fetchForReview() =>
      _fake.fetchForReview();

  @override
  Future<Result<BursaryApplication>> submit(String id) async =>
      switch (submitAnswer) {
        final failure? => Err(failure),
        null => await _fake.submit(id),
      };

  @override
  Future<Result<void>> update(
    String id, {
    required Cents amount,
    required DateTime deadline,
    required int version,
  }) async => switch (editAnswer) {
    final failure? => Err(failure),
    null => await _fake.update(
      id,
      amount: amount,
      deadline: deadline,
      version: version,
    ),
  };
}

Future<void> _pumpDetail(WidgetTester tester, BursaryRepository repository) =>
    tester.pumpWidget(
      ProviderScope(
        overrides: [
          bursaryRepositoryProvider.overrideWithValue(repository),
          dashboardRepositoryProvider.overrideWithValue(
            FakeDashboardRepository(latency: Duration.zero),
          ),
          // Week 11 Day 3: the screen reads the phone's cache.
          inMemoryDatabase,
        ],
        retry: (retryCount, error) => null,
        child: MaterialApp(
          // The app's theme: the status chip reads our tokens from it.
          theme: AppTheme.light(),
          home: const BursaryDetailScreen(id: Seed.nsfasId),
        ),
      ),
    );

/// Opens Edit, types [rands], and saves.
Future<void> _editAmount(WidgetTester tester, String rands) async {
  await tester.tap(find.widgetWithText(OutlinedButton, 'Edit'));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Amount in rands'),
    rands,
  );
  await tester.tap(find.widgetWithText(FilledButton, 'Save'));
  await tester.pumpAndSettle();
}

// Typed as an escape: a no-break space looks exactly like a space.
const _fiftyThousand = 'R\u00A050\u00A0000,00';

void main() {
  // Week 11 Day 1: Submit calls the repository, and the API decides.
  testWidgets('a Draft submits, and the screen shows the new status', (
    tester,
  ) async {
    await _pumpDetail(tester, _Answers());
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
      _Answers(
        submitAnswer: const RuleFailure(
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
      _Answers(submitAnswer: const ServerFailure(correlationId: 'abc123')),
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

  group('Week 11 Day 3: editing', () {
    testWidgets('saved: the new amount, and "Saved."', (tester) async {
      await _pumpDetail(tester, _Answers());
      await tester.pumpAndSettle();

      await _editAmount(tester, '50000');

      expect(find.text(_fiftyThousand), findsOneWidget);
      expect(find.text('Saved.'), findsOneWidget);
    });

    testWidgets('changed elsewhere: our words, and the old amount back', (
      tester,
    ) async {
      await _pumpDetail(
        tester,
        // What the API really sends for a stale version: EF Core's message.
        _Answers(
          editAnswer: const ConflictFailure(
            detail: 'The database operation was expected to affect 1 row(s)',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _editAmount(tester, '50000');

      expect(find.textContaining('changed somewhere else'), findsOneWidget);
      expect(find.textContaining('database operation'), findsNothing);
      expect(find.text(_fiftyThousand), findsNothing);
    });

    testWidgets('offline: shown, marked "Not saved yet", and kept', (
      tester,
    ) async {
      await _pumpDetail(tester, _Answers(editAnswer: const OfflineFailure()));
      await tester.pumpAndSettle();

      await _editAmount(tester, '50000');

      expect(find.text(_fiftyThousand), findsOneWidget);
      expect(find.textContaining('Not saved yet'), findsWidgets);
      expect(find.text('Send again'), findsOneWidget);
      expect(find.text('Discard'), findsOneWidget);
    });
  });
}
