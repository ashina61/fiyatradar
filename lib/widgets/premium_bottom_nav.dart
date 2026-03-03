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
    _NavTab(
      index: 0,
      filledIcon: Icons.home_rounded,
      outlinedIcon: Icons.home_outlined,
      semanticLabel: 'Ana Sayfa',
    ),
    _NavTab(
      index: 1,
      filledIcon: Icons.explore,
      outlinedIcon: Icons.explore_outlined,
      semanticLabel: 'Keşfet',
    ),
    _NavTab(
      index: 3,
      filledIcon: Icons.shopping_bag,
      outlinedIcon: Icons.shopping_bag_outlined,
      semanticLabel: 'Sepet',
    ),
    _NavTab(
      index: 4,
      filledIcon: Icons.person,
      outlinedIcon: Icons.person_outline,
      semanticLabel: 'Profil',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return SizedBox(
      height: 128 + bottomInset,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            left: 16,
            right: 16,
            bottom: 24 + bottomInset,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  height: 82,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: Colors.white.withOpacity(0.8)),
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
          ),
          Positioned(
            bottom: 24 + bottomInset + 50,
            child: _HeroFloatingButton(onTap: onCenterTap),
          ),
        ],
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
    final textStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: const Color(0xFF6B4226),
          letterSpacing: 0.1,
        );

    return InkWell(
      borderRadius: BorderRadius.circular(100),
      onTap: onTap,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: selected ? 18 : 12,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFFAF6F0) : Colors.transparent,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedPadding(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.only(bottom: selected ? 3 : 0),
                child: Icon(
                  selected ? tab.filledIcon : tab.outlinedIcon,
                  size: 26,
                  color: selected ? const Color(0xFF6B4226) : const Color(0xFFA38671),
                  semanticLabel: tab.semanticLabel,
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                alignment: Alignment.centerLeft,
                child: selected
                    ? Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Text(tab.semanticLabel, style: textStyle, overflow: TextOverflow.fade, softWrap: false),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroFloatingButton extends StatelessWidget {
  const _HeroFloatingButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        width: 64,
        height: 64,
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
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF8C5938), Color(0xFF4A2E1B)],
            ),
          ),
          child: const Icon(
            Icons.add_rounded,
            color: Colors.white,
            size: 30,
            semanticLabel: 'Fiyat Ekle',
          ),
        ),
      ),
    );
  }
}

class _NavTab {
  const _NavTab({
    required this.index,
    required this.filledIcon,
    required this.outlinedIcon,
    required this.semanticLabel,
  });

  final int index;
  final IconData filledIcon;
  final IconData outlinedIcon;
  final String semanticLabel;
}
