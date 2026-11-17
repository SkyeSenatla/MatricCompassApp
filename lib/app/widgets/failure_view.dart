import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:matric_compass/app/theme/app_tokens.dart';
import 'package:matric_compass/core/errors/failure.dart';

/// Week 11 Day 1: a screen that couldn't load. Every screen's failure state
/// uses it, so every failure reads the same way.
///
/// [title] says what didn't load, in the screen's own words. Below it the
/// Failure's message says why, and an unexpected failure shows its
/// reference, which the person can copy for support.
class FailureView extends StatelessWidget {
  /// Creates the view for [error], which is a Failure from Week 11 Day 1.
  const new({
    required this.title,
    required this.error,
    this.onRetry,
    super.key,
  });

  /// What didn't load, such as "We couldn't load your dashboard."
  final String title;

  /// What went wrong. Anything that isn't a Failure is a bug, shown as a
  /// server failure rather than as its raw text.
  final Object error;

  /// Shown as "Try again" when set.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final failure = switch (error) {
      final Failure failure => failure,
      _ => const ServerFailure(),
    };
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              failure is OfflineFailure
                  ? Icons.cloud_off_outlined
                  : Icons.error_outline,
              size: 48,
            ),
            const SizedBox(height: AppTokens.space3),
            Text(title, style: text.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: AppTokens.space2),
            Text(failure.message, textAlign: TextAlign.center),
            if (failure.showsReference && failure.correlationId != null)
              ReferenceText(failure.correlationId!),
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

/// Week 11 Day 1: the correlationId as the person's reference: selectable,
/// and copied with one tap, so it reaches support exactly.
class ReferenceText extends StatelessWidget {
  /// Creates the reference line for [correlationId].
  const new(this.correlationId, {super.key});

  /// The API's trace id for the failed request.
  final String correlationId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppTokens.space2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: SelectableText('Reference $correlationId')),
          IconButton(
            tooltip: 'Copy reference',
            icon: const Icon(Icons.copy),
            onPressed: () =>
                Clipboard.setData(ClipboardData(text: correlationId)),
          ),
        ],
      ),
    );
  }
}

/// Week 11 Day 1: a failed action (a submit), shown in a SnackBar. With a
/// reference it stays until it's dismissed: four seconds isn't long enough
/// to copy one.
void showFailureSnackBar(ScaffoldMessengerState messenger, Failure failure) {
  final reference = failure.showsReference ? failure.correlationId : null;
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        reference == null
            ? failure.message
            : '${failure.message} Reference $reference',
      ),
      showCloseIcon: reference != null,
      duration: reference == null
          ? const Duration(seconds: 6)
          : const Duration(days: 1),
      action: reference == null
          ? null
          : SnackBarAction(
              label: 'Copy',
              onPressed: () =>
                  Clipboard.setData(ClipboardData(text: reference)),
            ),
    ),
  );
}
