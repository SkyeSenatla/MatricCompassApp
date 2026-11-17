import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'access_token.g.dart';

/// Week 11 Day 1: an access token and when it stops working. Day 2 uses
/// `expiresAt` to refresh a minute before it runs out.
typedef SessionToken = ({String value, DateTime expiresAt});

/// Week 11 Day 1: the signed-in person's access token, in memory only.
///
/// Memory, not storage: a 5-minute token isn't worth writing to disk, and a
/// token on disk is one more thing to protect. Day 2 adds the long-lived
/// refresh token, and that one goes in secure storage.
@Riverpod(keepAlive: true)
class AccessToken extends _$AccessToken {
  @override
  SessionToken? build() => null;

  /// Keeps the token [value] for every request until [expiresAt].
  void save(String value, {required DateTime expiresAt}) =>
      state = (value: value, expiresAt: expiresAt);

  /// Forgets the token: signed out.
  void clear() => state = null;
}
