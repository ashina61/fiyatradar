import 'package:flutter/material.dart';

import '../widgets/prototype_ui.dart';
import 'tabs/add_price_tab.dart';
import 'tabs/basket_tab.dart';
import 'tabs/explore_tab.dart';
import 'tabs/home_tab.dart';
import 'tabs/profile_tab.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, this.initialIndex = 0});
  final int initialIndex;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _index;
  static const _tabs = [
    HomeTab(),
    ExploreTab(),
    AddPriceTab(),
    BasketTab(),
    ProfileTab(),
  ];

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: 72,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [ProtoColors.bgPrimary.withAlpha(247), ProtoColors.bgPrimary.withAlpha(208)],
            ),
            border: Border(top: BorderSide(color: ProtoColors.border)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _item(0, Icons.home_filled, 'Ana Sayfa'),
              _item(1, Icons.search, 'Ara'),
              _item(2, Icons.add_circle_outline, 'Ekle'),
              _item(3, Icons.shopping_basket_outlined, 'Sepet'),
              _item(4, Icons.person_outline, 'Profil'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(int i, IconData icon, String label) {
    final active = _index == i;
    return GestureDetector(
      onTap: () => setState(() => _index = i),
      child: Container(
        padding: FRInsets.navItem,
        decoration: BoxDecoration(
          color: active ? ProtoColors.tan.withOpacity(0.1) : Colors.transparent,
          borderRadius: FRRadii.lg,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 18, color: active ? ProtoColors.tan : ProtoColors.textSubtle),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: active ? ProtoColors.tan : ProtoColors.textSubtle)),
        ]),
      ),
    );
  }
}
