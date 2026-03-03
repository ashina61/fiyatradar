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
      bottom: 24, // Ekranın altından ne kadar yukarıda duracağı
      left: 16,
      right: 16,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // 1. Ana Kapsül (Arka plan)
          Container(
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white, 
              borderRadius: BorderRadius.circular(36),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6B4226).withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                // Sol Taraf (Ana Sayfa ve Keşfet)
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, "Ana Sayfa"),
                      _buildNavItem(1, Icons.explore_rounded, Icons.explore_outlined, "Keşfet"),
                    ],
                  ),
                ),
                // Orta Butonun Yeri (Burası asla daralmaz, diğerlerini itmez)
                const SizedBox(width: 70),
                // Sağ Taraf (Sepet ve Profil)
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(2, Icons.shopping_bag_rounded, Icons.shopping_bag_outlined, "Sepet"),
                      _buildNavItem(3, Icons.person_rounded, Icons.person_outlined, "Profil"),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Hero FAB (Ortadaki Elmas/Squircle Buton)
          Positioned(
            top: -16, // Kapsülden yukarı taşır
            child: GestureDetector(
              onTap: onFabTap,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF6F0), // Ana uygulamanın arka plan rengi
                  borderRadius: BorderRadius.circular(22),
                ),
                padding: const EdgeInsets.all(4), // Kesik kalınlığı
                child: Container(
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
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Animasyonlu Sekme Öğesi
  Widget _buildNavItem(int index, IconData filledIcon, IconData outlinedIcon, String label) {
    bool isActive = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(horizontal: isActive ? 16 : 12, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF6B4226).withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? filledIcon : outlinedIcon,
              color: isActive ? const Color(0xFF6B4226) : const Color(0xFFA38671),
              size: 26,
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
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
                    overflow: Clip.none,
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
