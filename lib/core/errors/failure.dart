/// Week 11 Day 1: everything that can go wrong between the app and the API,
/// as one sealed type.
///
/// Every Dio error and every error response becomes exactly one of these,
/// in one place (`failureFrom` in failure_mapping.dart). Nothing above the
/// data layer ever sees a DioException. Sealed: a screen's switch over a
/// Failure must decide what each one looks like, or it doesn't compile.
///
/// It implements [Exception] so a provider can throw it, and Riverpod
/// carries it in an AsyncError for the screen.
sealed class Failure implements Exception {
  /// Creates the failure.
  const new({this.correlationId});

  /// The API's trace id for this request, when it sent one. Shown as the
  /// person's "reference" on unexpected failures; support finds the same id
  /// in the Aspire traces.
  final String? correlationId;

  /// What the person reads. Decided here, once, so every screen says the
  /// same thing for the same failure.
  String get message;

  /// Whether to show [correlationId] as a reference. Only for failures the
  /// person can't fix themselves: those are the ones support is asked about.
  bool get showsReference => false;

  // A plain toString: logs show the kind and the reference, never a body.
  @override
  String toString() => 'Failure($message, ref: $correlationId)';
}

/// 400 with `errors`: one or more fields are invalid.
final class ValidationFailure extends Failure {
  /// Creates the failure.
  const new({required this.fieldErrors, super.correlationId});

  /// camelCase field name → its messages, shown under each field.
  final Map<String, List<String>> fieldErrors;

  @override
  String get message => 'Some details need fixing.';
}

/// 401: not signed in, or the token expired. Day 2 refreshes first.
final class UnauthorizedFailure extends Failure {
  /// Creates the failure.
  const new({super.correlationId});

  @override
  String get message => 'Please sign in again.';
}

/// 403: signed in, but not allowed. Never a reason to sign anyone out.
final class ForbiddenFailure extends Failure {
  /// Creates the failure.
  const new({super.correlationId});

  @override
  String get message => "You don't have permission to do that.";
}

/// 404: doesn't exist, or isn't yours. The API doesn't say which, and
/// neither does the app.
final class NotFoundFailure extends Failure {
  /// Creates the failure.
  const new({super.correlationId});

  @override
  String get message => 'Not found.';
}

/// 409: the record changed (wrong status, stale version, duplicate).
/// Reload and decide again.
final class ConflictFailure extends Failure {
  /// Creates the failure.
  const new({this.detail, super.correlationId});

  /// The API's sentence for people, such as "This application is already
  /// submitted."
  final String? detail;

  @override
  String get message =>
      detail ?? 'This changed somewhere else. Reload and try again.';
}

/// 422: a business rule said no (missing documents, deadline passed).
final class RuleFailure extends Failure {
  /// Creates the failure.
  const new({this.detail, super.correlationId});

  /// The API's sentence for people, such as "Upload these documents first:
  /// Certified ID Copy, Proof of Household Income."
  final String? detail;

  @override
  String get message => detail ?? "That isn't allowed right now.";
}

/// 429: too many requests. Wait [retryAfter], from the Retry-After header.
final class RateLimitedFailure extends Failure {
  /// Creates the failure.
  const new({this.retryAfter, super.correlationId});

  /// How long the API asked us to wait, when it said.
  final Duration? retryAfter;

  @override
  String get message => switch (retryAfter) {
    final wait? => 'Too many attempts. Try again in ${wait.inSeconds} seconds.',
    null => 'Too many attempts. Try again in a minute.',
  };
}

/// 5xx, or an answer the app couldn't read (an HTML page instead of JSON).
final class ServerFailure extends Failure {
  /// Creates the failure.
  const new({super.correlationId});

  @override
  String get message => 'Something went wrong on our side.';

  @override
  bool get showsReference => true;
}

/// No answer at all: no connection, a timeout, the API not running.
final class OfflineFailure extends Failure {
  /// Creates the failure.
  const new();

  @override
  String get message => "You're offline, or we couldn't reach the server.";
}
