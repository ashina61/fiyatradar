import 'package:flutter/material.dart';

enum LevelStatus { achieved, current, locked }

class PointsSummary {
  const PointsSummary({
    required this.totalPoints,
    required this.level,
    required this.levelName,
    required this.nextLevelRemaining,
    required this.progress,
  });

  final int totalPoints;
  final int level;
  final String levelName;
  final int nextLevelRemaining;
  final double progress;
}

@immutable
class PointsState {
  const PointsState({
    required this.totalPoints,
    required this.currentLevelName,
    required this.pointsThisWeek,
    required this.nextLevelTargetPoints,
    required this.streakDays,
    required this.levelProgressPercent,
    required this.pointsRemainingToNextLevel,
    required this.dailyGoals,
    required this.activities,
    required this.trustScore,
    required this.trustTotalVotes,
    required this.requiredMinTrust,
    required this.isTrustGated,
    required this.finalLevelLabel,
    required this.trustLabel,
    required this.nextLevelName,
  });

  final int totalPoints;
  final String currentLevelName;
  final int pointsThisWeek;
  final int nextLevelTargetPoints;
  final int streakDays;
  final double levelProgressPercent;
  final int pointsRemainingToNextLevel;
  final List<DailyTask> dailyGoals;
  final List<PointsActivity> activities;
  final int trustScore;
  final int trustTotalVotes;
  final int requiredMinTrust;
  final bool isTrustGated;
  final String finalLevelLabel;
  final String trustLabel;
  final String nextLevelName;

  static const PointsState placeholder = PointsState(
    totalPoints: 200,
    currentLevelName: 'Gözlemci',
    pointsThisWeek: 47,
    nextLevelTargetPoints: 300,
    streakDays: 3,
    levelProgressPercent: 0.38,
    pointsRemainingToNextLevel: 300,
    dailyGoals: [
      DailyTask(
        title: 'Fiyat Bildir',
        description: '2 fiyat bildirimi yap',
        reward: 20,
        current: 1,
        target: 2,
        icon: Icons.sell_rounded,
        iconBackground: Color(0xFFFFE7D1),
      ),
      DailyTask(
        title: 'Doğrula',
        description: '5 fiyatı doğrula',
        reward: 10,
        current: 3,
        target: 5,
        icon: Icons.verified_rounded,
        iconBackground: Color(0xFFDFF3FF),
      ),
      DailyTask(
        title: 'Yorum Yap',
        description: '1 ürüne yorum bırak',
        reward: 5,
        current: 0,
        target: 1,
        icon: Icons.chat_bubble_rounded,
        iconBackground: Color(0xFFEAE7FF),
      ),
    ],
    activities: [
      PointsActivity(
        type: 'price_entry',
        title: 'Fiyat bildirimi',
        subtitle: 'Migros • iPhone 15',
        points: 5,
        createdAt: 'Bugün',
      ),
      PointsActivity(
        type: 'price_verify',
        title: 'Fiyat doğrulaması',
        subtitle: 'CarrefourSA • Süt 1L',
        points: 2,
        createdAt: 'Dün',
      ),
    ],
    trustScore: 27,
    trustTotalVotes: 6,
    requiredMinTrust: 40,
    isTrustGated: true,
    finalLevelLabel: 'Avcı',
    trustLabel: 'Gelişen Güven',
    nextLevelName: 'Avcı',
  );
}

class PointsActivity {
  const PointsActivity({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.points,
    required this.createdAt,
  });

  final String type;
  final String title;
  final String subtitle;
  final int points;
  final String createdAt;
}

class DailyTask {
  const DailyTask({
    required this.title,
    required this.description,
    required this.reward,
    required this.current,
    required this.target,
    required this.icon,
    required this.iconBackground,
  });

  final String title;
  final String description;
  final int reward;
  final int current;
  final int target;
  final IconData icon;
  final Color iconBackground;

  double get progress => target == 0 ? 0 : (current / target).clamp(0, 1);
}

class RewardItem {
  const RewardItem({required this.title, required this.subtitle, required this.cost});

  final String title;
  final String subtitle;
  final int cost;
}

class LevelItem {
  const LevelItem({required this.name, required this.requiredPoints, required this.status});

  final String name;
  final int requiredPoints;
  final LevelStatus status;
}
