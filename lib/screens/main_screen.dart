import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/basket/basket_screen.dart';
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

    const screens = [
      HomeScreen(),
      SearchScreen(),
      SizedBox.shrink(),
      BasketScreen(),
      ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: currentTab, children: screens),
      bottomNavigationBar: PremiumBottomNav(
        currentIndex: currentTab,
        onCenterTap: _openAddPrice,
        onTap: (index) => ref.read(currentTabProvider.notifier).state = index,
      ),
    );
  }
}
