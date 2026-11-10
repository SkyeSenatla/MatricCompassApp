import 'package:flutter/material.dart';
import 'package:matric_compass/app/app_config.dart';
import 'package:matric_compass/app/home_placeholder.dart';

/// Week 10 Day 1: the app shell. Day 3 swaps `home` for go_router.
class MatricCompassApp extends StatelessWidget {
  /// Creates the app for one flavour's [config].
  const new({required this.config, super.key});

  /// The build's settings.
  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Matric Compass',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: const Color(0xFF1B5E20)),
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
      home: HomePlaceholder(config: config),
    );
  }
}
