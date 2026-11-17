// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'tertiary_application_response.g.dart';

@JsonSerializable()
class TertiaryApplicationResponse {
  const TertiaryApplicationResponse({
    required this.id,
    required this.studentId,
    required this.institutionName,
    required this.programmeName,
    required this.status,
  });

  factory TertiaryApplicationResponse.fromJson(Map<String, Object?> json) =>
      _$TertiaryApplicationResponseFromJson(json);

  final String id;
  final String studentId;
  final String institutionName;
  final String programmeName;
  final String status;

  Map<String, Object?> toJson() => _$TertiaryApplicationResponseToJson(this);
}
