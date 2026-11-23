import 'package:matric_compass/core/api/generated/matric_compass_api.dart';
import 'package:matric_compass/core/api/generated/models/bursary_application_response.dart';
import 'package:matric_compass/core/api/generated/models/bursary_application_update_request.dart';
import 'package:matric_compass/core/errors/failure_mapping.dart';
import 'package:matric_compass/core/errors/result.dart';
import 'package:matric_compass/core/money/cents.dart';
import 'package:matric_compass/features/bursaries/domain/bursary_application.dart';
import 'package:matric_compass/features/bursaries/domain/bursary_repository.dart';
import 'package:matric_compass/features/bursaries/domain/bursary_status.dart';

/// Week 11 Day 1: bursary applications from the API.
final class ApiBursaryRepository implements BursaryRepository {
  /// Creates the repository over the generated API client.
  const new(this._api);

  final MatricCompassApi _api;

  /// The API's largest page. Week 11 Day 4 adds paging; until then a staff
  /// list shows the first page only.
  static const _pageSize = 50;

  @override
  Future<Result<BursaryApplication>> fetchById(String id) => guard(
    () async =>
        (await _api.bursaryApplications.getApiV1BursaryApplicationsId(id: id))
            .toDomain(),
  );

  @override
  Future<Result<List<BursaryApplication>>> fetchForReview() => guard(() async {
    // Two statuses, two calls, each in the API's deadline order. The app
    // filters nothing itself: the server decides what each status holds.
    final (submitted, underReview) = await (
      _page(BursaryStatus.submitted),
      _page(BursaryStatus.underReview),
    ).wait;
    return [...submitted, ...underReview];
  });

  @override
  Future<Result<BursaryApplication>> submit(String id) => guard(
    () async =>
        (await _api.bursaryApplications.postApiV1BursaryApplicationsIdSubmit(
          id: id,
        )).toDomain(),
  );

  @override
  Future<Result<void>> update(
    String id, {
    required Cents amount,
    required DateTime deadline,
    required int version,
  }) => guard(
    () => _api.bursaryApplications.putApiV1BursaryApplicationsId(
      id: id,
      body: BursaryApplicationUpdateRequest(
        amountInCents: amount.value,
        deadline: deadline.toUtc(),
        version: version,
      ),
    ),
  );

  Future<List<BursaryApplication>> _page(BursaryStatus status) async {
    final page = await _api.bursaryApplications.getApiV1BursaryApplications(
      status: status.apiName,
      orderBy: 'deadline',
      pageSize: _pageSize,
    );
    return [for (final item in page.items) item.toDomain()];
  }
}

/// The API's application, as the app means it. Shared with the students
/// repository, which lists one learner's applications.
extension BursaryApplicationMapping on BursaryApplicationResponse {
  /// The domain type.
  BursaryApplication toDomain() => BursaryApplication(
    id: id,
    studentId: studentId,
    funder: funder,
    amount: Cents(amountInCents),
    deadline: deadline.toUtc(),
    status: BursaryStatus.fromApi(status),
    requiredDocuments: requiredDocuments,
    // Kept exactly as sent: Day 3's edit sends it back for the 409 check.
    version: version,
    submittedAt: submittedAt?.toUtc(),
  );
}
