import 'package:matric_compass/core/fakes/fake_latency_provider.dart';
import 'package:matric_compass/features/dashboard/data/fake_dashboard_repository.dart';
import 'package:matric_compass/features/dashboard/domain/dashboard_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dashboard_repository_provider.g.dart';

/// Week 10 Day 2: the one place that names the implementation. Week 11
/// changes this line to the real repository; no widget changes.
///
/// keepAlive: a repository holds no screen's state, and rebuilding it on
/// every visit would buy nothing.
@Riverpod(keepAlive: true)
DashboardRepository dashboardRepository(Ref ref) =>
    FakeDashboardRepository(latency: ref.watch(fakeLatencyProvider));
