// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'aptitude_test_response.g.dart';

@JsonSerializable()
class AptitudeTestResponse {
  const AptitudeTestResponse({
    required this.id,
    required this.studentId,
    required this.testType,
    required this.dateTaken,
    required this.score,
    required this.recommendedCareers,
  });

  factory AptitudeTestResponse.fromJson(Map<String, Object?> json) =>
      _$AptitudeTestResponseFromJson(json);

  final String id;
  final String studentId;
  final String testType;
  final DateTime dateTaken;
  final int score;
  final List<String> recommendedCareers;

  Map<String, Object?> toJson() => _$AptitudeTestResponseToJson(this);
}
