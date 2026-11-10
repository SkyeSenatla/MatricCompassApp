import 'package:flutter_test/flutter_test.dart';
import 'package:matric_compass/core/money/cents.dart';
import 'package:matric_compass/core/money/format_rands.dart';

void main() {
  // Written with \u00A0 on purpose: a no-break space looks exactly like a
  // space on screen, and a test typed with a normal space fails.
  const nbsp = '\u00A0';

  group('formatRands', () {
    test('formats the NSFAS amount', () {
      expect(formatRands(const Cents(4500000)), 'R${nbsp}45${nbsp}000,00');
    });

    test('formats ten cents', () {
      expect(formatRands(const Cents(10)), 'R${nbsp}0,10');
    });

    test('formats R 1 500,00', () {
      expect(formatRands(const Cents(150000)), 'R${nbsp}1${nbsp}500,00');
    });

    test('formats zero', () {
      expect(formatRands(const Cents(0)), 'R${nbsp}0,00');
    });

    test('formats a negative amount', () {
      expect(formatRands(const Cents(-505)), '-R${nbsp}5,05');
    });

    test('formats a million rand', () {
      expect(
        formatRands(const Cents(100000000)),
        'R${nbsp}1${nbsp}000${nbsp}000,00',
      );
    });
  });

  test('Cents add up in whole cents', () {
    expect(const Cents(10) + const Cents(20), const Cents(30));
  });
}
