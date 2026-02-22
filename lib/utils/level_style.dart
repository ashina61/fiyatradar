import 'package:flutter/material.dart';

import 'elite_level_engine.dart';
import 'level_system.dart';

class LevelStyle {
  const LevelStyle._();

  static UserLevel fromTotalPoints(int totalPoints) => levelBuilder(totalPoints);

  static UserLevel fromLevel(EliteLevel level) {
    return UserLevel.fromEliteStyle(EliteLevelEngine.getLevelStyle(level), minPoints: 0);
  }

  static UserLevel fromEliteLevel(EliteLevel level) {
    return fromLevel(level);
  }

  static UserLevel fromFinalLevel({required int totalPoints, required int trustPercent, required int totalVotes}) {
    final level = EliteLevelEngine.getFinalLevel(totalPoints, trustPercent, totalVotes);
    return fromEliteLevel(level);
  }

  static UserLevel fromLevelLabel(String? levelLabel, {int? fallbackTotalPoints}) {
    final raw = (levelLabel ?? '').trim();
    if (raw.isNotEmpty) {
      final elite = EliteLevelEngine.parseLevelLabel(raw, fallback: EliteLevelEngine.getPointsLevel(fallbackTotalPoints ?? 0));
      return fromEliteLevel(elite);
    }
    return fromTotalPoints(fallbackTotalPoints ?? 0);
  }

  static Color colorForLabel(String? levelLabel, {int? fallbackTotalPoints}) {
    return fromLevelLabel(levelLabel, fallbackTotalPoints: fallbackTotalPoints).badgeForeground;
  }

  static Color readableTextColorForGradient(List<Color> gradient) {
    final surface = Color.lerp(gradient.first, gradient.last, 0.5) ?? gradient.first;
    final whiteContrast = _contrastRatio(surface, Colors.white);
    final blackContrast = _contrastRatio(surface, Colors.black87);
    final winner = whiteContrast >= blackContrast ? Colors.white : Colors.black87;
    return winner.withOpacity(0.92);
  }

  static double _contrastRatio(Color a, Color b) {
    final first = a.computeLuminance();
    final second = b.computeLuminance();
    final maxL = first > second ? first : second;
    final minL = first > second ? second : first;
    return (maxL + 0.05) / (minL + 0.05);
  }
}
