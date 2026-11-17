import 'package:matric_compass/core/api/generated/matric_compass_api.dart';
import 'package:matric_compass/core/api/generated/models/aptitude_test_response.dart';
import 'package:matric_compass/core/api/generated/models/tertiary_application_response.dart';
import 'package:matric_compass/core/errors/failure_mapping.dart';
import 'package:matric_compass/core/errors/result.dart';
import 'package:matric_compass/features/careers/domain/aptitude_test.dart';
import 'package:matric_compass/features/careers/domain/careers_repository.dart';
import 'package:matric_compass/features/careers/domain/tertiary_application.dart';
import 'package:matric_compass/features/careers/domain/tertiary_status.dart';

/// Week 11 Day 1: the Careers tab from the API. A learner gets her own
/// records without passing her id: the API scopes them by her token.
final class ApiCareersRepository implements CareersRepository {
  /// Creates the repository over the generated API client.
  const new(this._api);

  final MatricCompassApi _api;

  @override
  Future<Result<List<AptitudeTest>>> fetchAptitudeTests() => guard(
    () async => [
      for (final test in await _api.aptitudeTests.getApiV1AptitudeTests())
        test.toDomain(),
    ],
  );

  @override
  Future<Result<List<TertiaryApplication>>> fetchTertiaryApplications() =>
      guard(
        () async => [
          for (final application
              in await _api.tertiaryApplications.getApiV1TertiaryApplications())
            application.toDomain(),
        ],
      );
}

extension on AptitudeTestResponse {
  AptitudeTest toDomain() => AptitudeTest(
    id: id,
    studentId: studentId,
    testType: testType,
    dateTaken: dateTaken.toUtc(),
    score: score,
    // As sent, in the server's order: the app never works these out.
    recommendedCareers: recommendedCareers,
  );
}

extension on TertiaryApplicationResponse {
  TertiaryApplication toDomain() => TertiaryApplication(
    id: id,
    studentId: studentId,
    institutionName: institutionName,
    programmeName: programmeName,
    status: TertiaryStatus.fromApi(status),
  );
}
