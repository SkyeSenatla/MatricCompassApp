import 'package:matric_compass/app/data_source.dart';
import 'package:matric_compass/app/network/dio_provider.dart';
import 'package:matric_compass/core/fakes/fake_latency_provider.dart';
import 'package:matric_compass/features/students/data/api_students_repository.dart';
import 'package:matric_compass/features/students/data/fake_students_repository.dart';
import 'package:matric_compass/features/students/domain/students_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'students_repository_provider.g.dart';

/// Week 10 Day 3: the one place that names the students implementation.
/// Week 11 Day 1: the API, unless a whole-app test asks for the fake.
@Riverpod(keepAlive: true)
StudentsRepository studentsRepository(Ref ref) {
  final source = ref.watch(dataSourceProvider);
  return switch (source) {
    DataSource.api => ApiStudentsRepository(
      ref.watch(matricCompassApiProvider),
    ),
    DataSource.fake => FakeStudentsRepository(
      latency: ref.watch(fakeLatencyProvider),
    ),
  };
}
