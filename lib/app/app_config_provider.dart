import 'package:matric_compass/app/app_config.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_config_provider.g.dart';

/// Week 11 Day 1: the build's config, for providers that need it (the Dio
/// client needs the API's address).
///
/// main.dart overrides it with the config it read and checked at startup.
/// Nothing else can know the value, so reading it without the override is
/// a programming error, and says so.
@Riverpod(keepAlive: true)
AppConfig appConfig(Ref ref) => throw UnimplementedError(
  'appConfigProvider is overridden in main.dart, and in tests that use it.',
);
