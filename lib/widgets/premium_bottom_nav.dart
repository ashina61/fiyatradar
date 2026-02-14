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
    _NavTab(index: 0, label: 'Ana Sayfa', icon: Icons.home_rounded),
    _NavTab(index: 1, label: 'Keşfet', icon: Icons.explore_rounded),
    _NavTab(index: 3, label: 'Sepet', icon: Icons.shopping_basket_rounded),
    _NavTab(index: 4, label: 'Profil', icon: Icons.person_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final width = MediaQuery.sizeOf(context).width * 0.92;
    final selectedSlot = _tabs.indexWhere((tab) => tab.index == currentIndex).clamp(0, _tabs.length - 1);

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 14),
      child: SizedBox(
        height: 98,
        child: Center(
          child: SizedBox(
            width: width,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      height: 74,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: scheme.surface.withOpacity(theme.brightness == Brightness.dark ? 0.78 : 0.84),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: scheme.outlineVariant.withOpacity(0.35)),
                        boxShadow: [
                          BoxShadow(
                            color: scheme.shadow.withOpacity(0.12),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final slotWidth = constraints.maxWidth / 5;
                          final bubbleLeft = selectedSlot < 2
                              ? selectedSlot * slotWidth
                              : (selectedSlot + 1) * slotWidth;

                          return Stack(
                            children: [
                              AnimatedPositioned(
                                duration: const Duration(milliseconds: 340),
                                curve: Curves.easeOutCubic,
                                left: bubbleLeft + 6,
                                top: 15,
                                child: Container(
                                  width: slotWidth - 12,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24),
                                    color: scheme.primaryContainer.withOpacity(0.68),
                                    boxShadow: [
                                      BoxShadow(
                                        color: scheme.primary.withOpacity(0.15),
                                        blurRadius: 16,
                                        spreadRadius: 1,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  for (final tab in _tabs.take(2))
                                    Expanded(
                                      child: _NavItem(
                                        icon: tab.icon,
                                        label: tab.label,
                                        selected: currentIndex == tab.index,
                                        onTap: () {
                                          HapticFeedback.selectionClick();
                                          onTap(tab.index);
                                        },
                                      ),
                                    ),
                                  SizedBox(width: slotWidth),
                                  for (final tab in _tabs.skip(2))
                                    Expanded(
                                      child: _NavItem(
                                        icon: tab.icon,
                                        label: tab.label,
                                        selected: currentIndex == tab.index,
                                        onTap: () {
                                          HapticFeedback.selectionClick();
                                          onTap(tab.index);
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: -14,
                  child: _CenterActionButton(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onCenterTap();
                    },
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

class _CenterActionButton extends StatelessWidget {
  const _CenterActionButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  scheme.primary.withOpacity(0.55),
                  scheme.tertiary.withOpacity(0.45),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withOpacity(0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.surface.withOpacity(theme.brightness == Brightness.dark ? 0.72 : 0.82),
                    border: Border.all(color: scheme.outlineVariant.withOpacity(0.45)),
                  ),
                  child: Icon(Icons.add_rounded, size: 30, color: scheme.primary),
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Fiyat Ekle',
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: SizedBox(
        height: 74,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              scale: selected ? 1.1 : 1,
              child: Icon(
                icon,
                size: 24,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedSlide(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              offset: selected ? Offset.zero : const Offset(0, 0.22),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                opacity: selected ? 1 : 0.74,
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: selected ? scheme.primary : scheme.onSurfaceVariant,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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

class _NavTab {
  const _NavTab({required this.index, required this.label, required this.icon});

  final int index;
  final String label;
  final IconData icon;
}
