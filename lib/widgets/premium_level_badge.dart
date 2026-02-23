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

class _PremiumLevelBadgeState extends State<PremiumLevelBadge>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

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
  void initState() {
    super.initState();
    _syncAnimationController();
  }

  @override
  void didUpdateWidget(covariant PremiumLevelBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.levelName != widget.levelName) {
      _syncAnimationController();
    }
  }

  void _syncAnimationController() {
    if (_hasPulseAnimation) {
      _controller ??= AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200),
      )..repeat(reverse: true);
      if (!_controller!.isAnimating) {
        _controller!.repeat(reverse: true);
      }
      return;
    }

    _controller?.stop();
    _controller?.dispose();
    _controller = null;
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = _resolveStyle();

    if (!_hasPulseAnimation || _controller == null) {
      return _badge(
        levelColor: style.levelColor,
        contentColor: style.contentColor,
        icon: style.icon,
      );
    }

    return AnimatedBuilder(
      animation: _controller!,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_controller!.value);
        final isLegend = widget.levelName == 'Radar Efsanesi';
        final pulseColor = isLegend
            ? Color.lerp(
                const Color(0xFF00E5FF).withOpacity(0.25),
                const Color(0xFF64FFDA).withOpacity(0.65),
                t,
              )!
            : Color.lerp(
                const Color(0xFFE040FB).withOpacity(0.22),
                const Color(0xFFBA68C8).withOpacity(0.58),
                t,
              )!;
        final blur = isLegend ? (10 + (24 * t)) : (8 + (20 * t));
        final spread = isLegend ? (0.6 + (2.8 * t)) : (0.4 + (2.2 * t));

        return _badge(
          levelColor: style.levelColor,
          contentColor: style.contentColor,
          icon: style.icon,
          boxShadow: [
            BoxShadow(
              color: pulseColor,
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
