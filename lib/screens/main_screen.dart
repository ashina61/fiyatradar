import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/notification_provider.dart';
import '../utils/theme.dart';
import 'add_price/add_price_screen.dart';
import 'home/home_screen.dart';
import 'notifications/notifications_screen.dart';
import 'profile/profile_screen.dart';
import 'search/search_screen.dart';

final currentTabProvider = StateProvider<int>((ref) => 0);

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fabController;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      lowerBound: 0.0,
      upperBound: 0.08,
    );
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

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
    final unreadCountAsync = ref.watch(unreadNotificationCountProvider);
    final unreadCount = unreadCountAsync.valueOrNull ?? 0;

    final screens = const [
      HomeScreen(),
      SearchScreen(),
      NotificationsScreen(),
      ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: currentTab, children: screens),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: GestureDetector(
        onTapDown: (_) => _fabController.forward(),
        onTapUp: (_) => _fabController.reverse(),
        onTapCancel: _fabController.reverse,
        child: AnimatedBuilder(
          animation: _fabController,
          builder: (context, child) {
            return Transform.scale(
              scale: 1 - _fabController.value,
              child: child,
            );
          },
          child: FloatingActionButton(
            onPressed: _openAddPrice,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            child: const Icon(Icons.add, size: 26),
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              Expanded(child: _buildNavItem('Ana Sayfa', Icons.home_outlined, Icons.home, 0, currentTab)),
              Expanded(child: _buildNavItem('Ara', Icons.search_outlined, Icons.search, 1, currentTab)),
              const SizedBox(width: 48),
              Expanded(
                child: _buildNavItemWithBadge(
                  label: 'Bildirimler',
                  icon: Icons.notifications_outlined,
                  selectedIcon: Icons.notifications,
                  index: 2,
                  currentTab: currentTab,
                  badgeCount: unreadCount,
                ),
              ),
              Expanded(child: _buildNavItem('Profil', Icons.person_outline, Icons.person, 3, currentTab)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    String label,
    IconData icon,
    IconData selectedIcon,
    int index,
    int currentTab,
  ) {
    final selected = currentTab == index;
    return InkWell(
      onTap: () => ref.read(currentTabProvider.notifier).state = index,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _AnimatedNavIcon(icon: selected ? selectedIcon : icon, selected: selected),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).hintColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItemWithBadge({
    required String label,
    required IconData icon,
    required IconData selectedIcon,
    required int index,
    required int currentTab,
    required int badgeCount,
  }) {
    final selected = currentTab == index;
    return InkWell(
      onTap: () => ref.read(currentTabProvider.notifier).state = index,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Badge(
            isLabelVisible: badgeCount > 0,
            label: Text('$badgeCount'),
            child: _AnimatedNavIcon(icon: selected ? selectedIcon : icon, selected: selected),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).hintColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedNavIcon extends StatelessWidget {
  final IconData icon;
  final bool selected;

  const _AnimatedNavIcon({required this.icon, required this.selected});

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      scale: selected ? 1.08 : 1,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 220),
        opacity: selected ? 1 : 0.7,
        child: Icon(icon),
      ),
    );
  }
}
