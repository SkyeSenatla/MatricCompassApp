// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'subject_response.dart';

part 'student_response.g.dart';

@JsonSerializable()
class StudentResponse {
  const StudentResponse({
    required this.id,
    required this.fullName,
    required this.learnerReferenceNumber,
    required this.subjects,
  });

  factory StudentResponse.fromJson(Map<String, Object?> json) =>
      _$StudentResponseFromJson(json);

  final String id;
  final String fullName;
  final String learnerReferenceNumber;
  final List<SubjectResponse> subjects;

  Map<String, Object?> toJson() => _$StudentResponseToJson(this);
}
