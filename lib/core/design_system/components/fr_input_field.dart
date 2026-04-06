import 'package:flutter/material.dart';

import '../tokens/radius.dart';

class FRInputField extends StatelessWidget {
  const FRInputField({super.key, this.controller, required this.label, this.keyboardType, this.onChanged});

  final TextEditingController? controller;
  final String label;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(borderRadius: FRDsRadius.sm)),
    );
  }
}
