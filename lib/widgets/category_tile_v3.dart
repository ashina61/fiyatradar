import 'package:flutter/material.dart';

import '../models/category_model.dart';
import '../utils/material_icon_resolver.dart';

class CategoryTileV3 extends StatefulWidget {
  const CategoryTileV3({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  final CategoryModel category;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<CategoryTileV3> createState() => _CategoryTileV3State();
}

class _CategoryTileV3State extends State<CategoryTileV3> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed == value) return;
    setState(() => _isPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;
    final scale = _isPressed ? 0.98 : (isSelected ? 1.05 : 1.0);

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: Transform.rotate(
          angle: isSelected ? -0.012 : 0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            width: 110,
            height: 130,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                colors: isSelected
                    ? const [Color(0xFFF8EFE2), Color(0xFFEEDCC7)]
                    : const [Color(0xFFF7F1EA), Color(0xFFF0E6DA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFD8B98F)
                    : const Color(0xFFE5D6C6).withOpacity(0.7),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
                if (isSelected)
                  BoxShadow(
                    color: const Color(0xFFB97A3A).withOpacity(0.18),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
              ],
            ),
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2, bottom: 8),
                    child: Center(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDFBF9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          materialIconFromName(widget.category.iconName),
                          color: const Color(0xFF8B4D22),
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ),
                Text(
                  widget.category.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B4E2E),
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
