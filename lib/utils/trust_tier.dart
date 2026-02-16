import 'package:flutter/material.dart';

class TrustTierInfo {
  const TrustTierInfo({
    required this.label,
    required this.emoji,
    required this.icon,
    required this.color,
  });

  final String label;
  final String emoji;
  final IconData icon;
  final Color color;
}

TrustTierInfo trustTierFromScore(int score) {
  final normalized = score.clamp(0, 100);
  if (normalized <= 19) {
    return const TrustTierInfo(
      label: 'Bronz',
      emoji: '🥉',
      icon: Icons.shield_outlined,
      color: Color(0xFF8D5A3A),
    );
  }
  if (normalized <= 39) {
    return const TrustTierInfo(
      label: 'Gümüş',
      emoji: '🥈',
      icon: Icons.workspace_premium_rounded,
      color: Color(0xFF8D99AE),
    );
  }
  if (normalized <= 59) {
    return const TrustTierInfo(
      label: 'Altın',
      emoji: '🥇',
      icon: Icons.workspace_premium_rounded,
      color: Color(0xFFC9A227),
    );
  }
  if (normalized <= 79) {
    return const TrustTierInfo(
      label: 'Platin',
      emoji: '🏅',
      icon: Icons.military_tech_rounded,
      color: Color(0xFF3F8EC4),
    );
  }

  return const TrustTierInfo(
    label: 'Elmas',
    emoji: '💎',
    icon: Icons.diamond_rounded,
    color: Color(0xFF4D72D9),
  );
}
