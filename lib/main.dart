import 'package:flutter/material.dart';
import 'package:matric_compass/app/app.dart';
import 'package:matric_compass/app/app_config.dart';

void main() {
  // Week 10 Day 1: fail at startup, loudly, if the build has no config.
  final config = AppConfig.fromEnvironment();
  runApp(MatricCompassApp(config: config));
}
