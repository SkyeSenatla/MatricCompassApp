import 'package:matric_compass/core/errors/failure.dart';
import 'package:matric_compass/core/network/access_token.dart';

/// Week 11 Day 2: what the HTTP layer needs from the session, and nothing
/// more. The interceptor in core/ depends on this; the session itself lives
/// in features/auth/data, which core/ must not import.
abstract interface class SessionTokens {
  /// The access token in memory now, or null when signed out.
  SessionToken? get current;

  /// Gets a new access token, at most once at a time.
  ///
  /// [sentToken] is the access token a failed request carried. If the
  /// current token is already a different one, another request refreshed
  /// first, and this answers with the current token instead of refreshing
  /// again with a refresh token that was just spent.
  Future<RefreshOutcome> refresh({String? sentToken});
}

/// How a refresh ended. Sealed: the interceptor and the auth controller
/// must each decide all three.
sealed class RefreshOutcome {
  const new();
}

/// A new access token, ready to use.
final class Refreshed extends RefreshOutcome {
  /// Creates the outcome.
  const new(this.token);

  /// The new access token.
  final SessionToken token;
}

/// The session is over: no refresh token, or the API refused it (401).
/// The only outcome that signs anyone out.
final class SessionEnded extends RefreshOutcome {
  /// Creates the outcome.
  const new();
}

/// The refresh couldn't happen: no network, or the API failed. Says nothing
/// about the session, so nobody is signed out.
final class RefreshUnavailable extends RefreshOutcome {
  /// Creates the outcome.
  const new(this.failure);

  /// Why it couldn't happen.
  final Failure failure;
}
