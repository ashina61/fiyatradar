import 'package:flutter/material.dart';

import '../utils/theme.dart';

class PremiumScaffoldShell extends StatelessWidget {
  const PremiumScaffoldShell({
    super.key,
    required this.child,
    this.topOffset = -80,
  });

  final Widget child;
  final double topOffset;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: topOffset,
          left: -46,
          child: _GlowOrb(size: 220, color: AppColors.primaryLight.withOpacity(0.22)),
        ),
        Positioned(
          top: 210,
          right: -70,
          child: _GlowOrb(size: 250, color: AppColors.accentLight.withOpacity(0.2)),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: child,
        ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color,
              color.withOpacity(0),
            ],
          ),
        ),
      ),
    );
  }
}
