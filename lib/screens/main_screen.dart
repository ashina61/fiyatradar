import 'package:flutter/material.dart';
import '../theme.dart';
import 'tabs/home_tab.dart';
import 'tabs/explore_tab.dart';
import 'tabs/add_price_tab.dart';
import 'tabs/cart_tab.dart';
import 'tabs/profile_tab.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;

  static const _tabs = <Widget>[
    HomeTab(),
    ExploreTab(),
    AddPriceTab(),
    CartTab(),
    ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: _CoffeeBottomBar(
        index: _index,
        onChanged: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _CoffeeBottomBar extends StatelessWidget {
  const _CoffeeBottomBar({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  static const _items = [
    (Icons.home_rounded, 'Anasayfa'),
    (Icons.explore_outlined, 'Keşfet'),
    (Icons.add, 'Fiyat Ekle'),
    (Icons.shopping_basket_outlined, 'Sepet'),
    (Icons.person_outline, 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: CoffeeColors.espresso,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: CoffeeColors.espresso.withOpacity(0.3),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_items.length, (i) {
            final selected = i == index;
            final isCenter = i == 2;
            final (icon, label) = _items[i];

            if (isCenter) {
              return GestureDetector(
                onTap: () => onChanged(i),
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: CoffeeColors.caramel,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: CoffeeColors.caramel.withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add,
                      color: CoffeeColors.espresso, size: 28),
                ),
              );
            }

            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? CoffeeColors.darkRoast
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon,
                          color: selected
                              ? CoffeeColors.caramel
                              : CoffeeColors.latte,
                          size: 22),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? CoffeeColors.cream
                              : CoffeeColors.latte,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
