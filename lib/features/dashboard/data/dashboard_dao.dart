import 'package:drift/drift.dart';
import 'package:matric_compass/app/database/app_database.dart';
import 'package:matric_compass/core/cache/snapshot.dart';
import 'package:matric_compass/core/money/cents.dart';
import 'package:matric_compass/features/bursaries/domain/bursary_status.dart';
import 'package:matric_compass/features/dashboard/data/dashboard_tables.dart';
import 'package:matric_compass/features/dashboard/domain/learner_dashboard.dart';

part 'dashboard_dao.g.dart';

/// Week 11 Day 3: the dashboard on the phone. Rows go in as the server sent
/// them and come out as domain types: nothing above data/ sees a row.
@DriftAccessor(tables: [DashboardHeaders, DashboardLines])
class DashboardDao extends DatabaseAccessor<AppDatabase>
    with _$DashboardDaoMixin {
  /// Creates the DAO; the database makes it.
  new(super.attachedDatabase);

  /// The cached dashboard, again every time it changes. Null until the
  /// first fetch has been saved.
  ///
  /// The watched query selects the real columns on purpose. Drift shares
  /// one stream between watchers of identical SQL: when both DAOs watched a
  /// "SELECT 1" trigger, the detail screen got this stream and never heard
  /// its own tables.
  Stream<Snapshot<LearnerDashboard>?> watch() => customSelect(
    'SELECT h.full_name, h.fetched_at, l.id, l.position, l.status, '
    'l.deadline, l.days_until_deadline, l.amount_in_cents '
    'FROM dashboard_headers h LEFT JOIN dashboard_lines l ON 1 = 1',
    readsFrom: {dashboardHeaders, dashboardLines},
  ).watch().asyncMap((_) => read());

  /// The cached dashboard now, or null.
  Future<Snapshot<LearnerDashboard>?> read() async {
    final header = await select(dashboardHeaders).getSingleOrNull();
    if (header == null) return null;
    final lines = await (select(
      dashboardLines,
    )..orderBy([(line) => OrderingTerm.asc(line.position)])).get();
    return Snapshot(
      LearnerDashboard(
        fullName: header.fullName,
        bursaryApplications: [
          for (final line in lines)
            BursarySummary(
              id: line.id,
              funder: line.funder,
              status: BursaryStatus.fromApi(line.status),
              // Drift keeps a DateTime as seconds and returns local time.
              deadline: line.deadline.toUtc(),
              daysUntilDeadline: line.daysUntilDeadline,
              amount: Cents(line.amountInCents),
            ),
        ],
      ),
      fetchedAt: header.fetchedAt.toUtc(),
    );
  }

  /// Replaces the cache with what the server just sent, in one transaction:
  /// a watcher never sees half an old dashboard and half a new one.
  Future<void> save(
    LearnerDashboard dashboard, {
    required DateTime fetchedAt,
  }) => transaction(() async {
    await delete(dashboardLines).go();
    await into(dashboardHeaders).insertOnConflictUpdate(
      DashboardHeadersCompanion.insert(
        id: const Value(1),
        fullName: dashboard.fullName,
        fetchedAt: fetchedAt,
      ),
    );
    await batch((batch) {
      batch.insertAll(dashboardLines, [
        for (final (position, line) in dashboard.bursaryApplications.indexed)
          DashboardLinesCompanion.insert(
            id: line.id,
            position: position,
            funder: line.funder,
            status: line.status.apiName,
            deadline: line.deadline,
            daysUntilDeadline: line.daysUntilDeadline,
            amountInCents: line.amount.value,
          ),
      ]);
    });
  });
}
