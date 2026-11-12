import 'package:matric_compass/core/fakes/fake_latency_provider.dart';
import 'package:matric_compass/features/auth/domain/auth_state.dart';
import 'package:matric_compass/features/auth/presentation/auth_controller.dart';
import 'package:matric_compass/features/bursaries/data/fake_bursary_repository.dart';
import 'package:matric_compass/features/bursaries/domain/bursary_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'bursary_repository_provider.g.dart';

/// Week 10 Day 2: the one place that names the bursary implementation.
///
/// Week 10 Day 3: it watches who is signed in. A learner gets a fake that
/// answers "not found" for anyone else's application, as the API's 404
/// does; staff see every application. Signing in as someone else builds a
/// new repository, so nothing of the last person's view carries over.
@Riverpod(keepAlive: true)
BursaryRepository bursaryRepository(Ref ref) {
  final auth = ref.watch(authControllerProvider);
  return FakeBursaryRepository(
    latency: ref.watch(fakeLatencyProvider),
    ownerId: switch (auth) {
      SignedIn(:final user) when !user.role.isStaff => user.studentId,
      SignedIn() => null,
      // Signed out sees nothing: no student has an empty id.
      SignedOut() => '',
    },
  );
}
