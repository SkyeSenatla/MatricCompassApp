import 'package:matric_compass/app/database/app_database.dart';
import 'package:matric_compass/core/errors/failure.dart';
import 'package:matric_compass/core/errors/result.dart';
import 'package:matric_compass/core/money/cents.dart';
import 'package:matric_compass/features/bursaries/data/bursary_repository_provider.dart';
import 'package:matric_compass/features/bursaries/domain/cached_bursary.dart';
import 'package:matric_compass/features/bursaries/presentation/bursary_application_provider.dart';
import 'package:matric_compass/features/dashboard/presentation/dashboard_cache.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'bursary_edit.g.dart';

/// Week 11 Day 3: how many edits are waiting to reach the server. Sign-out
/// asks before throwing them away.
@riverpod
Stream<int> pendingEditCount(Ref ref) =>
    ref.watch(appDatabaseProvider).bursaryDao.watchPendingCount();

/// Week 11 Day 3: changing a Draft's amount and deadline, optimistically.
///
/// The edit goes into the phone's pending-edits table first, so the screen
/// shows it at once, marked "Saving". Then it is sent with the version it
/// was made against, and the server's answer decides:
///
/// * accepted: the new version is fetched, and the pending edit goes;
/// * 409, changed elsewhere: the pending edit goes (that is the rollback),
///   and the latest version is fetched to show;
/// * no answer: the pending edit stays, marked "Not saved yet", to send
///   again or discard. It never pretends to be saved;
/// * any other refusal: rolled back, and the reason shown.
///
/// The state is "sending right now", so the screen can disable its
/// buttons: a second tap meanwhile would only earn a 409.
@riverpod
class BursaryEdit extends _$BursaryEdit {
  @override
  bool build(String id) => false;

  /// Makes the edit and sends it. Returns the server's answer for the
  /// screen to put into words.
  Future<Result<void>> save({
    required Cents amount,
    required DateTime deadline,
  }) async {
    final cache = ref.read(appDatabaseProvider).bursaryDao;
    final cached = await cache.read(id);
    if (cached == null) return const Err(NotFoundFailure());
    final edit = PendingEdit(
      amount: amount,
      deadline: deadline,
      // The version the person was looking at: the server checks it.
      baseVersion: cached.server.version,
      madeAt: DateTime.now().toUtc(),
    );
    // Optimistic: on screen now, before the server has seen it.
    await cache.putPendingEdit(id, edit);
    return await _send(edit);
  }

  /// Sends a pending edit again, after no answer. Safe to repeat: it carries
  /// the same base version, so if the first one did arrive, this one is a
  /// 409, never a second change.
  Future<Result<void>> sendAgain() async {
    final cached = await ref.read(appDatabaseProvider).bursaryDao.read(id);
    final edit = cached?.pending;
    if (edit == null) return const Ok(null);
    return await _send(edit);
  }

  /// Throws the pending edit away: the screen shows the server's values.
  Future<void> discard() =>
      ref.read(appDatabaseProvider).bursaryDao.removePendingEdit(id);

  Future<Result<void>> _send(PendingEdit edit) async {
    state = true;
    final repository = ref.read(bursaryRepositoryProvider);
    final cache = ref.read(appDatabaseProvider).bursaryDao;
    final result = await repository.update(
      id,
      amount: edit.amount,
      deadline: edit.deadline,
      version: edit.baseVersion,
    );
    switch (result) {
      case Ok():
        // 204 has no body: fetch the new version before dropping the
        // pending edit, so the screen never flashes back to the old values.
        switch (await repository.fetchById(id)) {
          case Ok(:final value):
            await cache.save(value, fetchedAt: DateTime.now().toUtc());
            _tellSync();
          case Err():
            // Saved, but we couldn't fetch it. Keep the new values with the
            // old version: the next edit then gets a 409 and a reload, which
            // is right, instead of overwriting blindly.
            final cached = await cache.read(id);
            if (cached != null) {
              await cache.save(
                cached.server.copyWith(
                  amount: edit.amount,
                  deadline: edit.deadline,
                ),
                fetchedAt: cached.fetchedAt,
              );
            }
        }
        await cache.removePendingEdit(id);
        // The dashboard shows the amount too.
        if (ref.mounted) ref.invalidate(dashboardSyncProvider);
      case Err(failure: OfflineFailure()):
        // No answer: it may or may not have arrived. Keep it, marked.
        break;
      case Err(failure: ConflictFailure()):
        // Changed elsewhere: roll back, and show the latest.
        await cache.removePendingEdit(id);
        if (await repository.fetchById(id) case Ok(:final value)) {
          await cache.save(value, fetchedAt: DateTime.now().toUtc());
          _tellSync();
        }
      case Err():
        // Refused for another reason (400, 404, 422): roll back.
        await cache.removePendingEdit(id);
    }
    if (ref.mounted) state = false;
    return result;
  }

  // We just fetched and cached the application: the screen's banner must
  // stop saying it's offline. Found on the emulator: after a successful
  // Send again, "You're offline" stayed until the screen was reopened.
  void _tellSync() {
    if (ref.mounted) ref.read(bursarySyncProvider(id).notifier).markSynced();
  }
}
