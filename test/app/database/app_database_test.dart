import 'package:flutter_test/flutter_test.dart';
import 'package:matric_compass/app/database/app_database.dart';
import 'package:matric_compass/core/fakes/seed.dart';
import 'package:matric_compass/core/money/cents.dart';
import 'package:matric_compass/features/auth/data/fake_personas.dart';
import 'package:matric_compass/features/bursaries/domain/cached_bursary.dart';
import 'package:matric_compass/features/dashboard/domain/learner_dashboard.dart';

import '../../support/test_database.dart';

/// Week 11 Day 3: the database on its own: what goes in comes out as domain
/// types, watchers hear every change, and sign-out leaves nothing.
void main() {
  late AppDatabase database;

  setUp(() {
    database = memoryDatabase();
    addTearDown(database.close);
  });

  final nsfas = Seed.applications.firstWhere((a) => a.id == Seed.nsfasId);
  final now = DateTime.utc(2026, 11, 18, 6, 12);

  // The bug this caught: both DAOs once watched a "SELECT 1" trigger
  // query. Two watchers of identical SQL shared one stream, so with the
  // dashboard open first, the detail screen heard only the dashboard's
  // tables and never saw its own save.
  test('the dashboard and a detail, watched together, each see their own '
      'saves', () async {
    final dashboard = database.dashboardDao.watch().listen((_) {});
    addTearDown(dashboard.cancel);
    final seen = <CachedBursary?>[];
    final detail = database.bursaryDao.watch(nsfas.id).listen(seen.add);
    addTearDown(detail.cancel);
    await pumpEventQueue();
    expect(seen, [null]);

    await database.bursaryDao.save(nsfas, fetchedAt: now);
    await pumpEventQueue();

    expect(seen.last?.server.funder, 'NSFAS');
  });

  test(
    'a pending edit is laid over the server values, not saved in them',
    () async {
      await database.bursaryDao.save(nsfas, fetchedAt: now);
      await database.bursaryDao.putPendingEdit(
        nsfas.id,
        PendingEdit(
          amount: const Cents(5000000),
          deadline: DateTime.utc(2027, 1, 15),
          baseVersion: nsfas.version,
          madeAt: now,
        ),
      );

      final cached = (await database.bursaryDao.read(nsfas.id))!;

      expect(cached.shown.amount, const Cents(5000000));
      expect(cached.server.amount, nsfas.amount);
      expect(cached.fetchedAt, now);
    },
  );

  test('the dashboard comes back in the order it went in', () async {
    final seen = <LearnerDashboard?>[];
    final subscription = database.dashboardDao.watch().listen(
      (snapshot) => seen.add(snapshot?.value),
    );
    addTearDown(subscription.cancel);

    final summaries = [
      for (final application in Seed.thandiweApplications)
        BursarySummary(
          id: application.id,
          funder: application.funder,
          status: application.status,
          deadline: application.deadline,
          daysUntilDeadline: 30,
          amount: application.amount,
        ),
    ];
    await database.dashboardDao.save(
      LearnerDashboard(
        fullName: Seed.thandiweName,
        bursaryApplications: summaries,
      ),
      fetchedAt: now,
    );
    await pumpEventQueue();

    expect(seen.last?.fullName, Seed.thandiweName);
    expect(seen.last?.bursaryApplications.map((s) => s.id), [
      for (final summary in summaries) summary.id,
    ]);
  });

  test(
    'wipe leaves nothing: rows, pending edits, the remembered user',
    () async {
      await database.bursaryDao.save(nsfas, fetchedAt: now);
      await database.sessionUserDao.save(FakePersonas.thandiwe);

      await database.wipe();

      expect(await database.bursaryDao.read(nsfas.id), isNull);
      expect(await database.sessionUserDao.read(), isNull);
      expect(await database.dashboardDao.read(), isNull);
    },
  );
}
