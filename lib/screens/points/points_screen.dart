import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../utils/theme.dart';
import '../../widgets/leaderboard_section.dart';
import '../../widgets/level_badge.dart';
import 'controllers/points_controller.dart';
import 'models/points_models.dart';
import '../../widgets/user_identity_renderer.dart';
import '../../utils/level_style.dart';
import '../../utils/level_system.dart';


class PointsScreen extends ConsumerStatefulWidget {
  const PointsScreen({super.key});

  @override
  ConsumerState<PointsScreen> createState() => _PointsScreenState();
}

class _PointsScreenState extends ConsumerState<PointsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pointsAsync = ref.watch(pointsStateProvider);
    final state = pointsAsync.valueOrNull ?? PointsState.placeholder;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Puanlar',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: _PremiumTabBar(controller: _tabController),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _OverviewTab(state: state),
                const _LeaderboardTab(),
                _ActivitiesTab(state: state),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Premium Tab Bar ----------

class _PremiumTabBar extends StatelessWidget {
  const _PremiumTabBar({required this.controller});
  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline.withOpacity(0.6)),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textTertiary,
        labelStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(text: 'Genel Bakis'),
          Tab(text: 'Zirvedekiler'),
          Tab(text: 'Aktivitiler'),
        ],
      ),
    );
  }
}

// ---------- Overview Tab ----------

class _OverviewTab extends StatefulWidget {
  const _OverviewTab({required this.state});
  final PointsState state;

  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() => _scrollOffset = _scrollController.offset);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        children: [
          _PrestigeScoreCard(state: widget.state, scrollOffset: _scrollOffset),
          const SizedBox(height: 20),
          _StatsRow(state: widget.state),
          const SizedBox(height: 20),
          _LevelProgressCard(state: widget.state, scrollOffset: _scrollOffset),
          const SizedBox(height: 20),
          _DailyGoalsSection(tasks: widget.state.dailyGoals),
        ],
      ),
    );
  }
}

// ---------- Leaderboard Tab ----------

class _LeaderboardTab extends StatelessWidget {
  const _LeaderboardTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: const LeaderboardSection(
        outerPadding: EdgeInsets.zero,
      ),
    );
  }
}

class _ActivitiesTab extends StatelessWidget {
  const _ActivitiesTab({required this.state});

  final PointsState state;

  @override
  Widget build(BuildContext context) {
    if (state.activities.isEmpty) {
      return const Center(
        child: Text(
          'Henüz puan aktivitesi yok',
          style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textTertiary),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      itemCount: state.activities.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final activity = state.activities[index];
        return _ActivityCard(activity: activity);
      },
    );
  }
}

// ---------- Prestige Score Card ----------

class _PrestigeScoreCard extends StatelessWidget {
  const _PrestigeScoreCard({required this.state, required this.scrollOffset});
  final PointsState state;
  final double scrollOffset;

  @override
  Widget build(BuildContext context) {
    final level = LevelStyle.fromLevelLabel(state.finalLevelLabel, fallbackTotalPoints: state.totalPoints);

    final visual = LevelStyle.visualFromLabel(level.label, fallbackTotalPoints: state.totalPoints);
    final eliteParallax = (scrollOffset * 0.08).clamp(-16.0, 16.0);
    return Transform.translate(
      offset: Offset(0, visual.isElite ? eliteParallax : 0),
      child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFF8EF),
            Color(0xFFF8EDDB),
          ],
        ),
        border: Border.all(color: const Color(0xFFE8D5B8)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Prestige label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Prestij Skoru',
              style: TextStyle(
                color: AppColors.primaryDark,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Circular score
          _AnimatedScoreRing(state: state, level: level, scrollOffset: scrollOffset),
          const SizedBox(height: 20),
          UserIdentityRenderer(
            userProfile: UserIdentityProfile(userName: state.currentLevelName, level: level),
            fontSize: 14,
            scrollOffset: scrollOffset,
          ),
        ],
      ),
    ));
  }
}

// ---------- Animated Score Ring ----------

class _AnimatedScoreRing extends StatefulWidget {
  const _AnimatedScoreRing({required this.state, required this.level, required this.scrollOffset});
  final PointsState state;
  final UserLevel level;
  final double scrollOffset;

  @override
  State<_AnimatedScoreRing> createState() => _AnimatedScoreRingState();
}

class _AnimatedScoreRingState extends State<_AnimatedScoreRing> with SingleTickerProviderStateMixin {
  late final AnimationController _sweepController;

  bool get _isElite => widget.level.label == 'Fiyat Lordu' || widget.level.label == 'Radar Efsanesi';
  bool get _isRadarEfsanesi => widget.level.label == 'Radar Efsanesi';

  @override
  void initState() {
    super.initState();
    _sweepController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _isRadarEfsanesi ? 10 : 8),
    );
    if (_isElite) {
      _sweepController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _AnimatedScoreRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    final shouldAnimate = _isElite;
    if (shouldAnimate && !_sweepController.isAnimating) {
      _sweepController.repeat(reverse: true);
    } else if (!shouldAnimate && _sweepController.isAnimating) {
      _sweepController.stop();
      _sweepController.value = 0;
    }
  }

  @override
  void dispose() {
    _sweepController.dispose();
    super.dispose();
  }

  List<Color> _ringSweepColors(List<Color> source) {
    if (source.length >= 4) return source;
    if (source.length == 3) {
      return [source[0], Color.lerp(source[0], source[1], 0.5)!, source[1], source[2]];
    }
    if (source.length == 2) {
      return [
        source[0],
        Color.lerp(source[0], source[1], 0.35)!,
        Color.lerp(source[0], source[1], 0.7)!,
        source[1],
      ];
    }
    return const [Color(0xFFD0B38F), Color(0xFFE6CEAE), Color(0xFFB88A56), Color(0xFFD0B38F)];
  }

  @override
  Widget build(BuildContext context) {
    final sweepColors = _ringSweepColors(widget.level.gradient);
    final breathe = (math.sin(_sweepController.value * math.pi * 2) + 1) / 2;
    final ringGlowOpacity = !_isElite ? 0.0 : (_isRadarEfsanesi ? (0.06 + (0.06 * breathe)) : (0.04 + (0.04 * breathe)));
    final ringGlowScale = !_isElite ? 1.0 : (_isRadarEfsanesi ? (1 + (0.03 * breathe)) : (1 + (0.015 * breathe)));

    final ringShift = _isElite ? (widget.scrollOffset * 0.10).clamp(-14.0, 14.0) : 0.0;
    return Transform.translate(
      offset: Offset(0, ringShift),
      child: SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _sweepController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _PremiumRingPainter(
                    progress: widget.state.levelProgressPercent,
                    sweepColors: sweepColors,
                    showGlow: ringGlowOpacity,
                  ),
                );
              },
            ),
          ),
          if (_isElite)
            Transform.scale(
              scale: ringGlowScale,
              child: Container(
                width: 168,
                height: 168,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFB28758).withOpacity(ringGlowOpacity),
                      blurRadius: 28,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),
            ),
          if (widget.state.isTrustGated)
            Positioned(
              right: 16,
              top: 16,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.84),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2C7AA)),
                ),
                child: const Icon(Icons.lock_rounded, size: 13, color: Color(0xFF7B5B46)),
              ),
            ),
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.08),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: widget.state.totalPoints),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return Text(
                      '$value',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        height: 1,
                        letterSpacing: -1,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                Text(
                  widget.level.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85),
                  ),
                ),
                if (widget.state.isTrustGated)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Icons.lock_rounded, size: 15, color: AppColors.textTertiary),
                  ),
                const Text(
                  'Toplam Puan',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ));
  }
}

class _PremiumRingPainter extends CustomPainter {
  const _PremiumRingPainter({
    required this.progress,
    required this.sweepColors,
    required this.showGlow,
  });

  final double progress;
  final List<Color> sweepColors;
  final double showGlow;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 12.0;
    final center = size.center(Offset.zero);
    final radius = (size.width / 2) - (strokeWidth / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);
    final clampedProgress = progress.clamp(0.0, 1.0);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFC6A989).withOpacity(0.22);

    canvas.drawCircle(center, radius, trackPaint);

    final gradient = SweepGradient(
      colors: sweepColors,
      stops: const [0.0, 0.32, 0.68, 1.0],
      transform: const GradientRotation(-math.pi / 2),
    );

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = gradient.createShader(rect);

    if (showGlow > 0 && clampedProgress > 0) {
      final glowPath = Path()
        ..addArc(rect, -math.pi / 2, (math.pi * 2) * clampedProgress);
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 1
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFB28758).withOpacity(showGlow)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawPath(glowPath, glowPaint);
    }

    canvas.drawArc(rect, -math.pi / 2, (math.pi * 2) * clampedProgress, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _PremiumRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.showGlow != showGlow ||
        oldDelegate.sweepColors != sweepColors;
  }
}

// ---------- Stats Row ----------

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.state});
  final PointsState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.trending_up_rounded,
            iconColor: AppColors.success,
            label: 'Bu Hafta',
            value: '+${state.pointsThisWeek}',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.flag_rounded,
            iconColor: AppColors.primary,
            label: 'Sonraki Seviye',
            value: '${state.nextLevelTargetPoints}',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.local_fire_department_rounded,
            iconColor: const Color(0xFFE67E22),
            label: 'Seri',
            value: '${state.streakDays} gun',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ---------- Level Progress Card ----------

class _LevelProgressCard extends StatefulWidget {
  const _LevelProgressCard({required this.state, required this.scrollOffset});
  final PointsState state;
  final double scrollOffset;

  @override
  State<_LevelProgressCard> createState() => _LevelProgressCardState();
}

class _LevelProgressCardState extends State<_LevelProgressCard> {
  bool _animateFill = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _animateFill = true);
      }
    });
  }

  String _formatScore(int value) {
    final text = value.toString();
    final chars = text.split('').reversed.toList();
    final buffer = StringBuffer();
    for (var i = 0; i < chars.length; i++) {
      if (i > 0 && i % 3 == 0) buffer.write('.');
      buffer.write(chars[i]);
    }
    return buffer.toString().split('').reversed.join();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final level = LevelStyle.fromLevelLabel(state.finalLevelLabel, fallbackTotalPoints: state.totalPoints);
    final visual = LevelStyle.visualFromLabel(level.label, fallbackTotalPoints: state.totalPoints);

    final scoreProgress = state.nextLevelTargetPoints <= 0
        ? 1.0
        : (state.totalPoints / state.nextLevelTargetPoints).clamp(0.0, 1.0);
    final trustProgress = state.requiredMinTrust <= 0
        ? 1.0
        : (state.trustScore / state.requiredMinTrust).clamp(0.0, 1.0);

    final pointsToNext = math.max(0, state.nextLevelTargetPoints - state.totalPoints);
    final trustToNext = math.max(0, state.requiredMinTrust - state.trustScore);

    final heroShift = (widget.scrollOffset * 0.05).clamp(-10.0, 10.0);

    return Transform.translate(
      offset: Offset(0, heroShift),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFFFFF), Color(0xFFF8F5F1)],
          ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFB8A99A).withOpacity(0.38),
              blurRadius: 40,
              offset: const Offset(18, 18),
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.85),
              blurRadius: 30,
              offset: const Offset(-10, -10),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              right: -24,
              bottom: -34,
              child: Transform.rotate(
                angle: -15 * math.pi / 180,
                child: Icon(
                  level.icon,
                  size: 200,
                  color: const Color(0xFF4A3623).withOpacity(0.03),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: LevelBadge(
                          level: level,
                          withEmoji: false,
                          uppercase: false,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Toplam Puan',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                            color: Color(0xFFA69587),
                          ),
                        ),
                        Text(
                          _formatScore(state.totalPoints),
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF4A3623),
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _NeumorphProgressGroup(
                  title: 'Seviye İlerlemesi',
                  leftValue: _formatScore(state.totalPoints),
                  rightValue: _formatScore(state.nextLevelTargetPoints),
                  progress: _animateFill ? scoreProgress : 0,
                  fillGradient: LinearGradient(
                    colors: [
                      visual.accentColor.withOpacity(0.75),
                      visual.accentColor,
                    ],
                  ),
                  fillShadowColor: visual.accentColor.withOpacity(0.45),
                  hintText: 'Sonraki seviyeye +${_formatScore(pointsToNext)} Puan',
                  badgeText: state.nextLevelName.toUpperCase(),
                  badgeIcon: Icons.north_east,
                ),
                const SizedBox(height: 22),
                _NeumorphProgressGroup(
                  title: 'Güven Skoru',
                  leftValue: '%${state.trustScore}',
                  rightValue: 'Min %${state.requiredMinTrust}',
                  progress: _animateFill ? trustProgress : 0,
                  fillGradient: state.isTrustGated
                      ? const LinearGradient(colors: [Color(0xFFC62828), Color(0xFFEF5350)])
                      : const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)]),
                  fillShadowColor: state.isTrustGated
                      ? const Color(0xFFEF5350).withOpacity(0.45)
                      : const Color(0xFF66BB6A).withOpacity(0.42),
                  hintText: trustToNext == 0
                      ? 'Bu seviye için güven şartı sağlandı'
                      : 'Güven şartı için +$trustToNext puan daha gerekli',
                  hintColor: trustToNext == 0 ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                  badgeText: state.isTrustGated ? 'GATED' : 'OK',
                  badgeIcon: state.isTrustGated ? Icons.lock : Icons.verified,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NeumorphProgressGroup extends StatelessWidget {
  const _NeumorphProgressGroup({
    required this.title,
    required this.leftValue,
    required this.rightValue,
    required this.progress,
    required this.fillGradient,
    required this.fillShadowColor,
    required this.hintText,
    required this.badgeText,
    required this.badgeIcon,
    this.hintColor = const Color(0xFF8C7A6B),
  });

  final String title;
  final String leftValue;
  final String rightValue;
  final double progress;
  final LinearGradient fillGradient;
  final Color fillShadowColor;
  final String hintText;
  final String badgeText;
  final IconData badgeIcon;
  final Color hintColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF4A3623),
              ),
            ),
            RichText(
              text: TextSpan(
                text: leftValue,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF4A3623),
                ),
                children: [
                  TextSpan(
                    text: ' / $rightValue',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFA69587),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFFEBE5DF),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8C7A6B).withOpacity(0.15),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.72),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.06),
                              Colors.transparent,
                              Colors.white.withOpacity(0.36),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 1400),
                        curve: Curves.easeOutCubic,
                        width: constraints.maxWidth * progress.clamp(0.0, 1.0),
                        decoration: BoxDecoration(
                          gradient: fillGradient,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: fillShadowColor, blurRadius: 14, offset: const Offset(0, 3)),
                          ],
                        ),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Colors.white.withOpacity(0.7), blurRadius: 8),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                hintText,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: hintColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFA69587).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(badgeIcon, size: 13, color: const Color(0xFFA69587)),
                  const SizedBox(width: 4),
                  Text(
                    badgeText,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFA69587),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DailyGoalsSection extends StatelessWidget {
  const _DailyGoalsSection({required this.tasks});
  final List<DailyTask> tasks;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Gunluk Hedefler',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.primary),
                  SizedBox(width: 6),
                  Text(
                    'Bugun',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...tasks.map((task) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _DailyGoalCard(task: task),
            )),
      ],
    );
  }
}

class _DailyGoalCard extends StatelessWidget {
  const _DailyGoalCard({required this.task});
  final DailyTask task;

  @override
  Widget build(BuildContext context) {
    final remaining = (task.target - task.current).clamp(0, task.target);
    final isComplete = remaining == 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isComplete ? AppColors.success.withOpacity(0.04) : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isComplete ? AppColors.success.withOpacity(0.3) : AppColors.outline.withOpacity(0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isComplete ? AppColors.success.withOpacity(0.1) : task.iconBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isComplete ? Icons.check_rounded : task.icon,
              size: 22,
              color: isComplete ? AppColors.success : AppColors.primaryDark,
            ),
          ),
          const SizedBox(width: 14),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isComplete ? AppColors.success : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  task.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    value: task.progress,
                    backgroundColor: AppColors.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation(
                      isComplete ? AppColors.success : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Reward & progress
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '+${task.reward}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${task.current}/${task.target}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activity});

  final PointsActivity activity;

  @override
  Widget build(BuildContext context) {
    final (icon, iconColor) = switch (activity.type) {
      'price_entry' => (Icons.sell_rounded, const Color(0xFFCC7A00)),
      'price_verify' => (Icons.verified_rounded, const Color(0xFF1565C0)),
      'comment' => (Icons.chat_bubble_rounded, const Color(0xFF5E35B1)),
      'photo_bonus' => (Icons.camera_alt_rounded, const Color(0xFF00897B)),
      _ => (Icons.stars_rounded, AppColors.primary),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline.withOpacity(0.6)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity.title, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(activity.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('+${activity.points}', style: TextStyle(fontWeight: FontWeight.w800, color: iconColor)),
              const SizedBox(height: 2),
              Text(activity.createdAt, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
            ],
          ),
        ],
      ),
    );
  }
}
