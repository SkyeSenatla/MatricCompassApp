import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matric_compass/app/app.dart';
import 'package:matric_compass/app/app_config.dart';
import 'package:matric_compass/app/app_config_provider.dart';
import 'package:matric_compass/app/retry_policy.dart';
import 'package:matric_compass/app/settings/theme_setting.dart';
import 'package:matric_compass/core/observability/error_reporter.dart';
import 'package:matric_compass/core/observability/scrubber.dart';
import 'package:matric_compass/features/auth/domain/auth_state.dart';
import 'package:matric_compass/features/auth/presentation/auth_controller.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

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
  // Week 12 Day 2: made here, before the app, so Sentry's scrubber can ask
  // it who is signed in; and watched by an observer that reports the
  // failures worth reporting.
  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(config),
      settingsStoreProvider.overrideWithValue(settings),
    ],
    retry: appRetryPolicy,
    observers: [
      if (config.reportsErrors) ReportingObserver(const SentryErrorReporter()),
    ],
  );
  void run() => runApp(
    UncontrolledProviderScope(
      container: container,
      child: MatricCompassApp(config: config),
    ),
  );

  // Week 12 Day 2: no DSN, no Sentry: tests, and anyone without a project.
  if (!config.reportsErrors) return run();

  final scrub = Scrubber(
    () => switch (container.read(authControllerProvider)) {
      SignedIn(:final user) => (name: user.displayName, email: user.email),
      _ => null,
    },
  );
  await SentryFlutter.init((options) {
    options
      ..dsn = config.sentryDsn
      // One environment per flavour, so dev's noise never hides prod's.
      ..environment = config.flavor.name
      // The release is left to Sentry: the app id, version and build number,
      // which Day 4's CI stamps on each build.
      // POPIA: no IP address or user details collected for us...
      ..sendDefaultPii = false
      // ...and whatever our own code put in a message, scrubbed on the way.
      ..beforeSend = scrub.call;
  }, appRunner: run);
}
