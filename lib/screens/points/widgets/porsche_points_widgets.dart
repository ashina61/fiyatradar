import 'package:flutter/material.dart';

import '../models/points_models.dart';

class AppColors {
  static const bgApp = Color(0xFFEFECE6);
  static const espresso = Color(0xFF1A120E);
  static const camel = Color(0xFFB88A5B);
  static const boxWhite = Color(0xFFFAFAFA);
  static const textDark = Color(0xFF1A120E);
  static const textMuted = Color(0xFF958B82);
  static const green = Color(0xFF27A85A);
}

class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({super.key, required this.selectedTab, required this.onChanged});
  final int selectedTab;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.espresso.withOpacity(0.06), borderRadius: BorderRadius.circular(999)),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _tab('Genel Bakış', 0),
          _tab('Zirvedekiler', 1),
        ],
      ),
    );
  }

  Widget _tab(String text, int index) {
    final active = index == selectedTab;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => onChanged(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? AppColors.espresso : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: active ? const [BoxShadow(color: Color(0x4D1A120E), blurRadius: 12, offset: Offset(0, 4))] : null,
          ),
          child: Text(text, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: active ? Colors.white : AppColors.textMuted)),
        ),
      ),
    );
  }
}

class BentoGridCard extends StatelessWidget {
  const BentoGridCard({super.key, required this.state});
  final PointsState state;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        flex: 13,
        child: Container(
          height: 142,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppColors.espresso, borderRadius: BorderRadius.circular(28), boxShadow: const [BoxShadow(color: Color(0x261A120E), blurRadius: 30, offset: Offset(0, 16))]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('TOPLAM PUAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0x99FFFFFF), letterSpacing: 1)),
            const Spacer(),
            Text('${state.totalPoints}', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1.5, height: 1)),
          ]),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        flex: 10,
        child: Column(children: [
          _mini('${state.pointsThisWeek > 0 ? '+' : ''}${state.pointsThisWeek}', 'Bu Hafta'),
          const SizedBox(height: 10),
          _mini('${state.trustTotalVotes}', 'Onaylı'),
        ]),
      ),
    ]);
  }

  Widget _mini(String value, String label) => Container(
        height: 66,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.boxWhite, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Color(0x0D1A120E), blurRadius: 14, offset: Offset(0, 4))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, letterSpacing: -1)),
          Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
        ]),
      );
}

class RankPodium extends StatelessWidget {
  const RankPodium({super.key, required this.state});
  final PointsState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.camel, borderRadius: BorderRadius.circular(26), boxShadow: const [BoxShadow(color: Color(0x33B88A5B), blurRadius: 24, offset: Offset(0, 8))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(state.currentLevelName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.4)),
        const SizedBox(height: 6),
        Text('Hedef: ${state.nextLevelName}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xB31A120E))),
      ]),
    );
  }
}

class PrivilegeCard extends StatelessWidget {
  const PrivilegeCard({super.key, required this.title, required this.unlocked, required this.icon});
  final String title;
  final bool unlocked;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.boxWhite, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Color(0x0D1A120E), blurRadius: 15, offset: Offset(0, 4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: unlocked ? AppColors.green : AppColors.textMuted),
        const SizedBox(height: 10),
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800), maxLines: 2, overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}

class MissionBox extends StatelessWidget {
  const MissionBox({super.key, required this.goal});
  final DailyTask goal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.boxWhite, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Color(0x0D1A120E), blurRadius: 15, offset: Offset(0, 4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('+${goal.reward} P', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.camel)),
        const Spacer(),
        Text(goal.title, style: const TextStyle(fontWeight: FontWeight.w800)),
        Text('${goal.current}/${goal.target} Tamamlandı', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ]),
    );
  }
}
