import 'package:flutter/material.dart';

class UserLevel {
  const UserLevel({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.borderColor,
    required this.textColor,
    required this.minPoints,
    this.maxPoints,
  });

  final String label;
  final IconData icon;
  final List<Color> gradient;
  final Color borderColor;
  final Color textColor;
  final int minPoints;
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
  'Elmas': Color(0xFFC89B3C),
};

const List<UserLevel> kUserLevels = [
  UserLevel(
    label: 'Standart',
    icon: Icons.shield_outlined,
    gradient: [Color(0xFFF3F4F6), Color(0xFFE5E7EB)],
    borderColor: Color(0xFFD1D5DB),
    textColor: Color(0xFF374151),
    minPoints: 0,
    maxPoints: 500,
  ),
  UserLevel(
    label: 'Bronz',
    icon: Icons.workspace_premium_rounded,
    gradient: [Color(0xFFC48A62), Color(0xFF8D5A3A)],
    borderColor: Color(0xFF8D5A3A),
    textColor: Color(0xFFFFFFFF),
    minPoints: 500,
    maxPoints: 2000,
  ),
  UserLevel(
    label: 'Gümüş',
    icon: Icons.workspace_premium_rounded,
    gradient: [Color(0xFFE5E7EB), Color(0xFF9CA3AF)],
    borderColor: Color(0xFF9CA3AF),
    textColor: Color(0xFF111827),
    minPoints: 2000,
    maxPoints: 5000,
  ),
  UserLevel(
    label: 'Elmas',
    icon: Icons.diamond_rounded,
    gradient: [Color(0xFFF8E7A1), Color(0xFFC89B3C)],
    borderColor: Color(0xFFB8860B),
    textColor: Color(0xFF2F2204),
    minPoints: 5000,
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
