import 'package:flutter/material.dart';

import 'models/points_models.dart';

class PointsScreen extends StatelessWidget {
  const PointsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = PointsMockData.build();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: const Text(
          'Puanlar',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 24,
            color: Color(0xFF2F1D0A),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          children: [
            _TabSwitcher(),
            const SizedBox(height: 16),
            _ScoreOverviewCard(summary: data.summary),
            const SizedBox(height: 16),
            _GoalsSection(tasks: data.dailyTasks),
          ],
        ),
      ),
    );
  }
}

class _TabSwitcher extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F1E8),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: const Color(0xFFE3D4B6)),
      ),
      child: Row(
        children: const [
          Expanded(
            child: _TabChip(
              title: 'Genel Bakış',
              isSelected: true,
            ),
          ),
          Expanded(
            child: _TabChip(
              title: 'Zirvedekiler',
              isSelected: false,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({required this.title, required this.isSelected});

  final String title;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFC5913B) : Colors.transparent,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: isSelected ? Colors.white : const Color(0xFF6A5436),
        ),
      ),
    );
  }
}

class _ScoreOverviewCard extends StatelessWidget {
  const _ScoreOverviewCard({required this.summary});

  final PointsSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFD),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFCF7),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFE8DBC2)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF5ECDE),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFE2D1B0)),
              ),
              child: const Text(
                '✨ Prestij Skoru',
                style: TextStyle(
                  color: Color(0xFF8A6A31),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 22),
            _CircleScore(summary: summary),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FB),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFD6DAE3), width: 2),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shield_outlined, color: Color(0xFF9AB3C7), size: 32),
                  SizedBox(width: 10),
                  Text(
                    'STANDART',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 42 / 2,
                      color: Color(0xFF3E4A5D),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              '${summary.nextLevelRemaining} puan kaldı',
              style: const TextStyle(
                color: Color(0xFF5A4B34),
                fontSize: 19,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F0DE),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFE8D2A7)),
              ),
              child: const Text(
                'Bu hafta +47 puan kazandın',
                style: TextStyle(
                  color: Color(0xFF665033),
                  fontSize: 19,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleScore extends StatelessWidget {
  const _CircleScore({required this.summary});

  final PointsSummary summary;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 270,
            height: 270,
            child: CircularProgressIndicator(
              value: summary.progress,
              strokeWidth: 18,
              strokeCap: StrokeCap.round,
              backgroundColor: const Color(0xFFEEE2CB),
              color: const Color(0xFFD9A13F),
            ),
          ),
          Container(
            width: 230,
            height: 230,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF7E9),
              shape: BoxShape.circle,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${summary.totalPoints}',
                  style: const TextStyle(
                    fontSize: 74,
                    color: Color(0xFF2F1A06),
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Toplam Puan',
                  style: TextStyle(
                    fontSize: 22,
                    color: Color(0xFF655C4F),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalsSection extends StatelessWidget {
  const _GoalsSection({required this.tasks});

  final List<DailyTask> tasks;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Hedefler',
                style: TextStyle(
                  color: Color(0xFF31200E),
                  fontWeight: FontWeight.w700,
                  fontSize: 44 / 2,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9EED6),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFE0C48E)),
                ),
                child: const Text(
                  'Bugün',
                  style: TextStyle(
                    color: Color(0xFF7A5E2D),
                    fontWeight: FontWeight.w600,
                    fontSize: 17,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            itemCount: tasks.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: 190,
            ),
            itemBuilder: (context, index) => _GoalCard(task: tasks[index]),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.task});

  final DailyTask task;

  @override
  Widget build(BuildContext context) {
    final remaining = (task.target - task.current).clamp(0, task.target);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8D9BC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: task.iconBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(task.icon, size: 20, color: const Color(0xFF8B6A2D)),
          ),
          const SizedBox(height: 12),
          Text(
            task.title.replaceFirst('Fiyat Bildir', 'Bugün Fiyat').replaceFirst('Doğrula', 'Bugün Doğrulama').replaceFirst('Yorum Yap', 'Bugün Foto'),
            style: const TextStyle(
              color: Color(0xFF34210E),
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
            maxLines: 2,
          ),
          const Spacer(),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: task.progress,
              backgroundColor: const Color(0xFFF1E8D8),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFE2D3B4)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Kalan: $remaining',
                style: const TextStyle(
                  color: Color(0xFF6D6253),
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Text(
                '+${task.reward} puan',
                style: const TextStyle(
                  color: Color(0xFF8B6A2D),
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
