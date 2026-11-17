// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'me_response.g.dart';

@JsonSerializable()
class MeResponse {
  const MeResponse({required this.email, required this.role});

  factory MeResponse.fromJson(Map<String, Object?> json) =>
      _$MeResponseFromJson(json);

  final String email;
  final String role;

  Map<String, Object?> toJson() => _$MeResponseToJson(this);
}
