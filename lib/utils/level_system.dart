import 'package:flutter/material.dart';

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
}

const Map<String, Color> levelColorMap = {
  'Standart': Color(0xFF6B7280),
  'Bronz': Color(0xFF8D5A3A),
  'Gümüş': Color(0xFF6B7280),
  'Elmas': Color(0xFF1C6FB2),
};

const List<UserLevel> kUserLevels = [
  UserLevel(
    label: 'Standart',
    icon: Icons.shield_outlined,
    gradient: [Color(0xFFF3F4F6), Color(0xFFE5E7EB)],
    borderColor: Color(0xFFD1D5DB),
    textColor: Color(0xFF374151),
    minPoints: 0,
    emoji: '🛡️',
    badgeBackground: Color(0xFFF4F5F6),
    badgeForeground: Color(0xFF4B5563),
    badgeBorder: Color(0xFFD5D9DE),
    maxPoints: 500,
  ),
  UserLevel(
    label: 'Bronz',
    icon: Icons.workspace_premium_rounded,
    gradient: [Color(0xFFC48A62), Color(0xFF8D5A3A)],
    borderColor: Color(0xFF8D5A3A),
    textColor: Color(0xFFFFFFFF),
    minPoints: 500,
    emoji: '🥉',
    badgeBackground: Color(0xFFF7EBE2),
    badgeForeground: Color(0xFF8D5A3A),
    badgeBorder: Color(0xFFD5B39B),
    maxPoints: 2000,
  ),
  UserLevel(
    label: 'Gümüş',
    icon: Icons.workspace_premium_rounded,
    gradient: [Color(0xFFE5E7EB), Color(0xFF9CA3AF)],
    borderColor: Color(0xFF9CA3AF),
    textColor: Color(0xFF111827),
    minPoints: 2000,
    emoji: '🥈',
    badgeBackground: Color(0xFFF1F5F9),
    badgeForeground: Color(0xFF60748B),
    badgeBorder: Color(0xFFC8D1DE),
    maxPoints: 5000,
  ),
  UserLevel(
    label: 'Elmas',
    icon: Icons.diamond_rounded,
    gradient: [Color(0xFFE8F4FF), Color(0xFFB7DFFF)],
    borderColor: Color(0xFF7DB9E8),
    textColor: Color(0xFF144B78),
    minPoints: 5000,
    emoji: '💎',
    badgeBackground: Color(0xFFE9F4FF),
    badgeForeground: Color(0xFF1C6FB2),
    badgeBorder: Color(0xFF8EC4EB),
  ),
];

UserLevel levelBuilder(int totalPoints) {
  for (final level in kUserLevels) {
    if (level.includes(totalPoints)) {
      return level;
    }
  }
  return kUserLevels.first;
}

UserLevel levelFromLabel(String name) {
  final normalized = name.trim().toLowerCase();
  return kUserLevels.firstWhere(
    (level) => level.label.toLowerCase() == normalized,
    orElse: () => kUserLevels.first,
  );
}
