import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PremiumBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onCenterTap;

  const PremiumBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onCenterTap,
  });

  static const _tabIndexes = <int>[0, 1, 3, 4];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width * 0.92;
    final selectedSlot = _tabIndexes.indexOf(currentIndex).clamp(0, 3);

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        height: 94,
        child: Center(
          child: SizedBox(
            width: width,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      height: 72,
                      decoration: BoxDecoration(
                        color: scheme.surface.withOpacity(0.82),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: scheme.outlineVariant.withOpacity(0.45)),
                        boxShadow: [
                          BoxShadow(
                            color: scheme.shadow.withOpacity(0.10),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: AnimatedAlign(
                              duration: const Duration(milliseconds: 320),
                              curve: Curves.easeOutCubic,
                              alignment: Alignment(-1 + (selectedSlot * 2 / 3), 0),
                              child: FractionallySizedBox(
                                widthFactor: 0.22,
                                child: Container(
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: scheme.primaryContainer.withOpacity(0.75),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              _NavItem(
                                icon: Icons.home_rounded,
                                label: 'Ana Sayfa',
                                selected: currentIndex == 0,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  onTap(0);
                                },
                              ),
                              _NavItem(
                                icon: Icons.search_rounded,
                                label: 'Keşfet',
                                selected: currentIndex == 1,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  onTap(1);
                                },
                              ),
                              const SizedBox(width: 72),
                              _NavItem(
                                icon: Icons.shopping_basket_rounded,
                                label: 'Sepet',
                                selected: currentIndex == 3,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  onTap(3);
                                },
                              ),
                              _NavItem(
                                icon: Icons.person_rounded,
                                label: 'Profil',
                                selected: currentIndex == 4,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  onTap(4);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onCenterTap();
                    },
                    child: Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: scheme.primary.withOpacity(0.35), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: scheme.primary.withOpacity(0.25),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: ColoredBox(
                            color: scheme.primaryContainer.withOpacity(0.95),
                            child: Icon(Icons.add_rounded, color: scheme.onPrimaryContainer, size: 30),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 4,
                  child: Text(
                    'Fiyat Ekle',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600),
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

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: SizedBox(
          height: 72,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                scale: selected ? 1.12 : 1,
                child: Icon(
                  icon,
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                  size: 24,
                ),
              ),
              AnimatedSlide(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                offset: selected ? Offset.zero : const Offset(0, 0.25),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 220),
                  opacity: selected ? 1 : 0.75,
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
      ),
    );
  }
}
