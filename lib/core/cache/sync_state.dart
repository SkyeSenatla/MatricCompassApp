import 'package:matric_compass/core/errors/failure.dart';

/// Week 11 Day 3: how the last attempt to fetch newer data went.
///
/// The cache answers "what do we know"; this answers "is it current".
/// Stale-while-revalidate needs both: the screen shows the cache at once,
/// and this decides the banner above it.
sealed class SyncState {
  /// Creates the state.
  const new();
}

/// Asking the server now. The cached data stays on screen meanwhile.
final class Syncing extends SyncState {
  /// Creates the state.
  const new();
}

/// The server answered, and the cache holds its answer.
final class Synced extends SyncState {
  /// Creates the state.
  const new();
}

/// The server couldn't be asked, or refused. The cache is all we have.
final class SyncFailed extends SyncState {
  /// Creates the state.
  const new(this.failure);

  /// Why. An OfflineFailure is the common one: no answer at all.
  final Failure failure;
}
