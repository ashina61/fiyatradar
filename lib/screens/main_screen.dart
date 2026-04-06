// lib/screens/main_screen.dart
// GREENFIELD v2 — thin floating pill bottom navigation.
// Rejected from previous iteration: rotated diamond FAB, rounded brown container,
// spaceBetween 5-slot layout with center popping out.
// UX goal: an almost-invisible navigation pill — the content owns the screen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/fr_ink.dart';
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
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddPriceScreen()));
    } finally {
      _navigating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tab = ref.watch(currentTabProvider);

    return Scaffold(
      backgroundColor: FRInk.paper,
      extendBody: true,
      body: Stack(
        children: [
          for (var i = 0; i < _screens.length; i++)
            Offstage(
              offstage: tab != i,
              child: TickerMode(enabled: tab == i, child: _screens[i]),
            ),
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                child: _NavPill(
                  selected: tab,
                  onSelected: (i) => ref.read(currentTabProvider.notifier).state = i,
                  onAdd: _openAdd,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavPill extends StatelessWidget {
  const _NavPill({required this.selected, required this.onSelected, required this.onAdd});
  final int selected;
  final ValueChanged<int> onSelected;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      decoration: BoxDecoration(
        color: FRInk.ink,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(color: Color(0x330E0E0C), blurRadius: 30, offset: Offset(0, 14)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          _NavItem(index: 0, label: 'pulse', icon: Icons.radio_button_checked_rounded, selected: selected, onTap: onSelected),
          _NavItem(index: 1, label: 'dizin', icon: Icons.search_rounded, selected: selected, onTap: onSelected),
          _AddInline(onTap: onAdd),
          _NavItem(index: 2, label: 'defter', icon: Icons.receipt_long_rounded, selected: selected, onTap: onSelected),
          _NavItem(index: 3, label: 'dosya', icon: Icons.person_outline_rounded, selected: selected, onTap: onSelected),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.index, required this.label, required this.icon, required this.selected, required this.onTap});
  final int index;
  final String label;
  final IconData icon;
  final int selected;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final active = selected == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: active ? FRInk.paper : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: active ? FRInk.ink : FRInk.paper.withOpacity(0.78)),
              if (active) ...[
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: FRType.family,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: FRInk.ink,
                    letterSpacing: 0.2,
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

class _AddInline extends StatelessWidget {
  const _AddInline({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50, height: 50,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: FRInk.saffron, shape: BoxShape.circle),
        child: const Icon(Icons.add_rounded, color: FRInk.paper, size: 24),
      ),
    );
  }
}
