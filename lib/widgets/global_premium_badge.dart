import 'package:flutter/material.dart';

import '../utils/elite_level_engine.dart';

class GlobalPremiumBadge extends StatefulWidget {
  const GlobalPremiumBadge({
    super.key,
    required this.levelName,
    this.userName,
    this.showVerifiedIcon = false,
    this.leadingIcon,
    this.levelColor,
    this.showPulseAnimation,
  });

  final String levelName;
  final Color? levelColor;
  final bool? showPulseAnimation;
  final String? userName;
  final bool showVerifiedIcon;
  final IconData? leadingIcon;

  @override
  State<GlobalPremiumBadge> createState() => _GlobalPremiumBadgeState();
}

class _GlobalPremiumBadgeState extends State<GlobalPremiumBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  late EliteLevelStyle _style;

  bool get _resolvedPulse {
    if (widget.showPulseAnimation != null) return widget.showPulseAnimation!;
    final normalized = widget.levelName.trim().toLowerCase();
    return normalized == 'fiyat lordu' || normalized == 'radar efsanesi';
  }

  Color get _resolvedColor => widget.levelColor ?? _style.badgeBorder;

  IconData get _resolvedIcon => widget.leadingIcon ?? _style.icon;

  @override
  void initState() {
    super.initState();
    _style = EliteLevelEngine.getLevelStyle(
      EliteLevelEngine.parseLevelLabel(widget.levelName),
    );
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (_resolvedPulse) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant GlobalPremiumBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.levelName != widget.levelName) {
      _style = EliteLevelEngine.getLevelStyle(
        EliteLevelEngine.parseLevelLabel(widget.levelName),
      );
    }

    if (_resolvedPulse) {
      if (!_controller.isAnimating) {
        _controller.repeat(reverse: true);
      }
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final levelInfo = _style;
    final hasPulseAnimation = _resolvedPulse;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: _resolvedColor, width: 1.5),
            boxShadow: hasPulseAnimation
                ? [
                    BoxShadow(
                      color: levelInfo.badgeBorder.withOpacity(
                        0.3 + (_animation.value * 0.4),
                      ),
                      blurRadius: 10 + (_animation.value * 18),
                      spreadRadius: 0 + (_animation.value * 4),
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: levelInfo.badgeBorder.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 0,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_resolvedIcon, color: _resolvedColor, size: 21),
              const SizedBox(width: 8),
              Text(
                (widget.userName ?? widget.levelName).trim(),
                style: TextStyle(
                  color: _resolvedColor,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (widget.showVerifiedIcon) ...[
                const SizedBox(width: 8),
                const Icon(Icons.verified, color: Color(0xFF1DA1F2), size: 21),
              ],
            ],
          ),
        );
      },
    );
  }
}
