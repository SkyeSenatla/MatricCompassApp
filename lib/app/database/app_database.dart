import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:matric_compass/features/auth/data/session_user_dao.dart';
import 'package:matric_compass/features/bursaries/data/bursary_dao.dart';
import 'package:matric_compass/features/bursaries/data/bursary_tables.dart';
import 'package:matric_compass/features/dashboard/data/dashboard_dao.dart';
import 'package:matric_compass/features/dashboard/data/dashboard_tables.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_database.g.dart';

/// Week 11 Day 3: the phone's own copy of what the signed-in person last
/// saw. Each feature owns its tables and DAO in its data/ folder; this file,
/// in the composition root, only puts them in one SQLite file.
///
/// It's a cache, not a source of truth: everything in it came from the
/// server (or is an edit on its way there), and sign-out empties it.
@DriftDatabase(
  tables: [
    DashboardHeaders,
    DashboardLines,
    CachedBursaries,
    PendingEdits,
    SessionUsers,
  ],
  daos: [DashboardDao, BursaryDao, SessionUserDao],
)
final class AppDatabase extends _$AppDatabase {
  /// Opens the database on a query executor: a file on the phone, or
  /// memory in tests.
  new(super.e);

  /// Bumped with every change to a table, with a migration for it.
  @override
  int get schemaVersion => 1;

  /// Week 11 Day 3: sign-out. Every row of the last person, in one
  /// transaction: the next person on this phone sees none of it, even
  /// offline.
  Future<void> wipe() => transaction(() async {
    for (final table in allTables) {
      await delete(table).go();
    }
  });
}

/// Week 11 Day 3: the one database, opened once. keepAlive: closing and
/// reopening it per screen would throw away its watchers.
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final database = AppDatabase(driftDatabase(name: 'matric_compass'));
  ref.onDispose(database.close);
  return database;
}
