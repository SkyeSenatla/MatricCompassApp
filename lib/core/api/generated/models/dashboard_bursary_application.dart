// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'dashboard_bursary_application.g.dart';

@JsonSerializable()
class DashboardBursaryApplication {
  const DashboardBursaryApplication({
    required this.id,
    required this.funder,
    required this.status,
    required this.deadline,
    required this.daysUntilDeadline,
    required this.amountInCents,
  });

  factory DashboardBursaryApplication.fromJson(Map<String, Object?> json) =>
      _$DashboardBursaryApplicationFromJson(json);

  final String id;
  final String funder;
  final String status;
  final DateTime deadline;
  final int daysUntilDeadline;
  final int amountInCents;

  Map<String, Object?> toJson() => _$DashboardBursaryApplicationToJson(this);
}
