import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/auth_provider.dart';
import '../../services/points_service.dart';
import '../../utils/theme.dart';
import '../auth/login_screen.dart';

final _pointsServiceProvider = Provider<PointsService>((ref) => PointsService());

class PointsScreen extends ConsumerStatefulWidget {
  const PointsScreen({super.key});

  @override
  ConsumerState<PointsScreen> createState() => _PointsScreenState();
}

class _PointsScreenState extends ConsumerState<PointsScreen> {
  final Set<String> _seenEarnedBadges = <String>{};
  final List<PointsActivityItem> _activities = [];
  DocumentSnapshot<Map<String, dynamic>>? _activityCursor;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  bool _badgeSeeded = false;
  String? _activityError;


  Future<void> _loadMoreActivity(String uid) async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() {
      _isLoadingMore = true;
      _activityError = null;
    });
    try {
      final page = await ref.read(_pointsServiceProvider).streamPointsActivity(uid, startAfter: _activityCursor);
      setState(() {
        _activities.addAll(page.items);
        _activityCursor = page.lastDocument;
        _hasMore = page.hasMore;
      });
    } on FirebaseException catch (e) {
      setState(() => _activityError = _firebaseMessage(e));
    } catch (_) {
      setState(() => _activityError = 'Aktivite listesi yüklenirken beklenmeyen bir hata oluştu.');
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  String _firebaseMessage(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'Bu alanı görüntüleme izniniz bulunmuyor.';
      case 'unavailable':
        return 'Sunucuya ulaşılamadı. Lütfen internet bağlantınızı kontrol edin.';
      default:
        return 'Veriler alınırken bir sorun oluştu.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authStateProvider);

    return userAsync.when(
      data: (authUser) {
        if (authUser == null) {
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

        final service = ref.read(_pointsServiceProvider);
        return Scaffold(
          appBar: AppBar(title: const Text('Puanlar')),
          body: StreamBuilder<UserPointsProfile>(
            stream: service.getUserPointsProfile(authUser.uid),
            builder: (context, profileSnapshot) {
              if (profileSnapshot.hasError) {
                final message = profileSnapshot.error is FirebaseException
                    ? _firebaseMessage(profileSnapshot.error! as FirebaseException)
                    : 'Profil bilgileri çözümlenemedi.';
                return _SectionState(message: message, icon: Icons.error_outline);
              }
              if (!profileSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final profile = profileSnapshot.data!;
              return StreamBuilder<List<PointsBadgeView>>(
                stream: service.streamBadges(profile.uid),
                builder: (context, badgesSnapshot) {
                  final badges = badgesSnapshot.data ?? const <PointsBadgeView>[];
                  _notifyNewBadge(badges);
                  return StreamBuilder<List<PointsRule>>(
                    stream: service.streamPointsRules(),
                    builder: (context, rulesSnapshot) {
                      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: service.pointsActivityQuery(profile.uid).snapshots(),
                        builder: (context, activitySnapshot) {
                          List<PointsActivityItem> firstPage = const [];
                          if (activitySnapshot.hasData) {
                            final docs = activitySnapshot.data!.docs;
                            firstPage = docs
                                .map(
                                  (doc) => PointsActivityItem(
                                    id: doc.id,
                                    type: (doc.data()['type'] as String?) ?? 'other',
                                    title: (doc.data()['title'] as String?) ?? 'Aktivite',
                                    points: (doc.data()['points'] as num?)?.toInt() ?? 0,
                                    createdAt: (doc.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                                    meta: (doc.data()['meta'] as Map<String, dynamic>?) ?? const {},
                                  ),
                                )
                                .toList();
                            _activityCursor = docs.isNotEmpty ? docs.last : null;
                            _hasMore = docs.length >= 20;
                            _activities
                              ..clear()
                              ..addAll(firstPage);
                          }

                          return ListView(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            children: [
                              PointsHeroSemiRing(profile: profile, weeklyPoints: _weeklyPoints(firstPage)),
                              const SizedBox(height: AppSpacing.xl),
                              BadgesGrid(
                                badges: badges,
                                loading: badgesSnapshot.connectionState == ConnectionState.waiting && badges.isEmpty,
                                error: badgesSnapshot.error,
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              GoalsCards(activities: firstPage),
                              const SizedBox(height: AppSpacing.xl),
                              PointsRulesList(
                                rules: rulesSnapshot.data ?? const [],
                                loading: rulesSnapshot.connectionState == ConnectionState.waiting,
                                error: rulesSnapshot.error,
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              ActivityTimeline(
                                initialActivities: _activities,
                                loading: activitySnapshot.connectionState == ConnectionState.waiting,
                                error: activitySnapshot.error ?? _activityError,
                                isLoadingMore: _isLoadingMore,
                                hasMore: _hasMore,
                                onLoadMore: () => _loadMoreActivity(profile.uid),
                              ),
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
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(body: Center(child: Text('Oturum alınamadı: $error'))),
    );
  }

  int _weeklyPoints(List<PointsActivityItem> items) {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return items.where((e) => e.createdAt.isAfter(weekAgo)).fold(0, (sum, item) => sum + item.points);
  }

  void _notifyNewBadge(List<PointsBadgeView> badges) {
    if (!mounted) return;
    final earnedNow = badges.where((b) => b.isEarned).toList();
    if (!_badgeSeeded) {
      _seenEarnedBadges.addAll(earnedNow.map((e) => e.definition.id));
      _badgeSeeded = true;
      return;
    }
    for (final badge in earnedNow) {
      if (_seenEarnedBadges.add(badge.definition.id)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('🎉 Yeni rozet kazandın: ${badge.definition.title}')),
          );
        });
      }
    }
  }
}

class PointsHeroSemiRing extends StatelessWidget {
  const PointsHeroSemiRing({super.key, required this.profile, required this.weeklyPoints});

  final UserPointsProfile profile;
  final int weeklyPoints;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: const [AppShadows.medium],
      ),
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: profile.ringProgress),
            duration: const Duration(milliseconds: 820),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return SizedBox(
                width: 240,
                height: 130,
                child: CustomPaint(
                  painter: _SemiRingPainter(progress: value),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TweenAnimationBuilder<int>(
                          tween: IntTween(begin: 0, end: profile.totalPoints),
                          duration: const Duration(milliseconds: 800),
                          builder: (_, points, __) => Text('$points', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w700)),
                        ),
                        const Text('Puan', style: TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 6),
                        Chip(label: Text('${profile.tier} Üye'), visualDensity: VisualDensity.compact),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Text('${profile.nextTier} seviyeye ${profile.remainingPoints} puan kaldı', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Bu hafta +$weeklyPoints puan', style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _SemiRingPainter extends CustomPainter {
  const _SemiRingPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(8, 8, size.width - 16, (size.width - 16));
    final bg = Paint()
      ..color = const Color(0xFFEFE3D7)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 13;
    final fg = Paint()
      ..color = const Color(0xFFD6A84B)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 13;
    canvas.drawArc(rect, math.pi, math.pi, false, bg);
    canvas.drawArc(rect, math.pi, math.pi * progress.clamp(0, 1), false, fg);
  }

  @override
  bool shouldRepaint(covariant _SemiRingPainter oldDelegate) => oldDelegate.progress != progress;
}

class BadgesGrid extends StatelessWidget {
  const BadgesGrid({super.key, required this.badges, required this.loading, required this.error});

  final List<PointsBadgeView> badges;
  final bool loading;
  final Object? error;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Başarılarım',
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? _SectionState(message: 'Rozetler şu an yüklenemiyor.', icon: Icons.error_outline)
              : badges.isEmpty
                  ? const _SectionState(message: 'Henüz rozet tanımı yok.', icon: Icons.workspace_premium_outlined)
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: math.min(8, badges.length),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 8, mainAxisSpacing: 8),
                      itemBuilder: (context, index) {
                        final badge = badges[index];
                        final earned = badge.isEarned;
                        return InkWell(
                          onTap: () => _showBadgeSheet(context, badge),
                          child: Opacity(
                            opacity: earned ? 1 : 0.4,
                            child: Container(
                              decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(AppRadius.md)),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Icon(_iconFor(badge.definition.iconKey), color: AppColors.primary),
                                  if (!earned) const Positioned(right: 6, top: 6, child: Icon(Icons.lock, size: 14)),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }

  IconData _iconFor(String key) {
    switch (key) {
      case 'flame':
        return Icons.local_fire_department;
      case 'diamond':
        return Icons.diamond_outlined;
      default:
        return Icons.bolt;
    }
  }

  void _showBadgeSheet(BuildContext context, PointsBadgeView badge) {
    final earnedText = badge.userBadge?.earnedAt == null
        ? 'Henüz kazanılmadı'
        : 'Kazanıldı: ${DateFormat('d MMMM y', 'tr_TR').format(badge.userBadge!.earnedAt!)}';
    final progress = badge.userBadge?.progress ?? 0;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(badge.definition.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(badge.definition.description),
            const SizedBox(height: 12),
            Text('İlerleme: $progress/${badge.definition.requirementTarget}'),
            const SizedBox(height: 6),
            Text(earnedText, style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class GoalsCards extends StatelessWidget {
  const GoalsCards({super.key, required this.activities});

  final List<PointsActivityItem> activities;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = activities.where((a) => a.createdAt.day == now.day && a.createdAt.month == now.month && a.createdAt.year == now.year).toList();
    final week = activities.where((a) => a.createdAt.isAfter(now.subtract(const Duration(days: 7)))).toList();

    final addedToday = today.where((a) => a.type == 'price_add').length;
    final verifyToday = today.where((a) => a.type == 'verification').length;
    final streak = _calculateStreak(week);

    return _SectionCard(
      title: 'Hedefler',
      child: Row(
        children: [
          _goal('Bugün', 'Fiyat ekle', '$addedToday/1', '+5'),
          const SizedBox(width: 8),
          _goal('Bugün', 'Doğrulama yap', '$verifyToday/1', '+5'),
          const SizedBox(width: 8),
          _goal('Hafta', 'Seri', '$streak/7', ''),
        ],
      ),
    );
  }

  Widget _goal(String badge, String title, String progress, String point) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(AppRadius.md)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(badge, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(progress),
          if (point.isNotEmpty) Text(point, style: const TextStyle(color: AppColors.primary)),
        ]),
      ),
    );
  }

  int _calculateStreak(List<PointsActivityItem> week) {
    final uniqueDays = week.map((e) => DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day)).toSet();
    var streak = 0;
    for (var i = 0; i < 7; i++) {
      final day = DateTime.now().subtract(Duration(days: i));
      if (uniqueDays.contains(DateTime(day.year, day.month, day.day))) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }
}

class PointsRulesList extends StatelessWidget {
  const PointsRulesList({super.key, required this.rules, required this.loading, required this.error});

  final List<PointsRule> rules;
  final bool loading;
  final Object? error;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Puan Nasıl Kazanılır?',
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? const _SectionState(message: 'Kural listesi getirilemedi.', icon: Icons.rule_folder_outlined)
              : rules.isEmpty
                  ? const _SectionState(message: 'Aktif puan kuralı bulunmuyor.', icon: Icons.rule)
                  : Column(
                      children: rules
                          .map(
                            (rule) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.bolt),
                              title: Text(rule.title),
                              subtitle: Text('${rule.description}${rule.dailyLimit != null ? '\nGünlük limit: ${rule.dailyLimit}' : ''}'),
                              trailing: Text('+${rule.points}', style: const TextStyle(fontWeight: FontWeight.w700)),
                            ),
                          )
                          .toList(),
                    ),
    );
  }
}

class ActivityTimeline extends StatelessWidget {
  const ActivityTimeline({
    super.key,
    required this.initialActivities,
    required this.loading,
    required this.error,
    required this.isLoadingMore,
    required this.hasMore,
    required this.onLoadMore,
  });

  final List<PointsActivityItem> initialActivities;
  final bool loading;
  final Object? error;
  final bool isLoadingMore;
  final bool hasMore;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Aktivite',
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? const _SectionState(message: 'Aktivite akışı yüklenemedi.', icon: Icons.timeline)
              : initialActivities.isEmpty
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Henüz aktivite yok. İlk fiyatını ekle ve puan kazanmaya başla.'),
                        const SizedBox(height: 8),
                        OutlinedButton(onPressed: () {}, child: const Text('İlk katkını yap')),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ..._grouped(context, initialActivities),
                        if (hasMore)
                          TextButton(
                            onPressed: isLoadingMore ? null : onLoadMore,
                            child: Text(isLoadingMore ? 'Yükleniyor...' : 'Daha fazla'),
                          ),
                      ],
                    ),
    );
  }

  List<Widget> _grouped(BuildContext context, List<PointsActivityItem> items) {
    final map = <String, List<PointsActivityItem>>{'Bugün': [], 'Dün': [], 'Bu Hafta': [], 'Daha Eski': []};
    final now = DateTime.now();
    for (final item in items) {
      final diff = now.difference(item.createdAt);
      if (diff.inDays == 0) {
        map['Bugün']!.add(item);
      } else if (diff.inDays == 1) {
        map['Dün']!.add(item);
      } else if (diff.inDays < 7) {
        map['Bu Hafta']!.add(item);
      } else {
        map['Daha Eski']!.add(item);
      }
    }

    final widgets = <Widget>[];
    map.forEach((title, list) {
      if (list.isEmpty) return;
      widgets.add(Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      ));
      widgets.addAll(
        list.map(
          (item) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.fiber_manual_record, size: 10),
            title: Text(item.title),
            subtitle: Text(_relative(item.createdAt)),
            trailing: Text('+${item.points}'),
          ),
        ),
      );
    });
    return widgets;
  }

  String _relative(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
    if (diff.inHours < 24) return '${diff.inHours} saat önce';
    return DateFormat('d MMM', 'tr_TR').format(date);
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.xl), boxShadow: const [AppShadows.small]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        child,
      ]),
    );
  }
}

class _SectionState extends StatelessWidget {
  const _SectionState({required this.message, required this.icon});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: AppColors.textSecondary),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center),
      ]),
    );
  }
}
