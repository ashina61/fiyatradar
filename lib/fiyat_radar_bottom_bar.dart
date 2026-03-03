import 'dart:math' as math;
import 'package:flutter/material.dart';

class FiyatRadarBottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final VoidCallback onFabTap;

  const FiyatRadarBottomBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.onFabTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Videodaki o tatlı zıplayarak kayma efekti
    const springCurve = Cubic(0.34, 1.56, 0.64, 1.0);

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        // Alt boşluk iOS ev çizgisi için
        padding: const EdgeInsets.only(top: 12, left: 12, right: 12, bottom: 24),
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
        // İŞTE SİHİR BURADA: Duvarları yıktık.
        // Hepsi tek bir Row içinde, biri genişlerse diğerlerini yumuşakça iter.
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildNavItem(0, Icons.home_rounded, "Ana Sayfa", springCurve),
            _buildNavItem(1, Icons.explore_rounded, "Keşfet", springCurve),
            
            // ORTA BUTON (Artık çivili değil, akışa dahil)
            Transform.translate(
              offset: const Offset(0, -12), // Yukarı doğru taşma efekti
              child: Transform.rotate(
                angle: math.pi / 4, // 45 derece dönük elmas
                child: GestureDetector(
                  onTap: onFabTap,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8C5938), Color(0xFF4A2E1B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6B4226).withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Transform.rotate(
                      angle: -math.pi / 4, // İçindeki artı (+) işareti dik dursun diye
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
                    ),
                  ),
                ),
              ),
            ),

            _buildNavItem(2, Icons.shopping_bag_rounded, "Sepet", springCurve),
            _buildNavItem(3, Icons.person_rounded, "Profil", springCurve),
          ],
        ),
      ),
    );
  }

  // Genişleyen Animasyonlu Sekme
  Widget _buildNavItem(int index, IconData icon, String label, Curve curve) {
    bool isActive = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: curve, // Kayma yaylanarak gerçekleşecek
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 16.0 : 10.0,
          vertical: 12.0,
        ),
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
            AnimatedSize(
              duration: const Duration(milliseconds: 400),
              curve: curve,
              child: Container(
                width: isActive ? null : 0,
                padding: EdgeInsets.only(left: isActive ? 6.0 : 0.0),
                child: Text(
                  isActive ? label : "",
                  style: const TextStyle(
                    color: Color(0xFF6B4226),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    fontFamily: 'Outfit',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
