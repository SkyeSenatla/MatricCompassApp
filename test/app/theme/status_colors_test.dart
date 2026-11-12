import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matric_compass/app/theme/app_theme.dart';
import 'package:matric_compass/app/theme/status_colors.dart';
import 'package:matric_compass/features/bursaries/domain/bursary_status.dart';

/// WCAG 2's contrast ratio between two colours, from 1:1 to 21:1.
double contrast(Color a, Color b) {
  double channel(double c) =>
      c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  double luminance(Color c) =>
      0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
  final la = luminance(a);
  final lb = luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  test('the formula gives black on white as 21:1', () {
    expect(contrast(Colors.black, Colors.white), closeTo(21, 0.01));
  });

  // The chip's words are body-sized text, so every pair needs WCAG AA's
  // 4.5:1, in light and in dark. A new status can't skip this: the loop
  // runs over every value.
  for (final (name, colors) in [
    ('light', StatusColors.light),
    ('dark', StatusColors.dark),
  ]) {
    for (final status in BursaryStatus.values) {
      test('$name: ${status.name} text is at least 4.5:1', () {
        final pair = colors.of(status);
        expect(contrast(pair.foreground, pair.background), greaterThan(4.5));
      });
    }
  }

  test('each theme carries its own status colours', () {
    expect(AppTheme.light().statusColors, StatusColors.light);
    expect(AppTheme.dark().statusColors, StatusColors.dark);
  });

  test('lerp lands on each end, so switching themes can animate', () {
    const light = StatusColors.light;
    const dark = StatusColors.dark;
    expect(light.lerp(dark, 0).approved.background, light.approved.background);
    expect(light.lerp(dark, 1).approved.background, dark.approved.background);
  });
}
