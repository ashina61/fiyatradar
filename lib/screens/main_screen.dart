import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'add_price/add_price_screen.dart';
import 'cart/cart_screen_v2.dart';
import 'home/home_screen.dart';
import 'profile/profile_screen.dart';
import 'search/search_screen.dart';

final currentTabProvider = StateProvider<int>((ref) => 0);

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  bool _isNavigating = false;

  // İndex 2 boşluktur (Ortadaki Fiyat Ekle Butonunun yeri)
  late final List<Widget> _screens = const [
    HomeScreen(key: PageStorageKey('home-tab')),
    SearchScreen(key: PageStorageKey('search-tab')),
    SizedBox.shrink(), // 2. İndex (FAB)
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
      backgroundColor: const Color(0xFFFAF6F0), // Arka plan
      extendBody: true, // Menünün arkasının şeffaf olması ve taşabilmesi için kritik!
      body: Stack(
        children: [
          // 1. KATMAN: SAYFALAR (Arka Planda)
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
            
          // 2. KATMAN: EFSANE KAYAN MENÜMÜZ (En Üstte)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _CustomBottomBar(
              selectedIndex: selectedIndex,
              onTabSelected:
                  (index) => ref.read(currentTabProvider.notifier).state = index,
              onCenterPressed: _onFABPressed,
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// V3 DİNAMİK KAYAN BOTTOM BAR (KUSURSUZ)
// ==========================================
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
    const springCurve = Cubic(0.34, 1.56, 0.64, 1.0);

    return Container(
      // Alt boşluk iOS ev çizgisi için
      padding: const EdgeInsets.only(top: 12, left: 12, right: 12, bottom: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
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
      // SİHİR BURADA: Expanded KULLANMADIK. Row içinde organik olarak birbirlerini iterler.
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _BottomTabItem(
            index: 0,
            selectedIndex: selectedIndex,
            label: 'Ana Sayfa',
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            onTap: onTabSelected,
            curve: springCurve,
          ),
          _BottomTabItem(
            index: 1,
            selectedIndex: selectedIndex,
            label: 'Keşfet',
            icon: Icons.explore_outlined,
            activeIcon: Icons.explore,
            onTap: onTabSelected,
            curve: springCurve,
          ),
          
          // ORTA BUTON (Elmas)
          Transform.translate(
            offset: const Offset(0, -12),
            child: Transform.rotate(
              angle: math.pi / 4,
              child: GestureDetector(
                onTap: onCenterPressed,
                child: Container(
                  height: 52,
                  width: 52,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF8C5938), Color(0xFF4A2E1B)],
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(18)),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x406B4226),
                        blurRadius: 15,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Transform.rotate(
                      angle: -math.pi / 4,
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
                    ),
                  ),
                ),
              ),
            ),
          ),

          _BottomTabItem(
            index: 3, // İndex 3 Sepet sayfasıdır
            selectedIndex: selectedIndex,
            label: 'Sepet',
            icon: Icons.shopping_bag_outlined,
            activeIcon: Icons.shopping_bag,
            onTap: onTabSelected,
            curve: springCurve,
          ),
          _BottomTabItem(
            index: 4, // İndex 4 Profil sayfasıdır
            selectedIndex: selectedIndex,
            label: 'Profil',
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            onTap: onTabSelected,
            curve: springCurve,
          ),
        ],
      ),
    );
  }
}

// Yana Doğru Genişleyen Dinamik Sekme
class _BottomTabItem extends StatelessWidget {
  const _BottomTabItem({
    required this.index,
    required this.selectedIndex,
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.onTap,
    required this.curve,
  });

  final int index;
  final int selectedIndex;
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final ValueChanged<int> onTap;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    final isActive = selectedIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: curve,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 16.0 : 10.0,
          vertical: 12.0,
        ),
        decoration: BoxDecoration(
          color: isActive ? const Color(0x1A6B4226) : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? const Color(0xFF6B4226) : const Color(0xFFA38671),
              size: 26,
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 400),
              curve: curve,
              child: Container(
                width: isActive ? null : 0,
                padding: EdgeInsets.only(left: isActive ? 6.0 : 0.0),
                child: Text(
                  isActive ? label : "",
                  style: const TextStyle(
                    color: Color(0xFF6B4226),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
