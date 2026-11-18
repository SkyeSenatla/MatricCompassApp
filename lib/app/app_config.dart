import 'package:flutter/services.dart';

/// The three builds of the app.
enum Flavor {
  /// Your laptop's API, through the emulator.
  dev,

  /// A shared HTTPS API that testers use.
  staging,

  /// The real thing.
  prod,
}

/// Week 10 Day 1: build-time settings, read from
/// `--dart-define-from-file=config/<flavour>.json`.
///
/// Nothing here is a secret: anyone can read these values out of the APK.
final class AppConfig {
  /// Creates a config. Use [AppConfig.fromEnvironment] in the app.
  const new({
    required this.flavor,
    required this.apiBaseUrl,
    this.refreshCookieName = 'refresh_token',
  });

  /// Reads the values the build was given, and checks them.
  factory fromEnvironment() => AppConfig.parse(
    nativeFlavor: appFlavor,
    flavorName: const String.fromEnvironment('FLAVOR'),
    apiBaseUrl: const String.fromEnvironment('API_BASE_URL'),
    refreshCookieName: const String.fromEnvironment('REFRESH_COOKIE_NAME'),
  );

  /// Checks the build's values. Separate from [AppConfig.fromEnvironment]
  /// so a test can feed it any combination.
  factory parse({
    required String? nativeFlavor,
    required String flavorName,
    required String apiBaseUrl,
    String refreshCookieName = 'refresh_token',
  }) {
    final flavor = Flavor.values.asNameMap()[flavorName];
    if (flavor == null || apiBaseUrl.isEmpty || refreshCookieName.isEmpty) {
      throw StateError(
        'No flavour config. Run with --flavor dev '
        '--dart-define-from-file=config/dev.json',
      );
    }
    // Catches "--flavor prod" built with config/dev.json: a prod app id
    // talking to a laptop's API.
    if (nativeFlavor != null && nativeFlavor != flavorName) {
      throw StateError(
        'The $nativeFlavor build was given config/$flavorName.json',
      );
    }
    return AppConfig(
      flavor: flavor,
      apiBaseUrl: apiBaseUrl,
      refreshCookieName: refreshCookieName,
    );
  }

  /// Which build this is.
  final Flavor flavor;

  /// Where the API lives. Used from Week 11.
  final String apiBaseUrl;

  /// Week 11 Day 2: the name of the API's refresh cookie. Configuration,
  /// not a string scattered through the code: every RondiTrack API names
  /// its own.
  final String refreshCookieName;
}
