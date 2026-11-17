// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'bursary_application_response.g.dart';

@JsonSerializable()
class BursaryApplicationResponse {
  const BursaryApplicationResponse({
    required this.id,
    required this.studentId,
    required this.funder,
    required this.amountInCents,
    required this.deadline,
    required this.status,
    required this.requiredDocuments,
    required this.submittedAt,
    required this.version,
  });

  factory BursaryApplicationResponse.fromJson(Map<String, Object?> json) =>
      _$BursaryApplicationResponseFromJson(json);

  final String id;
  final String studentId;
  final String funder;
  final int amountInCents;
  final DateTime deadline;
  final String status;
  final List<String> requiredDocuments;
  final DateTime? submittedAt;
  final int version;

  Map<String, Object?> toJson() => _$BursaryApplicationResponseToJson(this);
}
