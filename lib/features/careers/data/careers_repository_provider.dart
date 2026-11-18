import 'package:matric_compass/app/data_source.dart';
import 'package:matric_compass/app/network/dio_provider.dart';
import 'package:matric_compass/core/fakes/fake_latency_provider.dart';
import 'package:matric_compass/features/auth/domain/auth_state.dart';
import 'package:matric_compass/features/auth/presentation/auth_controller.dart';
import 'package:matric_compass/features/careers/data/api_careers_repository.dart';
import 'package:matric_compass/features/careers/data/fake_careers_repository.dart';
import 'package:matric_compass/features/careers/domain/careers_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'careers_repository_provider.g.dart';

/// Week 10 Day 4: the one place that names the Careers implementation.
///
/// Week 11 Day 1: the API scopes Careers by the learner's token. The fake
/// is scoped to her student id; staff and signed-out callers get an empty
/// id, which matches nobody's records.
@Riverpod(keepAlive: true)
CareersRepository careersRepository(Ref ref) {
  final auth = ref.watch(authControllerProvider);
  return switch (ref.watch(dataSourceProvider)) {
    DataSource.api => ApiCareersRepository(ref.watch(matricCompassApiProvider)),
    DataSource.fake => FakeCareersRepository(
      latency: ref.watch(fakeLatencyProvider),
      ownerId: switch (auth) {
        SignedIn(:final user) => user.studentId ?? '',
        SignedOut() || Restoring() => '',
      },
    ),
  };
}
