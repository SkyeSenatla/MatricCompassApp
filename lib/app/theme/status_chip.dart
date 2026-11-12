import 'package:flutter/material.dart';
import 'package:matric_compass/app/theme/app_tokens.dart';
import 'package:matric_compass/app/theme/status_colors.dart';

/// Week 10 Day 4: a status in words, on its colour pair from the theme.
/// Day 3's bursary chip, lifted out once a second status (the university
/// pipeline) needed the same look. Words first: the colour helps people see
/// it faster; it never says it alone.
class StatusChip extends StatelessWidget {
  /// Creates a chip that reads [label], coloured by [colors].
  const new({required this.label, required this.colors, super.key});

  /// What the chip says.
  final String label;

  /// Its background and text colours, from the theme's status tokens.
  final StatusColor colors;

  @override
  Widget build(BuildContext context) {
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
          label,
          style: Theme.of(context).textTheme.labelLarge
              ?.copyWith(color: colors.foreground),
        ),
      ),
    );
  }
}
