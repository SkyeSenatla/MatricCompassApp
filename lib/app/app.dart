import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matric_compass/app/app_config.dart';
import 'package:matric_compass/app/router/router_provider.dart';
import 'package:matric_compass/app/theme/app_theme.dart';

/// Week 10 Day 1: the app shell.
///
/// Week 10 Day 3: `home` becomes go_router, and one theme becomes two. The
/// phone's setting picks light or dark; nothing in a widget changes.
class MatricCompassApp extends ConsumerWidget {
  /// Creates the app for one flavour's [config].
  const new({required this.config, super.key});

  /// The build's settings.
  final AppConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Matric Compass',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: ref.watch(routerProvider),
      // A corner banner on every non-prod build, so a screenshot always
      // says which API it came from.
      builder: (context, child) => switch (config.flavor) {
        Flavor.prod => child!,
        Flavor.dev || Flavor.staging => Banner(
          message: config.flavor.name.toUpperCase(),
          location: BannerLocation.topEnd,
          child: child,
        ),
      },
    );
  }
}
