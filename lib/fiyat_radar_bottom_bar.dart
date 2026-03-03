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
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        // Üst köşeler oval, alt kısımda iOS barı için padding
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
            // SOL BÖLÜM (Yazılar uzasa da kendi içinde kalır)
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildNavItem(0, Icons.home_rounded, "Ana Sayfa"),
                  _buildNavItem(1, Icons.explore_rounded, "Keşfet"),
                ],
              ),
            ),
            
            // ORTA BUTON ALANI (Beton gibi sabit alan)
            SizedBox(
              width: 70, 
              child: Center(
                child: _buildSquircleFab(),
              ),
            ),

            // SAĞ BÖLÜM (Yazılar uzasa da kendi içinde kalır)
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

  // Ortadaki Dönük Elmas Buton
  Widget _buildSquircleFab() {
    return Transform.translate(
      offset: const Offset(0, -12), // Butonu yukarı fırlatıyoruz
      child: Transform.rotate(
        angle: math.pi / 4, // 45 derece döndür (Elmas şekli)
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
              borderRadius: BorderRadius.circular(20), 
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6B4226).withOpacity(0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Transform.rotate(
              angle: -math.pi / 4, // İkon X olmasın diye geri çeviriyoruz
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
            ),
          ),
        ),
      ),
    );
  }

  // Genişleyen Animasyonlu Sekmeler
  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isActive = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
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
            AnimatedSize(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              child: SizedBox(
                width: isActive ? null : 0, 
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
