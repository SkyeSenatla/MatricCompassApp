import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:matric_compass/app/database/app_database.dart';
import 'package:matric_compass/core/cache/sync_state.dart';
import 'package:matric_compass/core/errors/failure.dart';
import 'package:matric_compass/core/errors/result.dart';
import 'package:matric_compass/features/bursaries/data/bursary_repository_provider.dart';
import 'package:matric_compass/features/bursaries/domain/cached_bursary.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'bursary_application_provider.g.dart';

/// Week 10 Day 2: one application by id. A family: one cached state per id,
/// so two applications never share (or leak) state.
///
/// Week 11 Day 3: from the phone's cache, with any edit still on its way
/// laid over it. Null if this phone has never fetched it.
@riverpod
Stream<CachedBursary?> cachedBursary(Ref ref, String id) =>
    ref.watch(appDatabaseProvider).bursaryDao.watch(id);

/// Week 11 Day 3: fetches application [id] in the background while its
/// screen is open, and keeps the cache current.
///
/// autoDispose: leave the detail screen and it goes; the print shows it in
/// the Run console. It logs the id only, never a name or an amount.
@riverpod
class BursarySync extends _$BursarySync {
  @override
  SyncState build(String id) {
    ref.onDispose(() => debugPrint('bursarySync($id) disposed'));
    unawaited(Future.microtask(_fetch));
    return const Syncing();
  }

  /// Another part of the app just fetched this application and cached it
  /// (an edit does): the cache is current, so the banner goes.
  void markSynced() => state = const Synced();

  /// Asks again: the banner's Try again.
  Future<void> refresh() async {
    state = const Syncing();
    await _fetch();
  }

  Future<void> _fetch() async {
    if (!ref.mounted) return;
    final result = await ref.read(bursaryRepositoryProvider).fetchById(id);
    if (!ref.mounted) return;
    final cache = ref.read(appDatabaseProvider).bursaryDao;
    switch (result) {
      case Ok(:final value):
        await cache.save(value, fetchedAt: DateTime.now().toUtc());
        if (ref.mounted) state = const Synced();
      case Err(failure: NotFoundFailure() && final failure):
        // Gone, or not ours (the API doesn't say which): the phone must
        // stop showing it.
        await cache.forget(id);
        if (ref.mounted) state = SyncFailed(failure);
      case Err(:final failure):
        state = SyncFailed(failure);
    }
  }
}
