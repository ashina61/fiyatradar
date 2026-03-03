import 'dart:math' as math;
import 'package:flutter/material.dart';

class FiyatRadarV3Bar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final VoidCallback onFabTap;

  const FiyatRadarV3Bar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.onFabTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        // V3 CSS: Alt boşluk iOS çizgisi için, üst köşeler oval
        padding: const EdgeInsets.only(top: 12, left: 16, right: 16, bottom: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6B4226).withOpacity(0.05),
              blurRadius: 25,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // SOL TARAF (Sekme 1 ve 2)
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildNavItem(0, Icons.home_rounded, "Ana Sayfa"),
                  _buildNavItem(1, Icons.explore_rounded, "Keşfet"),
                ],
              ),
            ),
            
            // ORTA BUTON (Squircle - Asla yeri değişmez)
            SizedBox(
              width: 70, // Merkezin alanını sabitliyoruz ki kayma olmasın
              child: Center(
                child: _buildSquircleFab(),
              ),
            ),

            // SAĞ TARAF (Sekme 3 ve 4)
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildNavItem(2, Icons.shopping_bag_rounded, "Sepet"),
                  _buildNavItem(3, Icons.person_rounded, "Profil"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // V3 Merkez Butonu (45 derece dönük elmas şekli)
  Widget _buildSquircleFab() {
    return Transform.translate(
      offset: const Offset(0, -12), // CSS'teki top: -12px ayarı
      child: Transform.rotate(
        angle: math.pi / 4, // 45 derece döndür (Elmas şeklini alır)
        child: GestureDetector(
          onTap: onFabTap,
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8C5938), Color(0xFF4A2E1B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20), // Yumuşatılmış köşe
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6B4226).withOpacity(0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Transform.rotate(
              angle: -math.pi / 4, // İkonun yamuk durmaması için geri döndürüyoruz (+ şekli X olmasın diye)
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
            ),
          ),
        ),
      ),
    );
  }

  // V3 Genişleyen Sekme
  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isActive = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        // Aktifken hap şeklinde uzar
        padding: EdgeInsets.symmetric(horizontal: isActive ? 18 : 12, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF6B4226).withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? const Color(0xFF6B4226) : const Color(0xFFA38671),
              size: 26,
            ),
            // Metin Genişleme Sihri
            AnimatedSize(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              child: SizedBox(
                width: isActive ? null : 0, // İnaktifken sıfır genişlik
                child: Padding(
                  padding: EdgeInsets.only(left: isActive ? 8.0 : 0),
                  child: Text(
                    isActive ? label : "",
                    style: const TextStyle(
                      color: Color(0xFF6B4226),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
