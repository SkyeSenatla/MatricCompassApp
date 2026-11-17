import 'package:matric_compass/app/data_source.dart';
import 'package:matric_compass/app/network/dio_provider.dart';
import 'package:matric_compass/core/fakes/fake_latency_provider.dart';
import 'package:matric_compass/features/auth/domain/auth_state.dart';
import 'package:matric_compass/features/auth/presentation/auth_controller.dart';
import 'package:matric_compass/features/bursaries/data/api_bursary_repository.dart';
import 'package:matric_compass/features/bursaries/data/fake_bursary_repository.dart';
import 'package:matric_compass/features/bursaries/domain/bursary_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'bursary_repository_provider.g.dart';

/// Week 10 Day 2: the one place that names the bursary implementation.
///
/// Week 10 Day 3: it watches who is signed in, so signing in as someone
/// else builds a new repository and nothing of the last person's view
/// carries over.
///
/// Week 11 Day 1: on the API, the server scopes what each person sees (a
/// learner gets 404 for anyone else's). The fake still plays that part.
@Riverpod(keepAlive: true)
BursaryRepository bursaryRepository(Ref ref) {
  final auth = ref.watch(authControllerProvider);
  return switch (ref.watch(dataSourceProvider)) {
    DataSource.api => ApiBursaryRepository(ref.watch(matricCompassApiProvider)),
    DataSource.fake => FakeBursaryRepository(
      latency: ref.watch(fakeLatencyProvider),
      ownerId: switch (auth) {
        SignedIn(:final user) when !user.role.isStaff => user.studentId,
        SignedIn() => null,
        // Signed out sees nothing: no student has an empty id.
        SignedOut() => '',
      },
    ),
  };
}
