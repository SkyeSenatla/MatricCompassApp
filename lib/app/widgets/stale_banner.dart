import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:matric_compass/core/errors/failure.dart';

/// Week 11 Day 3: the line above cached data when the last fetch failed.
///
/// It always says how old the data is: "offline, last updated 08:12".
/// Cached data with no age looks live, and people act on what looks live.
class StaleBanner extends StatelessWidget {
  /// Creates the banner.
  const new({
    required this.fetchedAt,
    required this.failure,
    required this.onRetry,
    DateTime Function()? clock,
    super.key,
  }) : _clock = clock ?? DateTime.now;

  /// When the server sent what's on screen.
  final DateTime fetchedAt;

  /// Why the last fetch failed.
  final Failure failure;

  /// Asks again.
  final VoidCallback onRetry;

  final DateTime Function() _clock;

  /// The banner's sentence. Public so a test can check the words alone.
  static String describe(Failure failure, DateTime fetchedAt, DateTime now) {
    final reason = switch (failure) {
      OfflineFailure() => "You're offline",
      _ => "We couldn't refresh this",
    };
    return '$reason. Last updated ${_age(fetchedAt.toLocal(), now)}.';
  }

  // Today: the time. Before today: the date and time.
  static String _age(DateTime at, DateTime now) {
    final sameDay =
        at.year == now.year && at.month == now.month && at.day == now.day;
    return sameDay
        ? DateFormat('HH:mm').format(at)
        : DateFormat('d MMM, HH:mm').format(at);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.secondaryContainer,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 4, 4),
        child: Row(
          children: [
            Icon(
              failure is OfflineFailure ? Icons.cloud_off : Icons.sync_problem,
              color: colors.onSecondaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                describe(failure, fetchedAt, _clock()),
                style: TextStyle(color: colors.onSecondaryContainer),
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
