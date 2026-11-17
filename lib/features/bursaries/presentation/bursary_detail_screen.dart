import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:matric_compass/app/widgets/failure_view.dart';
import 'package:matric_compass/core/errors/failure.dart';
import 'package:matric_compass/core/errors/result.dart';
import 'package:matric_compass/core/money/format_rands.dart';
import 'package:matric_compass/features/bursaries/domain/bursary_application.dart';
import 'package:matric_compass/features/bursaries/domain/bursary_workflow.dart';
import 'package:matric_compass/features/bursaries/presentation/bursary_application_provider.dart';
import 'package:matric_compass/features/bursaries/presentation/bursary_status_chip.dart';
import 'package:matric_compass/features/bursaries/presentation/bursary_submission.dart';

/// Week 10 Day 2: one application, from the family provider.
///
/// Week 10 Day 3: it is reached by its address, /bursaries/:id, so a deep
/// link or a push notification can open it from a cold start. It needs
/// only the id. Staff see it too, at /staff/applications/:id.
///
/// Week 11 Day 1: "not found" is the API's 404 as a NotFoundFailure, other
/// failures show the shared FailureView, and Submit is real.
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
    final submitting = ref.watch(bursarySubmissionProvider(id));

    Future<void> submit() async {
      final messenger = ScaffoldMessenger.of(context);
      final result = await ref
          .read(bursarySubmissionProvider(id).notifier)
          .submit();
      // The API decided. 422 and 409 carry its own sentence in `detail`.
      switch (result) {
        case Ok():
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Submitted. Your counsellor will review it.'),
            ),
          );
        case Err(:final failure):
          showFailureSnackBar(messenger, failure);
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Bursary application')),
      body: switch (application) {
        AsyncData(:final value) => _Details(
          application: value,
          forLearner: forLearner,
          onSubmit: submitting ? null : submit,
        ),
        // "Not yours" and "doesn't exist" read the same, as the API's 404.
        AsyncError(error: NotFoundFailure()) => const Center(
          child: Text('Application not found.'),
        ),
        AsyncError(:final error) => FailureView(
          title: "We couldn't load this application.",
          error: error,
          onRetry: () => ref.invalidate(bursaryApplicationProvider(id)),
        ),
        AsyncLoading() => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Details extends StatelessWidget {
  const new({
    required this.application,
    required this.forLearner,
    required this.onSubmit,
  });

  final BursaryApplication application;
  final bool forLearner;

  /// Null while a submit is on its way: the button is disabled.
  final VoidCallback? onSubmit;

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
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final action in actions)
                  switch (action) {
                    // Week 11 Day 1: the one action that calls the API so
                    // far. The others arrive with Week 11 Day 4's forms.
                    LearnerAction.submit => FilledButton(
                      onPressed: onSubmit,
                      child: Text(action.label),
                    ),
                    LearnerAction.edit || LearnerAction.uploadDocuments => Chip(
                      label: Text(action.label),
                    ),
                  },
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
