import 'package:matric_compass/features/bursaries/data/bursary_repository_provider.dart';
import 'package:matric_compass/features/bursaries/domain/bursary_application.dart';
import 'package:matric_compass/features/students/data/students_repository_provider.dart';
import 'package:matric_compass/features/students/domain/student.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'students_providers.g.dart';

/// Week 10 Day 3: the counsellor's students list.
@riverpod
Future<List<Student>> students(Ref ref) =>
    ref.watch(studentsRepositoryProvider).fetchAll();

/// Week 10 Day 3: one student, by the id in the address. A family, as on
/// Day 2: the detail pane needs only the id, so a deep link or a rotated
/// tablet rebuilds it with nothing missing.
@riverpod
Future<StudentProfile> student(Ref ref, String id) =>
    ref.watch(studentsRepositoryProvider).fetchById(id);

/// Week 10 Day 3: the staff Applications tab.
@riverpod
Future<List<BursaryApplication>> applicationsForReview(Ref ref) =>
    ref.watch(bursaryRepositoryProvider).fetchForReview();
