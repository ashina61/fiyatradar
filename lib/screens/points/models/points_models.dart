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

class PointsMockData {
  const PointsMockData({required this.summary, required this.dailyTasks, required this.rewards, required this.levels});

  final PointsSummary summary;
  final List<DailyTask> dailyTasks;
  final List<RewardItem> rewards;
  final List<LevelItem> levels;

  factory PointsMockData.build() {
    return const PointsMockData(
      summary: PointsSummary(
        totalPoints: 200,
        level: 2,
        levelName: 'Standart',
        nextLevelRemaining: 300,
        progress: 0.38,
      ),
      dailyTasks: [
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
      rewards: [
        RewardItem(title: 'Aylık Çekiliş', subtitle: '500 puan ile katıl', cost: 500),
        RewardItem(title: 'Hediye Kartı', subtitle: '1000 puan ile kazan', cost: 1000),
        RewardItem(title: 'VIP Rozet', subtitle: '2000 puan ile özel rozet', cost: 2000),
        RewardItem(title: 'Market İndirimi', subtitle: '3000 puan ile %5 indirim', cost: 3000),
      ],
      levels: [
        LevelItem(name: 'Başlangıç', requiredPoints: 0, status: LevelStatus.achieved),
        LevelItem(name: 'Keşifçi', requiredPoints: 200, status: LevelStatus.achieved),
        LevelItem(name: 'Katkıcı', requiredPoints: 400, status: LevelStatus.current),
        LevelItem(name: 'Uzman', requiredPoints: 600, status: LevelStatus.locked),
        LevelItem(name: 'Usta', requiredPoints: 800, status: LevelStatus.locked),
        LevelItem(name: 'Efsane', requiredPoints: 1000, status: LevelStatus.locked),
        LevelItem(name: 'Lider', requiredPoints: 1400, status: LevelStatus.locked),
        LevelItem(name: 'Şampiyon', requiredPoints: 1800, status: LevelStatus.locked),
        LevelItem(name: 'Efsanevi', requiredPoints: 2400, status: LevelStatus.locked),
        LevelItem(name: 'Titan', requiredPoints: 3200, status: LevelStatus.locked),
      ],
    );
  }
}
