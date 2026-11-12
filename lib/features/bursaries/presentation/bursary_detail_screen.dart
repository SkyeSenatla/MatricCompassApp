import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:matric_compass/core/money/format_rands.dart';
import 'package:matric_compass/features/bursaries/domain/bursary_application.dart';
import 'package:matric_compass/features/bursaries/domain/bursary_repository.dart';
import 'package:matric_compass/features/bursaries/domain/bursary_workflow.dart';
import 'package:matric_compass/features/bursaries/presentation/bursary_application_provider.dart';
import 'package:matric_compass/features/bursaries/presentation/bursary_status_chip.dart';

/// Week 10 Day 2: one application, from the family provider.
///
/// Week 10 Day 3: it is reached by its address, /bursaries/:id, so a deep
/// link or a push notification can open it from a cold start. It needs
/// only the id. Staff see it too, at /staff/applications/:id.
class BursaryDetailScreen extends ConsumerWidget {
  /// Creates the screen for application [id].
  const new({required this.id, this.forLearner = true, super.key});

  /// The application's id.
  final String id;

  /// Whether to show what the learner can do next. Staff don't act as her.
  final bool forLearner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final application = ref.watch(bursaryApplicationProvider(id));

    return Scaffold(
      appBar: AppBar(title: const Text('Bursary application')),
      body: switch (application) {
        AsyncData(:final value) => _Details(
          application: value,
          forLearner: forLearner,
        ),
        // "Not yours" and "doesn't exist" read the same, as the API's 404.
        AsyncError(error: BursaryNotFoundException()) => const Center(
          child: Text('Application not found.'),
        ),
        AsyncError() => const Center(
          child: Text("We couldn't load this application."),
        ),
        AsyncLoading() => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Details extends StatelessWidget {
  const new({required this.application, required this.forLearner});

  final BursaryApplication application;
  final bool forLearner;

  static final DateFormat _date = DateFormat('d MMM y');

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final actions = learnerActions(application, now: DateTime.now());

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(application.funder, style: text.headlineSmall),
        const SizedBox(height: 8),
        Text(formatRands(application.amount), style: text.titleLarge),
        const SizedBox(height: 8),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: BursaryStatusChip(application.status),
        ),
        const SizedBox(height: 8),
        Text('Deadline ${_date.format(application.deadline.toUtc())}'),
        if (forLearner) ...[
          const SizedBox(height: 24),
          Text('What you can do next', style: text.titleMedium),
          const SizedBox(height: 8),
          if (actions.isEmpty)
            const Text('Nothing right now.')
          else
            Wrap(
              spacing: 8,
              children: [
                for (final action in actions) Chip(label: Text(action.label)),
              ],
            ),
        ],
      ],
    );
  }
}

extension on LearnerAction {
  String get label => switch (this) {
    LearnerAction.edit => 'Edit',
    LearnerAction.uploadDocuments => 'Upload documents',
    LearnerAction.submit => 'Submit',
  };
}
