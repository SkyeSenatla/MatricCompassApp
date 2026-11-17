import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'data_source.g.dart';

/// Week 11 Day 1: where every repository gets its data.
enum DataSource {
  /// Week 10's in-memory fakes. Tests that drive the whole app use these.
  fake,

  /// The Matric Compass API.
  api,
}

/// Week 11 Day 1: the app runs on the API. Each feature's repository
/// provider switches on this, so it is still the one place that names an
/// implementation, and whole-app tests override this one provider instead
/// of four.
@Riverpod(keepAlive: true)
DataSource dataSource(Ref ref) => DataSource.api;
