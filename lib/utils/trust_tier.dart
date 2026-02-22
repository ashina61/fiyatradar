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
  if (normalized < 20) {
    return const TrustTierInfo(
      label: 'Temkinli Güven',
      emoji: '🛡️',
      icon: Icons.shield_outlined,
      color: Color(0xFF8D6E63),
    );
  }
  if (normalized < 40) {
    return const TrustTierInfo(
      label: 'Gelişen Güven',
      emoji: '🔰',
      icon: Icons.security_rounded,
      color: Color(0xFF9E7B60),
    );
  }
  if (normalized < 80) {
    return const TrustTierInfo(
      label: 'Güvenilir Radar',
      emoji: '✅',
      icon: Icons.verified_user_rounded,
      color: Color(0xFF7A5A46),
    );
  }

  return const TrustTierInfo(
    label: 'Elite Güven',
    emoji: '👑',
    icon: Icons.workspace_premium_rounded,
    color: Color(0xFF5D4037),
  );
}
