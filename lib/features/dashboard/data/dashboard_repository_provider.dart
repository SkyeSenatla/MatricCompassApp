import 'package:matric_compass/app/data_source.dart';
import 'package:matric_compass/app/network/dio_provider.dart';
import 'package:matric_compass/core/fakes/fake_latency_provider.dart';
import 'package:matric_compass/features/dashboard/data/api_dashboard_repository.dart';
import 'package:matric_compass/features/dashboard/data/fake_dashboard_repository.dart';
import 'package:matric_compass/features/dashboard/domain/dashboard_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dashboard_repository_provider.g.dart';

/// Week 10 Day 2: the one place that names the implementation.
///
/// Week 11 Day 1: the API, unless a whole-app test asks for the fake. This
/// switch is the swap: no widget, notifier or view state changed for it.
///
/// keepAlive: a repository holds no screen's state, and rebuilding it on
/// every visit would buy nothing.
@Riverpod(keepAlive: true)
DashboardRepository dashboardRepository(Ref ref) {
  final source = ref.watch(dataSourceProvider);
  return switch (source) {
    DataSource.api => ApiDashboardRepository(
      ref.watch(matricCompassApiProvider),
    ),
    DataSource.fake => FakeDashboardRepository(
      latency: ref.watch(fakeLatencyProvider),
    ),
  };
}
