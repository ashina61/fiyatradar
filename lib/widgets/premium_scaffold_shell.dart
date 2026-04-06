import 'package:flutter/material.dart';

import '../theme/fr_ink.dart';

class PremiumScaffoldShell extends StatelessWidget {
  const PremiumScaffoldShell({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [FRInk.paper, Color(0xFFEDE8E1)],
        ),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        child: child,
      ),
    );
  }
}
