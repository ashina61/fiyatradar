import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../services/points_service.dart';
import '../../utils/theme.dart';
import '../add_price/add_price_screen.dart';
import '../auth/login_screen.dart';

final _pointsServiceProvider = Provider<PointsService>((ref) => PointsService());

class PointsScreen extends ConsumerStatefulWidget {
  const PointsScreen({super.key});

  @override
  ConsumerState<PointsScreen> createState() => _PointsScreenState();
}

class _PointsScreenState extends ConsumerState<PointsScreen> {
  final Set<String> _seenUnlocked = <String>{};
  bool _seeded = false;

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authStateProvider);
    return authAsync.when(
      data: (user) {
        if (user == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Puanlar')),
            body: Center(
              child: FilledButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                child: const Text('Puanlarını görmek için giriş yap'),
              ),
            ),
          );
        }
        final pointsService = ref.read(_pointsServiceProvider);
        return FutureBuilder<void>(
          future: pointsService.ensurePointsDefaultsSeeded(),
          builder: (context, seedSnap) {
            return Scaffold(
              appBar: AppBar(title: const Text('Puanlar')),
              body: SafeArea(
                child: StreamBuilder<UserPointsProfile>(
                  stream: pointsService.streamUserProfile(user.uid),
                  builder: (context, profileSnap) {
                    final profile = profileSnap.data;
                    return StreamBuilder<List<PointsRule>>(
                      stream: pointsService.streamPointsRules(),
                      builder: (context, rulesSnap) {
                        return StreamBuilder<List<PointsBadge>>(
                          stream: pointsService.streamBadges(user.uid),
                          builder: (context, badgeSnap) {
                            final badges = badgeSnap.data ?? const <PointsBadge>[];
                            _notifyBadgeUnlock(badges);
                            return StreamBuilder<List<PointsActivityItem>>(
                              stream: pointsService.streamActivity(user.uid),
                              builder: (context, activitySnap) {
                                final activities = activitySnap.data ?? const <PointsActivityItem>[];
                                return ListView(
                                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 120),
                                  children: [
                                    if (profile == null) const _SkeletonCard(height: 260) else _HeroCard(profile: profile, activities: activities),
                                    const SizedBox(height: AppSpacing.lg),
                                    _GoalsCard(
                                      profile: profile,
                                      activities: activities,
                                      onPriceGoalTap: _goToAddPrice,
                                    ),
                                    const SizedBox(height: AppSpacing.lg),
                                    _RulesCard(rules: rulesSnap.data ?? const []),
                                    const SizedBox(height: AppSpacing.lg),
                                    _BadgesCard(badges: badges),
                                    const SizedBox(height: AppSpacing.lg),
                                    _ActivityCard(activities: activities, onCtaTap: _goToAddPrice),
                                  ],
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            );
          },
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const Scaffold(body: SizedBox.shrink()),
    );
  }

  void _goToAddPrice() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPriceScreen()));
  }

  void _notifyBadgeUnlock(List<PointsBadge> badges) {
    if (!mounted) return;
    final unlocked = badges.where((e) => e.isUnlocked).toList();
    if (!_seeded) {
      _seenUnlocked.addAll(unlocked.map((e) => e.id));
      _seeded = true;
      return;
    }
    for (final badge in unlocked) {
      if (_seenUnlocked.add(badge.id)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          showDialog<void>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Yeni rozet kazandın!'),
              content: Text(badge.title),
            ),
          );
        });
      }
    }
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.profile, required this.activities});

  final UserPointsProfile profile;
  final List<PointsActivityItem> activities;

  @override
  Widget build(BuildContext context) {
    final weekly = activities.where((e) => e.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 7)))).fold<int>(0, (s, e) => s + e.points);
    return _SectionCard(
      child: Column(
        children: [
          SizedBox(
            height: 210,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 220,
                  height: 220,
                  child: CustomPaint(painter: _RingPainter(progress: profile.progress)),
                ),
                Transform.translate(
                  offset: const Offset(0, 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${profile.totalPoints}', style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w800, letterSpacing: -1)),
                      const Text('Puan', style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            alignment: WrapAlignment.center,
            children: [
              Chip(label: Text(profile.level)),
              if (profile.nextLevel != null)
                Chip(label: Text('Sonraki: ${profile.nextLevel!.title}')),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (profile.nextLevel != null)
            Text('Kalan: ${profile.remainingForNextLevel} puan', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            weekly == 0 ? 'Bu hafta henüz puan yok' : 'Bu hafta +$weekly puan',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _GoalsCard extends StatelessWidget {
  const _GoalsCard({required this.profile, required this.activities, required this.onPriceGoalTap});

  final UserPointsProfile? profile;
  final List<PointsActivityItem> activities;
  final VoidCallback onPriceGoalTap;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = activities.where((a) => a.createdAt.year == now.year && a.createdAt.month == now.month && a.createdAt.day == now.day);
    final price = today.where((a) => a.type == 'price_add').length;
    final verify = today.where((a) => a.type == 'verification').length;
    final weekStreak = _weekStreak(activities);

    return _SectionCard(
      title: 'Hedefler',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _GoalChip(title: 'Bugün Fiyat', progress: '$price/1', reward: '+5', onTap: onPriceGoalTap),
            const SizedBox(width: AppSpacing.sm),
            _GoalChip(title: 'Bugün Doğrulama', progress: '$verify/1', reward: '+2'),
            const SizedBox(width: AppSpacing.sm),
            _GoalChip(title: 'Hafta Seri', progress: '$weekStreak/7', reward: '+2'),
          ],
        ),
      ),
    );
  }

  int _weekStreak(List<PointsActivityItem> items) {
    final meaningful = items.where((e) => e.type == 'price_add' || e.type == 'verification').toList();
    final days = meaningful.map((e) => DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day)).toSet().length;
    return days.clamp(0, 7);
  }
}

class _RulesCard extends StatelessWidget {
  const _RulesCard({required this.rules});

  final List<PointsRule> rules;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Puan Nasıl Kazanılır?',
      child: rules.isEmpty
          ? const _PremiumEmpty(icon: Icons.auto_awesome, title: 'Kurallar hazırlanıyor', subtitle: 'Yeni görevler yakında burada görünecek.')
          : Column(
              children: rules
                  .map(
                    (e) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.bolt_rounded, color: AppColors.primary),
                      title: Text(e.title),
                      subtitle: Text(e.description),
                      trailing: Text('+${e.points}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _BadgesCard extends StatelessWidget {
  const _BadgesCard({required this.badges});

  final List<PointsBadge> badges;

  @override
  Widget build(BuildContext context) {
    final display = badges.isEmpty
        ? List<PointsBadge>.generate(
            5,
            (i) => const PointsBadge(
              id: 'locked',
              title: 'Kilitli',
              description: 'Yakında',
              iconKey: 'star',
              unlockCondition: '',
              isActive: true,
            ),
          )
        : badges;

    return _SectionCard(
      title: 'Başarılarım',
      child: SizedBox(
        height: 115,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, index) => _BadgeTile(badge: display[index]),
          separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
          itemCount: display.length,
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activities, required this.onCtaTap});

  final List<PointsActivityItem> activities;
  final VoidCallback onCtaTap;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Aktivite',
      child: activities.isEmpty
          ? Column(
              children: [
                const _PremiumEmpty(icon: Icons.local_fire_department_outlined, title: 'Henüz aktivite yok', subtitle: 'İlk katkınla puan yolculuğunu başlat.'),
                const SizedBox(height: AppSpacing.sm),
                FilledButton(onPressed: onCtaTap, child: const Text('İlk katkını yap')),
              ],
            )
          : Column(
              children: activities
                  .map(
                    (e) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(radius: 14, backgroundColor: AppColors.surfaceVariant, child: const Icon(Icons.bolt, size: 14)),
                      title: Text(_activityLabel(e.type)),
                      trailing: Text('+${e.points}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  String _activityLabel(String type) {
    switch (type) {
      case 'price_add':
        return 'Fiyat ekledin';
      case 'verification':
        return 'Doğrulama yaptın';
      case 'comment':
        return 'Yorum yaptın';
      case 'report_confirmed':
        return 'Bildirimin onaylandı';
      case 'invite_reward':
        return 'Arkadaş daveti ödülü';
      case 'streak_bonus':
        return 'Seri bonusu kazandın';
      default:
        return 'Katkı yaptın';
    }
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 14;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 16
      ..color = const Color(0xFFEFE5DB);
    final fill = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 16
      ..shader = const LinearGradient(colors: [Color(0xFFD4AF6D), Color(0xFFB8863B)]).createShader(rect);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, track);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * progress.clamp(0, 1), false, fill);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => oldDelegate.progress != progress;
}

class _GoalChip extends StatelessWidget {
  const _GoalChip({required this.title, required this.progress, required this.reward, this.onTap});

  final String title;
  final String progress;
  final String reward;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Ink(
        width: 150,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(AppRadius.lg)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(progress, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text(reward, style: const TextStyle(fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.badge});

  final PointsBadge badge;

  @override
  Widget build(BuildContext context) {
    final unlocked = badge.isUnlocked;
    return Container(
      width: 98,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: BackdropFilter(
          filter: unlocked ? ImageFilter.blur(sigmaX: 0, sigmaY: 0) : ImageFilter.blur(sigmaX: 1.2, sigmaY: 1.2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(unlocked ? Icons.workspace_premium_rounded : Icons.lock_outline, color: AppColors.primary),
              const SizedBox(height: 6),
              Text(unlocked ? badge.title : 'Kilitli', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              Text(unlocked ? 'Açıldı' : 'Yakında', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({this.title, required this.child});
  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: const [AppShadows.small],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title!, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.sm),
          ],
          child,
        ],
      ),
    );
  }
}

class _PremiumEmpty extends StatelessWidget {
  const _PremiumEmpty({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.secondaryDark),
        const SizedBox(height: AppSpacing.sm),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
      ],
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(AppRadius.xl)),
    );
  }
}
