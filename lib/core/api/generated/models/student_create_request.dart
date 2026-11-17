// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'student_create_request.g.dart';

@JsonSerializable()
class StudentCreateRequest {
  const StudentCreateRequest({
    required this.fullName,
    required this.learnerReferenceNumber,
  });

  factory StudentCreateRequest.fromJson(Map<String, Object?> json) =>
      _$StudentCreateRequestFromJson(json);

  final String fullName;
  final String learnerReferenceNumber;

  Map<String, Object?> toJson() => _$StudentCreateRequestToJson(this);
}
