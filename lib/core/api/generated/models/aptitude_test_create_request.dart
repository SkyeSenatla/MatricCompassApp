// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'aptitude_test_create_request.g.dart';

@JsonSerializable()
class AptitudeTestCreateRequest {
  const AptitudeTestCreateRequest({
    required this.studentId,
    required this.testType,
    required this.dateTaken,
    required this.score,
  });

  factory AptitudeTestCreateRequest.fromJson(Map<String, Object?> json) =>
      _$AptitudeTestCreateRequestFromJson(json);

  final String studentId;
  final String testType;
  final DateTime dateTaken;
  final int score;

  Map<String, Object?> toJson() => _$AptitudeTestCreateRequestToJson(this);
}
