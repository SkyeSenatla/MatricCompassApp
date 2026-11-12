import 'package:flutter/material.dart';
import 'package:matric_compass/app/theme/app_tokens.dart';
import 'package:matric_compass/app/theme/status_colors.dart';

/// Week 10 Day 3: the tokens, applied. One seed gives Material 3's colour
/// roles in light and dark; our status colours ride along as an extension.
abstract final class AppTheme {
  /// The light theme.
  static ThemeData light() => _build(Brightness.light, StatusColors.light);

  /// The dark theme: the same seed and roles, new values.
  static ThemeData dark() => _build(Brightness.dark, StatusColors.dark);

  static ThemeData _build(Brightness brightness, StatusColors status) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppTokens.seed,
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: scheme,
      cardTheme: const CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppTokens.radius)),
        ),
      ),
      extensions: [status],
    );
  }
}

/// Reads our extension back from the theme.
extension StatusColorsOf on ThemeData {
  /// The status colours for this theme.
  StatusColors get statusColors => extension<StatusColors>()!;
}
