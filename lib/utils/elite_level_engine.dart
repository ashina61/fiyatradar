import 'package:flutter/material.dart';

const int minVotesForTrust = 10;

enum EliteLevel { standart, bronz, gumus, altin, elmas }

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

class EliteLevelEngine {
  const EliteLevelEngine._();

  static const Map<EliteLevel, int> _rank = {
    EliteLevel.standart: 1,
    EliteLevel.bronz: 2,
    EliteLevel.gumus: 3,
    EliteLevel.altin: 4,
    EliteLevel.elmas: 5,
  };

  static EliteLevel getPointsLevel(int totalPoints) {
    if (totalPoints >= 5000) return EliteLevel.elmas;
    if (totalPoints >= 2000) return EliteLevel.gumus;
    if (totalPoints >= 500) return EliteLevel.bronz;
    return EliteLevel.standart;
  }

  static EliteLevel getTrustLevel(int trustPercent, int totalVotes) {
    if (totalVotes < minVotesForTrust || trustPercent < 40) return EliteLevel.standart;
    if (trustPercent >= 80) return EliteLevel.elmas;
    if (trustPercent >= 60) return EliteLevel.altin;
    if (trustPercent >= 40) return EliteLevel.bronz;
    return EliteLevel.standart;
  }

  static EliteLevel getFinalLevel(int totalPoints, int trustPercent, int totalVotes) {
    final pointsLevel = getPointsLevel(totalPoints);
    final trustLevel = getTrustLevel(trustPercent, totalVotes);
    return _rank[pointsLevel]! <= _rank[trustLevel]! ? pointsLevel : trustLevel;
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

  static EliteLevelStyle getLevelStyle(EliteLevel level) {
    switch (level) {
      case EliteLevel.standart:
        return const EliteLevelStyle(
          level: EliteLevel.standart,
          label: 'Standart',
          emoji: '🛡️',
          icon: Icons.shield_outlined,
          gradient: [Color(0xFFF3F4F6), Color(0xFFE5E7EB)],
          borderColor: Color(0xFFD1D5DB),
          textColor: Color(0xFF374151),
          badgeBackground: Color(0xFFF4F5F6),
          badgeForeground: Color(0xFF4B5563),
          badgeBorder: Color(0xFFD5D9DE),
        );
      case EliteLevel.bronz:
        return const EliteLevelStyle(
          level: EliteLevel.bronz,
          label: 'Bronz',
          emoji: '🥉',
          icon: Icons.workspace_premium_rounded,
          gradient: [Color(0xFFC48A62), Color(0xFF8D5A3A)],
          borderColor: Color(0xFF8D5A3A),
          textColor: Color(0xFFFFFFFF),
          badgeBackground: Color(0xFFF7EBE2),
          badgeForeground: Color(0xFF8D5A3A),
          badgeBorder: Color(0xFFD5B39B),
        );
      case EliteLevel.gumus:
        return const EliteLevelStyle(
          level: EliteLevel.gumus,
          label: 'Gümüş',
          emoji: '🥈',
          icon: Icons.workspace_premium_rounded,
          gradient: [Color(0xFFE5E7EB), Color(0xFF9CA3AF)],
          borderColor: Color(0xFF9CA3AF),
          textColor: Color(0xFF111827),
          badgeBackground: Color(0xFFF1F5F9),
          badgeForeground: Color(0xFF60748B),
          badgeBorder: Color(0xFFC8D1DE),
        );
      case EliteLevel.altin:
        return const EliteLevelStyle(
          level: EliteLevel.altin,
          label: 'Altın',
          emoji: '🥇',
          icon: Icons.workspace_premium_rounded,
          gradient: [Color(0xFFFFE7A3), Color(0xFFE1B12C)],
          borderColor: Color(0xFFC9A227),
          textColor: Color(0xFF5F4500),
          badgeBackground: Color(0xFFFFF7D6),
          badgeForeground: Color(0xFF876300),
          badgeBorder: Color(0xFFE3C46A),
        );
      case EliteLevel.elmas:
        return const EliteLevelStyle(
          level: EliteLevel.elmas,
          label: 'Elmas',
          emoji: '💎',
          icon: Icons.diamond_rounded,
          gradient: [Color(0xFFE8F4FF), Color(0xFFB7DFFF)],
          borderColor: Color(0xFF7DB9E8),
          textColor: Color(0xFF144B78),
          badgeBackground: Color(0xFFE9F4FF),
          badgeForeground: Color(0xFF1C6FB2),
          badgeBorder: Color(0xFF8EC4EB),
        );
    }
  }

  static EliteLevel parseLevelLabel(String? raw, {EliteLevel fallback = EliteLevel.standart}) {
    final normalized = (raw ?? '').trim().toLowerCase();
    switch (normalized) {
      case 'bronz':
      case 'bronze':
        return EliteLevel.bronz;
      case 'gümüş':
      case 'gumus':
      case 'silver':
        return EliteLevel.gumus;
      case 'altın':
      case 'altin':
      case 'gold':
        return EliteLevel.altin;
      case 'elmas':
      case 'diamond':
        return EliteLevel.elmas;
      case 'standart':
      case 'yeni':
      case 'standard':
        return EliteLevel.standart;
      default:
        return fallback;
    }
  }
}
