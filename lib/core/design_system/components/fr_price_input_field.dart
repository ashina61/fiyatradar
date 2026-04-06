import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/colors.dart';
import '../tokens/radius.dart';
import '../tokens/typography.dart';

class FRPriceInputField extends StatelessWidget {
  const FRPriceInputField({
    super.key,
    this.controller,
    this.onChanged,
    this.currency = '₺',
    this.hintText = '0,00',
    this.inputFormatters = const [],
  });

  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String currency;
  final String hintText;
  final List<TextInputFormatter> inputFormatters;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: inputFormatters,
      style: FRDsTypography.displayLarge,
      decoration: InputDecoration(
        prefixText: '$currency ',
        hintText: hintText,
        filled: true,
        fillColor: FRDsColors.frSurface,
        border: const OutlineInputBorder(
          borderRadius: FRDsRadius.lg,
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
