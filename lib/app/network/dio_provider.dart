import 'package:dio/dio.dart';
import 'package:matric_compass/app/app_config_provider.dart';
import 'package:matric_compass/core/api/generated/matric_compass_api.dart';
import 'package:matric_compass/core/network/access_token.dart';
import 'package:matric_compass/core/network/access_token_interceptor.dart';
import 'package:matric_compass/core/network/safe_log_interceptor.dart';
import 'package:matric_compass/features/auth/presentation/auth_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dio_provider.g.dart';

/// Week 11 Day 1: the app's one HTTP client, built from the flavour's
/// config. No address is typed into code: dev's comes from config/dev.json.
///
/// keepAlive: one client, one connection pool, one set of interceptors for
/// the whole app. Repositories receive it; no widget ever sees it.
@Riverpod(keepAlive: true)
Dio dio(Ref ref) {
  final config = ref.watch(appConfigProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      // Reaching the server: a phone with no signal should fail fast.
      connectTimeout: const Duration(seconds: 10),
      // Waiting for an answer once connected.
      receiveTimeout: const Duration(seconds: 20),
      // Sending a body: Week 12's document uploads over mobile data.
      sendTimeout: const Duration(seconds: 60),
      headers: {'Accept': 'application/json'},
    ),
  );
  // They run in this order. Logging first sees every request.
  dio.interceptors.addAll([
    SafeLogInterceptor(),
    AccessTokenInterceptor(
      readToken: () => ref.read(accessTokenProvider)?.value,
      onUnauthorized: () => ref.read(authControllerProvider.notifier).signOut(),
    ),
  ]);
  ref.onDispose(dio.close);
  return dio;
}

/// Week 11 Day 1: the client generated from contract/openapi/v1.json.
/// Only API repositories (in each feature's data folder) use it.
@Riverpod(keepAlive: true)
MatricCompassApi matricCompassApi(Ref ref) =>
    MatricCompassApi(ref.watch(dioProvider));
