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

  @override
  Widget build(BuildContext context) {
    final currentTab = ref.watch(currentTabProvider);
    final unreadCountAsync = ref.watch(unreadNotificationCountProvider);
    final unreadCount = unreadCountAsync.valueOrNull ?? 0;

    final screens = const [
      HomeScreen(),
      SearchScreen(),
      AddPriceScreen(),
      NotificationsScreen(),
      ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: currentTab, children: screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.4),
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: currentTab,
          animationDuration: const Duration(milliseconds: 240),
          onDestinationSelected: (index) {
            ref.read(currentTabProvider.notifier).state = index;
          },
          destinations: [
            _navDestination('Ana Sayfa', Icons.home_outlined, Icons.home, currentTab == 0),
            _navDestination('Ara', Icons.search_outlined, Icons.search, currentTab == 1),
            NavigationDestination(
              icon: GestureDetector(
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
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      gradient: AppColors.gradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(currentTab == 2 ? 0.34 : 0.22),
                          blurRadius: currentTab == 2 ? 14 : 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 20),
                  ),
                ),
              ),
              label: 'Fiyat Ekle',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: unreadCount > 0,
                label: Text('$unreadCount'),
                child: _AnimatedNavIcon(
                  icon: Icons.notifications_outlined,
                  selected: currentTab == 3,
                ),
              ),
              selectedIcon: Badge(
                isLabelVisible: unreadCount > 0,
                label: Text('$unreadCount'),
                child: _AnimatedNavIcon(
                  icon: Icons.notifications,
                  selected: currentTab == 3,
                ),
              ),
              label: 'Bildirimler',
            ),
            _navDestination('Profil', Icons.person_outline, Icons.person, currentTab == 4),
          ],
        ),
      ),
    );
  }

  NavigationDestination _navDestination(
    String label,
    IconData icon,
    IconData selectedIcon,
    bool selected,
  ) {
    return NavigationDestination(
      icon: _AnimatedNavIcon(icon: icon, selected: selected),
      selectedIcon: _AnimatedNavIcon(icon: selectedIcon, selected: selected),
      label: label,
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
