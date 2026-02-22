import 'package:flutter/material.dart';
import '../utils/level_system.dart';

class LevelBadge extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final fontSize = compact ? 10.0 : 11.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 7,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(colors: level.gradient),
        border: Border.all(color: level.borderColor.withOpacity(0.8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(level.icon, size: compact ? 12 : 15, color: level.textColor),
          SizedBox(width: compact ? 4 : 6),
          LevelFancyText(
            level: level,
            fontSize: fontSize,
            withEmoji: withEmoji,
            uppercase: uppercase,
          ),
        ],
      ),
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

    final baseStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.2,
      color: Colors.white, // gradient ile dolacak
    );

    // Outline paint (net premium)
    final outlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = level.badgeBorder.withOpacity(0.95);

    // 1) Outline layer
    final outline = Text(
      renderedText,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: baseStyle.copyWith(foreground: outlinePaint),
    );

    // 2) Glow layer
    final glow = Text(
      renderedText,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: baseStyle.copyWith(
        shadows: [
          Shadow(
            blurRadius: 10,
            color: level.badgeBorder.withOpacity(0.40),
            offset: const Offset(0, 2),
          ),
          Shadow(
            blurRadius: 18,
            color: level.badgeBorder.withOpacity(0.25),
            offset: const Offset(0, 0),
          ),
        ],
      ),
    );

    // 3) Gradient fill layer
    final fill = ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: level.gradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      child: Text(
        renderedText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: baseStyle,
      ),
    );

    return Stack(
      alignment: Alignment.centerLeft,
      children: [outline, glow, fill],
    );
  }
}
