import 'package:matric_compass/core/errors/result.dart';
import 'package:matric_compass/features/bursaries/data/bursary_repository_provider.dart';
import 'package:matric_compass/features/bursaries/domain/bursary_application.dart';
import 'package:matric_compass/features/bursaries/presentation/bursary_application_provider.dart';
import 'package:matric_compass/features/dashboard/presentation/dashboard_cache.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'bursary_submission.g.dart';

/// Week 11 Day 1: submitting one application. The state is "sending right
/// now", so the screen can disable the button: a second tap while the first
/// is on its way would only earn a 409.
///
/// A family by id, autoDispose: it lives as long as the detail screen.
/// It is never retried automatically. A submit is a write: if the answer
/// was lost, the first one may already have worked.
@riverpod
class BursarySubmission extends _$BursarySubmission {
  @override
  bool build(String id) => false;

  /// Submits, and returns the API's answer for the screen to show.
  /// Submitting needs the server: offline it is an OfflineFailure, shown,
  /// never queued.
  Future<Result<BursaryApplication>> submit() async {
    state = true;
    final result = await ref.read(bursaryRepositoryProvider).submit(id);
    if (!ref.mounted) return result;
    state = false;
    // Worked or not, the application may have changed (a 409 means it
    // already did): fetch it, and the dashboard, again.
    // Week 11 Day 3: into the cache, which the screens watch.
    ref
      ..invalidate(bursarySyncProvider(id))
      ..invalidate(dashboardSyncProvider);
    return result;
  }
}
