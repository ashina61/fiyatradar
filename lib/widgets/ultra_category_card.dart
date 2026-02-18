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
    'temizlik': 'assets/icons/categories/temizlik.png',
    'kisisel_bakim': 'assets/icons/categories/kisisel_bakim.png',
    'kitap': 'assets/icons/categories/kitap.png',
    'spor': 'assets/icons/categories/spor.png',
    'gida': 'assets/icons/categories/gida.png',
    'elektronik': 'assets/icons/categories/elektronik.png',
    'bebek': 'assets/icons/categories/bebek.png',
    'evcil_hayvan': 'assets/icons/categories/evcil_hayvan.png',
    'ev_yasam': 'assets/icons/categories/ev_yasam.png',
    'icecek': 'assets/icons/categories/icecek.png',
    'atistirmalik': 'assets/icons/categories/atistirmalik.png',
  };

  static String normalize(String value) {
    const trToAscii = {
      'ı': 'i',
      'ş': 's',
      'ğ': 'g',
      'ü': 'u',
      'ö': 'o',
      'ç': 'c',
    };

    var normalized = value.toLowerCase().trim();
    trToAscii.forEach((key, replacement) {
      normalized = normalized.replaceAll(key, replacement);
    });
    normalized = normalized.replaceAll(RegExp(r'\s+'), '_');
    normalized = normalized.replaceAll('&', '');
    normalized = normalized.replaceAll(RegExp(r'[^a-z0-9_]'), '');
    normalized = normalized.replaceAll(RegExp(r'_+'), '_');

    return normalized;
  }

  @override
  State<UltraCategoryCard> createState() => _UltraCategoryCardState();
}

class _UltraCategoryCardState extends State<UltraCategoryCard> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final normalizedCategory = UltraCategoryCard.normalize(widget.categoryName);
    final iconPath = UltraCategoryCard.categoryIcons[normalizedCategory];
    debugPrint(
      'UltraCategoryCard category="${widget.categoryName}" normalized="$normalizedCategory" icon="$iconPath"',
    );
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
                if (iconPath != null) ...[
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: Image.asset(
                      iconPath,
                      width: 28,
                      height: 28,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
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
