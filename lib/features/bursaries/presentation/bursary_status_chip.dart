import 'package:flutter/material.dart';
import 'package:matric_compass/app/theme/app_theme.dart';
import 'package:matric_compass/app/theme/app_tokens.dart';
import 'package:matric_compass/features/bursaries/domain/bursary_status.dart';
import 'package:matric_compass/features/bursaries/presentation/bursary_status_label.dart';

/// Week 10 Day 3: a status, in words first. The colour comes from the
/// theme's status tokens and helps people see it faster; it never says it
/// alone.
class BursaryStatusChip extends StatelessWidget {
  /// Creates the chip for [status].
  const new(this.status, {super.key});

  /// The status to show.
  final BursaryStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.statusColors.of(status);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(AppTokens.radius),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space2,
          vertical: AppTokens.space1,
        ),
        child: Text(
          status.label,
          style: theme.textTheme.labelLarge?.copyWith(color: colors.foreground),
        ),
      ),
    );
  }
}
