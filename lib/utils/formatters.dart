import 'package:intl/intl.dart';

final NumberFormat _trCurrencyFormatter = NumberFormat('#,##0.00', 'tr_TR');
final NumberFormat _trIntegerFormatter = NumberFormat('#,##0', 'tr_TR');

String formatTRY(num value, {bool withDecimals = true}) {
  if (!withDecimals) {
    return '${_trIntegerFormatter.format(value)}₺';
  }

  var formatted = _trCurrencyFormatter.format(value);
  if (formatted.endsWith(',00')) {
    formatted = formatted.substring(0, formatted.length - 3);
  }
  return '$formatted₺';
}
