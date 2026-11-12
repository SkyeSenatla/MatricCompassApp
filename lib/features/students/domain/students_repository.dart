import 'package:matric_compass/features/students/domain/student.dart';

/// Week 10 Day 3: the counsellor's view of learners. A fake today, the API's
/// staff endpoints from Week 11.
abstract interface class StudentsRepository {
  /// Every learner, by name.
  Future<List<Student>> fetchAll();

  /// One learner and her applications, or a [StudentNotFoundException].
  Future<StudentProfile> fetchById(String id);
}

/// No student with that id.
final class StudentNotFoundException implements Exception {
  /// Creates the exception for [id].
  const new(this.id);

  /// The id that wasn't found.
  final String id;

  @override
  String toString() => 'StudentNotFoundException($id)';
}
