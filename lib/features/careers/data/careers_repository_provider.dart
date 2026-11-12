import 'package:matric_compass/core/fakes/fake_latency_provider.dart';
import 'package:matric_compass/features/auth/domain/auth_state.dart';
import 'package:matric_compass/features/auth/presentation/auth_controller.dart';
import 'package:matric_compass/features/careers/data/fake_careers_repository.dart';
import 'package:matric_compass/features/careers/domain/careers_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'careers_repository_provider.g.dart';

/// Week 10 Day 4: the one place that names the Careers implementation.
/// Careers is a learner tab, so it is scoped to her student id. Staff and
/// signed-out callers get an empty id, which matches nobody's records.
@Riverpod(keepAlive: true)
CareersRepository careersRepository(Ref ref) {
  final auth = ref.watch(authControllerProvider);
  return FakeCareersRepository(
    latency: ref.watch(fakeLatencyProvider),
    ownerId: switch (auth) {
      SignedIn(:final user) => user.studentId ?? '',
      SignedOut() => '',
    },
  );
}
