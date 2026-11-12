import 'package:matric_compass/features/careers/domain/aptitude_test.dart';
import 'package:matric_compass/features/careers/domain/tertiary_application.dart';

/// Week 10 Day 4: what the Careers tab needs from somewhere. Two methods for
/// the API's two endpoints: GET /api/v1/aptitude-tests and
/// GET /api/v1/tertiary-applications. Both only ever return the signed-in
/// learner's own records, as the API has since Week 9.
abstract interface class CareersRepository {
  /// Her aptitude tests, newest first.
  Future<List<AptitudeTest>> fetchAptitudeTests();

  /// Her university applications.
  Future<List<TertiaryApplication>> fetchTertiaryApplications();
}
