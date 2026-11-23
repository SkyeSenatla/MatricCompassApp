import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:matric_compass/app/database/app_database.dart';

/// Week 11 Day 3: the app's database in memory: real SQLite, real Drift,
/// nothing on disk, gone when the test ends.
AppDatabase memoryDatabase() {
  // Each test opens its own: that's the point, not a mistake.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  // Drift keeps a cancelled stream alive for one zero-length timer, in case
  // someone listens again. A widget test fails on any timer still pending
  // at its end, so tests close streams at once.
  return AppDatabase(
    DatabaseConnection(
      NativeDatabase.memory(),
      closeStreamsSynchronously: true,
    ),
  );
}

/// The override every test that touches the cache needs: main() never
/// overrides it, so without this a test would try to open a file.
final Override inMemoryDatabase = appDatabaseProvider.overrideWith((ref) {
  final database = memoryDatabase();
  ref.onDispose(database.close);
  return database;
});
