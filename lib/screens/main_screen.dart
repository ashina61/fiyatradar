import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cart/cart_screen_v2.dart';
import '../widgets/premium_bottom_nav.dart';
import 'add_price/add_price_screen.dart';
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

  late final List<Widget> _screens = const [
    HomeScreen(key: PageStorageKey('home-tab')),
    SearchScreen(key: PageStorageKey('search-tab')),
    SizedBox.shrink(),
    CartScreenV2(key: PageStorageKey('basket-tab')),
    ProfileScreen(key: PageStorageKey('profile-tab')),
  ];

  Future<void> _openAddPrice() async {
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
    final currentTab = ref.watch(currentTabProvider);

    return Scaffold(
      body: Stack(
        children: [
          for (var i = 0; i < _screens.length; i++)
            IgnorePointer(
              ignoring: currentTab != i,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                opacity: currentTab == i ? 1 : 0,
                child: KeyedSubtree(
                  key: ValueKey('tab-$i'),
                  child: _screens[i],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: PremiumBottomNav(
        currentIndex: currentTab,
        onCenterTap: _openAddPrice,
        onTap: (index) => ref.read(currentTabProvider.notifier).state = index,
      ),
    );
  }
}
