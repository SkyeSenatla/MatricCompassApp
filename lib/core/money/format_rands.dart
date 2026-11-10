import 'package:intl/intl.dart';
import 'package:matric_compass/core/money/cents.dart';

// Week 10 Day 1: en_ZA groups thousands with a no-break space, so
// "R 45 000,00" never splits across two lines.
final NumberFormat _wholeRands = NumberFormat('#,##0', 'en_ZA');

const String _noBreakSpace = '\u00A0';

/// Formats [amount] the South African way: `R 45 000,00`.
///
/// Integer arithmetic only. Dividing by 100.0 would turn the amount into a
/// double, the one thing money must never be.
String formatRands(Cents amount) {
  final absolute = amount.value.abs();
  final rands = _wholeRands.format(absolute ~/ 100);
  final cents = (absolute % 100).toString().padLeft(2, '0');
  final sign = amount.value < 0 ? '-' : '';
  return '${sign}R$_noBreakSpace$rands,$cents';
}
