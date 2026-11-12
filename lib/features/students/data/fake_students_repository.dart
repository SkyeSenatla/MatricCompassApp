import 'package:matric_compass/core/fakes/seed.dart';
import 'package:matric_compass/features/students/domain/student.dart';
import 'package:matric_compass/features/students/domain/students_repository.dart';

/// Week 10 Day 3: the three learners the API seeds, from memory. Their names
/// and learner numbers match the API; Sipho's and Ayanda's ids are fake.
final class FakeStudentsRepository implements StudentsRepository {
  /// Creates the fake; tests pass a zero [latency].
  new({this.latency = const Duration(milliseconds: 600)});

  /// How long each call pretends the network takes.
  final Duration latency;

  static const _students = [
    Student(
      id: Seed.ayandaId,
      fullName: 'Ayanda Zulu',
      learnerNumber: 'LRN-2026-00342',
    ),
    Student(
      id: Seed.siphoId,
      fullName: 'Sipho Dlamini',
      learnerNumber: 'LRN-2026-00287',
    ),
    Student(
      id: Seed.thandiweId,
      fullName: Seed.thandiweName,
      learnerNumber: 'LRN-2026-00114',
    ),
  ];

  @override
  Future<List<Student>> fetchAll() async {
    await Future<void>.delayed(latency);
    return _students;
  }

  @override
  Future<StudentProfile> fetchById(String id) async {
    await Future<void>.delayed(latency);
    for (final student in _students) {
      if (student.id == id) {
        return StudentProfile(
          student: student,
          applications: [
            for (final application in Seed.applications)
              if (application.studentId == id) application,
          ],
        );
      }
    }
    throw StudentNotFoundException(id);
  }
}
