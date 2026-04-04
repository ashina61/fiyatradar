import 'package:flutter/material.dart';

import 'elite_level_engine.dart';
import 'level_config.dart';

class UserLevel {
  const UserLevel({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.borderColor,
    required this.textColor,
    required this.minPoints,
    required this.emoji,
    required this.badgeBackground,
    required this.badgeForeground,
    required this.badgeBorder,
    this.maxPoints,
  });

  final String label;
  final IconData icon;
  final List<Color> gradient;
  final Color borderColor;
  final Color textColor;
  final int minPoints;
  final String emoji;
  final Color badgeBackground;
  final Color badgeForeground;
  final Color badgeBorder;
  final int? maxPoints;

  bool includes(int totalPoints) {
    if (totalPoints < minPoints) return false;
    if (maxPoints == null) return true;
    return totalPoints < maxPoints!;
  }

  factory UserLevel.fromEliteStyle(
    EliteLevelStyle style, {
    required int minPoints,
    int? maxPoints,
  }) {
    return UserLevel(
      label: style.label,
      icon: style.icon,
      gradient: style.gradient,
      borderColor: style.borderColor,
      textColor: style.textColor,
      minPoints: minPoints,
      maxPoints: maxPoints,
      emoji: style.emoji,
      badgeBackground: style.badgeBackground,
      badgeForeground: style.badgeForeground,
      badgeBorder: style.badgeBorder,
    );
  }
}

const Map<String, Color> levelColorMap = {
  'Gözlemci': Color(0xFF8D6E63),
  'Avcı': Color(0xFF9C6A3B),
  'Tasarrufçu': Color(0xFF8B5E3C),
  'Market Ustası': Color(0xFF6D4C41),
  'Fiyat Lordu': Color(0xFF5D4037),
  'Radar Efsanesi': Color(0xFFA67C52),
};

final List<UserLevel> kUserLevels = [
  for (var i = 0; i < LevelConfig.levels.length; i++)
    UserLevel.fromEliteStyle(
      EliteLevelEngine.getLevelStyle(EliteLevelEngine.parseLevelLabel(LevelConfig.levels[i].label)),
      minPoints: LevelConfig.levels[i].minPoints,
      maxPoints: i == LevelConfig.levels.length - 1 ? null : LevelConfig.levels[i + 1].minPoints,
    ),
];

UserLevel levelBuilder(int totalPoints) {
  final level = EliteLevelEngine.getPointsLevel(totalPoints);
  return UserLevel.fromEliteStyle(EliteLevelEngine.getLevelStyle(level), minPoints: 0);
}

UserLevel levelFromLabel(String name) {
  final normalized = name.trim().toLowerCase();
  final direct = kUserLevels.where((l) => l.label.trim().toLowerCase() == normalized);
  if (direct.isNotEmpty) return direct.first;

  final elite = EliteLevelEngine.parseLevelLabel(name);
  final style = EliteLevelEngine.getLevelStyle(elite);
  return UserLevel.fromEliteStyle(style, minPoints: 0);
}
