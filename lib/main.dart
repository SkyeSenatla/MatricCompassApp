import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matric_compass/app/app.dart';
import 'package:matric_compass/app/app_config.dart';
import 'package:matric_compass/app/app_config_provider.dart';
import 'package:matric_compass/app/retry_policy.dart';
import 'package:matric_compass/app/settings/theme_setting.dart';

Future<void> main() async {
  // Week 10 Day 1: fail at startup, loudly, if the build has no config.
  final config = AppConfig.fromEnvironment();
  // Week 11 Day 3: the settings are read before the first frame, so the
  // app never flashes the wrong theme. Plugins need the binding first.
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await PrefsSettingsStore.open();
  // Week 10 Day 2: one container for the whole app. Tests make their own,
  // with overrides.
  // Week 10 Day 3: with our retry policy: "not found" is never retried.
  // Week 11 Day 1: the config is a provider now, so the Dio client can read
  // the API's address from it.
  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        settingsStoreProvider.overrideWithValue(settings),
      ],
      retry: appRetryPolicy,
      child: MatricCompassApp(config: config),
    ),
  );
}
