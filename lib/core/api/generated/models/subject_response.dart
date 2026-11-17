// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'subject_response.g.dart';

@JsonSerializable()
class SubjectResponse {
  const SubjectResponse({
    required this.code,
    required this.currentMark,
    required this.targetMark,
  });

  factory SubjectResponse.fromJson(Map<String, Object?> json) =>
      _$SubjectResponseFromJson(json);

  final String code;
  final double currentMark;
  final double targetMark;

  Map<String, Object?> toJson() => _$SubjectResponseToJson(this);
}
