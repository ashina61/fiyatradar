import 'package:flutter/material.dart';

import '../utils/theme.dart';

class CategoryCard extends StatefulWidget {
  const CategoryCard({
    super.key,
    required this.title,
    required this.iconAssetPath,
    required this.isSelected,
    required this.onTap,
    required this.accentColor,
    this.bgTint,
  });

  final String title;
  final String iconAssetPath;
  final bool isSelected;
  final VoidCallback onTap;
  final Color accentColor;
  final Color? bgTint;

  @override
  State<CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.isSelected
        ? widget.accentColor.withOpacity(0.95)
        : widget.accentColor.withOpacity(_isHovered ? 0.42 : 0.18);

    final scale = _isPressed
        ? 0.98
        : _isHovered
            ? 1.02
            : 1.0;

    final backgroundColor = const Color(0xFFF3EDE3);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) {
        setState(() {
          _isHovered = false;
          _isPressed = false;
        });
      },
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        scale: scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width: 100,
          height: 92,
          decoration: BoxDecoration(
            color: widget.bgTint == null
                ? backgroundColor
                : Color.alphaBlend(widget.bgTint!, backgroundColor),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: borderColor,
              width: widget.isSelected ? 1.8 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: _isHovered ? 16 : 12,
                offset: const Offset(0, 6),
              ),
              if (widget.isSelected)
                BoxShadow(
                  color: widget.accentColor.withOpacity(0.24),
                  blurRadius: 18,
                  spreadRadius: 0.8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(24),
              splashColor: widget.accentColor.withOpacity(0.08),
              highlightColor: widget.accentColor.withOpacity(0.05),
              onHighlightChanged: (pressed) {
                if (_isPressed != pressed) {
                  setState(() => _isPressed = pressed);
                }
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Center(
                        child: Image.asset(
                          widget.iconAssetPath,
                          width: 48,
                          height: 48,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.category_outlined,
                            color: AppColors.secondaryDark,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
