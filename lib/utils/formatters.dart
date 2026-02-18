import 'package:intl/intl.dart';

final NumberFormat _trCurrencyFormatter = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);
final NumberFormat _trIntegerFormatter = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);

String formatTRY(
  num value, {
  bool withDecimals = true,
  bool trailingSymbol = true,
  bool keepTrailingZeros = false,
}) {
  if (!withDecimals) {
    final formatted = _trIntegerFormatter.format(value);
    return trailingSymbol ? '${formatted.substring(1)}₺' : formatted;
  }

  var formatted = _trCurrencyFormatter.format(value);
  if (!keepTrailingZeros && formatted.endsWith(',00')) {
    formatted = formatted.substring(0, formatted.length - 3);
  }
  if (trailingSymbol) {
    return '${formatted.substring(1)}₺';
  }
  return formatted;
}

String formatTRYWhole(num value) => formatTRY(value, withDecimals: false);
