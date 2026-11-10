import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matric_compass/app/app.dart';
import 'package:matric_compass/app/app_config.dart';

void main() {
  // Week 10 Day 1: fail at startup, loudly, if the build has no config.
  final config = AppConfig.fromEnvironment();
  // Week 10 Day 2: one container for the whole app. Tests make their own,
  // with overrides.
  runApp(ProviderScope(child: MatricCompassApp(config: config)));
}
