// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/aptitude_test_create_request.dart';
import '../models/aptitude_test_response.dart';

part 'aptitude_tests_client.g.dart';

@RestApi()
abstract class AptitudeTestsClient {
  factory AptitudeTestsClient(Dio dio, {String? baseUrl}) =
      _AptitudeTestsClient;

  /// Lists aptitude tests, newest first.
  ///
  /// [studentId] - Staff: only this student's tests. A learner always gets their own.
  @GET('/api/v1/aptitude-tests')
  Future<List<AptitudeTestResponse>> getApiV1AptitudeTests({
    @Query('studentId') String? studentId,
  });

  /// Records an aptitude test result.
  ///
  /// A learner may record only their own; staff may record anyone's.
  @POST('/api/v1/aptitude-tests')
  Future<AptitudeTestResponse> postApiV1AptitudeTests({
    @Body() required AptitudeTestCreateRequest body,
  });
}
