import 'package:flutter/material.dart';

import 'elite_level_engine.dart';

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
  'Standart': Color(0xFF6B7280),
  'Bronz': Color(0xFF8D5A3A),
  'Gümüş': Color(0xFF6B7280),
  'Altın': Color(0xFFC9A227),
  'Elmas': Color(0xFF1C6FB2),
};

final List<UserLevel> kUserLevels = [
  UserLevel.fromEliteStyle(
    EliteLevelEngine.getLevelStyle(EliteLevel.standart),
    minPoints: 0,
    maxPoints: 500,
  ),
  UserLevel.fromEliteStyle(
    EliteLevelEngine.getLevelStyle(EliteLevel.bronz),
    minPoints: 500,
    maxPoints: 2000,
  ),
  UserLevel.fromEliteStyle(
    EliteLevelEngine.getLevelStyle(EliteLevel.gumus),
    minPoints: 2000,
    maxPoints: 5000,
  ),
  UserLevel.fromEliteStyle(
    EliteLevelEngine.getLevelStyle(EliteLevel.elmas),
    minPoints: 5000,
  ),
];

UserLevel levelBuilder(int totalPoints) {
  final level = EliteLevelEngine.getPointsLevel(totalPoints);
  switch (level) {
    case EliteLevel.standart:
      return kUserLevels[0];
    case EliteLevel.bronz:
      return kUserLevels[1];
    case EliteLevel.gumus:
      return kUserLevels[2];
    case EliteLevel.altin:
      return UserLevel.fromEliteStyle(
        EliteLevelEngine.getLevelStyle(EliteLevel.altin),
        minPoints: 2000,
        maxPoints: 5000,
      );
    case EliteLevel.elmas:
      return kUserLevels[3];
  }
}

/// ✅ Label'dan level çekme (UI tarafında “ELMAS / Elmas / elmas” hepsini çözer)
UserLevel levelFromLabel(String name) {
  final normalized = name.trim().toLowerCase();

  // 1) Önce mevcut listeden label eşleşmesi (min/max korunsun)
  final direct = kUserLevels.where((l) => l.label.trim().toLowerCase() == normalized);
  if (direct.isNotEmpty) return direct.first;

  // 2) Elite engine parse ile (altın gibi listede olmayanları da yakalar)
  final elite = EliteLevelEngine.parseLevelLabel(name);
  final style = EliteLevelEngine.getLevelStyle(elite);

  // minPoints burada sadece UI için; engine seviyeyi zaten doğru parse etti
  return UserLevel.fromEliteStyle(style, minPoints: 0);
}