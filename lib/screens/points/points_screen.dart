import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../utils/theme.dart';
import '../../widgets/leaderboard_section.dart';
import 'controllers/points_controller.dart';
import 'models/points_models.dart';
import '../../widgets/user_identity_renderer.dart';
import '../../utils/level_system.dart';
import '../../utils/elite_level_engine.dart';
import '../../utils/level_style.dart';
import '../../utils/level_config.dart';


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

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.state});
  final PointsState state;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        children: [
          _PrestigeScoreCard(state: state),
          const SizedBox(height: 20),
          _StatsRow(state: state),
          const SizedBox(height: 20),
          _LevelProgressCard(state: state),
          const SizedBox(height: 20),
          _DailyGoalsSection(tasks: state.dailyGoals),
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
  const _PrestigeScoreCard({required this.state});
  final PointsState state;

  @override
  Widget build(BuildContext context) {
    final level = LevelStyle.fromLevelLabel(state.finalLevelLabel, fallbackTotalPoints: state.totalPoints);

    return Container(
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
          _AnimatedScoreRing(state: state, level: level),
          const SizedBox(height: 20),
          UserIdentityRenderer(
            userProfile: UserIdentityProfile(userName: state.currentLevelName, level: level),
            fontSize: 14,
          ),
        ],
      ),
    );
  }
}

// ---------- Animated Score Ring ----------

class _AnimatedScoreRing extends StatefulWidget {
  const _AnimatedScoreRing({required this.state, required this.level});
  final PointsState state;
  final UserLevel level;

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

    return SizedBox(
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
    );
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

class _LevelProgressCard extends StatelessWidget {
  const _LevelProgressCard({required this.state});
  final PointsState state;

  static const Map<String, Color> _levelColors = {
    'Gözlemci': Color(0xFFD4C4B7),
    'Avcı': Color(0xFFE67E22),
    'Tasarrufçu': Color(0xFF95A5A6),
    'Market Ustası': Color(0xFFF1C40F),
    'Fiyat Lordu': Color(0xFF9B59B6),
    'Radar Efsanesi': Color(0xFF00E5FF),
  };

  Color _levelColor(String label) => _levelColors[label] ?? const Color(0xFFD4C4B7);

  @override
  Widget build(BuildContext context) {
    final level = LevelStyle.fromLevelLabel(state.finalLevelLabel, fallbackTotalPoints: state.totalPoints);
    final currentLevelIndex = LevelConfig.levels.indexWhere((item) => item.label == level.label).clamp(0, LevelConfig.levels.length - 1);
    final currentLevelConfig = LevelConfig.levels[currentLevelIndex];
    final nextLevelConfig = currentLevelIndex < LevelConfig.levels.length - 1 ? LevelConfig.levels[currentLevelIndex + 1] : null;

    final levelColor = _levelColor(level.label);
    final nextLevelPoints = nextLevelConfig?.minPoints ?? state.totalPoints;
    final nextLevelTrust = nextLevelConfig?.minTrustGate ?? state.requiredMinTrust;
    final currentLevelMinPoints = currentLevelConfig.minPoints;
    final levelPointRange = (nextLevelPoints - currentLevelMinPoints).clamp(1, 1 << 31);
    final currentPointsWithinLevel = (state.totalPoints - currentLevelMinPoints).clamp(0, levelPointRange);
    final pointsProgress = nextLevelConfig == null ? 1.0 : currentPointsWithinLevel / levelPointRange;

    final trustProgress = nextLevelConfig == null
        ? 1.0
        : (state.trustScore / nextLevelTrust.clamp(1, 100)).clamp(0.0, 1.0);

    final pointsRemaining = nextLevelConfig == null ? 0 : (nextLevelPoints - state.totalPoints).clamp(0, nextLevelPoints);
    final trustRemaining = nextLevelConfig == null ? 0 : (nextLevelTrust - state.trustScore).clamp(0, nextLevelTrust);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2B201A),
            Color(0xFF1F1712),
          ],
        ),
        border: Border.all(color: const Color(0xFF5D4A3D).withOpacity(0.65)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.20),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GlassLevelBadge(levelName: level.label, levelColor: levelColor),
          const SizedBox(height: 18),
          _ProgressMetric(
            label: 'Puan İlerlemesi',
            primaryText: '${state.totalPoints} / ${nextLevelConfig == null ? '∞' : nextLevelPoints} Puan',
            helperText: nextLevelConfig == null ? 'Maksimum seviyedesin' : 'Sonraki seviyeye +$pointsRemaining Puan',
            progress: pointsProgress,
            progressColor: levelColor,
          ),
          const SizedBox(height: 14),
          _ProgressMetric(
            label: 'Güven Skoru',
            primaryText: '%${state.trustScore} / %$nextLevelTrust Güven',
            helperText: nextLevelConfig == null ? 'Maksimum seviyedesin' : 'Hedefe +%$trustRemaining Güven Skoru',
            progress: trustProgress,
            progressColor: levelColor.withOpacity(0.92),
          ),
        ],
      ),
    );
  }
}

class _GlassLevelBadge extends StatelessWidget {
  const _GlassLevelBadge({required this.levelName, required this.levelColor});

  final String levelName;
  final Color levelColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: levelColor.withOpacity(0.9), width: 1.3),
        boxShadow: [
          BoxShadow(
            color: levelColor.withOpacity(0.32),
            blurRadius: 14,
            spreadRadius: 0.4,
          ),
        ],
      ),
      child: Text(
        levelName,
        style: TextStyle(
          color: levelColor,
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.1,
          shadows: [
            Shadow(
              color: levelColor.withOpacity(0.65),
              blurRadius: 12,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressMetric extends StatelessWidget {
  const _ProgressMetric({
    required this.label,
    required this.primaryText,
    required this.helperText,
    required this.progress,
    required this.progressColor,
  });

  final String label;
  final String primaryText;
  final String helperText;
  final double progress;
  final Color progressColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFFE8D8CB),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          primaryText,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFFDCCABD),
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 10,
            backgroundColor: const Color(0xFF4A3B32),
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          helperText,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFFEAD7C9),
          ),
        ),
      ],
    );
  }
}

// ---------- Daily Goals Section ----------

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
