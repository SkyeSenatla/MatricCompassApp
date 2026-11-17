// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'bursary_application_create_request.g.dart';

@JsonSerializable()
class BursaryApplicationCreateRequest {
  const BursaryApplicationCreateRequest({
    required this.studentId,
    required this.funder,
    required this.amountInCents,
    required this.deadline,
    required this.requiredDocuments,
  });

  factory BursaryApplicationCreateRequest.fromJson(Map<String, Object?> json) =>
      _$BursaryApplicationCreateRequestFromJson(json);

  final String studentId;
  final String funder;
  final int amountInCents;
  final DateTime deadline;
  final List<String> requiredDocuments;

  Map<String, Object?> toJson() =>
      _$BursaryApplicationCreateRequestToJson(this);
}
