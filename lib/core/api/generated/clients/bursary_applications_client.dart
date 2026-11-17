// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/bursary_application_create_request.dart';
import '../models/bursary_application_response.dart';
import '../models/bursary_application_update_request.dart';
import '../models/paged_response_of_bursary_application_response.dart';

part 'bursary_applications_client.g.dart';

@RestApi()
abstract class BursaryApplicationsClient {
  factory BursaryApplicationsClient(Dio dio, {String? baseUrl}) =
      _BursaryApplicationsClient;

  /// Lists bursary applications, one page at a time.
  @GET('/api/v1/bursary-applications')
  Future<PagedResponseOfBursaryApplicationResponse>
  getApiV1BursaryApplications({
    @Query('PageSize') int? pageSize,
    @Query('PageToken') String? pageToken,
    @Query('StudentId') String? studentId,
    @Query('Status') String? status,
    @Query('OrderBy') String? orderBy,
  });

  /// Creates a new bursary application for a student.
  ///
  /// Rejects a deadline in the past and a second active application with the.
  ///
  /// same funder for the same student — see the 409 and 422 responses below.
  @POST('/api/v1/bursary-applications')
  Future<BursaryApplicationResponse> postApiV1BursaryApplications({
    @Body() required BursaryApplicationCreateRequest body,
  });

  /// Gets a single bursary application by id.
  ///
  /// [id] - The bursary application's id.
  @GET('/api/v1/bursary-applications/{id}')
  Future<BursaryApplicationResponse> getApiV1BursaryApplicationsId({
    @Path('id') required String id,
  });

  /// Updates the amount and deadline of an existing bursary application.
  ///
  /// [id] - The bursary application's id.
  @PUT('/api/v1/bursary-applications/{id}')
  Future<void> putApiV1BursaryApplicationsId({
    @Path('id') required String id,
    @Body() required BursaryApplicationUpdateRequest body,
  });

  /// Deletes a bursary application.
  ///
  /// [id] - The bursary application's id.
  @DELETE('/api/v1/bursary-applications/{id}')
  Future<void> deleteApiV1BursaryApplicationsId({
    @Path('id') required String id,
  });

  /// Submits a Draft application to its funder.
  ///
  /// The learner who owns it, or staff. Every required document must be uploaded first.
  ///
  /// [id] - The bursary application's id.
  @POST('/api/v1/bursary-applications/{id}/submit')
  Future<BursaryApplicationResponse> postApiV1BursaryApplicationsIdSubmit({
    @Path('id') required String id,
  });
}
