import 'package:flutter/material.dart';

import '../models/product.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/design.dart';

class LevelInfo {
  final String name;
  final String emoji;
  final int minPoints;
  final int? maxPoints;
  final Color color;

  const LevelInfo({
    required this.name,
    required this.emoji,
    required this.minPoints,
    this.maxPoints,
    required this.color,
  });
}

const levels = [
  LevelInfo(
    name: 'Gözlemci',
    emoji: '👁️',
    minPoints: 0,
    maxPoints: 99,
    color: Color(0xFF9E9E9E),
  ),
  LevelInfo(
    name: 'Avcı',
    emoji: '🎯',
    minPoints: 100,
    maxPoints: 299,
    color: Color(0xFF8D6E63),
  ),
  LevelInfo(
    name: 'Tasarrufçu',
    emoji: '💡',
    minPoints: 300,
    maxPoints: 699,
    color: Color(0xFF2E7D32),
  ),
  LevelInfo(
    name: 'Market Ustası',
    emoji: '⭐',
    minPoints: 700,
    maxPoints: 1499,
    color: Color(0xFF1565C0),
  ),
  LevelInfo(
    name: 'Fiyat Lordu',
    emoji: '🔥',
    minPoints: 1500,
    maxPoints: 2999,
    color: Color(0xFF7B1FA2),
  ),
  LevelInfo(
    name: 'Radar Efsanesi',
    emoji: '💎',
    minPoints: 3000,
    maxPoints: null,
    color: Color(0xFFB07B4F),
  ),
];

LevelInfo currentLevel(int points) {
  for (var i = levels.length - 1; i >= 0; i--) {
    if (points >= levels[i].minPoints) return levels[i];
  }
  return levels.first;
}

LevelInfo? nextLevel(int points) {
  final cur = currentLevel(points);
  final idx = levels.indexOf(cur);
  if (idx < levels.length - 1) return levels[idx + 1];
  return null;
}

double levelProgress(int points) {
  final cur = currentLevel(points);
  final next = nextLevel(points);
  if (next == null) return 1.0;
  final rangeStart = cur.minPoints;
  final rangeEnd = next.minPoints;
  return ((points - rangeStart) / (rangeEnd - rangeStart)).clamp(0.0, 1.0);
}

class PointsScreen extends StatelessWidget {
  const PointsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final points = state.points;
    final level = currentLevel(points);
    final nextLvl = nextLevel(points);
    final progress = levelProgress(points);
    final int toNext =
        nextLvl == null ? 0 : (nextLvl.minPoints - points).clamp(0, 1 << 30);

    final pointNotifications = state.notifications
        .where(
          (n) => ('${n.title} ${n.body}').toLowerCase().contains('puan'),
        )
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Puanlar'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          _HeroSummary(
            points: points,
            level: level,
            nextLevel: nextLvl,
            toNext: toNext,
            progress: progress,
          ),
          const SizedBox(height: 14),
          _LevelSystemCard(activeLevel: level),
          const SizedBox(height: 14),
          const _EarnPointsCard(),
          const SizedBox(height: 14),
          _PointsHistoryCard(history: pointNotifications),
          const SizedBox(height: 14),
          const _InfoCard(),
        ],
      ),
    );
  }
}

class _HeroSummary extends StatelessWidget {
  const _HeroSummary({
    required this.points,
    required this.level,
    required this.nextLevel,
    required this.toNext,
    required this.progress,
  });

  final int points;
  final LevelInfo level;
  final LevelInfo? nextLevel;
  final int toNext;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: CoffeeColors.espresso,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: CoffeeColors.espresso.withOpacity(0.25),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PUAN ÖZETİ',
            style: TextStyle(
              color: CoffeeColors.latte,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$points puan',
            style: const TextStyle(
              color: CoffeeColors.cream,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${level.emoji} ${level.name}',
            style: TextStyle(
              color: Color.lerp(level.color, Colors.white, 0.45),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.14),
              valueColor: const AlwaysStoppedAnimation<Color>(CoffeeColors.caramel),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            nextLevel == null
                ? 'En yüksek seviyedesin. Katkıların topluluğu büyütüyor.'
                : '$toNext puan sonra ${nextLevel!.emoji} ${nextLevel!.name} seviyesine geçersin.',
            style: const TextStyle(
              color: CoffeeColors.latte,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelSystemCard extends StatelessWidget {
  const _LevelSystemCard({required this.activeLevel});

  final LevelInfo activeLevel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CoffeeColors.crema),
        boxShadow: FR.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Seviye Sistemi',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: CoffeeColors.espresso,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          ...levels.map((level) {
            final isActive = level.name == activeLevel.name;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isActive ? level.color.withOpacity(0.10) : CoffeeColors.foam,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isActive ? level.color.withOpacity(0.45) : CoffeeColors.crema,
                ),
              ),
              child: Row(
                children: [
                  Text(level.emoji, style: const TextStyle(fontSize: 15)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      level.name,
                      style: TextStyle(
                        color: CoffeeColors.espresso,
                        fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    level.maxPoints == null
                        ? '${level.minPoints}+'
                        : '${level.minPoints}-${level.maxPoints}',
                    style: TextStyle(
                      color: isActive ? level.color : CoffeeColors.cocoa,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _EarnPointsCard extends StatelessWidget {
  const _EarnPointsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CoffeeColors.crema),
        boxShadow: FR.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Puan Kazanma Yolları',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: CoffeeColors.espresso,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          _rewardRow(Icons.add_circle_outline, 'Fiyat ekle', '+${PointsRules.addPrice} puan'),
          _rewardRow(Icons.inventory_2_outlined, 'Yeni ürün ekle', '+${PointsRules.addProduct} puan'),
          _rewardRow(Icons.favorite_border, 'Favorilere ekle', '+${PointsRules.favorite} puan'),
          _rewardRow(Icons.login_outlined, 'Günlük giriş', '+${PointsRules.dailyLogin} puan'),
        ],
      ),
    );
  }
}

class _PointsHistoryCard extends StatelessWidget {
  const _PointsHistoryCard({required this.history});

  final List<AppNotification> history;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CoffeeColors.crema),
        boxShadow: FR.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Puan Geçmişi',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: CoffeeColors.espresso,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          if (history.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: CoffeeColors.foam,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Henüz puan hareketi görünmüyor. İlk katkından sonra burada listelenecek.',
                style: TextStyle(color: CoffeeColors.cocoa, fontSize: 12, height: 1.4),
              ),
            )
          else
            ...history.take(10).map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: CoffeeColors.foam,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.stars_rounded,
                          color: CoffeeColors.caramel, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              color: CoffeeColors.espresso,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.body,
                            style: const TextStyle(
                              color: CoffeeColors.cocoa,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: CoffeeColors.foam,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CoffeeColors.crema),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: CoffeeColors.cocoa, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '100 puan = ₺5 değerinde',
              style: TextStyle(
                color: CoffeeColors.cocoa,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _rewardRow(IconData icon, String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Icon(icon, size: 16, color: CoffeeColors.darkRoast),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: CoffeeColors.espresso,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: CoffeeColors.caramel.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: const TextStyle(
              color: CoffeeColors.caramel,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
      ],
    ),
  );
}
