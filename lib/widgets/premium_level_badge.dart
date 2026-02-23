import 'dart:ui';

import 'package:flutter/material.dart';
import '../utils/elite_level_engine.dart';

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

  EliteLevel get _eliteLevel => EliteLevelEngine.parseLevelLabel(widget.levelName);

  bool get _hasPulseAnimation =>
      _eliteLevel == EliteLevel.fiyatLordu || _eliteLevel == EliteLevel.radarEfsanesi;

  ({Color levelColor, Color contentColor, IconData icon}) _resolveStyle() {
    final style = EliteLevelEngine.getLevelStyle(_eliteLevel);
    return (
      levelColor: style.badgeBorder,
      contentColor: style.textColor,
      icon: style.icon,
    );
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
        ),
      ),
    );
  }
}
