/// Week 11 Day 3: a value the phone kept, and when the server last said so.
///
/// The screen always shows [fetchedAt]: cached data with no age looks live,
/// and people act on what looks live.
final class Snapshot<T> {
  /// Creates the snapshot.
  const new(this.value, {required this.fetchedAt});

  /// What the server sent, as the app means it.
  final T value;

  /// When the server sent it, in UTC.
  final DateTime fetchedAt;
}
