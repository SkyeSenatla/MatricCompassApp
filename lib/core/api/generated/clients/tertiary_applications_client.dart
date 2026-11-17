// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/tertiary_application_response.dart';

part 'tertiary_applications_client.g.dart';

@RestApi()
abstract class TertiaryApplicationsClient {
  factory TertiaryApplicationsClient(Dio dio, {String? baseUrl}) =
      _TertiaryApplicationsClient;

  /// Lists tertiary applications.
  ///
  /// [studentId] - Staff: only this student's. A learner always gets their own.
  @GET('/api/v1/tertiary-applications')
  Future<List<TertiaryApplicationResponse>> getApiV1TertiaryApplications({
    @Query('studentId') String? studentId,
  });
}
