import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matric_compass/app/router/routes.dart';
import 'package:matric_compass/app/theme/app_tokens.dart';
import 'package:matric_compass/core/money/format_rands.dart';
import 'package:matric_compass/features/bursaries/presentation/bursary_status_chip.dart';
import 'package:matric_compass/features/dashboard/presentation/dashboard_controller.dart';
import 'package:matric_compass/features/dashboard/presentation/dashboard_view.dart';

/// Week 10 Day 3: the learner's Bursaries tab. The same data as the
/// dashboard, so it reuses the dashboard's controller and view state.
/// Tapping one goes to its address, /bursaries/:id, on this tab's stack.
class BursariesScreen extends ConsumerWidget {
  /// Creates the screen.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = DashboardView.from(ref.watch(dashboardControllerProvider));
    final controller = ref.read(dashboardControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Bursaries')),
      body: switch (view) {
        DashboardLoading() => const Center(child: CircularProgressIndicator()),
        DashboardEmpty() => const Center(
          child: Text('No bursary applications yet.'),
        ),
        DashboardFailure() => Center(
          child: FilledButton(
            onPressed: controller.reload,
            child: const Text('Try again'),
          ),
        ),
        DashboardData(:final dashboard) => ListView(
          padding: const EdgeInsets.all(AppTokens.space3),
          children: [
            for (final summary in dashboard.bursaryApplications)
              Card(
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
                  onTap: () => BursaryDetailRoute(id: summary.id).go(context),
                ),
              ),
          ],
        ),
      },
    );
  }
}
