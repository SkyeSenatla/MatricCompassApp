// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'bursary_application_response.dart';

part 'paged_response_of_bursary_application_response.g.dart';

@JsonSerializable()
class PagedResponseOfBursaryApplicationResponse {
  const PagedResponseOfBursaryApplicationResponse({
    required this.items,
    required this.nextPageToken,
  });

  factory PagedResponseOfBursaryApplicationResponse.fromJson(
    Map<String, Object?> json,
  ) => _$PagedResponseOfBursaryApplicationResponseFromJson(json);

  final List<BursaryApplicationResponse> items;
  final String nextPageToken;

  Map<String, Object?> toJson() =>
      _$PagedResponseOfBursaryApplicationResponseToJson(this);
}
