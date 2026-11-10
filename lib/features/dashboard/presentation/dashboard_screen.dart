import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:matric_compass/core/money/format_rands.dart';
import 'package:matric_compass/features/bursaries/presentation/bursary_detail_screen.dart';
import 'package:matric_compass/features/bursaries/presentation/bursary_status_label.dart';
import 'package:matric_compass/features/dashboard/domain/learner_dashboard.dart';
import 'package:matric_compass/features/dashboard/presentation/dashboard_controller.dart';
import 'package:matric_compass/features/dashboard/presentation/dashboard_view.dart';

/// Week 10 Day 2: the learner's home. It knows the controller and the domain
/// types; it never imports a repository.
class DashboardScreen extends ConsumerWidget {
  /// Creates the screen.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = DashboardView.from(ref.watch(dashboardControllerProvider));
    final controller = ref.read(dashboardControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Matric Compass')),
      // Exhaustive: delete a case and this stops compiling.
      body: switch (view) {
        DashboardLoading() => const _LoadingList(),
        DashboardEmpty(:final fullName) => _EmptyState(fullName: fullName),
        DashboardData(:final dashboard, :final refreshing) => RefreshIndicator(
          onRefresh: controller.reload,
          child: _BursaryList(dashboard: dashboard, refreshing: refreshing),
        ),
        DashboardFailure() => _FailureState(onRetry: controller.reload),
      },
    );
  }
}

class _LoadingList extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final placeholder = Theme.of(context).colorScheme.surfaceContainerHighest;
    // A skeleton the shape of the list, not a lone spinner.
    return Semantics(
      label: 'Loading your dashboard',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (var i = 0; i < 3; i++)
            Container(
              key: ValueKey('skeleton-$i'),
              height: 88,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: placeholder,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const new({required this.fullName});

  final String fullName;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.school_outlined, size: 48),
            const SizedBox(height: 16),
            Text('Hello, $fullName', style: text.titleLarge),
            const SizedBox(height: 8),
            Text(
              'No bursary applications yet. '
              'When you start one, it will show here.',
              style: text.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _FailureState extends StatelessWidget {
  const new({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48),
            const SizedBox(height: 16),
            const Text(
              "We couldn't load your dashboard.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

class _BursaryList extends StatelessWidget {
  const new({required this.dashboard, required this.refreshing});

  final LearnerDashboard dashboard;
  final bool refreshing;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (refreshing) const LinearProgressIndicator(),
        Text('Hello, ${dashboard.fullName}', style: text.titleLarge),
        const SizedBox(height: 16),
        for (final summary in dashboard.bursaryApplications)
          _BursaryCard(summary: summary),
      ],
    );
  }
}

// Week 10 Day 2: the deadline is midnight UTC and the rules compare its UTC
// date, so show the UTC date. Week 11 Day 4 localises this.
final DateFormat _deadlineFormat = DateFormat('d MMM y');

class _BursaryCard extends StatelessWidget {
  const new({required this.summary});

  final BursarySummary summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(summary.funder),
        subtitle: Text(
          '${summary.status.label} · '
          'Deadline ${_deadlineFormat.format(summary.deadline.toUtc())} '
          '(${summary.daysUntilDeadline} days)',
        ),
        trailing: Text(formatRands(summary.amount)),
        // Day 3 replaces this with a typed go_router route.
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => BursaryDetailScreen(id: summary.id),
          ),
        ),
      ),
    );
  }
}
