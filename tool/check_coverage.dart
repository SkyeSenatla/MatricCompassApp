// Week 12 Day 1: fails the build when test coverage drops below a floor.
//
//   flutter test --coverage
//   dart run tool/check_coverage.dart 80
//
// It reads coverage/lcov.info, leaves out code nobody writes by hand, and
// prints the line coverage of the rest. Below the floor: exit code 1, so
// CI goes red. The same script on every laptop and in CI, with no
// third-party action to trust or keep up to date.

import 'dart:io';

/// Generated or copied code: covering it proves nothing about our tests.
const _excluded = [
  '.g.dart',
  '.freezed.dart',
  'lib/core/api/generated/',
  'lib/l10n/',
];

void main(List<String> args) {
  final floor = args.isEmpty ? null : double.tryParse(args.first);
  if (floor == null || floor < 0 || floor > 100) {
    stderr.writeln('Usage: dart run tool/check_coverage.dart <floor 0-100>');
    exit(64);
  }
  final file = File('coverage/lcov.info');
  if (!file.existsSync()) {
    stderr.writeln('No coverage/lcov.info: run flutter test --coverage first.');
    exit(66);
  }

  var found = 0;
  var hit = 0;
  var counting = false;
  for (final line in file.readAsLinesSync()) {
    if (line.startsWith('SF:')) {
      final path = line.substring(3).replaceAll(r'\', '/');
      counting = !_excluded.any(path.contains);
    } else if (counting && line.startsWith('LF:')) {
      found += int.parse(line.substring(3));
    } else if (counting && line.startsWith('LH:')) {
      hit += int.parse(line.substring(3));
    }
  }

  final percent = found == 0 ? 0.0 : hit * 100 / found;
  stdout.writeln(
    'Line coverage: ${percent.toStringAsFixed(1)}% '
    '($hit of $found lines), floor $floor%.',
  );
  if (percent < floor) {
    stderr.writeln('Below the floor: add tests, or explain the drop.');
    exit(1);
  }
}
