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
      height: 112 + bottomInset,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            left: 16,
            right: 16,
            bottom: 20 + bottomInset,
            child: Container(
              height: 80,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x146B4226),
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  for (final tab in _tabs.take(2))
                    _DockNavItem(
                      tab: tab,
                      selected: tab.index == currentIndex,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onTap(tab.index);
                      },
                    ),
                  const SizedBox(width: 70),
                  for (final tab in _tabs.skip(2))
                    _DockNavItem(
                      tab: tab,
                      selected: tab.index == currentIndex,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onTap(tab.index);
                      },
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 20 + bottomInset + 36,
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
    const activeColor = Color(0xFF6B4226);
    const inactiveColor = Color(0xFFA38671);

    return Expanded(
      child: Center(
        child: InkWell(
          borderRadius: BorderRadius.circular(100),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeInOut,
            constraints: BoxConstraints(minWidth: selected ? 114 : 50),
            padding: EdgeInsets.symmetric(
              horizontal: selected ? 16 : 12,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: selected ? const Color(0x1A6B4226) : Colors.transparent,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected ? tab.filledIcon : tab.outlinedIcon,
                  size: 25,
                  color: selected ? activeColor : inactiveColor,
                  semanticLabel: tab.semanticLabel,
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeInOut,
                  child: selected
                      ? Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            tab.semanticLabel,
                            overflow: TextOverflow.fade,
                            softWrap: false,
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: activeColor,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
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
      child: Transform.translate(
        offset: const Offset(0, -12),
        child: Container(
          width: 62,
          height: 62,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white, width: 1.4),
            boxShadow: const [
              BoxShadow(
                color: Color(0x336B4226),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(19),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF8C5938), Color(0xFF4A2E1B)],
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 31,
                semanticLabel: 'Fiyat Ekle',
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
    required this.filledIcon,
    required this.outlinedIcon,
    required this.semanticLabel,
  });

  final int index;
  final IconData filledIcon;
  final IconData outlinedIcon;
  final String semanticLabel;
}
