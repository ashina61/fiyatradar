import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/navigation_provider.dart';
import 'add_price/add_price_screen.dart';
import 'cart/cart_screen_v2.dart';
import 'home/home_screen.dart';
import 'profile/profile_screen.dart';
import 'search/search_screen.dart';


class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  bool _isNavigating = false;

  late final List<Widget> _screens = const [
    HomeScreen(key: PageStorageKey('home-tab')),
    SearchScreen(key: PageStorageKey('search-tab')),
    SizedBox.shrink(),
    CartScreenV2(key: PageStorageKey('basket-tab')),
    ProfileScreen(key: PageStorageKey('profile-tab')),
  ];

  Future<void> _onFABPressed() async {
    if (_isNavigating) return;
    _isNavigating = true;
    try {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AddPriceScreen()),
      );
    } finally {
      _isNavigating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(currentTabProvider);

    return Scaffold(
      body: Stack(
        children: [
          for (var i = 0; i < _screens.length; i++)
            IgnorePointer(
              ignoring: selectedIndex != i,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                opacity: selectedIndex == i ? 1 : 0,
                child: KeyedSubtree(
                  key: ValueKey('tab-$i'),
                  child: _screens[i],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _CustomBottomBar(
        selectedIndex: selectedIndex,
        onTabSelected: (index) => ref.read(currentTabProvider.notifier).state = index,
        onCenterPressed: _onFABPressed,
      ),
    );
  }
}

class _CustomBottomBar extends StatelessWidget {
  const _CustomBottomBar({
    required this.selectedIndex,
    required this.onTabSelected,
    required this.onCenterPressed,
  });

  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onCenterPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0D6B4226),
            blurRadius: 25,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Row(
            children: [
              Expanded(
                child: _BottomTabItem(
                  index: 0,
                  selectedIndex: selectedIndex,
                  label: 'Ana Sayfa',
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  onTap: onTabSelected,
                ),
              ),
              Expanded(
                child: _BottomTabItem(
                  index: 1,
                  selectedIndex: selectedIndex,
                  label: 'Keşfet',
                  icon: Icons.explore_outlined,
                  activeIcon: Icons.explore,
                  onTap: onTabSelected,
                ),
              ),
              Expanded(
                child: Center(
                  child: Transform.translate(
                    offset: const Offset(0, -12),
                    child: GestureDetector(
                      onTap: onCenterPressed,
                      child: Transform.rotate(
                        angle: math.pi / 4,
                        child: Container(
                          height: 54,
                          width: 54,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF8C5938),
                                Color(0xFF4A2E1B),
                              ],
                            ),
                            borderRadius: BorderRadius.all(Radius.circular(20)),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x406B4226),
                                blurRadius: 20,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Transform.rotate(
                              angle: -math.pi / 4,
                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _BottomTabItem(
                  index: 3,
                  selectedIndex: selectedIndex,
                  label: 'Sepet',
                  icon: Icons.shopping_bag_outlined,
                  activeIcon: Icons.shopping_bag,
                  onTap: onTabSelected,
                ),
              ),
              Expanded(
                child: _BottomTabItem(
                  index: 4,
                  selectedIndex: selectedIndex,
                  label: 'Profil',
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  onTap: onTabSelected,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomTabItem extends StatelessWidget {
  const _BottomTabItem({
    required this.index,
    required this.selectedIndex,
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.onTap,
  });

  final int index;
  final int selectedIndex;
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final isActive = selectedIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.elasticOut,
          padding: isActive
              ? const EdgeInsets.symmetric(horizontal: 20, vertical: 12)
              : const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isActive ? const Color(0x1A6B4226) : Colors.transparent,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? activeIcon : icon,
                color:
                    isActive ? const Color(0xFF6B4226) : const Color(0xFFA38671),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 400),
                curve: Curves.elasticOut,
                child: Row(
                  children: [
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 220),
                      opacity: isActive ? 1 : 0,
                      child: isActive
                          ? const SizedBox(width: 8)
                          : const SizedBox.shrink(),
                    ),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 220),
                      opacity: isActive ? 1 : 0,
                      child: isActive
                          ? Text(
                              label,
                              style: const TextStyle(
                                color: Color(0xFF6B4226),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
