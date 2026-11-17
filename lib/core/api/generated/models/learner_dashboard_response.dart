// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'dashboard_bursary_application.dart';
import 'dashboard_subject.dart';

part 'learner_dashboard_response.g.dart';

@JsonSerializable()
class LearnerDashboardResponse {
  const LearnerDashboardResponse({
    required this.fullName,
    required this.subjects,
    required this.bursaryApplications,
  });

  factory LearnerDashboardResponse.fromJson(Map<String, Object?> json) =>
      _$LearnerDashboardResponseFromJson(json);

  final String fullName;
  final List<DashboardSubject> subjects;
  final List<DashboardBursaryApplication> bursaryApplications;

  Map<String, Object?> toJson() => _$LearnerDashboardResponseToJson(this);
}
