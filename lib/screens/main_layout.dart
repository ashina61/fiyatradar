import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../core/theme/app_colors.dart';
import 'add_price_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      HomeScreen(onTabChange: _goToTab),
      const SearchScreen(),
      const AddPriceScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: tabs[currentIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => currentIndex = 2),
        backgroundColor: AppColors.tan,
        shape: const CircleBorder(),
        child: const FaIcon(FontAwesomeIcons.plus, color: AppColors.bgPrimary, size: 22),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Container(
        height: 72,
        decoration: const BoxDecoration(
          color: Color.fromRGBO(42, 37, 34, 0.97),
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _item(FontAwesomeIcons.house, 'Ana Sayfa', 0),
            _item(FontAwesomeIcons.magnifyingGlass, 'Ara', 1),
            const SizedBox(width: 42),
            _item(FontAwesomeIcons.user, 'Profil', 3),
          ],
        ),
      ),
    );
  }

  void _goToTab(int index) => setState(() => currentIndex = index);

  Widget _item(IconData icon, String label, int i) {
    final active = currentIndex == i;
    return InkWell(
      onTap: () => setState(() => currentIndex = i),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          FaIcon(icon, size: 18, color: active ? AppColors.tan : AppColors.textSubtle),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: active ? AppColors.tan : AppColors.textSubtle)),
        ]),
      ),
    );
  }
}
