import 'package:flutter/material.dart';

class UltraCategoryCard extends StatefulWidget {
  const UltraCategoryCard({
    super.key,
    required this.categoryName,
    required this.isSelected,
    required this.onTap,
  });

  final String categoryName;
  final bool isSelected;
  final VoidCallback onTap;

  static const Map<String, String> categoryIcons = {
    'Temizlik': 'assets/categories/temizlik.png',
    'Kişisel Bakım': 'assets/categories/kisisel_bakim.png',
    'Kitap': 'assets/categories/kitap.png',
    'Spor': 'assets/categories/spor.png',
    'Gıda': 'assets/categories/gida.png',
    'Elektronik': 'assets/categories/elektronik.png',
    'Bebek': 'assets/categories/bebek.png',
    'Evcil Hayvan': 'assets/categories/evcil_hayvan.png',
    'Moda': 'assets/categories/moda.png',
    'Ev & Yaşam': 'assets/categories/ev_yasam.png',
    'Oyuncak': 'assets/categories/oyuncak.png',
    'Diğer': 'assets/categories/diger.png',
  };

  static final Map<String, AssetImage> _assetCache = {
    for (final entry in categoryIcons.entries) entry.key: AssetImage(entry.value),
  };

  @override
  State<UltraCategoryCard> createState() => _UltraCategoryCardState();
}

class _UltraCategoryCardState extends State<UltraCategoryCard> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final hasIcon = UltraCategoryCard.categoryIcons.containsKey(widget.categoryName);
    final showGlow = widget.isSelected || _hovered;
    final scale = widget.isSelected
        ? 0.96
        : (_pressed
            ? 0.97
            : 1.0);

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
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          scale: scale,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            width: 110,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF5EFE7),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: widget.isSelected
                    ? const Color(0xFFC8A97E)
                    : const Color(0xFFC8A97E).withOpacity(_hovered ? 0.32 : 0.16),
                width: widget.isSelected ? 1.4 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
                if (showGlow)
                  BoxShadow(
                    color: const Color(0xFFC8A97E).withOpacity(widget.isSelected ? 0.28 : 0.18),
                    blurRadius: widget.isSelected ? 20 : 14,
                    spreadRadius: widget.isSelected ? 0.8 : 0.25,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: hasIcon
                      ? Image(
                          image: UltraCategoryCard._assetCache[widget.categoryName]!,
                          width: 28,
                          height: 28,
                          fit: BoxFit.contain,
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.categoryName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF5B4636),
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
