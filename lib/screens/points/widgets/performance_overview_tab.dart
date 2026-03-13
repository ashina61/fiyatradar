import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/points_models.dart';
import 'points_palette.dart';

class PerformanceOverviewTab extends StatelessWidget {
  const PerformanceOverviewTab({super.key, required this.state});

  final PointsState state;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PerformanceHeader(displayName: _resolveDisplayName(state)),
          const SizedBox(height: 16),
          OverviewBentoSection(state: state),
          const SizedBox(height: 12),
          RankProgressCard(state: state),
          const SizedBox(height: 20),
          const _SectionTitle('Ayrıcalıkların'),
          const SizedBox(height: 12),
          const PrivilegeCardsSection(),
          const SizedBox(height: 18),
          const _SectionTitle('Puan Kazan'),
          const SizedBox(height: 12),
          MissionsGridSection(state: state),
        ],
      ),
    );
  }

  String _resolveDisplayName(PointsState data) {
    final fromLevel = data.currentLevelName.trim();
    if (fromLevel.isNotEmpty && fromLevel.length < 20) return fromLevel;
    return 'Radar Kullanıcısı';
  }
}

class PerformanceHeader extends StatelessWidget {
  const PerformanceHeader({super.key, required this.displayName});

  final String displayName;

  @override
  Widget build(BuildContext context) {
    final initials = displayName
        .split(' ')
        .where((e) => e.trim().isNotEmpty)
        .take(2)
        .map((e) => e.characters.first.toUpperCase())
        .join();

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: PointsPalette.textDark,
                  letterSpacing: -1,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Radar İstatistiklerin',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: PointsPalette.textMuted,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: PointsPalette.espresso,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x261A120E),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Text(
            initials.isEmpty ? 'FR' : initials,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: PointsPalette.bgApp,
            ),
          ),
        ),
      ],
    );
  }
}

class OverviewBentoSection extends StatelessWidget {
  const OverviewBentoSection({super.key, required this.state});

  final PointsState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 13,
          child: Container(
            height: 152,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: PointsPalette.espresso,
              borderRadius: BorderRadius.circular(32),
              boxShadow: const [
                BoxShadow(color: Color(0x261A120E), blurRadius: 30, offset: Offset(0, 16)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TOPLAM PUAN',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0x99FFFFFF), letterSpacing: 1),
                ),
                const Spacer(),
                Text(
                  NumberFormat.decimalPattern('tr_TR').format(state.totalPoints),
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1.5, height: 1),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 10,
          child: Column(
            children: [
              _MiniMetricCard(
                value: '${state.pointsThisWeek > 0 ? '+' : ''}${state.pointsThisWeek}',
                label: 'Bu Hafta',
                valueColor: state.pointsThisWeek >= 0 ? PointsPalette.green : Colors.red,
              ),
              const SizedBox(height: 12),
              _MiniMetricCard(
                value: '${state.trustTotalVotes}',
                label: 'Onaylı',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniMetricCard extends StatelessWidget {
  const _MiniMetricCard({required this.value, required this.label, this.valueColor = PointsPalette.textDark});

  final String value;
  final String label;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PointsPalette.boxWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x0D1A120E), blurRadius: 14, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: valueColor, letterSpacing: -0.8, height: 1.0)),
          const SizedBox(height: 4),
          Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: PointsPalette.textMuted, letterSpacing: 0.6)),
        ],
      ),
    );
  }
}

class RankProgressCard extends StatelessWidget {
  const RankProgressCard({super.key, required this.state});

  final PointsState state;

  @override
  Widget build(BuildContext context) {
    final pointsProgress = state.nextLevelTargetPoints <= 0 ? 0.0 : (state.totalPoints / state.nextLevelTargetPoints).clamp(0.0, 1.0);
    final trustProgress = state.requiredMinTrust <= 0 ? 0.0 : (state.trustScore / state.requiredMinTrust).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PointsPalette.camel,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [BoxShadow(color: Color(0x33B88A5B), blurRadius: 24, offset: Offset(0, 8))],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(state.finalLevelLabel, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: PointsPalette.espresso)),
                    const SizedBox(height: 4),
                    const Text('Her iki şartı tamamla, seviye atla.', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xB31A120E))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: PointsPalette.espresso, borderRadius: BorderRadius.circular(10)),
                child: Text('Hedef: ${state.nextLevelName}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: PointsPalette.camel)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ConditionProgress(
            title: 'Puan Şartı',
            detail: '${NumberFormat.compact(locale: 'tr_TR').format(state.totalPoints)} / ${NumberFormat.compact(locale: 'tr_TR').format(state.nextLevelTargetPoints)}',
            progress: pointsProgress,
            fillColor: PointsPalette.espresso,
          ),
          const SizedBox(height: 12),
          _ConditionProgress(
            title: 'Güven Şartı',
            detail: '%${state.trustScore} / Min %${state.requiredMinTrust}',
            progress: trustProgress,
            fillColor: const Color(0xFFEFECE6),
          ),
        ],
      ),
    );
  }
}

class _ConditionProgress extends StatelessWidget {
  const _ConditionProgress({required this.title, required this.detail, required this.progress, required this.fillColor});

  final String title;
  final String detail;
  final double progress;
  final Color fillColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: PointsPalette.espresso)),
            Text(detail, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: PointsPalette.espresso)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: const Color(0x1A1A120E),
            color: fillColor,
          ),
        ),
      ],
    );
  }
}

class PrivilegeCardsSection extends StatelessWidget {
  const PrivilegeCardsSection({super.key});

  @override
  Widget build(BuildContext context) {
    const privileges = [
      (title: 'Temel Fiyat Bildirimi', unlocked: true, icon: Icons.sell_rounded),
      (title: 'Özel Market Alarmları', unlocked: true, icon: Icons.notifications_active_rounded),
      (title: 'Geçmiş Fiyat Analizi', unlocked: false, icon: Icons.history_rounded),
    ];

    return SizedBox(
      height: 136,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final item = privileges[index];
          return _PrivilegeCard(title: item.title, unlocked: item.unlocked, icon: item.icon);
        },
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: privileges.length,
      ),
    );
  }
}

class _PrivilegeCard extends StatelessWidget {
  const _PrivilegeCard({required this.title, required this.unlocked, required this.icon});

  final String title;
  final bool unlocked;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 148,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PointsPalette.boxWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x0D1A120E), blurRadius: 15, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: unlocked ? PointsPalette.greenBg : const Color(0x141A120E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: unlocked ? PointsPalette.green : PointsPalette.textMuted),
          ),
          const SizedBox(height: 12),
          Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: PointsPalette.textDark)),
          const Spacer(),
          Row(
            children: [
              Icon(unlocked ? Icons.check_rounded : Icons.lock_outline_rounded, size: 12, color: unlocked ? PointsPalette.green : PointsPalette.textMuted),
              const SizedBox(width: 2),
              Text(unlocked ? 'Açık' : 'Kilitli', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: unlocked ? PointsPalette.green : PointsPalette.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

class MissionsGridSection extends StatelessWidget {
  const MissionsGridSection({super.key, required this.state});

  final PointsState state;

  @override
  Widget build(BuildContext context) {
    final fallback = <_MissionData>[
      const _MissionData(title: 'Fiyat Bildir', subtitle: '0/20 Tamamlandı', points: 5, icon: Icons.sell_rounded),
      const _MissionData(title: 'Doğrula', subtitle: '0/30 Tamamlandı', points: 2, icon: Icons.verified_rounded, isGreen: true),
      const _MissionData(title: 'Fotoğraf Ekle', subtitle: '0/10 Tamamlandı', points: 3, icon: Icons.photo_camera_rounded),
      const _MissionData(title: 'Admin Bonusu', subtitle: 'Özel Görev', points: 10, icon: Icons.bolt_rounded, isDarkBadge: true),
    ];

    final providerTasks = state.dailyGoals.take(3).map((goal) {
      final progress = goal.target <= 0 ? 'Özel Görev' : '${goal.current}/${goal.target} Tamamlandı';
      return _MissionData(title: goal.title, subtitle: progress, points: goal.reward, icon: goal.icon);
    }).toList();

    final tasks = providerTasks.isEmpty ? fallback : [...providerTasks, fallback.last];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tasks.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.08,
      ),
      itemBuilder: (context, index) => _MissionCard(data: tasks[index]),
    );
  }
}

class _MissionCard extends StatelessWidget {
  const _MissionCard({required this.data});

  final _MissionData data;

  @override
  Widget build(BuildContext context) {
    Color badgeBg() {
      if (data.isDarkBadge) return PointsPalette.espresso;
      if (data.isGreen) return PointsPalette.greenBg;
      return PointsPalette.goldBg;
    }

    Color badgeText() {
      if (data.isDarkBadge) return Colors.white;
      if (data.isGreen) return PointsPalette.green;
      return PointsPalette.camel;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PointsPalette.boxWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.transparent),
        boxShadow: const [BoxShadow(color: Color(0x0D1A120E), blurRadius: 15, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: badgeBg(), borderRadius: BorderRadius.circular(8)),
              child: Text('+${data.points} P', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: badgeText())),
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: PointsPalette.bgApp, borderRadius: BorderRadius.circular(10)),
            child: Icon(data.icon, size: 18, color: PointsPalette.espresso),
          ),
          const SizedBox(height: 12),
          Text(data.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: PointsPalette.textDark)),
          const SizedBox(height: 4),
          Text(data.subtitle, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: PointsPalette.textMuted)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: PointsPalette.textDark, letterSpacing: -0.5));
  }
}

class _MissionData {
  const _MissionData({
    required this.title,
    required this.subtitle,
    required this.points,
    required this.icon,
    this.isGreen = false,
    this.isDarkBadge = false,
  });

  final String title;
  final String subtitle;
  final int points;
  final IconData icon;
  final bool isGreen;
  final bool isDarkBadge;
}
