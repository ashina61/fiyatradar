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
