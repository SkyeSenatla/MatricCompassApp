import 'dart:async';

import 'package:dio/dio.dart';
import 'package:matric_compass/app/app_config_provider.dart';
import 'package:matric_compass/core/api/generated/matric_compass_api.dart';
import 'package:matric_compass/core/network/safe_log_interceptor.dart';
import 'package:matric_compass/core/network/session_interceptor.dart';
import 'package:matric_compass/features/auth/data/session.dart';
import 'package:matric_compass/features/auth/presentation/auth_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dio_provider.g.dart';

BaseOptions _options(String baseUrl) => BaseOptions(
  baseUrl: baseUrl,
  // Reaching the server: a phone with no signal should fail fast.
  connectTimeout: const Duration(seconds: 10),
  // Waiting for an answer once connected.
  receiveTimeout: const Duration(seconds: 20),
  // Sending a body: Week 12's document uploads over mobile data.
  sendTimeout: const Duration(seconds: 60),
  headers: {'Accept': 'application/json'},
);

/// Week 11 Day 1: the app's HTTP client, built from the flavour's config.
/// No address is typed into code: dev's comes from config/dev.json.
///
/// Week 11 Day 2: its session interceptor adds the access token, refreshes
/// it before it expires, and turns a 401 into one refresh and one retry.
///
/// keepAlive: one client, one connection pool, one set of interceptors for
/// the whole app. Repositories receive it; no widget ever sees it.
@Riverpod(keepAlive: true)
Dio dio(Ref ref) {
  final dio = Dio(_options(ref.watch(appConfigProvider).apiBaseUrl));
  // They run in this order. Logging first sees every request.
  dio.interceptors.addAll([
    SafeLogInterceptor(),
    SessionInterceptor(
      session: ref.watch(sessionProvider),
      retryWith: ref.watch(bareDioProvider),
      // A refresh the API refused: the session is over.
      onSessionEnded: () =>
          unawaited(ref.read(authControllerProvider.notifier).sessionEnded()),
    ),
  ]);
  ref.onDispose(dio.close);
  return dio;
}

/// Week 11 Day 2: the same client WITHOUT the session interceptor, for the
/// auth calls themselves and for sending a request again after a refresh.
/// Going through the session interceptor would queue them behind the very
/// error being handled, and they would wait forever.
@Riverpod(keepAlive: true)
Dio bareDio(Ref ref) {
  final dio = Dio(_options(ref.watch(appConfigProvider).apiBaseUrl))
    ..interceptors.add(SafeLogInterceptor());
  ref.onDispose(dio.close);
  return dio;
}

/// Week 11 Day 1: the client generated from contract/openapi/v1.json.
/// Only API repositories (in each feature's data folder) use it.
@Riverpod(keepAlive: true)
MatricCompassApi matricCompassApi(Ref ref) =>
    MatricCompassApi(ref.watch(dioProvider));
