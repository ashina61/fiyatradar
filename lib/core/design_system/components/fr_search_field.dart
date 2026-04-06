import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radius.dart';

class FRSearchField extends StatelessWidget {
  const FRSearchField({super.key, this.controller, this.hintText = 'Ara', this.onChanged});

  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search),
        fillColor: FRDsColors.frSurface,
        filled: true,
        border: OutlineInputBorder(borderRadius: FRDsRadius.pill, borderSide: BorderSide.none),
      ),
    );
  }
}
