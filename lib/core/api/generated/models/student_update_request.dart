// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'student_update_request.g.dart';

@JsonSerializable()
class StudentUpdateRequest {
  const StudentUpdateRequest({required this.fullName});

  factory StudentUpdateRequest.fromJson(Map<String, Object?> json) =>
      _$StudentUpdateRequestFromJson(json);

  final String fullName;

  Map<String, Object?> toJson() => _$StudentUpdateRequestToJson(this);
}
