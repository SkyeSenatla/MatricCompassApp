import 'package:flutter/widgets.dart';

/// Week 10 Day 3: Material 3's window size classes. Lay out for the window
/// the app is given, never for "a tablet": split screen, rotation and
/// unfolding move the same app across these while it runs.
enum WindowSize {
  /// Under 600 dp: a phone upright. One pane, a bottom bar.
  compact,

  /// 600 to 839 dp: a tablet upright, an open foldable. A side rail.
  medium,

  /// 840 dp and wider: a tablet on its side. List and detail together.
  expanded;

  /// Where medium starts.
  static const mediumMin = 600.0;

  /// Where expanded starts.
  static const expandedMin = 840.0;

  /// The class for a window [width] wide.
  static WindowSize forWidth(double width) {
    if (width >= expandedMin) return expanded;
    if (width >= mediumMin) return medium;
    return compact;
  }

  /// The class of the app's window, from MediaQuery: use it for the big
  /// decisions (bar or rail, one pane or two). Inside a pane, measure the
  /// space you're given with LayoutBuilder instead.
  static WindowSize of(BuildContext context) =>
      forWidth(MediaQuery.sizeOf(context).width);
}
