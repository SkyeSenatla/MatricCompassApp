import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Week 10 Day 4: two items from the reviewer's send-back list, checked by
/// CI instead of by a reviewer's memory. Plain file reads, no widgets.
void main() {
  List<File> dartFiles(String dir) =>
      Directory(dir)
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) => !f.path.endsWith('.g.dart'))
          .where((f) => !f.path.endsWith('.freezed.dart'))
          .toList();

  String name(File f) => f.path.replaceAll(r'\', '/');

  test('no colour is typed into a feature: the theme decides colours', () {
    final offenders = [
      for (final file in dartFiles('lib/features'))
        if (file.readAsStringSync().contains('Color(0x')) name(file),
    ];

    expect(offenders, isEmpty, reason: 'Use a theme role or a status token');
  });

  test('no screen imports a data/ file: screens see providers only', () {
    // Each exception is written down with its reason and its end date.
    const allowed = {
      // The fake sign-in lists the fake personas until Week 11 Day 2.
      'lib/features/auth/presentation/sign_in_screen.dart',
    };
    final screens = dartFiles('lib/features').where(
      (f) =>
          name(f).contains('/presentation/') &&
          (name(f).endsWith('_screen.dart') ||
              name(f).endsWith('_page.dart') ||
              name(f).endsWith('_pane.dart')),
    );
    final offenders = [
      for (final file in screens)
        if (file.readAsStringSync().contains('/data/') &&
            !allowed.contains(name(file)))
          name(file),
    ];

    expect(screens, isNotEmpty);
    expect(offenders, isEmpty, reason: 'Watch a provider instead');
  });
}
