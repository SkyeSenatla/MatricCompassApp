import 'package:drift/drift.dart';

/// Week 11 Day 3: bursary applications as the server last sent them. Only
/// the server's truth goes here; an edit not yet accepted lives in
/// [PendingEdits], so undoing it is deleting one row.
@DataClassName('CachedBursaryRow')
class CachedBursaries extends Table {
  /// The application's id.
  TextColumn get id => text()();

  /// The learner it belongs to.
  TextColumn get studentId => text()();

  /// The funder's name.
  TextColumn get funder => text()();

  /// The amount, in cents.
  IntColumn get amountInCents => integer()();

  /// The deadline (midnight UTC).
  DateTimeColumn get deadline => dateTime()();

  /// The status as the API spells it.
  TextColumn get status => text()();

  /// The documents the funder requires, as a JSON list of names.
  TextColumn get requiredDocuments => text()();

  /// The server's version: an edit sends it back, and a stale one is a 409.
  IntColumn get version => integer()();

  /// When it was submitted, if it was.
  DateTimeColumn get submittedAt => dateTime().nullable()();

  /// When the server sent this row.
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Week 11 Day 3: an edit the person made that the server hasn't accepted
/// yet. A small outbox: it survives a killed app, and it remembers the
/// version it was based on, so sending it again later is still checked.
@DataClassName('PendingEditRow')
class PendingEdits extends Table {
  /// The application's id: one pending edit per application.
  TextColumn get id => text()();

  /// The new amount, in cents.
  IntColumn get amountInCents => integer()();

  /// The new deadline (midnight UTC).
  DateTimeColumn get deadline => dateTime()();

  /// The server version the person was looking at when they edited.
  IntColumn get baseVersion => integer()();

  /// When the person made the edit.
  DateTimeColumn get madeAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
