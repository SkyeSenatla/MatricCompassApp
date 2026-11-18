import 'dart:async';

import 'package:matric_compass/app/app_config_provider.dart';
import 'package:matric_compass/app/network/dio_provider.dart';
import 'package:matric_compass/core/errors/failure.dart';
import 'package:matric_compass/core/errors/failure_mapping.dart';
import 'package:matric_compass/core/errors/result.dart';
import 'package:matric_compass/core/network/access_token.dart';
import 'package:matric_compass/core/network/refresh_token_store.dart';
import 'package:matric_compass/core/network/session_tokens.dart';
import 'package:matric_compass/features/auth/data/auth_api.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'session.g.dart';

/// Week 11 Day 2: the signed-in session: the access token in memory, the
/// refresh token in secure storage, and one refresh at a time.
final class Session implements SessionTokens {
  /// Creates the session. readAccess and writeAccess reach the in-memory
  /// access token.
  new({
    required this._api,
    required this._store,
    required this._readAccess,
    required this._writeAccess,
  });

  final AuthApi _api;
  final RefreshTokenStore _store;
  final SessionToken? Function() _readAccess;
  final void Function(SessionToken? token) _writeAccess;

  // Bumped by every sign-out. A refresh that started in an earlier
  // generation throws its result away instead of signing someone back in.
  int _generation = 0;

  // The refresh running now, shared by everyone who asks: single flight.
  Future<RefreshOutcome>? _inFlight;

  @override
  SessionToken? get current => _readAccess();

  /// Signs in: the access token into memory, the refresh token into secure
  /// storage.
  Future<Result<SessionToken>> signIn(String email, String password) async {
    switch (await guard(() => _api.signIn(email, password))) {
      case Ok(value: final pair):
        await _store.write(pair.refreshToken);
        _writeAccess(pair.access);
        return Ok(pair.access);
      case Err(:final failure):
        return Err(failure);
    }
  }

  @override
  Future<RefreshOutcome> refresh({String? sentToken}) {
    final now = current;
    // Another request already refreshed: use its token, and never present
    // the refresh token it just spent.
    if (sentToken != null && now != null && now.value != sentToken) {
      return Future.value(Refreshed(now));
    }
    if (_inFlight case final running?) return running;
    late final Future<RefreshOutcome> started;
    started = _refreshOnce().whenComplete(() {
      if (identical(_inFlight, started)) _inFlight = null;
    });
    return _inFlight = started;
  }

  Future<RefreshOutcome> _refreshOnce() async {
    final generation = _generation;
    final stored = await _store.read();
    if (stored == null) return const SessionEnded();

    final result = await guard(() => _api.refresh(stored));
    // Signed out while we waited: this result belongs to nobody.
    if (generation != _generation) return const SessionEnded();

    switch (result) {
      case Ok(value: final pair):
        // Rotation: the new refresh token replaces the spent one at once.
        await _store.write(pair.refreshToken);
        if (generation != _generation) {
          // Sign-out happened during the write: undo it.
          await _store.delete();
          return const SessionEnded();
        }
        _writeAccess(pair.access);
        return Refreshed(pair.access);
      case Err(failure: UnauthorizedFailure()):
        // Spent, expired or revoked: the only answer that ends a session.
        _writeAccess(null);
        await _store.delete();
        return const SessionEnded();
      case Err(:final failure):
        // Offline or a server error: the session may be fine. Keep it.
        return RefreshUnavailable(failure);
    }
  }

  /// Signs out: forgets everything on the phone first, then tells the API.
  ///
  /// The phone first, so a dead network can never keep a person signed in
  /// on a shared phone. The API call uses the refresh token read before it
  /// was deleted, and its failure is ignored: the API answers 204 even
  /// with no cookie, so there's nothing to recover.
  Future<void> signOut() async {
    _generation++;
    _inFlight = null;
    _writeAccess(null);
    final stored = await _store.read();
    await _store.delete();
    if (stored == null) return;
    await guard(() => _api.signOut(stored)).timeout(
      const Duration(seconds: 5),
      onTimeout: () => const Err(OfflineFailure()),
    );
  }
}

/// Week 11 Day 2: the one session. keepAlive: it must outlive every screen.
@Riverpod(keepAlive: true)
Session session(Ref ref) => Session(
  api: AuthApi(
    ref.watch(bareDioProvider),
    cookieName: ref.watch(appConfigProvider).refreshCookieName,
  ),
  store: ref.watch(refreshTokenStoreProvider),
  readAccess: () => ref.read(accessTokenProvider),
  writeAccess: (token) {
    final access = ref.read(accessTokenProvider.notifier);
    if (token == null) {
      access.clear();
    } else {
      access.save(token.value, expiresAt: token.expiresAt);
    }
  },
);
