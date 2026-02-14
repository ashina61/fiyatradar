import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../admin/admin_panel_screen.dart';
import '../auth/login_screen.dart';
import '../notifications/notifications_screen.dart';

enum ProfileMood { growing, stable, underReview, elite }

enum TrustStability { low, medium, high }

ProfileMood getProfileMood(
  int trend,
  TrustStability stability,
  bool hasRecentReport,
  int streakDays,
  double trustLevel,
) {
  if (trustLevel >= 85 && streakDays >= 7) return ProfileMood.elite;
  if (hasRecentReport || trend < 0) return ProfileMood.underReview;
  if (trend > 0 && stability != TrustStability.low) return ProfileMood.growing;
  return ProfileMood.stable;
}

class ProfileSignals {
  const ProfileSignals({
    required this.trend,
    required this.stability,
    required this.hasRecentReport,
    required this.streakDays,
    required this.trustLevel,
    required this.monthlySavings,
    required this.verifiedActions,
    required this.priceEntries,
    required this.reportsResolved,
    required this.hasAnyImpact,
  });

  factory ProfileSignals.fromUser(UserModel? user) {
    final trustLevel = (user?.reliabilityScore ?? 70).clamp(0.0, 100.0);
    final verifiedActions = user?.validations ?? 0;
    final priceEntries = user?.priceEntries ?? 0;
    final reportsResolved = math.max(0, verifiedActions - (priceEntries ~/ 2));
    final trend = verifiedActions - (priceEntries ~/ 3);
    final stability = trustLevel >= 80
        ? TrustStability.high
        : trustLevel >= 55
            ? TrustStability.medium
            : TrustStability.low;
    final hasRecentReport = trend < -1;
    final streakDays = verifiedActions == 0 ? 0 : math.max(1, verifiedActions ~/ 2);
    final monthlySavings = (user?.points ?? 0) * 3.4;
    final hasAnyImpact = verifiedActions > 0 || priceEntries > 0 || monthlySavings > 1;

    return ProfileSignals(
      trend: trend,
      stability: stability,
      hasRecentReport: hasRecentReport,
      streakDays: streakDays,
      trustLevel: trustLevel,
      monthlySavings: monthlySavings,
      verifiedActions: verifiedActions,
      priceEntries: priceEntries,
      reportsResolved: reportsResolved,
      hasAnyImpact: hasAnyImpact,
    );
  }

  final int trend;
  final TrustStability stability;
  final bool hasRecentReport;
  final int streakDays;
  final double trustLevel;
  final double monthlySavings;
  final int verifiedActions;
  final int priceEntries;
  final int reportsResolved;
  final bool hasAnyImpact;

  ProfileMood get mood =>
      getProfileMood(trend, stability, hasRecentReport, streakDays, trustLevel);
}



class _MoodPresentation {
  const _MoodPresentation({
    required this.auraColor,
    required this.secondaryAuraColor,
    required this.glowOpacity,
    required this.heroMessage,
    required this.reputationInsight,
  });

  final Color auraColor;
  final Color secondaryAuraColor;
  final double glowOpacity;
  final String heroMessage;
  final String reputationInsight;
}

_MoodPresentation _moodPresentation(BuildContext context, ProfileMood mood) {
  final scheme = Theme.of(context).colorScheme;
  switch (mood) {
    case ProfileMood.growing:
      return _MoodPresentation(
        auraColor: Color.alphaBlend(scheme.tertiary.withOpacity(0.18), scheme.primary),
        secondaryAuraColor: scheme.secondary,
        glowOpacity: 0.2,
        heroMessage: 'Yükselen güven profili',
        reputationInsight: 'Bu hafta güvenin yükseliyor. Aynı tempoda devam.',
      );
    case ProfileMood.underReview:
      return _MoodPresentation(
        auraColor: Color.alphaBlend(scheme.surface.withOpacity(0.3), scheme.primary),
        secondaryAuraColor: Color.alphaBlend(scheme.surface.withOpacity(0.25), scheme.secondary),
        glowOpacity: 0.1,
        heroMessage: 'Profil gözlemde, kalite korunuyor',
        reputationInsight: 'Sistem gözlemi aktif. Doğrulama yaparak skoru toparla.',
      );
    case ProfileMood.elite:
      return _MoodPresentation(
        auraColor: Color.alphaBlend(scheme.tertiary.withOpacity(0.45), scheme.primary),
        secondaryAuraColor: Color.alphaBlend(scheme.tertiary.withOpacity(0.25), scheme.secondary),
        glowOpacity: 0.26,
        heroMessage: 'Elit güven standardı',
        reputationInsight: 'Elit katkıdasın. Topluluğa liderlik ediyorsun.',
      );
    case ProfileMood.stable:
      return _MoodPresentation(
        auraColor: scheme.primary,
        secondaryAuraColor: scheme.secondary,
        glowOpacity: 0.12,
        heroMessage: 'Profil ritmi stabil',
        reputationInsight: 'Profil stabil. Daha fazla doğrulama ile seviye atlayabilirsin.',
      );
  }
}

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _scrollT = ValueNotifier<double>(0);
  late final AnimationController _introController;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..forward();
  }

  void _onScroll() {
    final normalized = (_scrollController.offset / 160).clamp(0.0, 1.0);
    _scrollT.value = normalized;
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _scrollT.dispose();
    _introController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userModelStreamProvider);
    final user = userAsync.valueOrNull;
    final signals = ProfileSignals.fromUser(user);
    final mood = signals.mood;

    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: CurvedAnimation(
            parent: _introController,
            curve: Curves.easeOutCubic,
          ),
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: ValueListenableBuilder<double>(
                  valueListenable: _scrollT,
                  builder: (context, t, _) => ProfileHero(user: user, scrollT: t, mood: mood, signals: signals),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                sliver: SliverList.list(
                  children: [
                    ReputationCard(user: user, signals: signals, mood: mood),
                    const SizedBox(height: 16),
                    ActivityFeed(user: user, signals: signals, mood: mood),
                    const SizedBox(height: 16),
                    ImpactPanel(user: user, signals: signals),
                    const SizedBox(height: 16),
                    BadgeCarousel(user: user, signals: signals),
                    const SizedBox(height: 16),
                    QuickActionBar(
                      mood: mood,
                      onMyPrices: _showMyPrices,
                      onReceipts: _showReceipts,
                      onFavorites: _showFavorites,
                      onNotifications: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const NotificationsScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    SettingsSection(
                      user: user,
                      onThemeToggle: () => ref
                          .read(themeModeProvider.notifier)
                          .toggleDarkMode(),
                      onEdit: _showProfileEdit,
                      onSecurity: _showSecurity,
                      onLogout: _logout,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMyPrices() {
    _showSnack('Fiyatlarım yakında daha detaylı görünümle burada olacak.');
  }

  void _showReceipts() {
    _showSnack('Fişlerim bölümü hazırlanıyor.');
  }

  void _showFavorites() {
    _showSnack('Favorilerim bölümü hazırlanıyor.');
  }

  void _showProfileEdit() {
    _showSnack('Profil düzenleme akışı güncellenecek.');
  }

  void _showSecurity() {
    _showSnack('Güvenlik tercihleri yakında burada olacak.');
  }

  Future<void> _logout() async {
    await ref.read(authServiceProvider).signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class ProfileHero extends StatefulWidget {
  const ProfileHero({
    super.key,
    required this.user,
    required this.scrollT,
    required this.mood,
    required this.signals,
  });

  final UserModel? user;
  final double scrollT;
  final ProfileMood mood;
  final ProfileSignals signals;

  @override
  State<ProfileHero> createState() => _ProfileHeroState();
}

class _ProfileHeroState extends State<ProfileHero> with SingleTickerProviderStateMixin {
  late final AnimationController _sparkleController;

  @override
  void initState() {
    super.initState();
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final user = widget.user;
    final moodPresentation = _moodPresentation(context, widget.mood);
    final trustScore = widget.signals.trustLevel;
    final trustBand = trustScore >= 80
        ? 'Elite Contributor'
        : trustScore >= 60
            ? 'Pro Contributor'
            : 'Rising Contributor';

    final auraOpacity = theme.brightness == Brightness.dark
        ? moodPresentation.glowOpacity * 0.75
        : moodPresentation.glowOpacity;
    final heroScale = (1 - (0.06 * widget.scrollT)).clamp(0.94, 1.0);
    final heroTranslate = widget.scrollT * 19.2;
    final avatarParallax = widget.scrollT * 16;

    return Transform.translate(
      offset: Offset(0, heroTranslate),
      child: Transform.scale(
        scale: heroScale,
        alignment: Alignment.topCenter,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scheme.primaryContainer,
                Color.alphaBlend(
                  scheme.surface.withOpacity(0.35),
                  scheme.secondaryContainer,
                ),
              ],
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Stack(
              children: [
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: const SizedBox.expand(),
                  ),
                ),
                Positioned(
                  top: -30 - (widget.scrollT * 10),
                  right: -12,
                  child: _GlowOrb(
                    color: moodPresentation.auraColor.withOpacity(auraOpacity),
                    size: 160,
                  ),
                ),
                Positioned(
                  left: -42,
                  bottom: -54 + (widget.scrollT * 12),
                  child: _GlowOrb(
                    color: moodPresentation.secondaryAuraColor.withOpacity(auraOpacity * 0.85),
                    size: 180,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Transform.translate(
                        offset: Offset(0, avatarParallax),
                        child: RepaintBoundary(
                          child: _AvatarTrustRing(
                            imageUrl: user?.photoUrl,
                            initials: _initials(user?.name),
                            auraColor:
                                moodPresentation.auraColor.withOpacity(auraOpacity + 0.06),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user?.name.isNotEmpty == true
                                  ? user!.name
                                  : 'FiyatRadar Kullanıcısı',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Icon(
                                Icons.verified_rounded,
                                color: scheme.primary,
                              ),
                              if (widget.mood == ProfileMood.elite)
                                Positioned(
                                  top: -3,
                                  right: -3,
                                  child: FadeTransition(
                                    opacity: Tween<double>(begin: 0.25, end: 0.85).animate(
                                      CurvedAnimation(
                                        parent: _sparkleController,
                                        curve: Curves.easeOutCubic,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.auto_awesome_rounded,
                                      size: 11,
                                      color: scheme.tertiary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        trustBand,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        moodPresentation.heroMessage,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _CollapsibleTrustSliver(
                        trustScore: trustScore,
                        collapsedT: widget.scrollT,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _initials(String? value) {
    if (value == null || value.trim().isEmpty) return 'FR';
    final parts = value.trim().split(' ');
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _CollapsibleTrustSliver extends StatelessWidget {
  const _CollapsibleTrustSliver({required this.trustScore, required this.collapsedT});

  final double trustScore;
  final double collapsedT;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surface.withOpacity(0.65),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: LinearProgressIndicator(
              minHeight: 6,
              value: trustScore / 100,
              borderRadius: BorderRadius.circular(99),
              backgroundColor: scheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
            ),
          ),
          const SizedBox(width: 12),
          Text('${trustScore.toStringAsFixed(0)}%', style: Theme.of(context).textTheme.labelLarge),
          if (collapsedT < 0.7) const SizedBox(width: 8),
          if (collapsedT < 0.7)
            Opacity(
              opacity: 1 - collapsedT,
              child: Icon(Icons.auto_awesome_rounded, size: 18, color: scheme.primary),
            ),
        ],
      ),
    );
  }
}

class _AvatarTrustRing extends StatelessWidget {
  const _AvatarTrustRing({
    required this.imageUrl,
    required this.initials,
    required this.auraColor,
  });

  final String? imageUrl;
  final String initials;
  final Color auraColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 92,
      width: 92,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: auraColor,
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: CircleAvatar(
        backgroundColor: scheme.surface,
        child: CircleAvatar(
          radius: 42,
          backgroundColor: scheme.surfaceContainerHigh,
          backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
              ? NetworkImage(imageUrl!)
              : null,
          child: imageUrl == null || imageUrl!.isEmpty
              ? Text(
                  initials,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                )
              : null,
        ),
      ),
    );
  }
}

class ReputationCard extends StatelessWidget {
  const ReputationCard({
    super.key,
    required this.user,
    required this.signals,
    required this.mood,
  });

  final UserModel? user;
  final ProfileSignals signals;
  final ProfileMood mood;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final score = signals.trustLevel;
    final weekly = signals.trend;
    final stability = signals.stability.name[0].toUpperCase() + signals.stability.name.substring(1);
    final moodPresentation = _moodPresentation(context, mood);

    return _GlassCard(
      pulse: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('AI Reputation Core', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'Social Trust Score',
                  value: score.toStringAsFixed(0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricTile(
                  label: 'Weekly Trend',
                  value: weekly >= 0 ? '+$weekly' : '$weekly',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricTile(
                  label: 'Stability',
                  value: stability,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: scheme.surface.withOpacity(0.7),
              border: Border.all(color: scheme.outlineVariant.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                Icon(
                  weekly >= 0 ? Icons.trending_up_rounded : Icons.trending_flat_rounded,
                  color: moodPresentation.auraColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    moodPresentation.reputationInsight,
                    style: theme.textTheme.bodyMedium,
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

class ActivityFeed extends StatelessWidget {
  const ActivityFeed({
    super.key,
    required this.user,
    required this.signals,
    required this.mood,
  });

  final UserModel? user;
  final ProfileSignals signals;
  final ProfileMood mood;

  @override
  Widget build(BuildContext context) {
    final validations = user?.validations ?? 0;
    final events = <_ActivityEvent>[
      _ActivityEvent('✔ Price verified', 'AI doğrulama motoru fiyatı güvenli buldu.'),
      _ActivityEvent('🔥 Contribution gained', '+${math.max(1, validations ~/ 5)} etki puanı kazanıldı.'),
      const _ActivityEvent('📌 Top contributor', 'Katkı yoğunluğu bu hafta öne çıktı.'),
      const _ActivityEvent('⚠ Report received', 'Sistem gözlemi aktif, profil stabilitesi korunuyor.'),
    ];

    if (mood == ProfileMood.underReview) {
      events
        ..removeWhere((e) => e.title.contains('Report received'))
        ..insert(
          0,
          const _ActivityEvent('⚠ Report received', 'Sistem gözlemi aktif. İnceleme kartı önceliklendirildi.'),
        );
    } else if (mood == ProfileMood.elite) {
      events
        ..removeWhere((e) => e.title.contains('Top contributor'))
        ..insert(
          0,
          const _ActivityEvent('👑 Top contributor', 'Topluluk güveninde lider katkı sağlıyorsun.'),
        );
    }

    if (signals.verifiedActions + signals.priceEntries == 0) {
      return _GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Live Activity Feed', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            const _FirstStepCard(
              title: 'İlk fiyatını ekle',
              subtitle: 'Veri akışını başlatıp profilini görünür hale getir.',
            ),
            const SizedBox(height: 10),
            const _FirstStepCard(
              title: 'Bir fiyat doğrula',
              subtitle: 'Doğrulama adımı güven trendini hızla güçlendirir.',
            ),
          ],
        ),
      );
    }

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Live Activity Feed', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...List.generate(events.length, (i) {
            return _StaggeredFadeSlide(
              index: i,
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _ActivityRow(event: events[i], isPriority: i == 0 && (mood == ProfileMood.underReview || mood == ProfileMood.elite)),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _FirstStepCard extends StatelessWidget {
  const _FirstStepCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: scheme.surface.withOpacity(0.72),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _ActivityEvent {
  const _ActivityEvent(this.title, this.subtitle);
  final String title;
  final String subtitle;
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.event, this.isPriority = false});

  final _ActivityEvent event;
  final bool isPriority;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      padding: isPriority ? const EdgeInsets.all(10) : EdgeInsets.zero,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isPriority
            ? scheme.secondaryContainer.withOpacity(0.35)
            : Colors.transparent,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: scheme.outlineVariant.withOpacity(0.35),
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(event.subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ImpactPanel extends StatelessWidget {
  const ImpactPanel({super.key, required this.user, required this.signals});

  final UserModel? user;
  final ProfileSignals signals;

  @override
  Widget build(BuildContext context) {
    final monthlyImpact = signals.monthlySavings;
    final streak = signals.streakDays;
    final highSavings = monthlyImpact >= 500;

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Impact Engine', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          if (!signals.hasAnyImpact) const _StartContributingCard()
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _CapsuleChip(
                  label: 'Monthly Savings',
                  value: '₺${monthlyImpact.toStringAsFixed(0)}',
                  emphasized: highSavings,
                ),
                const _CapsuleChip(label: 'Top Market', value: 'Migros'),
                if (streak > 0)
                  _CapsuleChip(
                    label: 'Activity Streak',
                    value: '$streak days',
                    pulse: true,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class BadgeCarousel extends StatefulWidget {
  const BadgeCarousel({super.key, required this.user, required this.signals});

  final UserModel? user;
  final ProfileSignals signals;

  @override
  State<BadgeCarousel> createState() => _BadgeCarouselState();
}

class _BadgeCarouselState extends State<BadgeCarousel> {
  int selected = 0;

  @override
  Widget build(BuildContext context) {
    final badges = [
      ('Doğrulayıcı', 'Onay kaliteni büyütür', widget.signals.verifiedActions),
      ('Fiyat Avcısı', 'Fiyat girişlerinde hız kazandırır', widget.signals.priceEntries),
      ('Signal Guard', 'Rapor yönetim ustalığı', widget.signals.reportsResolved),
    ]..sort((a, b) => b.$3.compareTo(a.$3));

    final recommended = badges.last;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Badge Cinema', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: badges.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final isSelected = selected == index;
              return _PressableScale(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => selected = index);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  width: 220,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    color: Theme.of(context).colorScheme.surface.withOpacity(0.74),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.35),
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                          blurRadius: 18,
                        ),
                    ],
                  ),
                  child: Transform.scale(
                    scale: isSelected ? 1.02 : 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(badges[index].$1, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text(badges[index].$2, style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        _RecommendedBadgeCard(title: recommended.$1),
      ],
    );
  }
}

class QuickActionBar extends StatelessWidget {
  const QuickActionBar({
    super.key,
    required this.mood,
    required this.onMyPrices,
    required this.onReceipts,
    required this.onFavorites,
    required this.onNotifications,
  });

  final ProfileMood mood;
  final VoidCallback onMyPrices;
  final VoidCallback onReceipts;
  final VoidCallback onFavorites;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              color: scheme.surface.withOpacity(0.82),
              border: Border.all(color: scheme.outlineVariant.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ActionIcon(label: 'Fiyatlarım', icon: Icons.price_change_outlined, onTap: onMyPrices, highlighted: mood == ProfileMood.stable || mood == ProfileMood.growing),
                _ActionIcon(label: 'Fişlerim', icon: Icons.receipt_long_outlined, onTap: onReceipts),
                _ActionIcon(
                  label: mood == ProfileMood.underReview ? 'Doğrulamalar' : mood == ProfileMood.elite ? 'Topluluk' : 'Favoriler',
                  icon: mood == ProfileMood.underReview ? Icons.shield_outlined : mood == ProfileMood.elite ? Icons.groups_2_outlined : Icons.favorite_outline,
                  onTap: onFavorites,
                  highlighted: mood == ProfileMood.underReview || mood == ProfileMood.elite,
                ),
                _ActionIcon(label: 'Bildirimler', icon: Icons.notifications_none, onTap: onNotifications),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SettingsSection extends ConsumerWidget {
  const SettingsSection({
    super.key,
    required this.user,
    required this.onThemeToggle,
    required this.onEdit,
    required this.onSecurity,
    required this.onLogout,
  });

  final UserModel? user;
  final VoidCallback onThemeToggle;
  final VoidCallback onEdit;
  final VoidCallback onSecurity;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Settings', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _SettingTile(icon: Icons.edit_outlined, title: 'Profile Edit', onTap: onEdit),
          _SettingTile(
            icon: Icons.dark_mode_outlined,
            title: 'Dark Mode',
            trailing: Switch(
              value: mode == ThemeMode.dark,
              onChanged: (_) => onThemeToggle(),
            ),
          ),
          _SettingTile(icon: Icons.notifications_outlined, title: 'Notifications', onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
          }),
          _SettingTile(icon: Icons.shield_outlined, title: 'Security', onTap: onSecurity),
          if (user?.isAdmin ?? false)
            _SettingTile(
              icon: Icons.admin_panel_settings_outlined,
              title: 'Admin Panel',
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminPanelScreen()));
              },
            ),
          _SettingTile(
            icon: Icons.logout_rounded,
            title: 'Logout',
            onTap: () {
              onLogout();
            },
          ),
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.label,
    required this.icon,
    required this.onTap,
    this.highlighted = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return _PressableScale(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: highlighted
              ? Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({required this.icon, required this.title, this.onTap, this.trailing});

  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: scheme.outlineVariant.withOpacity(0.32))),
        ),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 10),
            Expanded(child: Text(title)),
            trailing ?? const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: scheme.surface.withOpacity(0.68),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
          Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _RecommendedBadgeCard extends StatelessWidget {
  const _RecommendedBadgeCard({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: scheme.surface.withOpacity(0.72),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.35)),
      ),
      child: Text('Sıradaki önerilen rozet: $title', style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

class _StartContributingCard extends StatelessWidget {
  const _StartContributingCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: scheme.secondaryContainer.withOpacity(0.35),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Katkıya başla', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('İlk fiyat veya doğrulama ile etki motorunu aktive et.', style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _CapsuleChip extends StatefulWidget {
  const _CapsuleChip({
    required this.label,
    required this.value,
    this.emphasized = false,
    this.pulse = false,
  });

  final String label;
  final String value;
  final bool emphasized;
  final bool pulse;

  @override
  State<_CapsuleChip> createState() => _CapsuleChipState();
}

class _CapsuleChipState extends State<_CapsuleChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      lowerBound: 0.97,
      upperBound: 1,
    );
    if (widget.pulse) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.value = 1;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ScaleTransition(
      scale: _pulseController,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        scale: widget.emphasized ? 1.05 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            color: scheme.secondaryContainer.withOpacity(0.55),
            border: widget.emphasized
                ? Border.all(color: scheme.primary.withOpacity(0.3))
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.label, style: Theme.of(context).textTheme.labelSmall),
              Text(
                widget.value,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassCard extends StatefulWidget {
  const _GlassCard({required this.child, this.pulse = false});

  final Widget child;
  final bool pulse;

  @override
  State<_GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<_GlassCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      lowerBound: 0.98,
      upperBound: 1,
    );
    if (widget.pulse) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.value = 1;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ScaleTransition(
      scale: _pulseController,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: scheme.surface.withOpacity(0.72),
          border: Border.all(color: scheme.outlineVariant.withOpacity(0.35)),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: widget.child,
      ),
    );
  }
}

class _StaggeredFadeSlide extends StatefulWidget {
  const _StaggeredFadeSlide({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_StaggeredFadeSlide> createState() => _StaggeredFadeSlideState();
}

class _StaggeredFadeSlideState extends State<_StaggeredFadeSlide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _offset = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(_opacity);
    Future<void>.delayed(Duration(milliseconds: widget.index * 40), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}

class _PressableScale extends StatefulWidget {
  const _PressableScale({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        scale: _pressed ? 0.97 : 1,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          opacity: _pressed ? 0.94 : 1,
          child: widget.child,
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}
