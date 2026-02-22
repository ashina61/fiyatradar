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

  // yeni
  final bool withEmoji;
  final bool uppercase;

  @override
  Widget build(BuildContext context) {
    final fontSize = compact ? 10.0 : 11.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12, vertical: compact ? 4 : 7),
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
          _LevelFancyText(
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

class _LevelFancyText extends StatelessWidget {
  const _LevelFancyText({
    required this.level,
    required this.fontSize,
    required this.withEmoji,
    required this.uppercase,
  });

  final UserLevel level;
  final double fontSize;
  final bool withEmoji;
  final bool uppercase;

  String _emojiFor(UserLevel l) {
    // level_system.dart içinde enum ise switch yap; class ise label’dan yakala
    final s = l.label.toLowerCase();
    if (s.contains('elmas') || s.contains('diamond')) return '💎';
    if (s.contains('alt') || s.contains('gold')) return '👑';
    if (s.contains('güm') || s.contains('gum') || s.contains('silver')) return '🥈';
    if (s.contains('bronz') || s.contains('bronze')) return '🥉';
    return '🛡️';
  }

  @override
  Widget build(BuildContext context) {
    var text = withEmoji ? '${_emojiFor(level)} ${level.label}' : level.label;
    if (uppercase) text = text.toUpperCase();

    final baseStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.2,
      color: Colors.white, // shader ile dolacak
    );

    final outlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = level.borderColor.withOpacity(0.95);

    // 1) Outline
    final outline = Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: baseStyle.copyWith(foreground: outlinePaint),
    );

    // 2) Glow
    final glow = Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: baseStyle.copyWith(
        shadows: [
          Shadow(blurRadius: 10, color: level.borderColor.withOpacity(0.40), offset: const Offset(0, 2)),
          Shadow(blurRadius: 18, color: level.borderColor.withOpacity(0.25), offset: const Offset(0, 0)),
        ],
      ),
    );

    // 3) Gradient fill
    final gradientFill = ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: level.gradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: baseStyle,
      ),
    );

    return Stack(
      alignment: Alignment.centerLeft,
      children: [outline, glow, gradientFill],
    );
  }
}