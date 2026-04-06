import 'package:flutter/material.dart';

import '../tokens/colors.dart';

class FRAppScaffold extends StatelessWidget {
  const FRAppScaffold({
    required this.child,
    super.key,
    this.bottomNavigationBar,
    this.backgroundColor,
    this.useSafeArea = true,
  });

  final Widget child;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;
  final bool useSafeArea;

  @override
  Widget build(BuildContext context) {
    final body = useSafeArea ? SafeArea(child: child) : child;
    return Scaffold(
      backgroundColor: backgroundColor ?? FRDsColors.frBackground,
      body: body,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
