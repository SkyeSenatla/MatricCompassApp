import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'theme_setting.g.dart';

/// Week 11 Day 3: small settings that belong to the phone, not to a person
/// or the server. SharedPreferences, behind an interface: tests use the
/// in-memory one, because a test has no platform storage.
///
/// Settings only, never data: SharedPreferences has no types, no queries,
/// no change streams, and writes a plain file.
abstract interface class SettingsStore {
  /// The value for [key], or null.
  String? read(String key);

  /// Keeps [value] for [key].
  Future<void> write(String key, String value);
}

/// SharedPreferences, with every allowed key read once at startup, so
/// reading a setting never waits (the theme is needed for the first frame).
final class PrefsSettingsStore implements SettingsStore {
  /// Wraps an opened SharedPreferencesWithCache.
  const new(this._prefs);

  final SharedPreferencesWithCache _prefs;

  /// The keys this app may store. Anything else is refused: a typo can't
  /// quietly become a new setting.
  static const Set<String> keys = {ThemeSetting.key};

  /// Opens the store. main() awaits this before the first frame.
  static Future<PrefsSettingsStore> open() async => PrefsSettingsStore(
    await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(allowList: keys),
    ),
  );

  @override
  String? read(String key) => _prefs.getString(key);

  @override
  Future<void> write(String key, String value) => _prefs.setString(key, value);
}

/// For tests: settings in a map.
final class InMemorySettingsStore implements SettingsStore {
  /// Creates the store, optionally with [values] already in it.
  new([Map<String, String>? values]) : _values = {...?values};

  final Map<String, String> _values;

  @override
  String? read(String key) => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;
}

/// Week 11 Day 3: the phone's settings store. main() overrides it with the
/// one it opened; reading it without the override is a programming error,
/// and says so.
@Riverpod(keepAlive: true)
SettingsStore settingsStore(Ref ref) => throw UnimplementedError(
  'settingsStoreProvider is overridden in main.dart, and in tests that use '
  'it.',
);

/// Week 11 Day 3: light, dark, or follow the phone. It belongs to the
/// phone, so sign-out keeps it.
@Riverpod(keepAlive: true)
class ThemeSetting extends _$ThemeSetting {
  /// The SharedPreferences key.
  static const key = 'theme_mode';

  @override
  ThemeMode build() {
    final stored = ref.watch(settingsStoreProvider).read(key);
    return ThemeMode.values.where((m) => m.name == stored).firstOrNull ??
        ThemeMode.system;
  }

  /// Uses [mode] now, and from the next launch.
  Future<void> choose(ThemeMode mode) async {
    state = mode;
    await ref.read(settingsStoreProvider).write(key, mode.name);
  }
}
