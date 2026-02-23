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

  bool get _hasPulseAnimation =>
      widget.levelName == 'Fiyat Lordu' || widget.levelName == 'Radar Efsanesi';

  ({Color levelColor, Color contentColor, IconData icon}) _resolveStyle() {
    switch (widget.levelName) {
      case 'Gözlemci':
        return (
          levelColor: const Color(0xFF8C7A6B),
          contentColor: const Color(0xFF8C7A6B),
          icon: Icons.visibility_rounded,
        );
      case 'Avcı':
        return (
          levelColor: const Color(0xFFF4511E),
          contentColor: const Color(0xFFF4511E),
          icon: Icons.my_location_rounded,
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
          icon: Icons.military_tech_rounded,
        );
      case 'Radar Efsanesi':
        return (
          levelColor: const Color(0xFF00E5FF),
          contentColor: const Color(0xFF0097A7),
          icon: Icons.diamond_rounded,
        );
      default:
        return (
          levelColor: const Color(0xFF8C7A6B),
          contentColor: const Color(0xFF8C7A6B),
          icon: Icons.visibility_rounded,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _resolveStyle();

    if (!_hasPulseAnimation) {
      return _badge(
        levelColor: style.levelColor,
        contentColor: style.contentColor,
        icon: style.icon,
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: _animateForward ? 0.0 : 1.0, end: _animateForward ? 1.0 : 0.0),
      duration: Duration(milliseconds: widget.levelName == 'Radar Efsanesi' ? 2600 : 2100),
      onEnd: () {
        if (mounted) {
          setState(() => _animateForward = !_animateForward);
        }
      },
      curve: Curves.easeInOut,
      builder: (context, t, _) {
        final blur = 8 + ((24 - 8) * t);
        final spread = 0.3 + ((2.2 - 0.3) * t);

        return _badge(
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

  Widget _badge({
    required Color levelColor,
    required Color contentColor,
    required IconData icon,
    List<BoxShadow>? boxShadow,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        color: levelColor.withOpacity(0.12),
        border: Border.all(color: levelColor.withOpacity(0.8), width: 1.5),
        boxShadow: boxShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: contentColor),
          const SizedBox(width: 6),
          Text(
            widget.displayText?.trim().isNotEmpty == true
                ? widget.displayText!.trim()
                : widget.levelName,
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
    );
  }
}
