import 'package:drift/drift.dart';

/// Week 11 Day 3: the dashboard's heading, one row: whose dashboard it is
/// and when the server last sent it. One phone, one signed-in person, so
/// one dashboard; sign-out wipes it.
@DataClassName('DashboardHeaderRow')
class DashboardHeaders extends Table {
  /// Always 1.
  IntColumn get id => integer()();

  /// The learner's name, for the greeting.
  TextColumn get fullName => text()();

  /// When the server sent this dashboard.
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Week 11 Day 3: one line of the dashboard's bursary list, in the
/// server's order.
@DataClassName('DashboardLineRow')
class DashboardLines extends Table {
  /// The application's id.
  TextColumn get id => text()();

  /// Its place in the list, as the server ordered it.
  IntColumn get position => integer()();

  /// The funder's name.
  TextColumn get funder => text()();

  /// The status as the API spells it, so a status this app version doesn't
  /// know survives the cache and still shows "Status not recognised".
  TextColumn get status => text()();

  /// The deadline (midnight UTC).
  DateTimeColumn get deadline => dateTime()();

  /// Computed by the server when it was fetched: it gets older with the
  /// cache, which is why the screen shows the cache's age.
  IntColumn get daysUntilDeadline => integer()();

  /// The amount, in cents: never a double.
  IntColumn get amountInCents => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
