import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/elite_level_engine.dart';
import '../utils/level_style.dart';
import '../utils/level_system.dart';

@immutable
class UserIdentityProfile {
  const UserIdentityProfile({
    required this.userName,
    required this.level,
  });

  final String userName;
  final UserLevel level;

  bool get isElite => level.label == 'Fiyat Lordu' || level.label == 'Radar Efsanesi';
  bool get isRadarEfsanesi => level.label == 'Radar Efsanesi';
}

class UserIdentityRenderer extends StatelessWidget {
  const UserIdentityRenderer({
    super.key,
    required this.userProfile,
    this.fontSize = 14,
    this.scrollOffset = 0,
  });

  final UserIdentityProfile userProfile;
  final double fontSize;
  final double scrollOffset;

  @override
  Widget build(BuildContext context) {
    final eliteLevel = EliteLevelEngine.parseLevelLabel(userProfile.level.label);
    final visual = LevelStyle.fromLevel(eliteLevel);

    if (!userProfile.isElite) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: visual.accentColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: visual.accentColor.withOpacity(0.35)),
        ),
        child: Text(
          userProfile.userName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: userProfile.level.textColor.withOpacity(visual.textOpacity),
          ),
        ),
      );
    }

    return _EliteIdentityText(userProfile: userProfile, fontSize: fontSize, scrollOffset: scrollOffset, visual: visual);
  }
}

class _EliteIdentityText extends StatefulWidget {
  const _EliteIdentityText({
    required this.userProfile,
    required this.fontSize,
    required this.scrollOffset,
    required this.visual,
  });

  final UserIdentityProfile userProfile;
  final double fontSize;
  final double scrollOffset;
  final LevelVisualStyle visual;

  @override
  State<_EliteIdentityText> createState() => _EliteIdentityTextState();
}

class _EliteIdentityTextState extends State<_EliteIdentityText> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Duration(seconds: widget.userProfile.isRadarEfsanesi ? 10 : 9))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minOpacity = widget.userProfile.isRadarEfsanesi ? 0.06 : 0.04;
    final maxOpacity = widget.userProfile.isRadarEfsanesi ? 0.12 : 0.08;
    final gradient = widget.visual.gradient ?? widget.userProfile.level.gradient;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final wave = (math.sin(_controller.value * math.pi * 2) + 1) / 2;
        final moving = (widget.scrollOffset.abs() * 0.0008).clamp(0.0, 0.1);
        final opacity = ((minOpacity + ((maxOpacity - minOpacity) * wave)) * (1 - moving)).clamp(minOpacity * 0.9, maxOpacity);
        final scale = 1 + (widget.userProfile.isRadarEfsanesi ? 0.03 : 0.015) * wave;

        return Stack(
          alignment: Alignment.centerLeft,
          children: [
            Transform.scale(
              scale: scale,
              alignment: Alignment.centerLeft,
              child: Container(
                height: widget.fontSize * 1.7,
                margin: const EdgeInsets.only(left: 18),
                width: (widget.userProfile.userName.length * widget.fontSize * 0.56).clamp(50, 280).toDouble(),
                decoration: BoxDecoration(
                  color: widget.visual.accentColor.withOpacity(opacity),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: widget.visual.accentColor.withOpacity(opacity),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.userProfile.level.icon, size: widget.fontSize + 1, color: widget.visual.accentColor.withOpacity(0.95)),
                const SizedBox(width: 8),
                ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) => LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight).createShader(bounds),
                  child: Text(
                    widget.userProfile.userName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: widget.fontSize,
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
