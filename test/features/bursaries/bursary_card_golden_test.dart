import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matric_compass/app/theme/app_theme.dart';
import 'package:matric_compass/core/money/cents.dart';
import 'package:matric_compass/features/bursaries/domain/bursary_status.dart';
import 'package:matric_compass/features/bursaries/presentation/bursary_card.dart';
import 'package:matric_compass/features/dashboard/domain/learner_dashboard.dart';

/// Week 12 Day 1: the bursary card in every status, light and dark: the
/// one picture that shows a status colour drifting, a chip that wraps, or a
/// dark theme that isn't one. No finder sees those.
///
/// Make or update the pictures on purpose, then look at them:
///   flutter test --update-goldens --tags golden
void main() {
  BursarySummary summary(BursaryStatus status) => BursarySummary(
    id: 'b-${status.name}',
    funder: 'Funza Lushaka Bursary',
    status: status,
    deadline: DateTime.utc(2026, 12, 3),
    daysUntilDeadline: 10,
    amount: const Cents(4500000),
  );

  // The theme goes around each card, not the group, so alchemist's labels
  // above each card stay readable in the dark picture too.
  Widget cards(ThemeData theme) => GoldenTestGroup(
    columns: 2,
    children: [
      // Every status, unknown included: a status the API adds later still
      // gets a card that reads properly.
      for (final status in BursaryStatus.values)
        GoldenTestScenario(
          name: status.name,
          child: Theme(
            data: theme,
            child: ColoredBox(
              color: theme.colorScheme.surface,
              child: SizedBox(width: 360, child: BursaryCard(summary(status))),
            ),
          ),
        ),
    ],
  );

  // goldenTest registers its tests straight away; its Future is alchemist's
  // own bookkeeping, so nothing here waits for it.
  group('BursaryCard', () {
    unawaited(
      goldenTest(
        'in every status, light',
        fileName: 'bursary_card_light',
        builder: () => cards(AppTheme.light()),
      ),
    );

    unawaited(
      goldenTest(
        'in every status, dark',
        fileName: 'bursary_card_dark',
        builder: () => cards(AppTheme.dark()),
      ),
    );
  });
}
