import 'package:matric_compass/core/money/cents.dart';
import 'package:matric_compass/features/bursaries/domain/bursary_application.dart';

/// Week 11 Day 3: an edit the server hasn't accepted yet.
final class PendingEdit {
  /// Creates the edit.
  const new({
    required this.amount,
    required this.deadline,
    required this.baseVersion,
    required this.madeAt,
  });

  /// The new amount.
  final Cents amount;

  /// The new deadline (midnight UTC).
  final DateTime deadline;

  /// The server version the edit was made against. Sent back with it, so a
  /// change made elsewhere in the meantime is a 409, not a silent overwrite.
  final int baseVersion;

  /// When the person made it.
  final DateTime madeAt;
}

/// Week 11 Day 3: one application as the phone knows it: the server's
/// last word, how old it is, and any edit still on its way.
final class CachedBursary {
  /// Creates the cached application.
  const new({required this.server, required this.fetchedAt, this.pending});

  /// What the server last sent. Never changed by an edit until the server
  /// accepts it.
  final BursaryApplication server;

  /// When the server sent it, in UTC.
  final DateTime fetchedAt;

  /// The person's edit, not yet accepted. Null if there is none.
  final PendingEdit? pending;

  /// What the screen shows: the server's application with the pending edit
  /// laid over it. This is the optimistic part.
  BursaryApplication get shown => switch (pending) {
    null => server,
    final edit => server.copyWith(amount: edit.amount, deadline: edit.deadline),
  };
}
