import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matric_compass/app/router/routes.dart';
import 'package:matric_compass/app/theme/app_tokens.dart';
import 'package:matric_compass/app/widgets/stale_banner.dart';
import 'package:matric_compass/features/bursaries/presentation/bursary_card.dart';
import 'package:matric_compass/features/dashboard/presentation/dashboard_cache.dart';
import 'package:matric_compass/features/dashboard/presentation/dashboard_view.dart';

/// Week 10 Day 3: the learner's Bursaries tab. The same data as the
/// dashboard, so it reuses the dashboard's controller and view state.
/// Tapping one goes to its address, /bursaries/:id, on this tab's stack.
///
/// Week 11 Day 3: the same cache and sync as the dashboard, so the two
/// tabs can never disagree.
class BursariesScreen extends ConsumerWidget {
  /// Creates the screen.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = DashboardView.from(
      ref.watch(cachedDashboardProvider),
      ref.watch(dashboardSyncProvider),
    );
    final sync = ref.read(dashboardSyncProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Bursaries')),
      body: switch (view) {
        DashboardLoading() => const Center(child: CircularProgressIndicator()),
        DashboardEmpty() => const Center(
          child: Text('No bursary applications yet.'),
        ),
        DashboardFailure() => Center(
          child: FilledButton(
            onPressed: sync.refresh,
            child: const Text('Try again'),
          ),
        ),
        DashboardData(
          :final dashboard,
          :final fetchedAt,
          :final staleBecause,
        ) =>
          Column(
            children: [
              if (staleBecause != null)
                StaleBanner(
                  fetchedAt: fetchedAt,
                  failure: staleBecause,
                  onRetry: sync.refresh,
                ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppTokens.space3),
                  children: [
                    for (final summary in dashboard.bursaryApplications)
                      BursaryCard(
                        summary,
                        onTap: () =>
                            BursaryDetailRoute(id: summary.id).go(context),
                      ),
                  ],
                ),
              ),
            ],
          ),
      },
    );
  }
}
