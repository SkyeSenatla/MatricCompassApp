import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:matric_compass/app/app.dart';
import 'package:matric_compass/app/app_config.dart';
import 'package:matric_compass/app/app_config_provider.dart';
import 'package:matric_compass/app/data_source.dart';
import 'package:matric_compass/app/database/app_database.dart';
import 'package:matric_compass/app/retry_policy.dart';
import 'package:matric_compass/app/settings/theme_setting.dart';

/// Week 12 Day 1: the one journey that crosses the whole app, on a real
/// Android: real plugins, a real SQLite file, real secure storage and
/// preferences, real taps.
///
/// It runs on Week 10's fakes, not the API: CI has no API to call, and a
/// shared API with a sign-in limit of five a minute per IP would make the
/// test fail for reasons that have nothing to do with the app. The API is
/// covered by the live smoke tests in test/live/.
///
///   flutter test integration_test --flavor dev \
///     --dart-define-from-file=config/dev.json
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a learner signs in, opens an application and signs out', (
    tester,
  ) async {
    // As main() does: the build's config and the phone's own settings.
    final config = AppConfig.fromEnvironment();
    final settings = await PrefsSettingsStore.open();
    final container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        settingsStoreProvider.overrideWithValue(settings),
        // The one difference from main(): the fakes, not the API.
        dataSourceProvider.overrideWithValue(DataSource.fake),
      ],
      retry: appRetryPolicy,
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MatricCompassApp(config: config),
      ),
    );
    await tester.pumpAndSettle();

    // Sign in. On the fakes the email picks the person; any password does.
    await tester.enterText(
      find.widgetWithText(TextField, 'Email'),
      'thandiwe@matric-compass.test',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Password'),
      'any password',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    // Sign-in writes to a real database file: real time, which
    // pumpAndSettle doesn't wait for. Wait for what the person waits for.
    await tester.pumpUntilFound(find.text('Hello, Thandiwe Nkosi'));

    // Open an application from the Bursaries tab.
    await tester.tap(find.text('Bursaries').last);
    await tester.pumpAndSettle();
    await tester.pumpUntilFound(find.text('Funza Lushaka'));
    await tester.tap(find.text('Funza Lushaka'));
    await tester.pumpUntilFound(find.text('What you can do next'));
    expect(find.text('Bursary application'), findsOneWidget);

    // Sign out from Profile: back to the sign-in screen.
    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
    await tester.pumpUntilFound(find.text('Welcome to Matric Compass'));

    // The screen changes first; the wipe finishes after. Asking the
    // database waits for the wipe (Drift runs one statement at a time),
    // and proves Week 11's rule: nothing of hers is left on the phone.
    // Without this, the test ends mid-wipe and tears the database down
    // under it.
    final database = container.read(appDatabaseProvider);
    for (final table in database.allTables) {
      expect(
        await database.select(table).get(),
        isEmpty,
        reason: table.actualTableName,
      );
    }
  });
}

extension on WidgetTester {
  /// Pumps frames until [finder] finds something, or fails after [timeout].
  /// On a real phone the app waits on real things (a database file, the
  /// fakes' pretend network delay), and pumpAndSettle can return first.
  Future<void> pumpUntilFound(
    Finder finder, {
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final end = DateTime.now().add(timeout);
    while (finder.evaluate().isEmpty) {
      if (DateTime.now().isAfter(end)) {
        fail('Not found within ${timeout.inSeconds} s: $finder');
      }
      await pump(const Duration(milliseconds: 100));
    }
  }
}
