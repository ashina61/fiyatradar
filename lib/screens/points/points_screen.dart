import 'package:flutter/material.dart';

import 'models/points_models.dart';
import 'widgets/daily_task_tile.dart';
import 'widgets/level_tile.dart';
import 'widgets/points_header_card.dart';
import 'widgets/reward_tile.dart';

class PointsScreen extends StatelessWidget {
  const PointsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = PointsMockData.build();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('Puanlar', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: PointsHeaderCard(summary: data.summary),
            ),
          ),
          _SectionHeader(
            icon: Icons.calendar_month_rounded,
            title: 'Günlük Görevler',
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            sliver: SliverList.separated(
              itemCount: data.dailyTasks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => DailyTaskTile(task: data.dailyTasks[index]),
            ),
          ),
          _SectionHeader(
            icon: Icons.card_giftcard_rounded,
            title: 'Ödüller',
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            sliver: SliverList.separated(
              itemCount: data.rewards.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) => RewardTile(reward: data.rewards[index], onTap: () {}),
            ),
          ),
          _SectionHeader(
            icon: Icons.layers_rounded,
            title: 'Seviyeler',
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            sliver: SliverList.separated(
              itemCount: data.levels.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) => LevelTile(level: data.levels[index]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends SliverToBoxAdapter {
  _SectionHeader({required IconData icon, required String title})
      : super(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
            child: Row(
              children: [
                Icon(icon, size: 18, color: const Color(0xFF5A6472)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF121619),
                  ),
                ),
              ],
            ),
          ),
        );
}
