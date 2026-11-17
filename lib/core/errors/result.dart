import 'package:matric_compass/core/errors/failure.dart';

/// Week 11 Day 1: what every repository returns. Ok with the value, or Err
/// with a [Failure]: failure is part of the signature, so a caller can't
/// forget it.
///
/// A sealed class, as Flutter's architecture guide does ("Error handling
/// with Result objects"). The README records why we chose it over records.
sealed class Result<T> {
  /// Creates the result.
  const new();
}

/// It worked.
final class Ok<T> extends Result<T> {
  /// Creates the result.
  const new(this.value);

  /// The value.
  final T value;
}

/// It failed, and here is how.
final class Err<T> extends Result<T> {
  /// Creates the result.
  const new(this.failure);

  /// What went wrong.
  final Failure failure;
}

/// Unwrapping for providers: a provider's job is to turn Err into an
/// AsyncError for the screen, so it throws the [Failure].
extension ResultValue<T> on Result<T> {
  /// The value, or throws the [Failure].
  T get valueOrThrow => switch (this) {
    Ok(:final value) => value,
    Err(:final failure) => throw failure,
  };
}
