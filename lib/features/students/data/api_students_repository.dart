import 'package:matric_compass/core/api/generated/matric_compass_api.dart';
import 'package:matric_compass/core/api/generated/models/student_response.dart';
import 'package:matric_compass/core/errors/failure_mapping.dart';
import 'package:matric_compass/core/errors/result.dart';
import 'package:matric_compass/features/bursaries/data/api_bursary_repository.dart';
import 'package:matric_compass/features/students/domain/student.dart';
import 'package:matric_compass/features/students/domain/students_repository.dart';

/// Week 11 Day 1: the counsellor's students from the API (staff only: a
/// learner gets 403, which becomes a ForbiddenFailure).
final class ApiStudentsRepository implements StudentsRepository {
  /// Creates the repository over the generated API client.
  const new(this._api);

  final MatricCompassApi _api;

  @override
  Future<Result<List<Student>>> fetchAll() => guard(
    () async => [
      for (final student in await _api.students.getApiV1Students())
        student.toDomain(),
    ],
  );

  @override
  Future<Result<StudentProfile>> fetchById(String id) => guard(() async {
    // Her details and her applications, fetched together. A 404 from
    // either becomes NotFoundFailure.
    final (student, page) = await (
      _api.students.getApiV1StudentsId(id: id),
      _api.bursaryApplications.getApiV1BursaryApplications(
        studentId: id,
        orderBy: 'deadline',
        // First page only until Week 11 Day 4.
        pageSize: 50,
      ),
    ).wait;
    return StudentProfile(
      student: student.toDomain(),
      applications: [for (final item in page.items) item.toDomain()],
    );
  });
}

extension on StudentResponse {
  Student toDomain() => Student(
    id: id,
    fullName: fullName,
    learnerNumber: learnerReferenceNumber,
  );
}
