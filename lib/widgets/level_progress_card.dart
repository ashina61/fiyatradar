import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'premium_level_badge.dart';

class LevelProgressCard extends StatefulWidget {
  const LevelProgressCard({
    super.key,
    required this.currentLevelName,
    required this.nextLevelName,
    required this.currentScore,
    required this.targetScore,
    required this.currentTrustPercentage,
    required this.targetTrustPercentage,
    required this.isTrustGated,
  });

  final String currentLevelName;
  final String nextLevelName;
  final int currentScore;
  final int targetScore;
  final double currentTrustPercentage;
  final double targetTrustPercentage;
  final bool isTrustGated;

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
    final scoreRate = widget.targetScore <= 0 ? 0.0 : (widget.currentScore / widget.targetScore).clamp(0.0, 1.0);
    final currentTrust = _asRate(widget.currentTrustPercentage);
    final targetTrust = _asRate(widget.targetTrustPercentage);
    final trustRate = targetTrust <= 0 ? 1.0 : (currentTrust / targetTrust).clamp(0.0, 1.0);
    final remainingScore = math.max(0, widget.targetScore - widget.currentScore);

    final trustUnlocked = !widget.isTrustGated || currentTrust >= targetTrust;
    final trustGradient = trustUnlocked
        ? const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)])
        : const LinearGradient(colors: [Color(0xFFC62828), Color(0xFFEF5350)]);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
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
            color: const Color(0xFFB8A99A).withOpacity(0.26),
            offset: const Offset(12, 12),
            blurRadius: 26,
          ),
          const BoxShadow(
            color: Color(0xCCFFFFFF),
            offset: Offset(-6, -6),
            blurRadius: 18,
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -10,
            bottom: -20,
            child: Transform.rotate(
              angle: -15 * math.pi / 180,
              child: Icon(
                visual.icon,
                size: 150,
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
                  Expanded(child: PremiumLevelBadge(levelName: widget.currentLevelName)),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Toplam Puan',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1, color: Color(0xFFA69587)),
                      ),
                      Text(
                        _formatScore(widget.currentScore),
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, height: 1.1, color: Color(0xFF4A3623)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 30),
              _ProgressGroup(
                title: 'Seviye İlerlemesi',
                leftValue: _formatScore(widget.currentScore),
                rightValue: _formatScore(widget.targetScore),
                progress: _animateFill ? scoreRate : 0,
                fillGradient: LinearGradient(colors: [visual.color.withOpacity(0.75), visual.color]),
                fillShadowColor: visual.color.withOpacity(0.4),
                hintText: 'Sonraki seviyeye +${_formatScore(remainingScore)} Puan',
                trailingText: 'SONRAKİ SEVİYE: ${widget.nextLevelName.toUpperCase()}',
                trailingColor: const Color(0xFFA69587),
              ),
              const SizedBox(height: 22),
              _ProgressGroup(
                title: 'Güven Skoru',
                leftValue: '%${(currentTrust * 100).round()}',
                rightValue: 'Min %${(targetTrust * 100).round()}',
                progress: _animateFill ? trustRate : 0,
                fillGradient: trustGradient,
                fillShadowColor: trustUnlocked
                    ? const Color(0xFF66BB6A).withOpacity(0.4)
                    : const Color(0xFFEF5350).withOpacity(0.4),
                hintText: trustUnlocked
                    ? 'Bu seviye için güven şartı sağlandı'
                    : 'Sonraki seviye için minimum güven şartı sağlanmalı',
                hintColor: trustUnlocked ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                trailingText: trustUnlocked ? 'UNLOCKED / AÇIK' : 'GATED',
                trailingColor: trustUnlocked ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
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
    required this.trailingText,
    required this.trailingColor,
    this.hintColor = const Color(0xFF8C7A6B),
  });

  final String title;
  final String leftValue;
  final String rightValue;
  final double progress;
  final LinearGradient fillGradient;
  final Color fillShadowColor;
  final String hintText;
  final String trailingText;
  final Color trailingColor;
  final Color hintColor;

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
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF4A3623)),
            ),
            RichText(
              text: TextSpan(
                text: leftValue,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF4A3623)),
                children: [
                  TextSpan(
                    text: ' / $rightValue',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFA69587)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 16,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: const Color(0xFFE9E2DB),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.65),
                offset: const Offset(0, -1),
                blurRadius: 3,
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Align(
                alignment: Alignment.centerLeft,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 1300),
                  curve: Curves.easeOutCubic,
                  width: constraints.maxWidth * progress.clamp(0.0, 1.0),
                  decoration: BoxDecoration(
                    gradient: fillGradient,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: fillShadowColor,
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                hintText,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: hintColor),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: trailingColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: trailingColor.withOpacity(0.45)),
              ),
              child: Text(
                trailingText,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: trailingColor),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
