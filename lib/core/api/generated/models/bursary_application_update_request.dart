// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'bursary_application_update_request.g.dart';

@JsonSerializable()
class BursaryApplicationUpdateRequest {
  const BursaryApplicationUpdateRequest({
    required this.amountInCents,
    required this.deadline,
    required this.version,
  });

  factory BursaryApplicationUpdateRequest.fromJson(Map<String, Object?> json) =>
      _$BursaryApplicationUpdateRequestFromJson(json);

  final int amountInCents;
  final DateTime deadline;
  final int version;

  Map<String, Object?> toJson() =>
      _$BursaryApplicationUpdateRequestToJson(this);
}
