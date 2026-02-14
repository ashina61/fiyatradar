import 'package:intl/intl.dart';

final NumberFormat _trCurrencyFormatter = NumberFormat('#,##0.00', 'tr_TR');
final NumberFormat _trIntegerFormatter = NumberFormat('#,##0', 'tr_TR');

String formatTRY(
  num value, {
  bool withDecimals = true,
  bool trailingSymbol = false,
  bool keepTrailingZeros = false,
}) {
  if (!withDecimals) {
    final formatted = _trIntegerFormatter.format(value);
    return trailingSymbol ? '$formatted ₺' : '$formatted₺';
  }

  var formatted = _trCurrencyFormatter.format(value);
  if (!keepTrailingZeros && formatted.endsWith(',00')) {
    formatted = formatted.substring(0, formatted.length - 3);
  }
  return trailingSymbol ? '$formatted ₺' : '$formatted₺';
}
