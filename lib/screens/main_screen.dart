import 'package:flutter/material.dart';

import '../widgets/executive_ui.dart';
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
  static const _tabs = [HomeTab(), ExploreTab(), AddPriceTab(), BasketTab(), ProfileTab()];

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ExecColors.bg,
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            color: ExecColors.surface.withOpacity(.97),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: ExecColors.bgDeep),
            boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 18, offset: Offset(0, 6))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _item(0, Icons.home_rounded, 'Home'),
              _item(1, Icons.search_rounded, 'Keşfet'),
              _item(2, Icons.add_rounded, 'Ekle', primary: true),
              _item(3, Icons.shopping_basket_rounded, 'Sepet'),
              _item(4, Icons.person_rounded, 'Profil'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(int i, IconData icon, String label, {bool primary = false}) {
    final active = _index == i;
    return GestureDetector(
      onTap: () => setState(() => _index = i),
      child: Container(
        width: primary ? 58 : 64,
        height: 50,
        decoration: BoxDecoration(
          color: primary
              ? ExecColors.espresso
              : active
                  ? ExecColors.espresso
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 19, color: (active || primary) ? ExecColors.gold : ExecColors.ink3),
            if (!primary) ...[
              const SizedBox(height: 2),
              Text(label, style: manrope(9, FontWeight.w700, color: active ? ExecColors.gold : ExecColors.ink4)),
            ]
          ],
        ),
      ),
    );
  }
}
