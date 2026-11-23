import 'package:drift/drift.dart';
import 'package:matric_compass/app/database/app_database.dart';
import 'package:matric_compass/features/auth/domain/app_user.dart';

part 'session_user_dao.g.dart';

/// Week 11 Day 3: who was signed in, as the last good token said. One row.
///
/// The access token dies with the app, so an offline launch can't read
/// the claims again. This row lets it open as that person, on cached data,
/// until a request gets through and the session refreshes. Never used to
/// decide what anyone may do: the API checks every request.
@DataClassName('SessionUserRow')
class SessionUsers extends Table {
  /// Always 1.
  IntColumn get id => integer()();

  /// The sign-in email.
  TextColumn get email => text()();

  /// The role's label, as Role.label spells it.
  TextColumn get role => text()();

  /// The learner's student id; null for staff.
  TextColumn get studentId => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Week 11 Day 3: reads and writes the one [SessionUsers] row.
@DriftAccessor(tables: [SessionUsers])
class SessionUserDao extends DatabaseAccessor<AppDatabase>
    with _$SessionUserDaoMixin {
  /// Creates the DAO; the database makes it.
  new(super.attachedDatabase);

  /// The last signed-in person, or null.
  Future<AppUser?> read() async {
    final row = await select(sessionUsers).getSingleOrNull();
    if (row == null) return null;
    final role = Role.values.where((r) => r.label == row.role).firstOrNull;
    if (role == null) return null;
    return AppUser(
      email: row.email,
      displayName: row.email,
      role: role,
      studentId: row.studentId,
    );
  }

  /// Remembers [user] as signed in.
  Future<void> save(AppUser user) => into(sessionUsers).insertOnConflictUpdate(
    SessionUsersCompanion.insert(
      id: const Value(1),
      email: user.email,
      role: user.role.label,
      studentId: Value(user.studentId),
    ),
  );
}
