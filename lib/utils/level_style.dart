import 'package:flutter/material.dart';

import 'elite_level_engine.dart';
import 'level_system.dart';

@immutable
class LevelVisualStyle {
  const LevelVisualStyle({
    required this.accentColor,
    required this.gradient,
    required this.textOpacity,
    required this.glowOpacity,
    required this.elevationLevel,
  });

  final Color accentColor;
  final List<Color>? gradient;
  final double textOpacity;
  final double glowOpacity;
  final int elevationLevel;

  bool get isElite => gradient != null;
}

class LevelStyle {
  const LevelStyle._();

  static UserLevel fromTotalPoints(int totalPoints) => levelBuilder(totalPoints);

  static LevelVisualStyle fromLevel(EliteLevel level) {
    switch (level) {
      case EliteLevel.gozlemci:
        return const LevelVisualStyle(
          accentColor: Color(0xFFC29D75),
          gradient: null,
          textOpacity: 0.90,
          glowOpacity: 0,
          elevationLevel: 1,
        );
      case EliteLevel.avci:
        return const LevelVisualStyle(
          accentColor: Color(0xFFD28A4E),
          gradient: null,
          textOpacity: 0.90,
          glowOpacity: 0,
          elevationLevel: 1,
        );
      case EliteLevel.tasarrufcu:
        return const LevelVisualStyle(
          accentColor: Color(0xFFB97D52),
          gradient: null,
          textOpacity: 0.90,
          glowOpacity: 0,
          elevationLevel: 1,
        );
      case EliteLevel.marketUstasi:
        return const LevelVisualStyle(
          accentColor: Color(0xFFA86B45),
          gradient: null,
          textOpacity: 0.90,
          glowOpacity: 0,
          elevationLevel: 2,
        );
      case EliteLevel.fiyatLordu:
        return const LevelVisualStyle(
          accentColor: Color(0xFFD9A86A),
          gradient: [Color(0xFFCE9558), Color(0xFFE3B374), Color(0xFFB97A45)],
          textOpacity: 0.90,
          glowOpacity: 0.06,
          elevationLevel: 3,
        );
      case EliteLevel.radarEfsanesi:
        return const LevelVisualStyle(
          accentColor: Color(0xFFE3B77B),
          gradient: [Color(0xFFE5C18D), Color(0xFFF4D6A3), Color(0xFFC88A4E)],
          textOpacity: 0.90,
          glowOpacity: 0.10,
          elevationLevel: 4,
        );
    }
  }

  static UserLevel fromEliteLevel(EliteLevel level) {
    return UserLevel.fromEliteStyle(EliteLevelEngine.getLevelStyle(level), minPoints: 0);
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

  static LevelVisualStyle visualFromLabel(String? levelLabel, {int? fallbackTotalPoints}) {
    final elite = EliteLevelEngine.parseLevelLabel(levelLabel, fallback: EliteLevelEngine.getPointsLevel(fallbackTotalPoints ?? 0));
    return fromLevel(elite);
  }

  static Color colorForLabel(String? levelLabel, {int? fallbackTotalPoints}) {
    return fromLevelLabel(levelLabel, fallbackTotalPoints: fallbackTotalPoints).badgeForeground;
  }

  static Color readableTextColorForGradient(List<Color> colors) {
    final surface = Color.lerp(colors.first, colors.last, 0.5) ?? colors.first;
    return surface.computeLuminance() > 0.48 ? Colors.black87 : Colors.white;
  }
}
