import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/motion_tokens.dart';

class PremiumBottomNav extends StatefulWidget {
  const PremiumBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onCenterTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onCenterTap;

  @override
  State<PremiumBottomNav> createState() => _PremiumBottomNavState();
}

class _PremiumBottomNavState extends State<PremiumBottomNav>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2100),
  )..repeat(reverse: true);

  static const _tabs = <_NavTab>[
    _NavTab(index: 0, label: 'Ana Sayfa', icon: Icons.home_rounded),
    _NavTab(index: 1, label: 'Keşfet', icon: Icons.explore_rounded),
    _NavTab(index: 3, label: 'Sepet', icon: Icons.shopping_basket_rounded),
    _NavTab(index: 4, label: 'Profil', icon: Icons.person_rounded),
  ];

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final width = MediaQuery.sizeOf(context).width * 0.93;
    final selectedSlot =
        _tabs.indexWhere((tab) => tab.index == widget.currentIndex).clamp(0, _tabs.length - 1);

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        height: 104,
        child: Center(
          child: SizedBox(
            width: width,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                    child: Container(
                      height: 78,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: scheme.surface.withOpacity(0.94),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: scheme.outlineVariant.withOpacity(0.8)),
                        gradient: LinearGradient(
                          colors: [
                            scheme.surface.withOpacity(0.94),
                            scheme.surfaceVariant.withOpacity(0.9),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: scheme.primary.withOpacity(0.15),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
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
                                duration: MotionTokens.navigation,
                                curve: MotionTokens.standard,
                                left: bubbleLeft + 8,
                                top: 14,
                                child: Container(
                                  width: slotWidth - 16,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24),
                                    gradient: LinearGradient(
                                      colors: [
                                        scheme.primaryContainer.withOpacity(0.9),
                                        scheme.secondaryContainer.withOpacity(0.82),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: scheme.primary.withOpacity(0.2),
                                        blurRadius: 18,
                                        offset: const Offset(0, 5),
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
                                        selected: widget.currentIndex == tab.index,
                                        onTap: () {
                                          HapticFeedback.selectionClick();
                                          widget.onTap(tab.index);
                                        },
                                      ),
                                    ),
                                  SizedBox(width: slotWidth),
                                  for (final tab in _tabs.skip(2))
                                    Expanded(
                                      child: _NavItem(
                                        icon: tab.icon,
                                        label: tab.label,
                                        selected: widget.currentIndex == tab.index,
                                        onTap: () {
                                          HapticFeedback.selectionClick();
                                          widget.onTap(tab.index);
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
                  top: -15,
                  child: _CenterActionButton(
                    pulse: _pulseController,
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      widget.onCenterTap();
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
  const _CenterActionButton({
    required this.pulse,
    required this.onTap,
  });

  final Animation<double> pulse;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: pulse,
        builder: (context, _) {
          final aura = 0.18 + (pulse.value * 0.16);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      scheme.primaryContainer.withOpacity(0.8),
                      scheme.secondary.withOpacity(0.76),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withOpacity(aura),
                      blurRadius: 24,
                      offset: const Offset(0, 9),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: scheme.primary,
                        border: Border.all(color: scheme.onPrimary.withOpacity(0.4)),
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        size: 31,
                        color: scheme.onPrimary,
                        semanticLabel: 'Fiyat Ekle',
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Fiyat Ekle',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          );
        },
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: SizedBox(
        height: 78,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              duration: MotionTokens.base,
              curve: MotionTokens.standard,
              scale: selected ? 1.14 : 1,
              child: Icon(
                icon,
                semanticLabel: label,
                size: 24,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedOpacity(
              duration: MotionTokens.fast,
              opacity: selected ? 1 : 0.7,
              child: Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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
