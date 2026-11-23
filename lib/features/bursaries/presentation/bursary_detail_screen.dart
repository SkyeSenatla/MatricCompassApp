import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:matric_compass/app/widgets/failure_view.dart';
import 'package:matric_compass/app/widgets/stale_banner.dart';
import 'package:matric_compass/core/cache/sync_state.dart';
import 'package:matric_compass/core/errors/failure.dart';
import 'package:matric_compass/core/errors/result.dart';
import 'package:matric_compass/core/money/cents.dart';
import 'package:matric_compass/core/money/format_rands.dart';
import 'package:matric_compass/features/bursaries/domain/bursary_workflow.dart';
import 'package:matric_compass/features/bursaries/domain/cached_bursary.dart';
import 'package:matric_compass/features/bursaries/presentation/bursary_application_provider.dart';
import 'package:matric_compass/features/bursaries/presentation/bursary_edit.dart';
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
///
/// Week 11 Day 3: it draws from the phone's cache, refreshed in the
/// background, and a learner can edit a Draft optimistically.
class BursaryDetailScreen extends ConsumerWidget {
  /// Creates the screen for application [id].
  const new({required this.id, this.forLearner = true, super.key});

  /// The application's id.
  final String id;

  /// Whether to show what the learner can do next. Staff don't act as her.
  final bool forLearner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cached = ref.watch(cachedBursaryProvider(id));
    final sync = ref.watch(bursarySyncProvider(id));
    final submitting = ref.watch(bursarySubmissionProvider(id));
    final saving = ref.watch(bursaryEditProvider(id));
    final syncer = ref.read(bursarySyncProvider(id).notifier);
    final editor = ref.read(bursaryEditProvider(id).notifier);

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

    Future<void> announce(Result<void> result) async {
      final messenger = ScaffoldMessenger.of(context);
      switch (result) {
        case Ok():
          messenger.showSnackBar(const SnackBar(content: Text('Saved.')));
        case Err(failure: OfflineFailure()):
          messenger.showSnackBar(
            const SnackBar(
              content: Text(
                "Not saved yet: you're offline. "
                "It's kept on this phone until you send it.",
              ),
            ),
          );
        // Our own words: the API's detail for a stale version is a
        // database message, not a sentence for people.
        case Err(failure: ConflictFailure()):
          messenger.showSnackBar(
            const SnackBar(
              content: Text(
                'This application changed somewhere else, so your change '
                "wasn't saved. Here is the latest.",
              ),
            ),
          );
        case Err(:final failure):
          showFailureSnackBar(messenger, failure);
      }
    }

    Future<void> edit(CachedBursary current) async {
      final shown = current.shown;
      final change = await showDialog<_Change>(
        context: context,
        builder: (_) =>
            _EditDialog(amount: shown.amount, deadline: shown.deadline),
      );
      if (change == null) return;
      await announce(
        await editor.save(amount: change.amount, deadline: change.deadline),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Bursary application')),
      body: switch ((cached, sync)) {
        (AsyncData(value: final current?), _) => Column(
          children: [
            if (sync case SyncFailed(:final failure))
              StaleBanner(
                fetchedAt: current.fetchedAt,
                failure: failure,
                onRetry: syncer.refresh,
              ),
            Expanded(
              child: _Details(
                current: current,
                forLearner: forLearner,
                saving: saving,
                onSubmit: submitting || saving ? null : submit,
                onEdit: saving ? null : () => edit(current),
                onSendAgain: saving
                    ? null
                    : () async {
                        await announce(await editor.sendAgain());
                      },
                onDiscard: saving ? null : editor.discard,
              ),
            ),
          ],
        ),
        // Nothing cached. "Not yours" and "doesn't exist" read the same, as
        // the API's 404.
        (AsyncData(value: null), SyncFailed(failure: NotFoundFailure())) =>
          const Center(child: Text('Application not found.')),
        (AsyncData(value: null), SyncFailed(:final failure)) => FailureView(
          title: "We couldn't load this application.",
          error: failure,
          onRetry: syncer.refresh,
        ),
        (AsyncError(:final error), _) => FailureView(
          title: "We couldn't load this application.",
          error: error,
          onRetry: syncer.refresh,
        ),
        (AsyncData(value: null), _) ||
        (AsyncLoading(), _) => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Details extends StatelessWidget {
  const new({
    required this.current,
    required this.forLearner,
    required this.saving,
    required this.onSubmit,
    required this.onEdit,
    required this.onSendAgain,
    required this.onDiscard,
  });

  final CachedBursary current;
  final bool forLearner;
  final bool saving;

  /// Null while something is on its way: the button is disabled.
  final VoidCallback? onSubmit;
  final VoidCallback? onEdit;
  final VoidCallback? onSendAgain;
  final VoidCallback? onDiscard;

  static final DateFormat _date = DateFormat('d MMM y');

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final application = current.shown;
    final actions = learnerActions(current.server, now: DateTime.now());

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
        // Week 11 Day 3: an edit the server hasn't accepted yet is shown,
        // and says so. Never presented as saved.
        if (current.pending != null) ...[
          const SizedBox(height: 16),
          _PendingEdit(
            saving: saving,
            onSendAgain: onSendAgain,
            onDiscard: onDiscard,
          ),
        ],
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
                    LearnerAction.submit => FilledButton(
                      onPressed: current.pending == null ? onSubmit : null,
                      child: Text(action.label),
                    ),
                    // Week 11 Day 3: Edit is real.
                    LearnerAction.edit => OutlinedButton(
                      onPressed: onEdit,
                      child: Text(action.label),
                    ),
                    // Week 12 adds uploads.
                    LearnerAction.uploadDocuments => Chip(
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

class _PendingEdit extends StatelessWidget {
  const new({
    required this.saving,
    required this.onSendAgain,
    required this.onDiscard,
  });

  final bool saving;
  final VoidCallback? onSendAgain;
  final VoidCallback? onDiscard;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: saving
            ? const Row(
                children: [
                  SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Saving your change…'),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Not saved yet. Your change is kept on this phone.',
                    style: TextStyle(color: colors.onTertiaryContainer),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilledButton.tonal(
                        onPressed: onSendAgain,
                        child: const Text('Send again'),
                      ),
                      TextButton(
                        onPressed: onDiscard,
                        child: const Text('Discard'),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

typedef _Change = ({Cents amount, DateTime deadline});

/// Week 11 Day 3: whole rands and a date. Day 4 builds the real form, with
/// cents, field errors from the API and a screen reader in mind.
class _EditDialog extends StatefulWidget {
  const new({required this.amount, required this.deadline});

  final Cents amount;
  final DateTime deadline;

  @override
  State<_EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<_EditDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _rands = TextEditingController(
    text: '${widget.amount.value ~/ 100}',
  );
  late DateTime _deadline = widget.deadline.toUtc();

  static final DateFormat _date = DateFormat('d MMM y');

  @override
  void dispose() {
    _rands.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(_deadline.year, _deadline.month, _deadline.day),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    // A deadline is a calendar day: midnight UTC, as the API stores it.
    if (picked != null) {
      setState(
        () => _deadline = DateTime.utc(picked.year, picked.month, picked.day),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit application'),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _rands,
              decoration: const InputDecoration(
                labelText: 'Amount in rands',
                prefixText: 'R ',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                final rands = int.tryParse(value ?? '');
                return rands == null || rands <= 0
                    ? 'Enter a whole number of rands, more than 0.'
                    : null;
              },
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickDeadline,
              icon: const Icon(Icons.event),
              label: Text('Deadline ${_date.format(_deadline)}'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (!_form.currentState!.validate()) return;
            final rands = int.parse(_rands.text);
            Navigator.of(
              context,
            ).pop<_Change>((amount: Cents(rands * 100), deadline: _deadline));
          },
          child: const Text('Save'),
        ),
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
