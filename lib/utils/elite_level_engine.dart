import 'package:flutter/material.dart';

import 'level_config.dart';

const int minVotesForTrust = LevelConfig.minVotesForTrust;

enum EliteLevel { gozlemci, avci, tasarrufcu, marketUstasi, fiyatLordu, radarEfsanesi }

enum TrustScoreStatus { enoughData, veriAz }

class EliteLevelStyle {
  const EliteLevelStyle({
    required this.level,
    required this.label,
    required this.emoji,
    required this.icon,
    required this.gradient,
    required this.borderColor,
    required this.textColor,
    required this.badgeBackground,
    required this.badgeForeground,
    required this.badgeBorder,
  });

  final EliteLevel level;
  final String label;
  final String emoji;
  final IconData icon;
  final List<Color> gradient;
  final Color borderColor;
  final Color textColor;
  final Color badgeBackground;
  final Color badgeForeground;
  final Color badgeBorder;
}

class TrustScoreSummary {
  const TrustScoreSummary({
    required this.verifiedTotal,
    required this.wrongTotal,
    required this.totalVotes,
    required this.trustPercent,
    required this.status,
  });

  final int verifiedTotal;
  final int wrongTotal;
  final int totalVotes;
  final int trustPercent;
  final TrustScoreStatus status;
}

class EliteLevelResult {
  const EliteLevelResult({
    required this.pointsLevel,
    required this.trustLevel,
    required this.finalLevel,
    required this.requiredMinTrust,
    required this.isTrustGated,
    required this.nextPointsLevel,
  });

  final EliteLevel pointsLevel;
  final EliteLevel trustLevel;
  final EliteLevel finalLevel;
  final int requiredMinTrust;
  final bool isTrustGated;
  final EliteLevel nextPointsLevel;
}

class EliteLevelEngine {
  const EliteLevelEngine._();

  static const Map<EliteLevel, String> _levelKeys = {
    EliteLevel.gozlemci: 'gozlemci',
    EliteLevel.avci: 'avci',
    EliteLevel.tasarrufcu: 'tasarrufcu',
    EliteLevel.marketUstasi: 'marketUstasi',
    EliteLevel.fiyatLordu: 'fiyatLordu',
    EliteLevel.radarEfsanesi: 'radarEfsanesi',
  };

  static EliteLevel _fromKey(String key) {
    return _levelKeys.entries.firstWhere((e) => e.value == key, orElse: () => _levelKeys.entries.first).key;
  }

  static List<LevelConfigItem> get _levels => LevelConfig.levels;

  static EliteLevel getPointsLevel(int totalPoints) {
    EliteLevel current = _fromKey(_levels.first.levelKey);
    for (final item in _levels) {
      if (totalPoints >= item.minPoints) {
        current = _fromKey(item.levelKey);
      }
    }
    return current;
  }

  static EliteLevel getTrustLevel(int trustPercent, int totalVotes) {
    final eligibleTrust = totalVotes < minVotesForTrust ? 0 : trustPercent.clamp(0, 100);
    EliteLevel current = _fromKey(_levels.first.levelKey);
    for (final item in _levels) {
      final threshold = LevelConfig.trustThresholds[item.levelKey] ?? 0;
      if (eligibleTrust >= threshold) {
        current = _fromKey(item.levelKey);
      }
    }
    return current;
  }

  static EliteLevelResult evaluate({required int totalPoints, required int trustPercent, required int totalVotes}) {
    final pointsLevel = getPointsLevel(totalPoints);
    final trustLevel = getTrustLevel(trustPercent, totalVotes);
    final pointsIndex = _levels.indexWhere((item) => _fromKey(item.levelKey) == pointsLevel);
    final trustIndex = _levels.indexWhere((item) => _fromKey(item.levelKey) == trustLevel);
    final finalIndex = pointsIndex < trustIndex ? pointsIndex : trustIndex;
    final nextPointsIndex = (pointsIndex + 1).clamp(0, _levels.length - 1).toInt();
    final nextPointsLevel = _fromKey(_levels[nextPointsIndex].levelKey);
    final requiredMinTrust = _levels[nextPointsIndex].minTrustGate;
    final effectiveTrust = totalVotes < minVotesForTrust ? 0 : trustPercent;
    final isTrustGated = pointsIndex < (_levels.length - 1) && (effectiveTrust < requiredMinTrust);

    return EliteLevelResult(
      pointsLevel: pointsLevel,
      trustLevel: trustLevel,
      finalLevel: _fromKey(_levels[finalIndex].levelKey),
      requiredMinTrust: requiredMinTrust,
      isTrustGated: isTrustGated,
      nextPointsLevel: nextPointsLevel,
    );
  }

  static EliteLevel getFinalLevel(int totalPoints, int trustPercent, int totalVotes) {
    return evaluate(totalPoints: totalPoints, trustPercent: trustPercent, totalVotes: totalVotes).finalLevel;
  }

  static TrustScoreSummary calculateTrust({required int verifiedTotal, required int wrongTotal}) {
    final totalVotes = verifiedTotal + wrongTotal;
    final raw = (verifiedTotal + 1) / (totalVotes + 2);
    final percent = (raw * 100).round().clamp(0, 100);
    return TrustScoreSummary(
      verifiedTotal: verifiedTotal,
      wrongTotal: wrongTotal,
      totalVotes: totalVotes,
      trustPercent: percent,
      status: totalVotes < minVotesForTrust ? TrustScoreStatus.veriAz : TrustScoreStatus.enoughData,
    );
  }

  static Gradient getLevelGradient(EliteLevel level, double trustScore, {bool locked = false}) {
    final style = getLevelStyle(level);
    final t = (trustScore.clamp(0, 100) / 100).toDouble();
    final adjusted = style.gradient.map((color) {
      final hsl = HSLColor.fromColor(color);
      final shifted = hsl
          .withSaturation((hsl.saturation + (0.12 * t)).clamp(0.0, 1.0))
          .withLightness((hsl.lightness + (0.10 * t)).clamp(0.0, 1.0));
      return Color.lerp(shifted.toColor(), const Color(0xFFFFBF7A), 0.06 * t)!;
    }).toList();

    return LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: locked ? adjusted.map((c) => c.withOpacity(0.55)).toList() : adjusted,
    );
  }

  static EliteLevelStyle getLevelStyle(EliteLevel level) {
    final item = _levels.firstWhere((it) => _fromKey(it.levelKey) == level);
    final isDark = level == EliteLevel.marketUstasi || level == EliteLevel.fiyatLordu;
    final border = Color.lerp(item.gradient.first, item.gradient.last, 0.55)!;
    return EliteLevelStyle(
      level: level,
      label: item.label,
      emoji: item.emoji,
      icon: item.icon,
      gradient: item.gradient,
      borderColor: border,
      textColor: isDark ? Colors.white : const Color(0xFF5D4037),
      badgeBackground: item.gradient.last.withOpacity(0.35),
      badgeForeground: const Color(0xFF5D4037),
      badgeBorder: border,
    );
  }

  static int minTrustForLevel(EliteLevel level) {
    return LevelConfig.trustThresholds[_levelKeys[level]] ?? 0;
  }

  static EliteLevel parseLevelLabel(String? raw, {EliteLevel fallback = EliteLevel.gozlemci}) {
    final normalized = (raw ?? '').trim().toLowerCase();
    for (final item in _levels) {
      if (item.label.toLowerCase() == normalized) return _fromKey(item.levelKey);
    }
    switch (normalized) {
      case 'standart':
      case 'standard':
      case 'bronz':
        return EliteLevel.gozlemci;
      case 'gümüş':
      case 'gumus':
        return EliteLevel.avci;
      case 'altın':
      case 'altin':
      case 'gold':
        return EliteLevel.tasarrufcu;
      case 'elmas':
      case 'diamond':
        return EliteLevel.radarEfsanesi;
      default:
        return fallback;
    }
  }
}
