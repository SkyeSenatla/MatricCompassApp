import 'package:flutter/material.dart';
import 'package:matric_compass/features/bursaries/domain/bursary_status.dart';

/// One status's colours: a background and the text on it.
@immutable
final class StatusColor {
  /// Creates a pair. Text on [background] uses [foreground].
  const new({required this.background, required this.foreground});

  /// The blend between two pairs, for an animated theme change.
  factory lerp(StatusColor a, StatusColor b, double t) => StatusColor(
    background: Color.lerp(a.background, b.background, t)!,
    foreground: Color.lerp(a.foreground, b.foreground, t)!,
  );

  /// The chip's fill.
  final Color background;

  /// The words on the chip.
  final Color foreground;
}

/// Week 10 Day 3: tokens Material doesn't have. Material 3 has no colour
/// for "Approved", so the status colours live in a theme extension: one
/// value for light and one for dark, each chosen and measured. Every pair
/// is at least 4.5:1, and status_colors_test.dart checks the sums.
///
/// Widgets ask the theme for a status's colour, never for a green.
@immutable
final class StatusColors extends ThemeExtension<StatusColors> {
  /// Creates the set.
  const new({
    required this.draft,
    required this.submitted,
    required this.underReview,
    required this.approved,
    required this.rejected,
    required this.unknown,
  });

  /// The light theme's values.
  static const light = StatusColors(
    draft: StatusColor(
      background: Color(0xFFE7E9E4),
      foreground: Color(0xFF2E322C),
    ),
    submitted: StatusColor(
      background: Color(0xFFDCE7FA),
      foreground: Color(0xFF173A73),
    ),
    underReview: StatusColor(
      background: Color(0xFFFCEBC8),
      foreground: Color(0xFF5C3B00),
    ),
    approved: StatusColor(
      background: Color(0xFFD3EFD6),
      foreground: Color(0xFF0E4E1C),
    ),
    rejected: StatusColor(
      background: Color(0xFFFADBD8),
      foreground: Color(0xFF7A1A12),
    ),
    unknown: StatusColor(
      background: Color(0xFFECE6F0),
      foreground: Color(0xFF45374F),
    ),
  );

  /// The dark theme's values: not the light ones inverted, but chosen
  /// again so they neither glare nor go muddy on a dark surface.
  static const dark = StatusColors(
    draft: StatusColor(
      background: Color(0xFF3A3E38),
      foreground: Color(0xFFE2E4DE),
    ),
    submitted: StatusColor(
      background: Color(0xFF1E3A66),
      foreground: Color(0xFFD6E3FF),
    ),
    underReview: StatusColor(
      background: Color(0xFF4D3500),
      foreground: Color(0xFFFFDEA6),
    ),
    approved: StatusColor(
      background: Color(0xFF1B4D26),
      foreground: Color(0xFFBDEFC3),
    ),
    rejected: StatusColor(
      background: Color(0xFF6B1F18),
      foreground: Color(0xFFFFDAD5),
    ),
    unknown: StatusColor(
      background: Color(0xFF463B4D),
      foreground: Color(0xFFEDDCF5),
    ),
  );

  /// A draft.
  final StatusColor draft;

  /// Submitted.
  final StatusColor submitted;

  /// Under review.
  final StatusColor underReview;

  /// Approved.
  final StatusColor approved;

  /// Rejected.
  final StatusColor rejected;

  /// A status this app doesn't know.
  final StatusColor unknown;

  /// The colours for [status]. Exhaustive, like the label: a new status is
  /// a compile error here until it has a colour too.
  StatusColor of(BursaryStatus status) => switch (status) {
    BursaryStatus.draft => draft,
    BursaryStatus.submitted => submitted,
    BursaryStatus.underReview => underReview,
    BursaryStatus.approved => approved,
    BursaryStatus.rejected => rejected,
    BursaryStatus.unknown => unknown,
  };

  @override
  StatusColors copyWith({
    StatusColor? draft,
    StatusColor? submitted,
    StatusColor? underReview,
    StatusColor? approved,
    StatusColor? rejected,
    StatusColor? unknown,
  }) => StatusColors(
    draft: draft ?? this.draft,
    submitted: submitted ?? this.submitted,
    underReview: underReview ?? this.underReview,
    approved: approved ?? this.approved,
    rejected: rejected ?? this.rejected,
    unknown: unknown ?? this.unknown,
  );

  @override
  StatusColors lerp(StatusColors? other, double t) {
    if (other == null) return this;
    return StatusColors(
      draft: StatusColor.lerp(draft, other.draft, t),
      submitted: StatusColor.lerp(submitted, other.submitted, t),
      underReview: StatusColor.lerp(underReview, other.underReview, t),
      approved: StatusColor.lerp(approved, other.approved, t),
      rejected: StatusColor.lerp(rejected, other.rejected, t),
      unknown: StatusColor.lerp(unknown, other.unknown, t),
    );
  }
}
