import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/design_system/tokens/colors.dart';
import 'add_price/add_price_screen.dart';
import 'cart/cart_screen.dart';
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
  late final List<Widget> _screens = const [
    HomeScreen(key: PageStorageKey('home-tab')),
    SearchScreen(key: PageStorageKey('search-tab')),
    CartScreen(key: PageStorageKey('basket-tab')),
    ProfileScreen(key: PageStorageKey('profile-tab')),
  ];

  bool _navigating = false;

  Future<void> _openAdd() async {
    if (_navigating) return;
    _navigating = true;
    try {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AddPriceScreen()),
      );
    } finally {
      _navigating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tab = ref.watch(currentTabProvider);

    return Scaffold(
      backgroundColor: FRDsColors.frBackground,
      extendBody: true,
      body: Stack(
        children: [
          for (var i = 0; i < _screens.length; i++)
            Offstage(
              offstage: tab != i,
              child: TickerMode(enabled: tab == i, child: _screens[i]),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                child: _ExecutiveDock(
                  selected: tab,
                  onSelected: (i) => ref.read(currentTabProvider.notifier).state = i,
                  onCenterTap: _openAdd,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExecutiveDock extends StatelessWidget {
  const _ExecutiveDock({
    required this.selected,
    required this.onSelected,
    required this.onCenterTap,
  });

  final int selected;
  final ValueChanged<int> onSelected;
  final VoidCallback onCenterTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      decoration: BoxDecoration(
        color: FRDsColors.frSurface,
        borderRadius: BorderRadius.circular(38),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2A2B1D14),
            blurRadius: 30,
            offset: Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          _DockItem(
            index: 0,
            selected: selected,
            icon: Icons.home_rounded,
            label: 'Ana Sayfa',
            onTap: onSelected,
          ),
          _DockItem(
            index: 1,
            selected: selected,
            icon: Icons.explore_outlined,
            label: 'Keşfet',
            onTap: onSelected,
          ),
          _CenterAction(onTap: onCenterTap),
          _DockItem(
            index: 2,
            selected: selected,
            icon: Icons.shopping_bag_outlined,
            label: 'Sepet',
            onTap: onSelected,
          ),
          _DockItem(
            index: 3,
            selected: selected,
            icon: Icons.person_outline_rounded,
            label: 'Profil',
            onTap: onSelected,
          ),
        ],
      ),
    );
  }
}

class _CenterAction extends StatelessWidget {
  const _CenterAction({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 62,
        height: 62,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF986038), Color(0xFF5B371F)],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x335B371F),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: FRDsColors.frSurface, size: 34),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  const _DockItem({
    required this.index,
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final int index;
  final int selected;
  final IconData icon;
  final String label;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final active = selected == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: active ? FRDsColors.frSurfaceMuted : Colors.transparent,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 24,
                color: active ? FRDsColors.frBrownDeep : FRDsColors.frTextMuted,
              ),
              if (active) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: FRDsColors.frBrownDeep,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
