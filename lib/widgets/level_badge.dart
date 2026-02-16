import 'package:flutter/material.dart';

import '../utils/level_system.dart';

class LevelBadge extends StatelessWidget {
  const LevelBadge({
    super.key,
    required this.level,
    this.compact = false,
  });

  final UserLevel level;
  final bool compact;

  @override
  Widget build(BuildContext context) {
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
          Text(
            level.label.toUpperCase(),
            style: TextStyle(
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
              color: level.textColor,
            ),
          ),
        ],
      ),
    );
  }
}
