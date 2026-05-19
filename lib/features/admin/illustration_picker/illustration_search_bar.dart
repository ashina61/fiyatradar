import 'package:flutter/material.dart';

import '../../../ui/tokens.dart';

class IllustrationSearchBar extends StatelessWidget {
  const IllustrationSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hintText = 'Etiket veya ürün ara (kola, süt, bisküvi…)',
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: frSurface(radius: FRRad.l),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: FR.ink3, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              cursorColor: FR.gold,
              style: frText(13.5, FontWeight.w700),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                hintText: hintText,
                hintStyle: frText(12.5, FontWeight.w600, color: FR.ink3),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            InkWell(
              onTap: () {
                controller.clear();
                onChanged('');
              },
              borderRadius: FRRad.all(999),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.close_rounded, color: FR.ink3, size: 16),
              ),
            ),
        ],
      ),
    );
  }
}
