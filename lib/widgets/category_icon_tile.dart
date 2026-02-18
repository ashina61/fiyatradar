import 'package:flutter/material.dart';

class CategoryIconTile extends StatelessWidget {
  const CategoryIconTile({
    super.key,
    required this.assetPath,
    required this.isActive,
    this.isHovered = false,
  });

  final String assetPath;
  final bool isActive;
  final bool isHovered;

  @override
  Widget build(BuildContext context) {
    final shouldEmphasize = isActive || isHovered;

    return AnimatedScale(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      scale: isActive ? 1.03 : 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFFF4EEE6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? const Color(0xFFB88A4A) : const Color(0xFFE6D9C8),
            width: isActive ? 1.8 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            if (shouldEmphasize)
              BoxShadow(
                color: const Color(0xFFB88A4A).withOpacity(isActive ? 0.12 : 0.07),
                blurRadius: isActive ? 10 : 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              assetPath,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      ),
    );
  }
}
