import 'package:flutter/material.dart';

import 'category_theme.dart';

class PremiumCategoryChip extends StatefulWidget {
  final CategoryMeta meta;
  final bool selected;
  final VoidCallback onTap;

  const PremiumCategoryChip({
    super.key,
    required this.meta,
    required this.selected,
    required this.onTap,
  });

  @override
  State<PremiumCategoryChip> createState() => _PremiumCategoryChipState();
}

class _PremiumCategoryChipState extends State<PremiumCategoryChip> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) {
        setState(() {
          _hovered = false;
          _pressed = false;
        });
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 100),
          scale: _pressed ? 0.98 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 98,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? CategoryTokens.chipBgActive : CategoryTokens.chipBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? CategoryTokens.chipBorderActive : CategoryTokens.chipBorder,
                width: selected ? 1.2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: CategoryTokens.shadowSoft,
                  blurRadius: selected ? 18 : (_hovered ? 14 : 10),
                  spreadRadius: selected ? 0.3 : 0,
                  offset: Offset(0, _hovered ? 5 : 3),
                ),
              ],
            ),
            child: Stack(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withOpacity(0.22),
                            Colors.white.withOpacity(0.02),
                          ],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: Image.asset(
                          widget.meta.iconAsset,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) {
                            return Image.asset(
                              'assets/icons/categories/temizlik.png',
                              fit: BoxFit.contain,
                            );
                          },
                          color: selected ? CategoryTokens.iconTintActive : CategoryTokens.iconTint,
                          colorBlendMode: BlendMode.srcIn,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.meta.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.2,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                        color: selected ? CategoryTokens.textPrimary : CategoryTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 100),
                      opacity: _pressed ? 1 : 0,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: CategoryTokens.pressedOverlay.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
