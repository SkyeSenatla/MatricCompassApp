import 'package:flutter/material.dart';
import 'package:matric_compass/app/theme/app_theme.dart';
import 'package:matric_compass/app/theme/status_chip.dart';
import 'package:matric_compass/features/careers/domain/tertiary_status.dart';
import 'package:matric_compass/features/careers/presentation/tertiary_status_label.dart';

/// Week 10 Day 4: a university application's stage, in words first.
class TertiaryStatusChip extends StatelessWidget {
  /// Creates the chip for [status].
  const new(this.status, {super.key});

  /// The stage to show.
  final TertiaryStatus status;

  @override
  Widget build(BuildContext context) => StatusChip(
    label: status.label,
    colors: Theme.of(context).statusColors.ofTertiary(status),
  );
}
