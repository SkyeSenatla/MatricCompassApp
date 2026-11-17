// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/learner_dashboard_response.dart';
import '../models/me_response.dart';

part 'me_client.g.dart';

@RestApi()
abstract class MeClient {
  factory MeClient(Dio dio, {String? baseUrl}) = _MeClient;

  /// Who the signed-in user is, and their role.
  ///
  /// The frontend uses the role to choose which screen to show. That's a.
  ///
  /// convenience, not security: every endpoint still checks the role itself.
  @GET('/api/v1/me')
  Future<MeResponse> getApiV1Me();

  /// Everything the learner dashboard shows, in one response.
  @GET('/api/v1/me/dashboard')
  Future<LearnerDashboardResponse> getApiV1MeDashboard();
}
