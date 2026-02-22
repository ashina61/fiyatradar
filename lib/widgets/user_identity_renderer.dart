import 'dart:math' as math;

import 'package:flutter/material.dart';

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
    if (!userProfile.isElite) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: userProfile.level.badgeBackground.withOpacity(0.22),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: userProfile.level.badgeBorder.withOpacity(0.75)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(userProfile.level.emoji, style: TextStyle(fontSize: fontSize)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                userProfile.userName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  color: userProfile.level.textColor,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return _EliteIdentityText(
      userProfile: userProfile,
      fontSize: fontSize,
      scrollOffset: scrollOffset,
    );
  }
}

class _EliteIdentityText extends StatefulWidget {
  const _EliteIdentityText({
    required this.userProfile,
    required this.fontSize,
    required this.scrollOffset,
  });

  final UserIdentityProfile userProfile;
  final double fontSize;
  final double scrollOffset;

  @override
  State<_EliteIdentityText> createState() => _EliteIdentityTextState();
}

class _EliteIdentityTextState extends State<_EliteIdentityText> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.userProfile.isRadarEfsanesi ? 10 : 8),
    )..repeat(reverse: true);
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
    final glowColor = const Color(0xFFB28758);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final wave = (math.sin(_controller.value * math.pi * 2) + 1) / 2;
        final opacity = minOpacity + ((maxOpacity - minOpacity) * wave);
        final scale = 1 + (widget.userProfile.isRadarEfsanesi ? 0.03 : 0.015) * wave;
        final yParallax = (widget.scrollOffset % 60) / 60;
        return Stack(
          alignment: Alignment.centerLeft,
          children: [
            Transform.translate(
              offset: Offset(0, yParallax * 2),
              child: Transform.scale(
                scale: scale,
                alignment: Alignment.centerLeft,
                child: Container(
                  height: widget.fontSize * 1.8,
                  margin: const EdgeInsets.only(left: 18),
                  width: (widget.userProfile.userName.length * widget.fontSize * 0.58).clamp(50, 280).toDouble(),
                  decoration: BoxDecoration(
                    color: glowColor.withOpacity(opacity),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: glowColor.withOpacity(opacity),
                        blurRadius: 18,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.userProfile.level.emoji, style: TextStyle(fontSize: widget.fontSize)),
                const SizedBox(width: 8),
                ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) => LinearGradient(
                    colors: widget.userProfile.level.gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: Text(
                    widget.userProfile.userName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: widget.fontSize,
                      fontWeight: FontWeight.w800,
                      shadows: [
                        Shadow(
                          color: glowColor.withOpacity(opacity * 0.8),
                          blurRadius: 9,
                        ),
                      ],
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
