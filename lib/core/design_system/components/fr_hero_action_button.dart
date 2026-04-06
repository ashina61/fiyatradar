import 'package:flutter/material.dart';

import '../tokens/colors.dart';

class FRHeroActionButton extends StatelessWidget {
  const FRHeroActionButton({required this.icon, super.key, this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: FRDsColors.frSurface),
      style: IconButton.styleFrom(
        backgroundColor: FRDsColors.frSurface.withOpacity(0.12),
        shape: const CircleBorder(),
      ),
    );
  }
}
