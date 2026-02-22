import 'package:flutter/material.dart';

class LevelConfigItem {
  const LevelConfigItem({
    required this.levelKey,
    required this.label,
    required this.minPoints,
    required this.minTrustGate,
    required this.gradient,
    required this.icon,
    required this.emoji,
  });

  final String levelKey;
  final String label;
  final int minPoints;
  final int minTrustGate;
  final List<Color> gradient;
  final IconData icon;
  final String emoji;
}

class LevelConfig {
  const LevelConfig._();

  static const int minVotesForTrust = 10;

  static const List<LevelConfigItem> levels = [
    LevelConfigItem(
      levelKey: 'gozlemci',
      label: 'Gözlemci',
      minPoints: 0,
      minTrustGate: 0,
      gradient: [Color(0xFFEDE0D4), Color(0xFFFFF8F0)],
      icon: Icons.visibility_rounded,
      emoji: '👁️',
    ),
    LevelConfigItem(
      levelKey: 'avci',
      label: 'Avcı',
      minPoints: 500,
      minTrustGate: 20,
      gradient: [Color(0xFFD4A574), Color(0xFFFFF1E0)],
      icon: Icons.track_changes_rounded,
      emoji: '🎯',
    ),
    LevelConfigItem(
      levelKey: 'tasarrufcu',
      label: 'Tasarrufçu',
      minPoints: 1500,
      minTrustGate: 40,
      gradient: [Color(0xFFC8956C), Color(0xFFF5EDE4)],
      icon: Icons.savings_rounded,
      emoji: '💰',
    ),
    LevelConfigItem(
      levelKey: 'marketUstasi',
      label: 'Market Ustası',
      minPoints: 3000,
      minTrustGate: 55,
      gradient: [Color(0xFF8D6E63), Color(0xFFE7C9A9)],
      icon: Icons.storefront_rounded,
      emoji: '🏪',
    ),
    LevelConfigItem(
      levelKey: 'fiyatLordu',
      label: 'Fiyat Lordu',
      minPoints: 5000,
      minTrustGate: 70,
      gradient: [Color(0xFF5D4037), Color(0xFFD4A574)],
      icon: Icons.workspace_premium_rounded,
      emoji: '👑',
    ),
    LevelConfigItem(
      levelKey: 'radarEfsanesi',
      label: 'Radar Efsanesi',
      minPoints: 8000,
      minTrustGate: 85,
      gradient: [Color(0xFFFFF1E0), Color(0xFFE7C9A9)],
      icon: Icons.auto_awesome_rounded,
      emoji: '✨',
    ),
  ];

  static const Map<String, int> trustThresholds = {
    'gozlemci': 0,
    'avci': 20,
    'tasarrufcu': 40,
    'marketUstasi': 55,
    'fiyatLordu': 70,
    'radarEfsanesi': 85,
  };
}
