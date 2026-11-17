// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/student_create_request.dart';
import '../models/student_response.dart';
import '../models/student_update_request.dart';

part 'students_client.g.dart';

@RestApi()
abstract class StudentsClient {
  factory StudentsClient(Dio dio, {String? baseUrl}) = _StudentsClient;

  /// Lists students, optionally only those matching a search.
  ///
  /// [search] - Part of a name or a learner reference number, any case. At most 100 characters.
  @GET('/api/v1/Students')
  Future<List<StudentResponse>> getApiV1Students({
    @Query('search') String? search,
  });

  /// Creates a new student record.
  ///
  /// Rejects a learner reference number that already belongs to another.
  ///
  /// student — see the 409 response below.
  @POST('/api/v1/Students')
  Future<StudentResponse> postApiV1Students({
    @Body() required StudentCreateRequest body,
  });

  /// Gets a single student by id.
  ///
  /// [id] - The student's id.
  @GET('/api/v1/Students/{id}')
  Future<StudentResponse> getApiV1StudentsId({@Path('id') required String id});

  /// Updates a student's full name.
  ///
  /// [id] - The student's id.
  @PUT('/api/v1/Students/{id}')
  Future<void> putApiV1StudentsId({
    @Path('id') required String id,
    @Body() required StudentUpdateRequest body,
  });

  /// Deletes a student.
  ///
  /// [id] - The student's id.
  @DELETE('/api/v1/Students/{id}')
  Future<void> deleteApiV1StudentsId({@Path('id') required String id});
}
