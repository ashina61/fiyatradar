import 'package:intl/intl.dart';

final NumberFormat _trCurrencyFormatter = NumberFormat('#,##0.00', 'tr_TR');
final NumberFormat _trIntegerFormatter = NumberFormat('#,##0', 'tr_TR');

String formatTRY(num value, {bool withDecimals = true}) {
  final formatted = withDecimals
      ? _trCurrencyFormatter.format(value)
      : _trIntegerFormatter.format(value);
  return '$formatted₺';
}
