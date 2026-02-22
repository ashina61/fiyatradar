import 'dart:ui';

import 'package:flutter/material.dart';
import '../utils/level_style.dart';
import '../utils/level_system.dart';

class LevelBadge extends StatefulWidget {
  const LevelBadge({
    super.key,
    required this.level,
    this.compact = false,
    this.withEmoji = true,
    this.uppercase = true,
  });

  final UserLevel level;
  final bool compact;

  final bool withEmoji;
  final bool uppercase;

  @override
  State<LevelBadge> createState() => _LevelBadgeState();
}

class _LevelBadgeState extends State<LevelBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  bool get _isFiyatLordu => widget.level.label == 'Fiyat Lordu';
  bool get _isRadarEfsanesi => widget.level.label == 'Radar Efsanesi';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _isRadarEfsanesi ? 2500 : 2000),
    );
    if (_isFiyatLordu || _isRadarEfsanesi) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant LevelBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.level.label == widget.level.label) return;

    if (_isFiyatLordu || _isRadarEfsanesi) {
      _controller
        ..duration = Duration(milliseconds: _isRadarEfsanesi ? 2500 : 2000)
        ..repeat(reverse: true);
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
    final fontSize = widget.compact ? 10.0 : 11.0;
    final baseColor = widget.level.badgeBorder;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final curveValue = Curves.easeInOut.transform(_controller.value);
        final glowBlur = _isFiyatLordu
            ? lerpDouble(10, 28, curveValue)!
            : _isRadarEfsanesi
                ? lerpDouble(8, 20, curveValue)!
                : 0.0;
        final glowOpacity = _isFiyatLordu
            ? lerpDouble(0.30, 0.75, curveValue)!
            : _isRadarEfsanesi
                ? lerpDouble(0.35, 0.85, curveValue)!
                : 0.0;

        final floatOffset = _isRadarEfsanesi ? lerpDouble(0, -3, curveValue)! : 0.0;

        return Transform.translate(
          offset: Offset(0, floatOffset),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 8 : 12,
              vertical: widget.compact ? 4 : 7,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              color: baseColor.withOpacity(0.1),
              border: Border.all(color: baseColor.withOpacity(0.8)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.16),
                  Colors.white.withOpacity(0.01),
                ],
              ),
              boxShadow: [
                if (_isFiyatLordu)
                  BoxShadow(
                    color: baseColor.withOpacity(glowOpacity),
                    blurRadius: glowBlur,
                  ),
                if (_isRadarEfsanesi)
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withOpacity(glowOpacity),
                    blurRadius: glowBlur,
                  ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.level.icon, size: widget.compact ? 12 : 15, color: _isRadarEfsanesi ? const Color(0xFF0097A7) : widget.level.textColor),
                SizedBox(width: widget.compact ? 4 : 6),
                LevelFancyText(
                  level: widget.level,
                  fontSize: fontSize,
                  withEmoji: widget.withEmoji,
                  uppercase: widget.uppercase,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class LevelFancyText extends StatelessWidget {
  const LevelFancyText({
    required this.level,
    required this.fontSize,
    required this.withEmoji,
    required this.uppercase,
    this.text,
  });

  final UserLevel level;
  final double fontSize;
  final bool withEmoji;
  final bool uppercase;
  final String? text;

  @override
  Widget build(BuildContext context) {
    var renderedText = text ?? (withEmoji ? '${level.emoji} ${level.label}' : level.label);
    if (uppercase) renderedText = renderedText.toUpperCase();

    final textColor = level.label == 'Radar Efsanesi'
        ? const Color(0xFF0097A7)
        : LevelStyle.readableTextColorForGradient(level.gradient);
    final baseStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.2,
      color: textColor,
      shadows: [
        Shadow(
          blurRadius: 6,
          color: level.badgeBorder.withOpacity(0.20),
          offset: const Offset(0, 1),
        ),
      ],
    );

    return Text(
      renderedText,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: baseStyle,
    );
  }
}
