import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DynamicBottomDock extends StatefulWidget {
  final ValueChanged<int>? onTabChanged;
  final int initialIndex;

  const DynamicBottomDock({
    super.key,
    this.onTabChanged,
    this.initialIndex = 0,
  });

  @override
  State<DynamicBottomDock> createState() => _DynamicBottomDockState();
}

class _DynamicBottomDockState extends State<DynamicBottomDock>
    with TickerProviderStateMixin {
  late int _currentIndex;
  late AnimationController _animationController;

  // Menü öğeleri: icon ve label
  final List<Map<String, dynamic>> _navItems = [
    {'icon': Icons.home_rounded, 'label': 'Ana Sayfa'},
    {'icon': Icons.explore_rounded, 'label': 'Keşfet'},
    {'icon': Icons.shopping_bag_rounded, 'label': 'Sepet'},
    {'icon': Icons.person_rounded, 'label': 'Profil'},
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Tıklama olayı
  void _onItemTapped(int index) {
    if (_currentIndex != index) {
      setState(() => _currentIndex = index);      _animationController.forward(from: 0);
      widget.onTabChanged?.call(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // Beyaz zemin + üst köşeler yuvarlak
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(32),
        ),
        // Hafif gölge
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B4226).withOpacity(0.05),
            blurRadius: 25,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNavItem(0), // Ana Sayfa
          _buildNavItem(1), // Keşfet
          _buildCenterButton(), // Ortadaki + butonu
          _buildNavItem(2), // Sepet
          _buildNavItem(3), // Profil
        ],
      ),
    );
  }

  // Tek bir menü öğesi (ikon + yazı)
  Widget _buildNavItem(int index) {
    final isActive = _currentIndex == index;
    final item = _navItems[index];

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        // Aktifse geniş padding, değilse normal
        padding: isActive
            ? const EdgeInsets.symmetric(horizontal: 20, vertical: 12)            : const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF6B4226).withOpacity(0.1) // Açık kahve
              : Colors.transparent,
          borderRadius: BorderRadius.circular(100), // Hap şeklinde
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // İkon
            Icon(
              item['icon'] as IconData,
              color: isActive
                  ? const Color(0xFF6B4226)
                  : const Color(0xFFA38671),
              size: 26,
            ),
            // Yazı (sadece aktifse görünür)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: isActive
                  ? Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        item['label'] as String,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6B4226),
                        ),
                      ),
                    )
