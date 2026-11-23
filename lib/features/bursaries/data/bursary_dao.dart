import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:matric_compass/app/database/app_database.dart';
import 'package:matric_compass/core/money/cents.dart';
import 'package:matric_compass/features/bursaries/data/bursary_tables.dart';
import 'package:matric_compass/features/bursaries/domain/bursary_application.dart';
import 'package:matric_compass/features/bursaries/domain/bursary_status.dart';
import 'package:matric_compass/features/bursaries/domain/cached_bursary.dart';

part 'bursary_dao.g.dart';

/// Week 11 Day 3: bursary applications on the phone, and the edits waiting
/// to reach the server.
@DriftAccessor(tables: [CachedBursaries, PendingEdits])
class BursaryDao extends DatabaseAccessor<AppDatabase> with _$BursaryDaoMixin {
  /// Creates the DAO; the database makes it.
  new(super.attachedDatabase);

  /// Application [id] as cached, with its pending edit if there is one;
  /// again whenever either changes. Null if it was never fetched.
  ///
  /// The watched query selects this application's real columns on purpose.
  /// Drift shares one stream between watchers of identical SQL: when both
  /// DAOs watched a "SELECT 1" trigger, this screen got the dashboard's
  /// stream and never heard its own tables.
  Stream<CachedBursary?> watch(String id) => customSelect(
    'SELECT b.version, b.fetched_at, b.amount_in_cents, b.deadline, '
    'b.status, p.amount_in_cents AS pending_amount, '
    'p.deadline AS pending_deadline, p.made_at AS pending_made_at '
    'FROM cached_bursaries b LEFT JOIN pending_edits p ON p.id = b.id '
    'WHERE b.id = ?',
    variables: [Variable.withString(id)],
    readsFrom: {cachedBursaries, pendingEdits},
  ).watch().asyncMap((_) => read(id));

  /// Application [id] as cached now, or null.
  Future<CachedBursary?> read(String id) async {
    final row = await (select(
      cachedBursaries,
    )..where((b) => b.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    final pending = await (select(
      pendingEdits,
    )..where((p) => p.id.equals(id))).getSingleOrNull();
    return CachedBursary(
      server: row.toDomain(),
      fetchedAt: row.fetchedAt.toUtc(),
      pending: pending?.toDomain(),
    );
  }

  /// Keeps what the server just sent. A pending edit is left alone: only
  /// the server's answer to that edit removes it.
  Future<void> save(
    BursaryApplication application, {
    required DateTime fetchedAt,
  }) => into(cachedBursaries).insertOnConflictUpdate(
    CachedBursariesCompanion.insert(
      id: application.id,
      studentId: application.studentId,
      funder: application.funder,
      amountInCents: application.amount.value,
      deadline: application.deadline,
      status: application.status.apiName,
      requiredDocuments: jsonEncode(application.requiredDocuments),
      version: application.version,
      submittedAt: Value(application.submittedAt),
      fetchedAt: fetchedAt,
    ),
  );

  /// Forgets application [id]: the server said it doesn't exist (or isn't
  /// ours), so the phone mustn't keep showing it.
  Future<void> forget(String id) => transaction(() async {
    await (delete(cachedBursaries)..where((b) => b.id.equals(id))).go();
    await (delete(pendingEdits)..where((p) => p.id.equals(id))).go();
  });

  /// Records an edit before it is sent: the screen shows it at once.
  Future<void> putPendingEdit(String id, PendingEdit edit) =>
      into(pendingEdits).insertOnConflictUpdate(
        PendingEditsCompanion.insert(
          id: id,
          amountInCents: edit.amount.value,
          deadline: edit.deadline,
          baseVersion: edit.baseVersion,
          madeAt: edit.madeAt,
        ),
      );

  /// Removes the pending edit for [id]: accepted, refused or discarded.
  Future<void> removePendingEdit(String id) =>
      (delete(pendingEdits)..where((p) => p.id.equals(id))).go();

  /// How many edits are waiting. Sign-out warns before throwing them away.
  Stream<int> watchPendingCount() {
    final count = pendingEdits.id.count();
    return (selectOnly(
      pendingEdits,
    )..addColumns([count])).map((row) => row.read(count) ?? 0).watchSingle();
  }
}

extension on CachedBursaryRow {
  BursaryApplication toDomain() => BursaryApplication(
    id: id,
    studentId: studentId,
    funder: funder,
    amount: Cents(amountInCents),
    deadline: deadline.toUtc(),
    status: BursaryStatus.fromApi(status),
    requiredDocuments: [
      for (final name in jsonDecode(requiredDocuments) as List<Object?>)
        name! as String,
    ],
    version: version,
    submittedAt: submittedAt?.toUtc(),
  );
}

extension on PendingEditRow {
  PendingEdit toDomain() => PendingEdit(
    amount: Cents(amountInCents),
    deadline: deadline.toUtc(),
    baseVersion: baseVersion,
    madeAt: madeAt.toUtc(),
  );
}
