import 'dart:ui';

import 'package:flutter/material.dart';
import '../utils/elite_level_engine.dart';
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

class _LevelBadgeState extends State<LevelBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  bool get _isFiyatLordu => widget.level.label == 'Fiyat Lordu';
  bool get _isRadarEfsanesi => widget.level.label == 'Radar Efsanesi';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _isRadarEfsanesi ? 2600 : 2100),
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
        ..duration = Duration(milliseconds: _isRadarEfsanesi ? 2600 : 2100)
        ..repeat(reverse: true);
    } else {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  ({Color color, Color textColor, IconData icon, bool softShadow, bool pulse, bool float})
      _styleFor(UserLevel levelData) {
    final eliteLevel = EliteLevelEngine.parseLevelLabel(levelData.label);
    return (
      color: levelData.badgeBorder,
      textColor: levelData.textColor,
      icon: levelData.icon,
      softShadow: eliteLevel == EliteLevel.avci ||
          eliteLevel == EliteLevel.tasarrufcu ||
          eliteLevel == EliteLevel.marketUstasi,
      pulse: eliteLevel == EliteLevel.fiyatLordu || eliteLevel == EliteLevel.radarEfsanesi,
      float: eliteLevel == EliteLevel.radarEfsanesi,
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(widget.level);
    var labelText = widget.withEmoji ? '${widget.level.emoji} ${widget.level.label}' : widget.level.label;
    if (widget.uppercase) labelText = labelText.toUpperCase();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_controller.value);
        final glowBlur = style.pulse ? lerpDouble(8, 24, t)! : 0.0;
        final spread = style.pulse ? lerpDouble(0.3, 2.2, t)! : 0.0;
        final glowOpacity = style.pulse ? lerpDouble(0.24, 0.50, t)! : 0.0;
        final floatY = style.float ? lerpDouble(0, -3, t)! : 0.0;

        return Transform.translate(
          offset: Offset(0, floatY),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              color: style.color.withOpacity(0.12),
              border: Border.all(color: style.color.withOpacity(0.8), width: 1.5),
              boxShadow: [
                if (style.softShadow)
                  BoxShadow(
                    color: style.color.withOpacity(widget.level.label == 'Market Ustası' ? 0.28 : 0.18),
                    blurRadius: widget.level.label == 'Market Ustası' ? 15 : 10,
                    spreadRadius: widget.level.label == 'Market Ustası' ? 0.7 : 0,
                  ),
                if (style.pulse)
                  BoxShadow(
                    color: style.color.withOpacity(glowOpacity),
                    blurRadius: glowBlur,
                    spreadRadius: spread,
                  ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(style.icon, size: 18, color: style.color),
                const SizedBox(width: 6),
                Text(
                  labelText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: style.textColor,
                    letterSpacing: 0.2,
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

class LevelFancyText extends StatelessWidget {
  const LevelFancyText({
    required this.level,
    required this.fontSize,
    required this.withEmoji,
    required this.uppercase,
    this.text,
    super.key,
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

    final color = level.label == 'Radar Efsanesi' ? const Color(0xFF0097A7) : level.badgeBorder;

    return Text(
      renderedText,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.2,
        color: color,
      ),
    );
  }
}
