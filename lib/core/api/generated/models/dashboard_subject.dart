// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'dashboard_subject.g.dart';

@JsonSerializable()
class DashboardSubject {
  const DashboardSubject({
    required this.code,
    required this.currentMark,
    required this.targetMark,
    required this.onTrack,
  });

  factory DashboardSubject.fromJson(Map<String, Object?> json) =>
      _$DashboardSubjectFromJson(json);

  final String code;
  final double currentMark;
  final double targetMark;
  final bool onTrack;

  Map<String, Object?> toJson() => _$DashboardSubjectToJson(this);
}
