import 'package:flutter/material.dart';

import '../theme/fr_foundation.dart';

class FRSearchField extends StatelessWidget {
  const FRSearchField({
    super.key,
    this.controller,
    this.hintText = 'Ürün, marka veya kategori ara...',
    this.onChanged,
    this.onClear,
  });

  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: FRSpaceInsets.fromLTRB(FRSpacing.mdPlus, FRSpacing.md, FRSpacing.smPlus, FRSpacing.md),
      decoration: BoxDecoration(
        color: FRColors.surface,
        borderRadius: FRRadius.lgPlusRadius,
        border: Border.all(color: FRColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: FRColors.tan, size: 18),
          const SizedBox(width: FRSpacing.md),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(
                  color: FRColors.textSubtle,
                  fontSize: 15,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          GestureDetector(
            onTap: onClear,
            child: const Icon(Icons.close_rounded, color: FRColors.textSubtle, size: 18),
          ),
        ],
      ),
    );
  }
}
