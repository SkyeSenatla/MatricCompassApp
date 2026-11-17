// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';

import 'clients/aptitude_tests_client.dart';
import 'clients/auth_client.dart';
import 'clients/bursary_applications_client.dart';
import 'clients/me_client.dart';
import 'clients/students_client.dart';
import 'clients/tertiary_applications_client.dart';

/// API | v1 `v1.0.0`
class MatricCompassApi {
  MatricCompassApi(Dio dio, {String? baseUrl}) : _dio = dio, _baseUrl = baseUrl;

  final Dio _dio;
  final String? _baseUrl;

  static String get version => '1.0.0';

  AptitudeTestsClient? _aptitudeTests;
  AuthClient? _auth;
  BursaryApplicationsClient? _bursaryApplications;
  MeClient? _me;
  StudentsClient? _students;
  TertiaryApplicationsClient? _tertiaryApplications;

  AptitudeTestsClient get aptitudeTests =>
      _aptitudeTests ??= AptitudeTestsClient(_dio, baseUrl: _baseUrl);

  AuthClient get auth => _auth ??= AuthClient(_dio, baseUrl: _baseUrl);

  BursaryApplicationsClient get bursaryApplications => _bursaryApplications ??=
      BursaryApplicationsClient(_dio, baseUrl: _baseUrl);

  MeClient get me => _me ??= MeClient(_dio, baseUrl: _baseUrl);

  StudentsClient get students =>
      _students ??= StudentsClient(_dio, baseUrl: _baseUrl);

  TertiaryApplicationsClient get tertiaryApplications =>
      _tertiaryApplications ??= TertiaryApplicationsClient(
        _dio,
        baseUrl: _baseUrl,
      );
}
