import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radius.dart';

class FRBottomDockNav extends StatelessWidget {
  const FRBottomDockNav({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    super.key,
    this.onCenterAction,
    this.centerIcon = Icons.add,
  }) : assert(items.length >= 2);

  final List<BottomNavigationBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback? onCenterAction;
  final IconData centerIcon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: FRDsColors.frSurface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(FRDsRadius.radiusLg),
          topRight: Radius.circular(FRDsRadius.radiusLg),
        ),
      ),
      child: BottomAppBar(
        color: Colors.transparent,
        child: Row(
          children: [
            Expanded(
              child: BottomNavigationBar(
                items: items,
                currentIndex: currentIndex,
                onTap: onTap,
                backgroundColor: Colors.transparent,
                selectedItemColor: FRDsColors.frBrownDeep,
                unselectedItemColor: FRDsColors.frTextMuted,
                elevation: 0,
                type: BottomNavigationBarType.fixed,
              ),
            ),
            if (onCenterAction != null)
              IconButton.filled(
                onPressed: onCenterAction,
                icon: Icon(centerIcon),
                color: FRDsColors.frSurface,
                style: IconButton.styleFrom(backgroundColor: FRDsColors.frBrownDeep),
              ),
          ],
        ),
      ),
    );
  }
}
