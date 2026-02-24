import 'dart:ui';

import 'package:flutter/material.dart';

class PremiumLevelBadge extends StatefulWidget {
  const PremiumLevelBadge({
    super.key,
    required this.levelName,
    this.displayText,
    this.showVerifiedIcon = false,
  });

  final String levelName;
  final String? displayText;
  final bool showVerifiedIcon;

  @override
  State<PremiumLevelBadge> createState() => _PremiumLevelBadgeState();
}

class _PremiumLevelBadgeState extends State<PremiumLevelBadge> {
  bool _animateForward = true;

  ({Color levelColor, Color contentColor, IconData icon}) _resolveStyle() {
    switch (widget.levelName.trim()) {
      case 'Avcı':
        return (
          levelColor: const Color(0xFFF4511E),
          contentColor: const Color(0xFFF4511E),
          icon: Icons.gps_fixed_rounded,
        );
      case 'Tasarrufçu':
        return (
          levelColor: const Color(0xFF1E88E5),
          contentColor: const Color(0xFF1E88E5),
          icon: Icons.savings_rounded,
        );
      case 'Market Ustası':
        return (
          levelColor: const Color(0xFFFFB300),
          contentColor: const Color(0xFFFFB300),
          icon: Icons.storefront_rounded,
        );
      case 'Fiyat Lordu':
        return (
          levelColor: const Color(0xFFE040FB),
          contentColor: const Color(0xFFE040FB),
          icon: Icons.workspace_premium_rounded,
        );
      case 'Radar Efsanesi':
        return (
          levelColor: const Color(0xFF00E5FF),
          contentColor: const Color(0xFF0097A7),
          icon: Icons.diamond_rounded,
        );
      case 'Gözlemci':
      default:
        return (
          levelColor: const Color(0xFF8C7A6B),
          contentColor: const Color(0xFF8C7A6B),
          icon: Icons.visibility_rounded,
        );
    }
  }

  bool get _hasPulseAnimation {
    final level = widget.levelName.trim();
    return level == 'Fiyat Lordu' || level == 'Radar Efsanesi';
  }

  @override
  Widget build(BuildContext context) {
    final style = _resolveStyle();

    if (!_hasPulseAnimation) {
      return _buildBadge(
        levelColor: style.levelColor,
        contentColor: style.contentColor,
        icon: style.icon,
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: _animateForward ? 0.0 : 1.0, end: _animateForward ? 1.0 : 0.0),
      duration: Duration(milliseconds: widget.levelName.trim() == 'Radar Efsanesi' ? 2600 : 2100),
      curve: Curves.easeInOut,
      onEnd: () {
        if (mounted) {
          setState(() => _animateForward = !_animateForward);
        }
      },
      builder: (context, t, child) {
        final blur = 8 + ((24 - 8) * t);
        final spread = 0.3 + ((2.2 - 0.3) * t);

        return _buildBadge(
          levelColor: style.levelColor,
          contentColor: style.contentColor,
          icon: style.icon,
          boxShadow: [
            BoxShadow(
              color: style.levelColor.withOpacity(0.24 + ((0.50 - 0.24) * t)),
              blurRadius: blur,
              spreadRadius: spread,
            ),
          ],
        );
      },
    );
  }

  Widget _buildBadge({
    required Color levelColor,
    required Color contentColor,
    required IconData icon,
    List<BoxShadow>? boxShadow,
  }) {
    final resolvedText = (widget.displayText?.trim().isNotEmpty == true)
        ? widget.displayText!.trim()
        : widget.levelName.trim();

    return ClipRRect(
      borderRadius: BorderRadius.circular(50),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            color: Colors.white.withOpacity(0.85),
            border: Border.all(color: levelColor, width: 1.5),
            boxShadow: boxShadow,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: contentColor),
              const SizedBox(width: 6),
              Text(
                resolvedText,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: contentColor,
                ),
              ),
              if (widget.showVerifiedIcon) ...[
                const SizedBox(width: 6),
                Icon(Icons.verified_rounded, size: 14, color: contentColor),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
