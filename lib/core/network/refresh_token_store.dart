import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'refresh_token_store.g.dart';

/// Week 11 Day 2: where the long-lived refresh token is kept between
/// launches. The 5-minute access token never comes here: it stays in memory.
abstract interface class RefreshTokenStore {
  /// The stored token, or null when nobody is signed in.
  Future<String?> read();

  /// Keeps [token], replacing any earlier one. Every refresh rotates it.
  Future<void> write(String token);

  /// Forgets the token: sign-out, or a session the API has ended.
  Future<void> delete();
}

/// The real store: flutter_secure_storage, which on Android encrypts with a
/// key held in the Android Keystore. Never SharedPreferences, never a file.
final class SecureRefreshTokenStore implements RefreshTokenStore {
  /// Creates the store over a FlutterSecureStorage (tests can pass their
  /// own).
  new([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _key = 'refresh_token';

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String token) => _storage.write(key: _key, value: token);

  @override
  Future<void> delete() => _storage.delete(key: _key);
}

/// A store that forgets everything when the app stops: for tests, and for
/// the whole-app tests on fakes. Never used by a real build.
final class InMemoryRefreshTokenStore implements RefreshTokenStore {
  /// Creates the store, optionally holding a token already.
  new([this._token]);

  String? _token;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> write(String token) async => _token = token;

  @override
  Future<void> delete() async => _token = null;
}

/// Week 11 Day 2: the refresh token's home. Tests override it with an
/// [InMemoryRefreshTokenStore], because there is no Keystore in a test.
@Riverpod(keepAlive: true)
RefreshTokenStore refreshTokenStore(Ref ref) => SecureRefreshTokenStore();
