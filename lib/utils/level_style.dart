import 'package:flutter/material.dart';

import 'level_system.dart';

class LevelStyle {
  const LevelStyle._();

  static UserLevel fromTotalPoints(int totalPoints) => levelBuilder(totalPoints);

  static UserLevel fromLevelLabel(String? levelLabel, {int? fallbackTotalPoints}) {
    final raw = (levelLabel ?? '').trim();
    if (raw.isNotEmpty) {
      return levelFromLabel(raw);
    }
    return fromTotalPoints(fallbackTotalPoints ?? 0);
  }

  static Color colorForLabel(String? levelLabel, {int? fallbackTotalPoints}) {
    return fromLevelLabel(levelLabel, fallbackTotalPoints: fallbackTotalPoints).badgeForeground;
  }
}
