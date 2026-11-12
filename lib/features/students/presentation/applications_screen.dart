import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matric_compass/app/router/routes.dart';
import 'package:matric_compass/app/theme/app_tokens.dart';
import 'package:matric_compass/core/money/format_rands.dart';
import 'package:matric_compass/features/bursaries/presentation/bursary_status_chip.dart';
import 'package:matric_compass/features/students/presentation/students_providers.dart';

/// Week 10 Day 3: the staff Applications tab: every application waiting
/// for a counsellor.
class ApplicationsScreen extends ConsumerWidget {
  /// Creates the screen.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applications = ref.watch(applicationsForReviewProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Applications')),
      body: switch (applications) {
        AsyncData(:final value) when value.isEmpty => const Center(
          child: Text('Nothing is waiting for review.'),
        ),
        AsyncData(:final value) => ListView(
          padding: const EdgeInsets.all(AppTokens.space3),
          children: [
            for (final application in value)
              Card(
                child: ListTile(
                  title: Text(application.funder),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: AppTokens.space1),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: BursaryStatusChip(application.status),
                    ),
                  ),
                  trailing: Text(formatRands(application.amount)),
                  onTap: () =>
                      StaffApplicationRoute(id: application.id).go(context),
                ),
              ),
          ],
        ),
        AsyncError() => const Center(
          child: Text("We couldn't load the applications."),
        ),
        AsyncLoading() => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}
