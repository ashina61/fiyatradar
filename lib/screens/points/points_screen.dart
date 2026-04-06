// lib/screens/points/points_screen.dart
// GREENFIELD v2 — points/progression in the "Quiet Intelligence" language.
// Rejected: dark pill tabs, "Performans & Puanlar" heavy title, Porsche-themed widgets,
// espresso tab containers and heavy cards.
// UX goal: a progression dossier — big numeral, progress line, activity list.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/fr_ink.dart';
import 'controllers/points_controller.dart';
import 'models/points_models.dart';

class PointsScreen extends ConsumerWidget {
  const PointsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pointsStateProvider);

    return Scaffold(
      backgroundColor: FRInk.paper,
      body: SafeArea(
        bottom: false,
        child: async.when(
          loading: () => const _Loading(),
          error: (_, __) => const _Msg('Puan verisi yüklenemedi.'),
          data: (s) => _Body(state: s),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state});
  final PointsState state;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 120),
      children: [
        _TopBar(onClose: () => Navigator.of(context).maybePop()),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: FRInk.gutter),
          child: Text('SEVİYE', style: FRType.micro),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: FRInk.gutter),
          child: Text(state.currentLevelName, style: FRType.title),
        ),
        const SizedBox(height: 22),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: FRInk.gutter),
          child: Text('${state.totalPoints}', style: FRType.display.copyWith(fontSize: 64)),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: FRInk.gutter),
          child: Text('toplam puan', style: FRType.body.copyWith(color: FRInk.inkMute)),
        ),
        const SizedBox(height: 26),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: FRInk.gutter),
          child: _ProgressLine(
            progress: state.levelProgressPercent.clamp(0, 100) / 100,
            nextLabel: state.nextLevelName,
            remaining: state.pointsRemainingToNextLevel,
          ),
        ),
        const SizedBox(height: 30),
        const _SectionLabel('BU HAFTA'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: FRInk.gutter),
          child: Row(
            children: [
              _Stat(label: 'PUAN', value: '${state.pointsThisWeek}'),
              Container(width: 1, height: 38, color: FRInk.hairline),
              _Stat(label: 'SERİ', value: '${state.streakDays} gün'),
              Container(width: 1, height: 38, color: FRInk.hairline),
              _Stat(label: 'GÜVEN', value: '${state.trustScore}%'),
            ],
          ),
        ),
        const SizedBox(height: 30),
        const _SectionLabel('GÜNLÜK HEDEFLER'),
        if (state.dailyGoals.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: FRInk.gutter, vertical: 16),
            child: Text('Bugün için aktif hedef yok.', style: FRType.body),
          )
        else
          for (var i = 0; i < state.dailyGoals.length; i++) ...[
            _GoalRow(g: state.dailyGoals[i]),
            if (i != state.dailyGoals.length - 1) const FRHairline(indent: FRInk.gutter),
          ],
        const SizedBox(height: 30),
        const _SectionLabel('SON HAREKETLER'),
        if (state.activities.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: FRInk.gutter, vertical: 16),
            child: Text('Henüz bir kayıt yok.', style: FRType.body),
          )
        else
          for (var i = 0; i < state.activities.length; i++) ...[
            _ActivityRow(a: state.activities[i]),
            if (i != state.activities.length - 1) const FRHairline(indent: FRInk.gutter),
          ],
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onClose});
  final VoidCallback onClose;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(FRInk.gutter, 14, FRInk.gutter, 18),
      child: Row(
        children: [
          GestureDetector(
            onTap: onClose,
            child: const Icon(Icons.arrow_back_rounded, size: 24, color: FRInk.ink),
          ),
          const Spacer(),
          const Text('PUANLAR', style: FRType.micro),
          const Spacer(),
          const SizedBox(width: 24),
        ],
      ),
    );
  }
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({required this.progress, required this.nextLabel, required this.remaining});
  final double progress;
  final String nextLabel;
  final int remaining;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Stack(
            children: [
              Container(height: 6, color: FRInk.paperDeep),
              FractionallySizedBox(
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(height: 6, color: FRInk.saffron),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Sonraki seviye · $nextLabel — $remaining puan kaldı',
          style: FRType.body.copyWith(color: FRInk.inkMute, fontSize: 13),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(FRInk.gutter, 0, FRInk.gutter, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: FRType.micro),
          const SizedBox(height: 10),
          const FRHairline(),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Text(value, style: FRType.title.copyWith(fontSize: 22)),
            const SizedBox(height: 4),
            Text(label, style: FRType.micro),
          ],
        ),
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  const _GoalRow({required this.g});
  final DailyTask g;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FRInk.gutter, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(g.title, style: FRType.bodyStrong, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(g.description, style: FRType.body.copyWith(color: FRInk.inkMute, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '+${g.reward}',
            style: FRType.numeral.copyWith(color: FRInk.saffron),
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.a});
  final PointsActivity a;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FRInk.gutter, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.title, style: FRType.bodyStrong, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(
                  '${a.subtitle} · ${a.createdAt}',
                  style: FRType.body.copyWith(color: FRInk.inkMute, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            (a.points >= 0 ? '+' : '') + a.points.toString(),
            style: FRType.numeral.copyWith(
              color: a.points >= 0 ? FRInk.fall : FRInk.rise,
            ),
          ),
        ],
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) => const Center(
        child: SizedBox(
          width: 18, height: 18,
          child: CircularProgressIndicator(strokeWidth: 1.5, color: FRInk.ink),
        ),
      );
}

class _Msg extends StatelessWidget {
  const _Msg(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(FRInk.gutter),
          child: Text(text, style: FRType.body),
        ),
      );
}
