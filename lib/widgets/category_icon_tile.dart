import 'package:flutter/material.dart';

class CategoryIcon extends StatelessWidget {
  const CategoryIcon({
    super.key,
    required this.assetPath,
    required this.isActive,
    this.scaleImage = true,
  });

  final String? assetPath;
  final bool isActive;
  final bool scaleImage;

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (assetPath == null) {
      child = const Icon(
        Icons.category_outlined,
        size: 24,
        color: Color(0xFF8D6E4A),
      );
    } else {
      final image = Image.asset(
        assetPath!,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      );

      child = scaleImage ? Transform.scale(scale: 1.35, child: image) : image;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFF4EEE6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isActive ? const Color(0xFFB88A4A) : const Color(0xFFE6D9C8),
          width: isActive ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isActive ? 0.09 : 0.06),
            blurRadius: isActive ? 12 : 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Center(child: child),
      ),
    );
  }
}
