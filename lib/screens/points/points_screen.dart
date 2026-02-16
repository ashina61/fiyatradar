import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../services/points_service.dart';
import '../../utils/level_system.dart';
import '../../utils/theme.dart';
import '../../widgets/badge_unlocked_overlay.dart';
import '../../widgets/leaderboard_section.dart';
import '../add_price/add_price_screen.dart';
import '../auth/login_screen.dart';

final _pointsServiceProvider = Provider<PointsService>((ref) => PointsService());

enum PointsTab { overview, leaderboard }

class PointsScreen extends ConsumerStatefulWidget {
  const PointsScreen({super.key});

  @override
  ConsumerState<PointsScreen> createState() => _PointsScreenState();
}

class _PointsScreenState extends ConsumerState<PointsScreen> with SingleTickerProviderStateMixin {
  String? _activeBadgeDialogId;
  bool _recomputedForUser = false;
  PointsTab _activeTab = PointsTab.overview;
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this)
      ..addListener(() {
        if (_tab.indexIsChanging) return;
        final nextTab = _tab.index == 0 ? PointsTab.overview : PointsTab.leaderboard;
        if (_activeTab == nextTab) return;
        setState(() {
          _activeTab = nextTab;
        });
      });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

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
        if (!_recomputedForUser) {
          _recomputedForUser = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            pointsService.recomputeUserGamification(user.uid);
          });
        }
        return FutureBuilder<void>(
          future: pointsService.ensurePointsDefaultsSeeded(),
          builder: (context, seedSnap) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Puanlar'),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(58),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: _buildPointsHeaderTabs(),
                  ),
                ),
              ),
              body: StreamBuilder<UserPointsProfile>(
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
                          return StreamBuilder<PendingBadgeUnlock?>(
                            stream: pointsService.streamLatestUnseenUnlockedBadge(user.uid),
                            builder: (context, pendingBadgeSnap) {
                              _notifyBadgeUnlock(user.uid, pendingBadgeSnap.data);
                              return StreamBuilder<List<PointsActivityItem>>(
                                stream: pointsService.streamActivity(user.uid),
                                builder: (context, activitySnap) {
                                  final activities = activitySnap.data ?? const <PointsActivityItem>[];
                                  final rules = rulesSnap.data ?? const <PointsRule>[];

                                  return TabBarView(
                                    controller: _tab,
                                    physics: const NeverScrollableScrollPhysics(),
                                    children: [
                                      _buildOverviewContent(
                                        profile: profile,
                                        activities: activities,
                                        rules: rules,
                                        badges: badges,
                                      ),
                                      _buildLeaderboardContent(),
                                    ],
                                  );
                                },
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
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const Scaffold(body: SizedBox.shrink()),
    );
  }

  void _goToAddPrice() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPriceScreen()));
  }

  void _notifyBadgeUnlock(String uid, PendingBadgeUnlock? pending) {
    if (!mounted || pending == null) return;
    if (_activeBadgeDialogId == pending.badgeId) return;

    _activeBadgeDialogId = pending.badgeId;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (_) => BadgeUnlockedOverlay(
          badgeTitle: pending.badgeTitle,
          badgeDescription: pending.badgeDescription,
          onAcknowledge: () => ref.read(_pointsServiceProvider).acknowledgeBadgeUnlock(uid: uid, badgeId: pending.badgeId),
        ),
      );
      if (!mounted) return;
      setState(() {
        _activeBadgeDialogId = null;
      });
    });
  }

  Widget _buildPointsHeaderTabs() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9ED),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE3CEAA)),
      ),
      child: TabBar(
        controller: _tab,
        onTap: (index) => setState(() {
          _activeTab = index == 0 ? PointsTab.overview : PointsTab.leaderboard;
        }),
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: const Color(0xFFB8863B),
          borderRadius: BorderRadius.circular(999),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF6F5A3C),
        labelStyle: const TextStyle(fontWeight: FontWeight.w800),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
        tabs: const [
          Tab(text: 'Genel Bakış'),
          Tab(text: 'Zirvedekiler'),
        ],
      ),
    );
  }

  Widget _buildOverviewContent({
    required UserPointsProfile? profile,
    required List<PointsActivityItem> activities,
    required List<PointsRule> rules,
    required List<PointsBadge> badges,
  }) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        final offset = Tween<Offset>(begin: const Offset(-0.03, 0), end: Offset.zero).animate(animation);
        return FadeTransition(opacity: animation, child: SlideTransition(position: offset, child: child));
      },
      child: ListView(
        key: ValueKey(_activeTab),
        padding: const EdgeInsets.fromLTRB(16, AppSpacing.lg, 16, 120),
        children: [
          if (profile == null)
            const _SkeletonCard(height: 260)
          else
            _HeroCard(profile: profile, activities: activities),
          const SizedBox(height: AppSpacing.lg),
          _GoalsCard(profile: profile, activities: activities, onPriceGoalTap: _goToAddPrice),
          const SizedBox(height: AppSpacing.lg),
          _RulesCard(rules: rules),
          const SizedBox(height: AppSpacing.lg),
          _BadgesCard(badges: badges),
          const SizedBox(height: AppSpacing.lg),
          _ActivityCard(activities: activities, onCtaTap: _goToAddPrice),
        ],
      ),
    );
  }

  Widget _buildLeaderboardContent() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        final offset = Tween<Offset>(begin: const Offset(0.03, 0), end: Offset.zero).animate(animation);
        return FadeTransition(opacity: animation, child: SlideTransition(position: offset, child: child));
      },
      child: ListView(
        key: ValueKey(_activeTab),
        padding: const EdgeInsets.fromLTRB(0, AppSpacing.lg, 0, 120),
        children: const [
          LeaderboardSection(
            outerPadding: EdgeInsets.all(20),
            headerToContentSpacing: 10,
            topThreeMinHeight: 220,
            myRankBarHeight: 54,
            myRankBarPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.profile, required this.activities});

  final UserPointsProfile profile;
  final List<PointsActivityItem> activities;

  @override
  Widget build(BuildContext context) {
    final weekly = profile.weeklyPoints;
    final level = levelBuilder(profile.totalPoints);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: _SectionCard(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFFFFCF5),
                  const Color(0xFFF6EFE1).withOpacity(0.9),
                ],
              ),
              border: Border.all(color: const Color(0xFFE0C38C).withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFB8863B).withOpacity(0.12),
                  blurRadius: 24,
                  spreadRadius: 1,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: const Color(0xFFB8863B).withOpacity(0.12),
                        border: Border.all(color: const Color(0xFFB8863B).withOpacity(0.25)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome, size: 13, color: Color(0xFF9C6D2A)),
                          SizedBox(width: 4),
                          Text('Prestij Skoru', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF9C6D2A))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 248,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 246,
                        height: 246,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFFFFF7E8),
                              const Color(0xFFFFE5B6).withOpacity(0.15),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 226,
                        height: 226,
                        child: CustomPaint(painter: _RingPainter(progress: profile.progress)),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${profile.totalPoints}',
                            style: const TextStyle(
                              fontSize: 54,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.4,
                              color: Color(0xFF3E250A),
                              height: 0.95,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Toplam Puan',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF7A6652),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _LevelBenefitChip(level: level),
                const SizedBox(height: 10),
                if (profile.nextLevel != null)
                  Text(
                    '${profile.nextLevel!.title} seviyesine ${profile.remainingForNextLevel} puan kaldı',
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5D4B3A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB8863B).withOpacity(0.10),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFB8863B).withOpacity(0.22)),
                  ),
                  child: Text(
                    weekly == 0 ? 'Bu hafta henüz puan yok' : 'Bu hafta +$weekly puan kazandın',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6E5436),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LevelBenefitChip extends StatelessWidget {
  const _LevelBenefitChip({required this.level});

  final UserLevel level;

  String get _benefit {
    switch (level.label) {
      case 'Elmas':
        return '%5';
      case 'Gümüş':
        return '%3';
      case 'Bronz':
        return '%2';
      default:
        return '%1';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDiamond = level.label == 'Elmas';
    final startColor = isDiamond ? const Color(0xFFEAF7FF) : level.badgeBackground;
    final endColor = isDiamond ? const Color(0xFFD7EDFF) : level.badgeBackground.withOpacity(0.86);
    final borderColor = isDiamond ? const Color(0xFF8CC8ED) : level.badgeBorder;
    final textColor = isDiamond ? const Color(0xFF1D74B4) : level.badgeForeground;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(colors: [startColor, endColor]),
        border: Border.all(color: borderColor, width: 1.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(level.emoji, style: TextStyle(fontSize: 16, color: textColor)),
          const SizedBox(width: 6),
          Text(
            '${level.label} $_benefit',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.1,
              color: textColor,
            ),
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
    final price = today.where((a) => a.type == 'price_add' || a.type == 'price_entry').length;
    final verify = today.where((a) => a.type == 'verification' || a.type == 'price_verify').length;
    final photo = today.where((a) => a.type == 'photo_upload').length;

    final goals = [
      _GoalItem(icon: Icons.sell_rounded, title: 'Bugün Fiyat', current: price, target: 1, reward: '+5 puan', onTap: onPriceGoalTap),
      _GoalItem(icon: Icons.verified_rounded, title: 'Bugün Doğrulama', current: verify, target: 1, reward: '+2 puan'),
      _GoalItem(icon: Icons.photo_camera_outlined, title: 'Bugün Foto', current: photo, target: 1, reward: '+2 puan'),
    ];

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Hedefler', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF3E250A))),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6E7CD),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFE4C289)),
                ),
                child: const Text('Bugün', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF8C6121))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            itemCount: goals.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.45,
            ),
            itemBuilder: (context, index) => _GoalMiniCard(item: goals[index]),
          ),
        ],
      ),
    );
  }
}

class _GoalItem {
  const _GoalItem({required this.icon, required this.title, required this.current, required this.target, required this.reward, this.onTap});

  final IconData icon;
  final String title;
  final int current;
  final int target;
  final String reward;
  final VoidCallback? onTap;
}

class _GoalMiniCard extends StatefulWidget {
  const _GoalMiniCard({required this.item});

  final _GoalItem item;

  @override
  State<_GoalMiniCard> createState() => _GoalMiniCardState();
}

class _GoalMiniCardState extends State<_GoalMiniCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final progressValue = (widget.item.current / widget.item.target).clamp(0, 1).toDouble();
    final completed = progressValue >= 1;
    final remaining = (widget.item.target - widget.item.current).clamp(0, widget.item.target);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.item.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: completed ? const Color(0xFFEFF8EE) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: completed ? const Color(0xFFA3D8A5) : const Color(0xFFE6D7BF)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_pressed ? 0.02 : 0.06),
              blurRadius: _pressed ? 6 : 10,
              offset: Offset(0, _pressed ? 2 : 5),
            ),
          ],
        ),
        transform: Matrix4.identity()..scale(_pressed ? 0.98 : 1.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: completed ? const Color(0xFFD4EFD5) : const Color(0xFFF7EFE2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(completed ? Icons.check_rounded : widget.item.icon, size: 15, color: completed ? const Color(0xFF2F8D3A) : const Color(0xFF8E6427)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(widget.item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ],
            ),
            const Spacer(),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 6,
                value: progressValue,
                backgroundColor: const Color(0xFFEFE4D3),
                valueColor: AlwaysStoppedAnimation<Color>(completed ? const Color(0xFF3EA549) : const Color(0xFFB8863B)),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    completed ? 'Tamamlandı' : 'Kalan: $remaining',
                    style: TextStyle(fontSize: 11, color: completed ? const Color(0xFF2F8D3A) : const Color(0xFF7A6652), fontWeight: FontWeight.w600),
                  ),
                ),
                Text(widget.item.reward, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF8E6427))),
              ],
            ),
          ],
        ),
      ),
    );
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
        height: 208,
        child: PageView.builder(
          controller: PageController(viewportFraction: 0.82),
          itemCount: display.length,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm, top: 4, bottom: 4),
            child: _BadgeTile(badge: display[index]),
          ),
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
      contentCrossAxisAlignment: CrossAxisAlignment.center,
      child: activities.isEmpty
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const _PremiumEmpty(icon: Icons.local_fire_department_outlined, title: 'Henüz aktivite yok', subtitle: 'İlk katkınla puan yolculuğunu başlat.'),
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.center,
                  child: FilledButton(onPressed: onCtaTap, child: const Text('İlk katkını yap')),
                ),
              ],
            )
          : Column(
              children: [
                for (var i = 0; i < activities.length; i++)
                  TweenAnimationBuilder<double>(
                    key: ValueKey('activity_${activities[i].id}'),
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 220 + (i * 20)),
                    curve: Curves.easeOut,
                    builder: (context, value, child) => Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, (1 - value) * 8),
                        child: child,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surfaceVariant,
                          border: Border.all(color: AppColors.outline.withOpacity(0.35)),
                        ),
                        child: const Icon(Icons.bolt, size: 14),
                      ),
                      title: Text(_activityLabel(activities[i].type)),
                      trailing: Text(
                        '${activities[i].points >= 0 ? '+' : ''}${activities[i].points}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  String _activityLabel(String type) {
    switch (type) {
      case 'price_add':
      case 'price_entry':
        return 'Fiyat ekledin';
      case 'verification':
      case 'price_verify':
      case 'verify_vote':
        return 'Fiyat doğruladın';
      case 'streak_bonus':
        return 'Seri bonusu kazandın';
      case 'admin_action':
        return 'Admin işlemi';
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
    final radius = (size.width / 2) - 12;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
      ..color = const Color(0xFFFFDFA3).withOpacity(0.22);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 16
      ..color = const Color(0xFFEADBC1);

    final fill = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 16
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0xFFFFE3A9),
          Color(0xFFD9AE61),
          Color(0xFFB9862F),
        ],
      ).createShader(rect);

    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, glow);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, track);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * progress.clamp(0, 1), false, fill);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => oldDelegate.progress != progress;
}


class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.badge});

  final PointsBadge badge;

  String _friendlyUnlockCondition(PointsBadge badge) {
    final raw = badge.unlockCondition.trim();
    if (raw.isEmpty) return 'Bu rozeti kazanmak için görevini tamamla.';

    final normalized = raw.toLowerCase();
    final conditionPatterns = <String, RegExp>{
      'price_entry': RegExp(r'(price_entry|priceaddcount)\s*(==|>=|<=|>|<)\s*(\d+)', caseSensitive: false),
      'price_verify': RegExp(r'(price_verify|verifycount)\s*(==|>=|<=|>|<)\s*(\d+)', caseSensitive: false),
      'trust_score': RegExp(r'(trustscore|trust_score)\s*(==|>=|<=|>|<)\s*(\d+)', caseSensitive: false),
      'is_admin': RegExp(r'(isadmin|is_admin)\s*(==|=)\s*(true|false)', caseSensitive: false),
    };

    String sentenceForNumericCondition({required String key, required String operatorToken, required int value}) {
      final templates = <String, String>{
        'price_entry_>=': 'En az {value} fiyat katkısı yapmalısın.',
        'price_entry_>': '{value} adetten fazla fiyat katkısı yapmalısın.',
        'price_entry_<=': 'En fazla {value} fiyat katkısı yapmış olmalısın.',
        'price_entry_<': '{value} adetten az fiyat katkısı yapmış olmalısın.',
        'price_entry_==': 'Tam olarak {value} fiyat katkısı yapmalısın.',
        'price_verify_>=': 'En az {value} fiyat doğrulaması yapmalısın.',
        'price_verify_>': '{value} adetten fazla fiyat doğrulaması yapmalısın.',
        'price_verify_<=': 'En fazla {value} fiyat doğrulaması yapmış olmalısın.',
        'price_verify_<': '{value} adetten az fiyat doğrulaması yapmış olmalısın.',
        'price_verify_==': 'Tam olarak {value} fiyat doğrulaması yapmalısın.',
        'trust_score_>=': 'Güven skorun en az %{value} olmalı.',
        'trust_score_>': 'Güven skorun %{value} değerinin üstünde olmalı.',
        'trust_score_<=': 'Güven skorun en fazla %{value} olmalı.',
        'trust_score_<': 'Güven skorun %{value} değerinin altında olmalı.',
        'trust_score_==': 'Güven skorun tam olarak %{value} olmalı.',
      };

      final template = templates['${key}_$operatorToken'];
      if (template == null) return 'Bu rozeti kazanmak için rozet koşulunu tamamlamalısın.';
      return template.replaceAll('{value}', '$value');
    }

    String sentenceForBooleanCondition({required String key, required bool value}) {
      final templates = <String, String>{
        'is_admin_true': 'Bu rozeti kazanmak için yönetici hesabına sahip olmalısın.',
        'is_admin_false': 'Bu rozet yalnızca yönetici olmayan kullanıcılar içindir.',
      };
      return templates['${key}_${value.toString()}'] ?? 'Bu rozeti kazanmak için rozet koşulunu tamamlamalısın.';
    }

    for (final entry in conditionPatterns.entries) {
      final match = entry.value.firstMatch(normalized);
      if (match == null) continue;

      if (entry.key == 'is_admin') {
        final boolValue = (match.group(3) ?? '').toLowerCase() == 'true';
        return sentenceForBooleanCondition(key: entry.key, value: boolValue);
      }

      final operatorToken = match.group(2);
      final value = int.tryParse(match.group(3) ?? '');
      if (operatorToken == null || value == null) break;
      return sentenceForNumericCondition(key: entry.key, operatorToken: operatorToken, value: value);
    }

    return 'Bu rozeti kazanmak için gerekli katkı hedeflerini tamamlamalısın.';
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = badge.isUnlocked;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: AppColors.surfaceVariant.withOpacity(0.75),
        border: Border.all(color: unlocked ? const Color(0xFFE9C46A).withOpacity(0.55) : AppColors.outline.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: unlocked ? const Color(0xFFE9C46A).withOpacity(0.18) : Colors.transparent,
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: BackdropFilter(
          filter: unlocked ? ImageFilter.blur(sigmaX: 0, sigmaY: 0) : ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: CircularProgressIndicator(
                          value: (badge.progress.clamp(0, 100)) / 100,
                          strokeWidth: 3,
                          backgroundColor: AppColors.outline.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(unlocked ? const Color(0xFFE9C46A) : AppColors.primary),
                        ),
                      ),
                      Icon(unlocked ? Icons.workspace_premium_rounded : Icons.lock_outline, color: unlocked ? const Color(0xFFE9C46A) : AppColors.primary),
                    ],
                  ),
                  const Spacer(),
                  if (unlocked)
                    const Icon(Icons.auto_awesome_rounded, size: 18, color: Color(0xFFE9C46A)),
                ],
              ),
              const SizedBox(height: 12),
              Text(unlocked ? badge.title : 'Kilitli Rozet', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(unlocked ? badge.description : 'Kilidi açmak için katkı yap.', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const Spacer(),
              Text(
                _friendlyUnlockCondition(badge),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
              ),
              if (badge.unlockedAt != null)
                Text('Açılma: ${badge.unlockedAt!.day}.${badge.unlockedAt!.month}.${badge.unlockedAt!.year}', style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({this.title, required this.child, this.contentCrossAxisAlignment = CrossAxisAlignment.start});
  final String? title;
  final Widget child;
  final CrossAxisAlignment contentCrossAxisAlignment;

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
        crossAxisAlignment: contentCrossAxisAlignment,
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
