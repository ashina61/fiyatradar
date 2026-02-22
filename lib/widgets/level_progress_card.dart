import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

class UserLevelBadge extends StatefulWidget {
  const UserLevelBadge({super.key, required this.levelName});

  final String levelName;

  @override
  State<UserLevelBadge> createState() => _UserLevelBadgeState();
}

class _UserLevelBadgeState extends State<UserLevelBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.levelName == 'Radar Efsanesi' ? 2500 : 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  ({Color baseColor, Color textColor, IconData icon, bool softShadow, bool pulse})
      _badgeStyle() {
    switch (widget.levelName) {
      case 'Gözlemci':
        return (
          baseColor: const Color(0xFF8C7A6B),
          textColor: const Color(0xFF8C7A6B),
          icon: Icons.visibility,
          softShadow: false,
          pulse: false,
        );
      case 'Avcı':
        return (
          baseColor: const Color(0xFFF4511E),
          textColor: const Color(0xFFF4511E),
          icon: Icons.my_location,
          softShadow: true,
          pulse: false,
        );
      case 'Tasarrufçu':
        return (
          baseColor: const Color(0xFF1E88E5),
          textColor: const Color(0xFF1E88E5),
          icon: Icons.savings,
          softShadow: true,
          pulse: false,
        );
      case 'Market Ustası':
        return (
          baseColor: const Color(0xFFFFB300),
          textColor: const Color(0xFFFFB300),
          icon: Icons.storefront,
          softShadow: true,
          pulse: false,
        );
      case 'Fiyat Lordu':
        return (
          baseColor: const Color(0xFFE040FB),
          textColor: const Color(0xFFE040FB),
          icon: Icons.military_tech,
          softShadow: false,
          pulse: true,
        );
      case 'Radar Efsanesi':
        return (
          baseColor: const Color(0xFF00E5FF),
          textColor: const Color(0xFF0097A7),
          icon: Icons.diamond,
          softShadow: false,
          pulse: true,
        );
      default:
        return (
          baseColor: const Color(0xFF8C7A6B),
          textColor: const Color(0xFF8C7A6B),
          icon: Icons.visibility,
          softShadow: false,
          pulse: false,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _badgeStyle();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final pulse = Curves.easeInOut.transform(_controller.value);
        final glowBlur = style.pulse
            ? lerpDouble(10, widget.levelName == 'Radar Efsanesi' ? 20 : 28, pulse)!
            : 0.0;
        final glowOpacity = style.pulse
            ? lerpDouble(0.3, widget.levelName == 'Radar Efsanesi' ? 0.8 : 0.75, pulse)!
            : 0.0;
        final floatOffset = style.pulse ? lerpDouble(0, -3, pulse)! : 0.0;

        return Transform.translate(
          offset: Offset(0, floatOffset),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              color: style.baseColor.withOpacity(
                widget.levelName == 'Market Ustası' ? 0.08 : 0.1,
              ),
              border: Border.all(
                color: style.baseColor.withOpacity(style.pulse ? 0.8 : 0.5),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0),
                ],
              ),
              boxShadow: [
                if (style.softShadow)
                  BoxShadow(
                    color: style.baseColor.withOpacity(
                      widget.levelName == 'Market Ustası' ? 0.3 : 0.15,
                    ),
                    blurRadius: widget.levelName == 'Market Ustası' ? 15 : 10,
                  ),
                if (style.pulse)
                  BoxShadow(
                    color: style.baseColor.withOpacity(glowOpacity),
                    blurRadius: glowBlur,
                  ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(style.icon, size: 20, color: style.baseColor),
                const SizedBox(width: 8),
                Text(
                  widget.levelName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: style.textColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class LevelProgressCard extends StatefulWidget {
  const LevelProgressCard({
    super.key,
    required this.currentLevelName,
    required this.nextLevelName,
    required this.currentScore,
    required this.targetScore,
    required this.currentTrustPercentage,
    required this.targetTrustPercentage,
  });

  final String currentLevelName;
  final String nextLevelName;
  final int currentScore;
  final int targetScore;
  final double currentTrustPercentage;
  final double targetTrustPercentage;

  @override
  State<LevelProgressCard> createState() => _LevelProgressCardState();
}

class _LevelProgressCardState extends State<LevelProgressCard> {
  bool _animateFill = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _animateFill = true);
    });
  }

  ({Color color, IconData icon}) _levelVisual() {
    switch (widget.currentLevelName) {
      case 'Gözlemci':
        return (color: const Color(0xFF8C7A6B), icon: Icons.visibility);
      case 'Avcı':
        return (color: const Color(0xFFF4511E), icon: Icons.my_location);
      case 'Tasarrufçu':
        return (color: const Color(0xFF1E88E5), icon: Icons.savings);
      case 'Market Ustası':
        return (color: const Color(0xFFFFB300), icon: Icons.storefront);
      case 'Fiyat Lordu':
        return (color: const Color(0xFFE040FB), icon: Icons.military_tech);
      case 'Radar Efsanesi':
        return (color: const Color(0xFF00E5FF), icon: Icons.diamond);
      default:
        return (color: const Color(0xFF8C7A6B), icon: Icons.visibility);
    }
  }

  double _asRate(double value) => value <= 1 ? value.clamp(0, 1) : (value / 100).clamp(0, 1);

  String _formatScore(int value) {
    final text = value.toString();
    final chars = text.split('').reversed.toList();
    final buffer = StringBuffer();
    for (var i = 0; i < chars.length; i++) {
      if (i > 0 && i % 3 == 0) buffer.write('.');
      buffer.write(chars[i]);
    }
    return buffer.toString().split('').reversed.join();
  }

  @override
  Widget build(BuildContext context) {
    final visual = _levelVisual();
    final scoreRate =
        widget.targetScore <= 0 ? 0.0 : (widget.currentScore / widget.targetScore).clamp(0.0, 1.0);
    final currentTrust = _asRate(widget.currentTrustPercentage);
    final targetTrust = _asRate(widget.targetTrustPercentage);
    final trustRate = targetTrust <= 0 ? 1.0 : (currentTrust / targetTrust).clamp(0.0, 1.0);
    final remainingScore = math.max(0, widget.targetScore - widget.currentScore);

    return Container(
      width: 340,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFF8F5F1)],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB8A99A).withOpacity(0.4),
            offset: const Offset(20, 20),
            blurRadius: 40,
          ),
          const BoxShadow(
            color: Color(0xCCFFFFFF),
            offset: Offset(-10, -10),
            blurRadius: 30,
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -20,
            bottom: -30,
            child: Transform.rotate(
              angle: -15 * math.pi / 180,
              child: Icon(
                visual.icon,
                size: 200,
                color: const Color(0xFF4A3623).withOpacity(0.03),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: UserLevelBadge(levelName: widget.currentLevelName)),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Toplam Puan',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                          color: Color(0xFFA69587),
                        ),
                      ),
                      Text(
                        _formatScore(widget.currentScore),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                          color: Color(0xFF4A3623),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 35),
              _ProgressGroup(
                title: 'Seviye İlerlemesi',
                leftValue: _formatScore(widget.currentScore),
                rightValue: _formatScore(widget.targetScore),
                progress: _animateFill ? scoreRate : 0,
                fillGradient: LinearGradient(colors: [visual.color.withOpacity(0.75), visual.color]),
                fillShadowColor: visual.color.withOpacity(0.5),
                hintText: 'Sonraki seviyeye +${_formatScore(remainingScore)} Puan',
                nextLevelName: widget.nextLevelName,
              ),
              const SizedBox(height: 25),
              _ProgressGroup(
                title: 'Güven Skoru',
                leftValue: '%${(currentTrust * 100).round()}',
                rightValue: 'Min %${(targetTrust * 100).round()}',
                progress: _animateFill ? trustRate : 0,
                fillGradient: const LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
                ),
                fillShadowColor: const Color(0xFF66BB6A).withOpacity(0.4),
                hintText: currentTrust >= targetTrust
                    ? 'Bu seviye için güven şartı sağlandı'
                    : 'Sonraki seviyeye güven şartı: Min %${(targetTrust * 100).round()}',
                nextLevelName: widget.nextLevelName,
                isTrust: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressGroup extends StatelessWidget {
  const _ProgressGroup({
    required this.title,
    required this.leftValue,
    required this.rightValue,
    required this.progress,
    required this.fillGradient,
    required this.fillShadowColor,
    required this.hintText,
    required this.nextLevelName,
    this.isTrust = false,
  });

  final String title;
  final String leftValue;
  final String rightValue;
  final double progress;
  final LinearGradient fillGradient;
  final Color fillShadowColor;
  final String hintText;
  final String nextLevelName;
  final bool isTrust;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF4A3623),
              ),
            ),
            RichText(
              text: TextSpan(
                text: leftValue,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF4A3623),
                ),
                children: [
                  TextSpan(
                    text: ' / $rightValue',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFA69587),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFFEBE5DF),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8C7A6B).withOpacity(0.15),
                offset: const Offset(0, 3),
                blurRadius: 6,
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.7),
                offset: const Offset(0, -2),
                blurRadius: 4,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.03),
                        Colors.transparent,
                        Colors.white.withOpacity(0.35),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedFractionallySizedBox(
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeOutCubic,
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: fillGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: fillShadowColor,
                            offset: const Offset(0, 3),
                            blurRadius: isTrust ? 10 : 15,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                hintText,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isTrust && hintText.contains('sağlandı')
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFF8C7A6B),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFA69587).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'SONRAKİ SEVİYE: $nextLevelName',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFA69587),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
