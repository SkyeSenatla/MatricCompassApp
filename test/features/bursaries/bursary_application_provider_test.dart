import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matric_compass/app/database/app_database.dart';
import 'package:matric_compass/core/cache/sync_state.dart';
import 'package:matric_compass/core/errors/failure.dart';
import 'package:matric_compass/core/errors/result.dart';
import 'package:matric_compass/core/fakes/seed.dart';
import 'package:matric_compass/core/money/cents.dart';
import 'package:matric_compass/features/bursaries/data/bursary_repository_provider.dart';
import 'package:matric_compass/features/bursaries/data/fake_bursary_repository.dart';
import 'package:matric_compass/features/bursaries/domain/bursary_application.dart';
import 'package:matric_compass/features/bursaries/domain/bursary_repository.dart';
import 'package:matric_compass/features/bursaries/domain/cached_bursary.dart';
import 'package:matric_compass/features/bursaries/presentation/bursary_application_provider.dart';
import 'package:matric_compass/features/bursaries/presentation/bursary_edit.dart';

import '../../support/test_database.dart';

/// The fake API, with the signal switched off and on, and an edit that can
/// be held mid-air.
class _Patchy implements BursaryRepository {
  new(this.inner);

  final FakeBursaryRepository inner;

  /// No answer at all, as in a taxi with no signal.
  bool offline = false;

  /// While set, every update waits for it.
  Completer<void>? hold;

  Future<Result<T>> _or<T>(Future<Result<T>> Function() call) async =>
      offline ? const Err(OfflineFailure()) : await call();

  @override
  Future<Result<BursaryApplication>> fetchById(String id) =>
      _or(() => inner.fetchById(id));

  @override
  Future<Result<List<BursaryApplication>>> fetchForReview() =>
      _or(inner.fetchForReview);

  @override
  Future<Result<BursaryApplication>> submit(String id) =>
      _or(() => inner.submit(id));

  @override
  Future<Result<void>> update(
    String id, {
    required Cents amount,
    required DateTime deadline,
    required int version,
  }) async {
    await hold?.future;
    return await _or(
      () => inner.update(
        id,
        amount: amount,
        deadline: deadline,
        version: version,
      ),
    );
  }
}

/// Week 11 Day 3: the cache, the background fetch and the optimistic edit,
/// with a real (in-memory) database and the fake API.
void main() {
  late _Patchy api;
  late AppDatabase database;
  late ProviderContainer container;

  setUp(() {
    api = _Patchy(FakeBursaryRepository(latency: Duration.zero));
    database = memoryDatabase();
    addTearDown(database.close);
    container = ProviderContainer.test(
      overrides: [
        bursaryRepositoryProvider.overrideWithValue(api),
        appDatabaseProvider.overrideWithValue(database),
      ],
      retry: (retryCount, error) => null,
    );
  });

  /// Waits until the sync for [id] has an answer.
  Future<void> settled(String id) async {
    for (var i = 0; i < 50; i++) {
      if (container.read(bursarySyncProvider(id)) is! Syncing) return;
      await pumpEventQueue();
    }
    fail('the sync never answered');
  }

  /// Opens the screen's providers for [id] and waits for the fetch.
  Future<void> open(String id) async {
    container
      ..listen(cachedBursaryProvider(id), (_, _) {})
      ..listen(bursarySyncProvider(id), (_, _) {})
      // The screen watches it; unwatched, an autoDispose provider resets.
      ..listen(bursaryEditProvider(id), (_, _) {});
    await settled(id);
  }

  Future<CachedBursary?> cached(String id) => database.bursaryDao.read(id);

  test('a fetch lands in the cache, and the screen reads the cache', () async {
    await open(Seed.nsfasId);

    expect((await cached(Seed.nsfasId))!.server.funder, 'NSFAS');
    expect(container.read(bursarySyncProvider(Seed.nsfasId)), isA<Synced>());
  });

  test('offline: the cache stays, and the sync says why', () async {
    await open(Seed.nsfasId);
    api.offline = true;

    await container.read(bursarySyncProvider(Seed.nsfasId).notifier).refresh();

    expect((await cached(Seed.nsfasId))!.server.funder, 'NSFAS');
    expect(
      container.read(bursarySyncProvider(Seed.nsfasId)),
      isA<SyncFailed>().having(
        (s) => s.failure,
        'failure',
        isA<OfflineFailure>(),
      ),
    );
  });

  test('not found: the phone forgets it', () async {
    await database.bursaryDao.save(
      Seed.applications.first.copyWith(id: 'gone'),
      fetchedAt: DateTime.now().toUtc(),
    );

    await open('gone');

    expect(await cached('gone'), isNull);
  });

  group('an optimistic edit', () {
    const newAmount = Cents(5000000);
    final newDeadline = DateTime.utc(2027, 1, 15);

    Future<Result<void>> save() => container
        .read(bursaryEditProvider(Seed.nsfasId).notifier)
        .save(amount: newAmount, deadline: newDeadline);

    test('accepted: the new values, with the new version', () async {
      await open(Seed.nsfasId);
      final before = (await cached(Seed.nsfasId))!.server.version;

      expect(await save(), isA<Ok<void>>());

      final after = (await cached(Seed.nsfasId))!;
      expect(after.pending, isNull);
      expect(after.server.amount, newAmount);
      expect(after.server.version, before + 1);
    });

    test('shown before the server answers', () async {
      await open(Seed.nsfasId);
      api.hold = Completer<void>();

      final saving = save();
      await pumpEventQueue();

      final meanwhile = (await cached(Seed.nsfasId))!;
      expect(meanwhile.shown.amount, newAmount, reason: 'optimistic');
      expect(meanwhile.server.amount, isNot(newAmount), reason: 'not saved');
      expect(container.read(bursaryEditProvider(Seed.nsfasId)), isTrue);

      api.hold!.complete();
      await saving;
    });

    test('changed elsewhere: a 409, rolled back to the latest', () async {
      await open(Seed.nsfasId);
      api.inner.changeElsewhere(Seed.nsfasId);

      final result = await save();

      expect((result as Err<void>).failure, isA<ConflictFailure>());
      final after = (await cached(Seed.nsfasId))!;
      expect(after.pending, isNull, reason: 'rolled back');
      expect(after.shown.amount, isNot(newAmount));
    });

    test('no answer: kept on the phone, marked, never saved', () async {
      await open(Seed.nsfasId);
      api.offline = true;

      final result = await save();

      expect((result as Err<void>).failure, isA<OfflineFailure>());
      final after = (await cached(Seed.nsfasId))!;
      expect(after.pending, isNotNull);
      expect(after.shown.amount, newAmount);
      expect(after.server.amount, isNot(newAmount));
    });

    test('sent again once online, it is saved', () async {
      await open(Seed.nsfasId);
      api.offline = true;
      await save();
      api.offline = false;

      final result = await container
          .read(bursaryEditProvider(Seed.nsfasId).notifier)
          .sendAgain();

      expect(result, isA<Ok<void>>());
      final after = (await cached(Seed.nsfasId))!;
      expect(after.pending, isNull);
      expect(after.server.amount, newAmount);
    });

    // Found on the emulator: the edit saved, but the banner still said
    // "You're offline" until the screen was opened again.
    test('saved after being offline: the offline banner goes', () async {
      await open(Seed.nsfasId);
      api.offline = true;
      await container
          .read(bursarySyncProvider(Seed.nsfasId).notifier)
          .refresh();
      await save();
      expect(
        container.read(bursarySyncProvider(Seed.nsfasId)),
        isA<SyncFailed>(),
      );
      api.offline = false;

      await container
          .read(bursaryEditProvider(Seed.nsfasId).notifier)
          .sendAgain();

      expect(container.read(bursarySyncProvider(Seed.nsfasId)), isA<Synced>());
    });

    test('discarded: the server values come back', () async {
      await open(Seed.nsfasId);
      api.offline = true;
      await save();

      await container
          .read(bursaryEditProvider(Seed.nsfasId).notifier)
          .discard();

      final after = (await cached(Seed.nsfasId))!;
      expect(after.pending, isNull);
      expect(after.shown.amount, isNot(newAmount));
    });
  });
}
