import 'package:flutter/material.dart';

import '../ui/components.dart';
import '../ui/tokens.dart';
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

  void _go(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FR.bg,
      extendBody: true,
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: _Dock(index: _index, onChange: _go),
    );
  }
}

class _Dock extends StatelessWidget {
  const _Dock({required this.index, required this.onChange});
  final int index;
  final ValueChanged<int> onChange;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, kFRDockMargin),
        child: Container(
          height: kFRDockHeight,
          decoration: BoxDecoration(
            color: FR.surface,
            borderRadius: FRRad.all(26),
            border: Border.all(color: FR.hairline),
            boxShadow: [
              BoxShadow(color: FR.shadowTone.withOpacity(.4), blurRadius: 24, offset: const Offset(0, 12)),
              BoxShadow(color: FR.gold.withOpacity(.06), blurRadius: 36, offset: const Offset(0, 0)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              FRDockItem(
                icon: Icons.home_rounded,
                label: 'Anasayfa',
                active: index == 0,
                onTap: () => onChange(0),
              ),
              FRDockItem(
                icon: Icons.radar_rounded,
                label: 'Keşfet',
                active: index == 1,
                onTap: () => onChange(1),
              ),
              FRDockFab(active: index == 2, onTap: () => onChange(2)),
              FRDockItem(
                icon: Icons.shopping_basket_rounded,
                label: 'Sepet',
                active: index == 3,
                onTap: () => onChange(3),
              ),
              FRDockItem(
                icon: Icons.person_rounded,
                label: 'Profil',
                active: index == 4,
                onTap: () => onChange(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
