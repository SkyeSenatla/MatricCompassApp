import 'package:matric_compass/core/errors/result.dart';
import 'package:matric_compass/features/students/domain/student.dart';

/// Week 10 Day 3: the counsellor's view of learners.
///
/// Week 11 Day 1: both methods return a Result; StudentNotFoundException is
/// gone in favour of NotFoundFailure.
abstract interface class StudentsRepository {
  /// Every learner, by name.
  Future<Result<List<Student>>> fetchAll();

  /// One learner and her applications, or Err(NotFoundFailure).
  Future<Result<StudentProfile>> fetchById(String id);
}
