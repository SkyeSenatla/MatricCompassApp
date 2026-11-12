import 'package:matric_compass/features/bursaries/domain/bursary_application.dart';

/// Week 10 Day 3: one learner, as a counsellor sees her in the list.
final class Student {
  /// Creates a student.
  const new({
    required this.id,
    required this.fullName,
    required this.learnerNumber,
  });

  /// The student's id; the address /staff/students/:id carries it.
  final String id;

  /// Her full name.
  final String fullName;

  /// The school's learner number, such as LRN-2026-00114.
  final String learnerNumber;
}

/// Week 10 Day 3: one student and her bursary applications, for the
/// detail pane.
final class StudentProfile {
  /// Creates a profile.
  const new({required this.student, required this.applications});

  /// Who she is.
  final Student student;

  /// Her applications, in deadline order.
  final List<BursaryApplication> applications;
}
