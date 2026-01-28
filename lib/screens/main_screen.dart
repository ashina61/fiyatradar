import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notification_provider.dart';
import '../utils/theme.dart';
import 'home/home_screen.dart';
import 'search/search_screen.dart';
import 'add_price/add_price_screen.dart';
import 'notifications/notifications_screen.dart';
import 'profile/profile_screen.dart';

final currentTabProvider = StateProvider<int>((ref) => 0);

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(currentTabProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    final screens = [
      const HomeScreen(),
      const SearchScreen(),
      const AddPriceScreen(),
      const NotificationsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentTab,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentTab,
        onDestinationSelected: (index) {
          ref.read(currentTabProvider.notifier).state = index;
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          const NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Ara',
          ),
          NavigationDestination(
            icon: Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 24,
              ),
            ),
            label: 'Fiyat Ekle',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unreadCount.valueOrNull != null &&
                  unreadCount.valueOrNull! > 0,
              label: Text('${unreadCount.valueOrNull ?? 0}'),
              child: const Icon(Icons.notifications_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: unreadCount.valueOrNull != null &&
                  unreadCount.valueOrNull! > 0,
              label: Text('${unreadCount.valueOrNull ?? 0}'),
              child: const Icon(Icons.notifications),
            ),
            label: 'Bildirimler',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
