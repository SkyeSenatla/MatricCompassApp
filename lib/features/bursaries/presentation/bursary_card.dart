import 'package:flutter/material.dart';
import 'package:matric_compass/app/theme/app_tokens.dart';
import 'package:matric_compass/core/money/format_rands.dart';
import 'package:matric_compass/features/bursaries/presentation/bursary_status_chip.dart';
import 'package:matric_compass/features/dashboard/domain/learner_dashboard.dart';

/// Week 10 Day 3: one bursary application on the Bursaries tab: the funder,
/// its status in words, and the amount.
///
/// Week 12 Day 1: lifted out of the Bursaries screen into a widget of its
/// own, so a golden test can draw it in every status, light and dark,
/// with no screen, router or provider around it.
class BursaryCard extends StatelessWidget {
  /// Creates the card for [summary].
  const new(this.summary, {this.onTap, super.key});

  /// The application, as the dashboard has it.
  final BursarySummary summary;

  /// Opens the application.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(summary.funder),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: AppTokens.space1),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: BursaryStatusChip(summary.status),
          ),
        ),
        trailing: Text(formatRands(summary.amount)),
        onTap: onTap,
      ),
    );
  }
}
