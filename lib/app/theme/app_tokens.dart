import 'package:flutter/painting.dart';

/// Week 10 Day 3: the design decisions, made once. Widgets never hold a
/// colour of their own: they ask the theme, which is built from these.
abstract final class AppTokens {
  /// Matric Compass green: the one seed the whole colour scheme grows from.
  static const seed = Color(0xFF1B5E20);

  /// Corner radius for cards and chips.
  static const radius = 12.0;

  /// The smallest spacing step, in logical pixels.
  static const space1 = 4.0;

  /// The second spacing step.
  static const space2 = 8.0;

  /// The third spacing step.
  static const space3 = 16.0;

  /// The fourth spacing step.
  static const space4 = 24.0;
}
