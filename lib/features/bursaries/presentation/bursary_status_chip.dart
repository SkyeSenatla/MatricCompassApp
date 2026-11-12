import 'package:flutter/material.dart';
import 'package:matric_compass/app/theme/app_theme.dart';
import 'package:matric_compass/app/theme/status_chip.dart';
import 'package:matric_compass/features/bursaries/domain/bursary_status.dart';
import 'package:matric_compass/features/bursaries/presentation/bursary_status_label.dart';

/// Week 10 Day 3: a bursary status, in words first, coloured by the
/// theme's status tokens. Week 10 Day 4: drawn by the shared [StatusChip].
class BursaryStatusChip extends StatelessWidget {
  /// Creates the chip for [status].
  const new(this.status, {super.key});

  /// The status to show.
  final BursaryStatus status;

  @override
  Widget build(BuildContext context) => StatusChip(
    label: status.label,
    colors: Theme.of(context).statusColors.of(status),
  );
}
