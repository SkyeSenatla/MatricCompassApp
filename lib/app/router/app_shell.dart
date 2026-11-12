import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:matric_compass/app/layout/window_size.dart';

/// One tab: its label, and its icons when not selected and selected.
final class ShellDestination {
  /// Creates a tab.
  const new({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  /// Every tab keeps its label, in a bar and in a rail.
  final String label;

  /// The icon when another tab is open.
  final IconData icon;

  /// The icon when this tab is open.
  final IconData selectedIcon;
}

/// Week 10 Day 3: the tabs change shape, not meaning. A bottom bar on a
/// compact window; a side rail from 600 dp. Same branches, same addresses,
/// same state in each tab: only the chrome is chosen from the window.
class AppShell extends StatelessWidget {
  /// Creates the shell around [navigationShell].
  const new({
    required this.navigationShell,
    required this.destinations,
    super.key,
  });

  /// go_router's shell: one navigator per branch.
  final StatefulNavigationShell navigationShell;

  /// The tabs, in branch order.
  final List<ShellDestination> destinations;

  // Tapping the open tab again goes back to that tab's first screen, as
  // most apps do. A choice, not a default.
  void _select(int index) => navigationShell.goBranch(
    index,
    initialLocation: index == navigationShell.currentIndex,
  );

  @override
  Widget build(BuildContext context) {
    return switch (WindowSize.of(context)) {
      WindowSize.compact => Scaffold(
        body: navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _select,
          destinations: [
            for (final d in destinations)
              NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
                label: d.label,
              ),
          ],
        ),
      ),
      WindowSize.medium || WindowSize.expanded => Scaffold(
        body: Row(
          children: [
            SafeArea(
              child: NavigationRail(
                selectedIndex: navigationShell.currentIndex,
                onDestinationSelected: _select,
                labelType: NavigationRailLabelType.all,
                destinations: [
                  for (final d in destinations)
                    NavigationRailDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.selectedIcon),
                      label: Text(d.label),
                    ),
                ],
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: navigationShell),
          ],
        ),
      ),
    };
  }
}
