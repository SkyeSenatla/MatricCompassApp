import 'package:matric_compass/core/fakes/fake_latency_provider.dart';
import 'package:matric_compass/features/students/data/fake_students_repository.dart';
import 'package:matric_compass/features/students/domain/students_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'students_repository_provider.g.dart';

/// Week 10 Day 3: the one place that names the students implementation.
@Riverpod(keepAlive: true)
StudentsRepository studentsRepository(Ref ref) =>
    FakeStudentsRepository(latency: ref.watch(fakeLatencyProvider));
