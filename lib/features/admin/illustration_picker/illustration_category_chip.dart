import 'package:flutter/material.dart';

import '../../../ui/tokens.dart';

/// Horizontal-scroll category filter chip used by the illustration picker.
/// Active chip uses espresso ink + cream foreground per spec.
class IllustrationCategoryChip extends StatelessWidget {
  const IllustrationCategoryChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? FR.ink : FR.surfaceHi;
    final fg = selected ? FR.bg : FR.ink;
    final border = selected ? FR.ink : FR.hairline;
    return InkWell(
      onTap: onTap,
      borderRadius: FRRad.all(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: FRRad.all(999),
          border: Border.all(color: border),
        ),
        child: Text(
          label,
          style: frText(12.5, FontWeight.w800, color: fg, letter: .2),
        ),
      ),
    );
  }
}
