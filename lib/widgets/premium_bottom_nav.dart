import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PremiumBottomNav extends StatelessWidget {
  const PremiumBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onCenterTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onCenterTap;

  static const _tabs = <_NavTab>[
    _NavTab(index: 0, icon: Icons.home_rounded, semanticLabel: 'Ana Sayfa'),
    _NavTab(index: 1, icon: Icons.explore_rounded, semanticLabel: 'Keşfet'),
    _NavTab(index: 3, icon: Icons.shopping_bag_rounded, semanticLabel: 'Sepet'),
    _NavTab(index: 4, icon: Icons.person_rounded, semanticLabel: 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: SizedBox(
          height: 102,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    height: 82,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xE6FFFFFF),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: Colors.white),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x146B4226),
                          blurRadius: 25,
                          offset: Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        for (final tab in _tabs.take(2))
                          Expanded(
                            child: _DockNavItem(
                              tab: tab,
                              selected: tab.index == currentIndex,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                onTap(tab.index);
                              },
                            ),
                          ),
                        const SizedBox(width: 74),
                        for (final tab in _tabs.skip(2))
                          Expanded(
                            child: _DockNavItem(
                              tab: tab,
                              selected: tab.index == currentIndex,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                onTap(tab.index);
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                child: _HeroSquircleButton(onTap: onCenterTap),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DockNavItem extends StatelessWidget {
  const _DockNavItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final _NavTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(100),
      onTap: onTap,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: const Cubic(0.34, 1.56, 0.64, 1),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFFAF6F0) : Colors.transparent,
            borderRadius: BorderRadius.circular(100),
          ),
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            offset: selected ? const Offset(0, -0.08) : Offset.zero,
            child: Icon(
              tab.icon,
              size: 26,
              color: selected ? const Color(0xFF6B4226) : const Color(0xFFA38671),
              semanticLabel: tab.semanticLabel,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroSquircleButton extends StatelessWidget {
  const _HeroSquircleButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: 62,
        height: 62,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF6F0),
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x406B4226),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Transform.rotate(
          angle: 0.785398,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFAF6F0), width: 3.5),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF8C5938), Color(0xFF4A2E1B)],
              ),
            ),
            child: Center(
              child: Transform.rotate(
                angle: -0.785398,
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 30,
                  semanticLabel: 'Ekle',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTab {
  const _NavTab({
    required this.index,
    required this.icon,
    required this.semanticLabel,
  });

  final int index;
  final IconData icon;
  final String semanticLabel;
}
