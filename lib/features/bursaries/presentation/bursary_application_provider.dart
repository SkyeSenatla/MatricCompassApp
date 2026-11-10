import 'package:flutter/foundation.dart';
import 'package:matric_compass/features/bursaries/data/bursary_repository_provider.dart';
import 'package:matric_compass/features/bursaries/domain/bursary_application.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'bursary_application_provider.g.dart';

/// Week 10 Day 2: one application by id. A family: one cached state per id,
/// so two applications never share (or leak) state, and two screens asking
/// for the same id share one fetch.
///
/// autoDispose: leave the detail screen and the state goes. The print shows
/// it in the Run console; it logs the id only, never a name or an amount.
@riverpod
Future<BursaryApplication> bursaryApplication(Ref ref, String id) {
  ref.onDispose(() => debugPrint('bursaryApplication($id) disposed'));
  return ref.watch(bursaryRepositoryProvider).fetchById(id);
}
