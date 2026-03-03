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
    // VİDEODAKİ O TATLI ZIPLAMA EFEKTİ (CSS: cubic-bezier(0.34, 1.56, 0.64, 1))
    const springCurve = Cubic(0.34, 1.56, 0.64, 1.0);

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // 1. ANA BEYAZ BAR
          Container(
            padding: const EdgeInsets.only(top: 12, left: 16, right: 16, bottom: 24), // CSS ile aynı
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
              children: [
                // SOL TARAF
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildNavItem(0, Icons.home_rounded, "Ana Sayfa", springCurve),
                      _buildNavItem(1, Icons.explore_rounded, "Keşfet", springCurve),
                    ],
                  ),
                ),
                
                // ORTASI (Elmas butonun alanı - Asla sağa sola kaymaz)
                const SizedBox(width: 70),

                // SAĞ TARAF
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildNavItem(2, Icons.shopping_bag_rounded, "Sepet", springCurve),
                      _buildNavItem(3, Icons.person_rounded, "Profil", springCurve),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. ORTA BUTON (VİDEODAKİ DÖNÜK ELMAS)
          Positioned(
            top: -12, // CSS: top: -12px
            child: Transform.rotate(
              angle: math.pi / 4, // Tam 45 derece döndürüyoruz
              child: GestureDetector(
                onTap: onFabTap,
                child: Container(
                  width: 54, // CSS: width: 54px
                  height: 54, // CSS: height: 54px
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8C5938), Color(0xFF4A2E1B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20), // Apple Squircle efekti
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6B4226).withOpacity(0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Transform.rotate(
                    angle: -math.pi / 4, // İçindeki artı (+) işareti çarpı (X) olmasın diye geri çeviriyoruz
                    child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // VİDEODAKİ GİBİ GENİŞLEYEN SEKME (Birebir CSS Ölçüleri)
  Widget _buildNavItem(int index, IconData icon, String label, Curve curve) {
    bool isActive = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400), // CSS: 0.4s
        curve: curve, // Yaylanma animasyonu
        // CSS'teki padding: 12px 20px (aktif) ve 12px (pasif) mantığı
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 20.0 : 12.0, 
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
            // YAZININ ÇIKMA ANİMASYONU
            AnimatedSize(
              duration: const Duration(milliseconds: 400),
              curve: curve,
              child: Container(
                width: isActive ? null : 0,
                // CSS: margin-left: 8px
                padding: EdgeInsets.only(left: isActive ? 8.0 : 0.0),
                child: Text(
                  isActive ? label : "",
                  style: const TextStyle(
                    color: Color(0xFF6B4226),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    fontFamily: 'Outfit', // Fontunu da bağladım
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
