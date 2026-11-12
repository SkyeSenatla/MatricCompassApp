import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:matric_compass/app/theme/app_tokens.dart';
import 'package:matric_compass/features/careers/domain/aptitude_test.dart';
import 'package:matric_compass/features/careers/domain/tertiary_application.dart';
import 'package:matric_compass/features/careers/presentation/careers_overview_provider.dart';
import 'package:matric_compass/features/careers/presentation/careers_view.dart';
import 'package:matric_compass/features/careers/presentation/tertiary_status_chip.dart';

/// Week 10 Day 4: the learner's Careers tab: her aptitude tests and her
/// university applications. It knows the provider and the domain types; it
/// never imports a repository, and it decides no rule of its own.
class CareersScreen extends ConsumerWidget {
  /// Creates the screen.
  const new({super.key});

  /// From this width the pane shows the two lists side by side.
  static const twoColumnMinWidth = 720.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = CareersView.from(ref.watch(careersOverviewProvider));

    return Scaffold(
      appBar: AppBar(title: const Text('Careers')),
      // Exhaustive: delete a case and this stops compiling.
      body: switch (view) {
        CareersLoading() => const Center(child: CircularProgressIndicator()),
        CareersEmpty() => const _Message(
          icon: Icons.explore_outlined,
          text:
              'No aptitude tests or university applications yet. '
              'When you have some, they will show here.',
        ),
        CareersFailure() => _Message(
          icon: Icons.cloud_off_outlined,
          text: "We couldn't load your careers.",
          onRetry: () => ref.invalidate(careersOverviewProvider),
        ),
        CareersData(:final overview) => LayoutBuilder(
          // Inside a pane, measure the space this pane is given (Day 3):
          // the window may be wide while a rail takes part of it.
          builder: (context, constraints) {
            final tests = _AptitudeSection(tests: overview.aptitudeTests);
            final applications = _ApplicationsSection(
              applications: overview.applications,
            );
            if (constraints.maxWidth >= twoColumnMinWidth) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppTokens.space3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: tests),
                    const SizedBox(width: AppTokens.space3),
                    Expanded(child: applications),
                  ],
                ),
              );
            }
            return ListView(
              padding: const EdgeInsets.all(AppTokens.space3),
              children: [
                tests,
                const SizedBox(height: AppTokens.space4),
                applications,
              ],
            );
          },
        ),
      },
    );
  }
}

class _AptitudeSection extends StatelessWidget {
  const new({required this.tests});

  final List<AptitudeTest> tests;

  static final DateFormat _date = DateFormat('d MMM y');

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Aptitude tests', style: text.titleLarge),
        const SizedBox(height: AppTokens.space2),
        if (tests.isEmpty) const Text('No aptitude tests yet.'),
        for (final test in tests)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTokens.space3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(test.testType, style: text.titleMedium),
                  Text(
                    '${_date.format(test.dateTaken.toUtc())} · '
                    'Score ${test.score} out of 100',
                  ),
                  const SizedBox(height: AppTokens.space2),
                  Text('Recommended careers', style: text.labelLarge),
                  const SizedBox(height: AppTokens.space1),
                  // As the API sends them, in its order. Never worked out
                  // here from the score.
                  Wrap(
                    spacing: AppTokens.space2,
                    runSpacing: AppTokens.space2,
                    children: [
                      for (final career in test.recommendedCareers)
                        Chip(label: Text(career)),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ApplicationsSection extends StatelessWidget {
  const new({required this.applications});

  final List<TertiaryApplication> applications;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('University applications', style: text.titleLarge),
        const SizedBox(height: AppTokens.space2),
        if (applications.isEmpty) const Text('No university applications yet.'),
        for (final application in applications)
          Card(
            child: ListTile(
              title: Text(application.institutionName),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: AppTokens.space1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(application.programmeName),
                    const SizedBox(height: AppTokens.space1),
                    TertiaryStatusChip(application.status),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const new({required this.icon, required this.text, this.onRetry});

  final IconData icon;
  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: AppTokens.space3),
            Text(text, textAlign: TextAlign.center),
            if (onRetry case final retry?) ...[
              const SizedBox(height: AppTokens.space3),
              FilledButton(onPressed: retry, child: const Text('Try again')),
            ],
          ],
        ),
      ),
    );
  }
}
