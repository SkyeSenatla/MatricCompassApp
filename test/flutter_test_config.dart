import 'dart:async';

import 'package:alchemist/alchemist.dart';

/// Week 12 Day 1: flutter test runs this before every test file under
/// test/, so every golden test shares one config.
///
/// Two kinds of golden:
/// - CI goldens (goldens/ci/): text drawn as blocks, so the same pixels on
///   Windows, macOS and Linux. These are the ones CI compares.
/// - Platform goldens (goldens/windows/): real text, for people to look
///   at. Fonts render differently on each operating system, so they are
///   made and compared on the class's Windows laptops only; CI (Linux) and
///   a Mac skip them.
Future<void> testExecutable(FutureOr<void> Function() testMain) =>
    AlchemistConfig.runWithConfig(
      // Not const: HostPlatform can't sit in a constant set.
      config: AlchemistConfig(
        platformGoldensConfig: PlatformGoldensConfig(
          platforms: {HostPlatform.windows},
        ),
      ),
      run: () async {
        await testMain();
      },
    );
