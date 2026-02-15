import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/theme.dart';
import '../admin/admin_panel_screen.dart';
import '../auth/login_screen.dart';
import '../notifications/notifications_screen.dart';
import '../product/product_detail_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int _reloadKey = 0;
  bool _unlockHandled = false;
  bool _showUnlockOverlay = false;
  Map<String, dynamic>? _unlockedBadge;
  String? _lastShownBadgeId;

  Future<ProfileBundle> _loadProfileBundle(UserModel fallbackUser) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        return ProfileBundle.empty(fallbackUser);
      }

      final firestore = FirebaseFirestore.instance;
      final doc = await firestore.collection('users').doc(uid).get().timeout(const Duration(seconds: 8));
      final profileData = (doc.data() ?? <String, dynamic>{});

      List<Map<String, dynamic>> activities = const [];
      try {
        final query = await firestore
            .collection('users')
            .doc(uid)
            .collection('activity')
            .orderBy('createdAt', descending: true)
            .limit(12)
            .get()
            .timeout(const Duration(seconds: 8));
        activities = query.docs.map((e) => e.data()).toList(growable: false);
      } catch (_) {
        activities = _readActivityListFromUserDoc(profileData);
      }

      final badgesFuture = firestore.collection('badges').orderBy('order').get();
      final userBadgesFuture = firestore.collection('users').doc(uid).collection('badges').get();
      final pricesFuture = firestore
          .collection('users')
          .doc(uid)
          .collection('prices')
          .orderBy('date', descending: true)
          .limit(200)
          .get();

      final results = await Future.wait([badgesFuture, userBadgesFuture, pricesFuture]).timeout(
        const Duration(seconds: 10),
      );

      final badgeMaster = (results[0] as QuerySnapshot<Map<String, dynamic>>)
          .docs
          .map((e) => {'id': e.id, ...e.data()})
          .toList(growable: false);
      final userBadgeIds = (results[1] as QuerySnapshot<Map<String, dynamic>>).docs.map((e) => e.id).toSet();
      final userPrices = (results[2] as QuerySnapshot<Map<String, dynamic>>).docs.map((e) => e.data()).toList(growable: false);

      return ProfileBundle.fromData(
        fallbackUser: fallbackUser,
        profileData: profileData,
        activities: activities,
        badgeMaster: badgeMaster,
        userBadgeIds: userBadgeIds,
        userPrices: userPrices,
      );
    } on TimeoutException {
      return ProfileBundle.error(
        fallbackUser,
        'Profil verisi zaman aşımına uğradı. Lütfen tekrar deneyin.',
      );
    } catch (_) {
      return ProfileBundle.error(
        fallbackUser,
        'Bir şeyler ters gitti. Profil bilgileri yüklenemedi.',
      );
    }
  }

  List<Map<String, dynamic>> _readActivityListFromUserDoc(
    Map<String, dynamic> profileData,
  ) {
    final raw = profileData['activityFeed'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList(growable: false);
  }

  Future<void> _openEditProfile() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );
    if (!mounted) return;
    setState(() {
      _reloadKey++;
      _unlockHandled = false;
    });
  }

  Future<void> _markUnlockAsSeen() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'justUnlockedBadge': false,
        'newBadgeFlag': false,
      }).timeout(const Duration(seconds: 8));
    } catch (_) {
      // Sessizce geçiyoruz, UI akışını bozmayalım.
    }
  }

  void _handleUnlockOverlay(ProfileBundle bundle) {
    final badgeId = (bundle.unlockedBadge?['id'] ?? bundle.unlockedBadge?['name'] ?? '').toString();
    if (_unlockHandled || !bundle.justUnlockedBadge || bundle.unlockedBadge == null || !mounted || badgeId.isEmpty || badgeId == _lastShownBadgeId) {
      return;
    }

    _unlockHandled = true;
    _markUnlockAsSeen();
    HapticFeedback.lightImpact();
    _lastShownBadgeId = badgeId;
    setState(() {
      _showUnlockOverlay = true;
      _unlockedBadge = bundle.unlockedBadge;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _showUnlockOverlay = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userModelStreamProvider);

    if (FirebaseAuth.instance.currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      });
      return const Scaffold(body: _ProfileLoadingView());
    }

    final fallbackUser = UserModel(
      uid: 'misafir',
      email: '',
      name: 'Kullanıcı',
      createdAt: DateTime.now(),
      reliabilityScore: 0,
    );

    return SafeArea(
      child: Scaffold(
        body: userAsync.when(
          loading: () => const _ProfileLoadingView(),
          error: (_, __) {
            final bundle = ProfileBundle.error(
              fallbackUser,
              'Bir şeyler ters gitti. Lütfen tekrar deneyin.',
            );
            return _ProfileScaffoldBody(
              bundle: bundle,
              user: fallbackUser,
              onRetry: () => setState(() => _reloadKey++),
              onEditProfile: _openEditProfile,
              showUnlockOverlay: _showUnlockOverlay,
              unlockedBadge: _unlockedBadge,
              onDismissOverlay: () => setState(() => _showUnlockOverlay = false),
            );
          },
          data: (user) {
            final safeUser = user ?? fallbackUser;
            return FutureBuilder<ProfileBundle>(
              key: ValueKey(_reloadKey),
              future: _loadProfileBundle(safeUser),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _ProfileLoadingView();
                }

                final bundle = snapshot.data ??
                    ProfileBundle.error(
                      safeUser,
                      'Bir şeyler ters gitti. Profil bölümü açılamadı.',
                    );

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _handleUnlockOverlay(bundle);
                });

                return _ProfileScaffoldBody(
                  bundle: bundle,
                  user: safeUser,
                  onRetry: () => setState(() => _reloadKey++),
                  onEditProfile: _openEditProfile,
                  showUnlockOverlay: _showUnlockOverlay,
                  unlockedBadge: _unlockedBadge,
                  onDismissOverlay: () => setState(() => _showUnlockOverlay = false),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ProfileScaffoldBody extends StatefulWidget {
  const _ProfileScaffoldBody({
    required this.bundle,
    required this.user,
    required this.onRetry,
    required this.onEditProfile,
    required this.showUnlockOverlay,
    required this.unlockedBadge,
    required this.onDismissOverlay,
  });

  final ProfileBundle bundle;
  final UserModel user;
  final VoidCallback onRetry;
  final VoidCallback onEditProfile;
  final bool showUnlockOverlay;
  final Map<String, dynamic>? unlockedBadge;
  final VoidCallback onDismissOverlay;

  @override
  State<_ProfileScaffoldBody> createState() => _ProfileScaffoldBodyState();
}

class _ProfileScaffoldBodyState extends State<_ProfileScaffoldBody> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.bundle.profile;

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () async => widget.onRetry(),
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 340,
                title: const Text('Profil'),
                flexibleSpace: AnimatedBuilder(
                  animation: _scrollController,
                  builder: (context, child) {
                    final offset = _scrollController.hasClients ? _scrollController.offset.clamp(0, 220) : 0.0;
                    final t = (offset / 220);
                    final scale = 1 - (0.08 * t);
                    final blur = 0.5 + (3 * t);
                    final radius = 24 + (6 * t);

                    return FlexibleSpaceBar(
                      background: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 86, 16, 12),
                        child: Transform.scale(
                          scale: scale,
                          alignment: Alignment.topCenter,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(radius),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                              child: Opacity(
                                opacity: 1 - (0.08 * t),
                                child: ProfileHeroCard(
                                  displayName: profile.displayName,
                                  avatarUrl: profile.avatarUrl,
                                  trustScore: profile.trustScore,
                                  levelName: profile.levelName,
                                  onEditProfile: widget.onEditProfile,
                                  avatarChangedAt: profile.avatarChangedAt,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (widget.bundle.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ErrorCard(
                          message: widget.bundle.errorMessage!,
                          onRetry: widget.onRetry,
                        ),
                      ),
                    StatChipsRow(
                      streakDays: profile.streakDays,
                      monthlySavings: profile.monthlySavings,
                      topMarketName: profile.topMarketName,
                    ),
                    const SizedBox(height: 16),
                    QuickActionsBar(userId: widget.user.uid),
                    const SizedBox(height: 16),
                    BadgeCinema(
                      badges: profile.badges,
                      animateFirstUnlock: widget.bundle.justUnlockedBadge,
                    ),
                    const SizedBox(height: 16),
                    LiveActivityTimeline(activities: widget.bundle.activities),
                    const SizedBox(height: 16),
                    PremiumSettingsPanel(user: widget.user, onEditProfile: widget.onEditProfile),
                  ]),
                ),
              ),
            ],
          ),
        ),
        UnlockBadgeToastOverlay(
          visible: widget.showUnlockOverlay,
          badge: widget.unlockedBadge,
          onDismiss: widget.onDismissOverlay,
        ),
      ],
    );
  }
}

class ProfileHeroCard extends StatefulWidget {
  const ProfileHeroCard({
    super.key,
    required this.displayName,
    required this.avatarUrl,
    required this.trustScore,
    required this.levelName,
    required this.onEditProfile,
    required this.avatarChangedAt,
  });

  final String displayName;
  final String? avatarUrl;
  final double trustScore;
  final String levelName;
  final VoidCallback onEditProfile;
  final DateTime? avatarChangedAt;

  @override
  State<ProfileHeroCard> createState() => _ProfileHeroCardState();
}

class _ProfileHeroCardState extends State<ProfileHeroCard> with SingleTickerProviderStateMixin {
  late final AnimationController _rippleController;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  }

  @override
  void didUpdateWidget(covariant ProfileHeroCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.avatarChangedAt != null && widget.avatarChangedAt != oldWidget.avatarChangedAt) {
      _rippleController.forward(from: 0);
      HapticFeedback.selectionClick();
    }
  }

  @override
  void dispose() {
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final safeScore = widget.trustScore.clamp(0, 100).toDouble();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            const Color(0xFFEAD8A8).withOpacity(0.46),
            cs.surface.withOpacity(0.94),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 88,
                height: 88,
                child: AnimatedBuilder(
                  animation: _rippleController,
                  builder: (context, _) {
                    final t = _rippleController.value;
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        if (t > 0)
                          Container(
                            width: 66 + (28 * t),
                            height: 66 + (28 * t),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFD4AF37).withOpacity((0.25 * (1 - t)).clamp(0, 0.25)),
                            ),
                          ),
                        if (t > 0)
                          Container(
                            width: 66 + (40 * t),
                            height: 66 + (40 * t),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFD4AF37).withOpacity((0.18 * (1 - t)).clamp(0, 0.2)),
                              ),
                            ),
                          ),
                        CircleAvatar(
                          radius: 38,
                          backgroundColor: cs.surface,
                          backgroundImage: (widget.avatarUrl ?? '').isNotEmpty ? NetworkImage(widget.avatarUrl!) : null,
                          child: (widget.avatarUrl ?? '').isEmpty
                              ? Text(
                                  widget.displayName.isNotEmpty ? widget.displayName[0].toUpperCase() : 'K',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 24),
                                )
                              : null,
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.verified_rounded, color: Colors.blue, size: 16),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: cs.secondaryContainer.withOpacity(0.45),
                      ),
                      child: Text(
                        '${widget.levelName} seviyesi',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: widget.onEditProfile,
                icon: const Icon(Icons.edit_rounded),
                tooltip: 'Profili Düzenle',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _TrustScoreRing(score: safeScore),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Güven skoru topluluk doğrulamalarına göre hesaplanır.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class StatChipsRow extends StatelessWidget {
  const StatChipsRow({
    super.key,
    required this.streakDays,
    required this.monthlySavings,
    required this.topMarketName,
  });

  final int streakDays;
  final String monthlySavings;
  final String topMarketName;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _StatChip(icon: Icons.local_fire_department_rounded, label: 'Seri', value: '$streakDays gün'),
        _StatChip(icon: Icons.savings_rounded, label: 'Aylık tasarruf', value: monthlySavings),
        _StatChip(
          icon: Icons.storefront_rounded,
          label: 'Verilere göre öne çıkan market',
          value: topMarketName,
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 160),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.primaryDark),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelSmall),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BadgeCinema extends StatefulWidget {
  const BadgeCinema({
    super.key,
    required this.badges,
    this.avatarChangedAt,
    this.animateFirstUnlock = false,
  });

  final List<Map<String, dynamic>> badges;
  final DateTime? avatarChangedAt;
  final bool animateFirstUnlock;

  @override
  State<BadgeCinema> createState() => _BadgeCinemaState();
}

class _BadgeCinemaState extends State<BadgeCinema> with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;
  bool _playedFirstUnlock = false;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    if (widget.animateFirstUnlock) {
      _playedFirstUnlock = true;
      _glowController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant BadgeCinema oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animateFirstUnlock && !_playedFirstUnlock) {
      _playedFirstUnlock = true;
      _glowController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final badges = widget.badges;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Rozet Sineması', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 10),
        if (badges.isEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 90,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 4,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) => _LockedBadgePreview(glowController: _glowController),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Katkı yaptıkça yeni rozetler açılacak.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          )
        else
          SizedBox(
            height: 132,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: badges.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final badge = badges[index];
                final unlocked = (badge['isUnlocked'] as bool?) ?? false;
                final title = (badge['name'] ?? 'Rozet').toString();
                final subtitle = (badge['description'] ?? 'Topluluk rozeti').toString();

                return Container(
                  width: 180,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: unlocked
                        ? LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.7),
                              Theme.of(context).colorScheme.surface,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: unlocked ? null : Theme.of(context).colorScheme.surfaceContainerHighest,
                    border: Border.all(
                      color: unlocked
                          ? AppColors.secondaryDark.withOpacity(0.35)
                          : AppColors.outlineVariant.withOpacity(0.6),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: unlocked
                                ? AppColors.secondary.withOpacity(0.25)
                                : Colors.grey.withOpacity(0.2),
                            child: Icon(
                              _badgeIconFromCodePoint(badge['iconCodePoint'] as int?),
                              color: unlocked ? AppColors.primaryDark : Colors.grey,
                            ),
                          ),
                          const Spacer(),
                          _AnimatedBadgeLockIcon(
                            unlocked: unlocked,
                            playUnlockAnimation: widget.animateFirstUnlock && index == 0 && unlocked,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class QuickActionsBar extends StatelessWidget {
  QuickActionsBar({super.key, required this.userId});

  final String userId;

  final List<_QuickActionData> _actions = const [
    _QuickActionData(title: 'Fiyatlarım', icon: Icons.sell_rounded),
    _QuickActionData(title: 'Fişlerim', icon: Icons.receipt_long_rounded),
    _QuickActionData(title: 'Favoriler', icon: Icons.favorite_rounded),
    _QuickActionData(title: 'Bildirimler', icon: Icons.notifications_active_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: _actions
            .map(
              (action) => Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () {
                    if (action.title == 'Bildirimler') {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                      );
                      return;
                    }
                    if (action.title == 'Fiyatlarım') {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => MyPricesScreen(userId: userId)),
                      );
                      return;
                    }
                    if (action.title == 'Favoriler') {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => FavoritesScreen(userId: userId)),
                      );
                      return;
                    }
                    if (action.title == 'Fişlerim') {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => ReceiptsScreen(userId: userId)),
                      );
                      return;
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${action.title} özelliği yakında.')),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(action.icon, color: AppColors.primaryDark),
                        const SizedBox(height: 4),
                        Text(
                          action.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class LiveActivityTimeline extends StatelessWidget {
  const LiveActivityTimeline({super.key, required this.activities});

  final List<Map<String, dynamic>> activities;

  @override
  Widget build(BuildContext context) {
    final list = activities;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Canlı Aktivite Akışı', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 10),
        if (list.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.outlineVariant.withOpacity(0.55)),
              color: Theme.of(context).colorScheme.surface,
            ),
            child: const Text('Henüz aktivite yok.'),
          )
        else
          ...list.map(
          (activity) {
            final title = (activity['title'] ?? 'Aktivite').toString();
            final icon = _timelineIcon(title);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Theme.of(context).colorScheme.surface,
                border: Border.all(color: AppColors.outlineVariant.withOpacity(0.55)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: icon.color.withOpacity(0.15),
                    child: Icon(icon.icon, color: icon.color, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text((activity['description'] ?? 'Detay bulunamadı.').toString()),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class PremiumSettingsPanel extends ConsumerWidget {
  const PremiumSettingsPanel({super.key, required this.user, required this.onEditProfile});

  final UserModel user;
  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ayarlar', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 8),
        _SettingsTile(icon: Icons.edit_rounded, title: 'Profili Düzenle', onTap: onEditProfile),
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
          ),
          child: SwitchListTile.adaptive(
            value: themeMode == ThemeMode.dark,
            onChanged: (_) => ref.read(themeModeProvider.notifier).toggleDarkMode(),
            title: const Text('Karanlık Mod'),
            secondary: const Icon(Icons.dark_mode_rounded, color: AppColors.primaryDark),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
        ),
        _SettingsTile(
          icon: Icons.notifications_rounded,
          title: 'Bildirim Ayarları',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
          ),
        ),
        _SettingsTile(
          icon: Icons.security_rounded,
          title: 'Güvenlik',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SecurityScreen()),
          ),
        ),
        if (user.isAdmin)
          _SettingsTile(
            icon: Icons.admin_panel_settings_rounded,
            title: 'Admin Paneli',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
            ),
          ),
        _SettingsTile(
          icon: Icons.info_outline_rounded,
          title: 'Hakkında',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AboutScreen()),
          ),
        ),
        _SettingsTile(
          icon: Icons.logout_rounded,
          title: 'Çıkış Yap',
          color: AppColors.error,
          onTap: () async {
            final shouldLogout =
                await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Çıkış Yap'),
                    content: const Text('Hesabından çıkış yapmak istediğine emin misin?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Vazgeç'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Çıkış Yap'),
                      ),
                    ],
                  ),
                ) ??
                false;

            if (!shouldLogout) return;

            await ref.read(authServiceProvider).signOut();
            if (!context.mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          },
        ),
      ],
    );
  }
}

class UnlockBadgeToastOverlay extends StatefulWidget {
  const UnlockBadgeToastOverlay({
    super.key,
    required this.visible,
    required this.badge,
    required this.onDismiss,
  });

  final bool visible;
  final Map<String, dynamic>? badge;
  final VoidCallback onDismiss;

  @override
  State<UnlockBadgeToastOverlay> createState() => _UnlockBadgeToastOverlayState();
}

class _UnlockBadgeToastOverlayState extends State<UnlockBadgeToastOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    if (widget.visible) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant UnlockBadgeToastOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !oldWidget.visible) {
      _controller.forward(from: 0);
    }
    if (!widget.visible && oldWidget.visible) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible || widget.badge == null) {
      return const SizedBox.shrink();
    }

    final badgeName = (widget.badge?['name'] ?? 'Özel Rozet').toString();
    final iconData = _badgeIconFromCodePoint(widget.badge?['iconCodePoint'] as int?);

    return Positioned.fill(
      child: GestureDetector(
        onTap: widget.onDismiss,
        child: ColoredBox(
          color: Colors.black.withOpacity(0.2),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2.6, sigmaY: 2.6),
            child: Center(
              child: FadeTransition(
                opacity: CurvedAnimation(parent: _controller, curve: Curves.easeOut),
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.8, end: 1).animate(
                    CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
                  ),
                  child: Container(
                    width: 290,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      color: Theme.of(context).colorScheme.surface.withOpacity(0.92),
                      border: Border.all(color: AppColors.secondary.withOpacity(0.5)),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.secondaryDark.withOpacity(0.22),
                          blurRadius: 22,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🎉 Yeni Rozet Kazandın!', style: TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 10),
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.secondary.withOpacity(0.2),
                          child: Icon(iconData, color: AppColors.primaryDark),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          badgeName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: widget.onDismiss,
                          child: const Text('Harika! Devam et'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrustScoreRing extends StatelessWidget {
  const _TrustScoreRing({required this.score});

  final double score;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final safe = score.clamp(0, 100).toDouble();

    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(96, 96),
            painter: _RingPainter(
              progress: safe / 100,
              backgroundColor: cs.outlineVariant.withOpacity(0.3),
              progressColor: AppColors.primaryDark,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('%${safe.round()}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                const SizedBox(height: 2),
                Text('Güven Skoru', style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
  });

  final double progress;
  final Color backgroundColor;
  final Color progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 8.0;
    final center = size.center(Offset.zero);
    final radius = (size.width - stroke) / 2;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.57,
      6.28318 * progress.clamp(0, 1),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.progressColor != progressColor;
  }
}

class _LockedBadgePreview extends StatelessWidget {
  const _LockedBadgePreview({required this.glowController});

  final AnimationController glowController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: glowController,
      builder: (context, child) {
        final glow = Curves.easeOut.transform(glowController.value);
        return Container(
          width: 84,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
            border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.5 + (glow * 0.3))),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4AF37).withOpacity(0.08 + glow * 0.18),
                blurRadius: 8 + (10 * glow),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 1.6, sigmaY: 1.6),
              child: Opacity(
                opacity: 0.3,
                child: const Center(
                  child: Icon(Icons.lock_rounded, color: Color(0xFFD4AF37), size: 26),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AnimatedBadgeLockIcon extends StatefulWidget {
  const _AnimatedBadgeLockIcon({
    required this.unlocked,
    required this.playUnlockAnimation,
  });

  final bool unlocked;
  final bool playUnlockAnimation;

  @override
  State<_AnimatedBadgeLockIcon> createState() => _AnimatedBadgeLockIconState();
}

class _AnimatedBadgeLockIconState extends State<_AnimatedBadgeLockIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    if (widget.playUnlockAnimation) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant _AnimatedBadgeLockIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.playUnlockAnimation && !oldWidget.playUnlockAnimation) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.playUnlockAnimation) {
      return Icon(
        widget.unlocked ? Icons.workspace_premium_rounded : Icons.lock_rounded,
        color: widget.unlocked ? AppColors.primaryDark : Colors.grey,
        size: 18,
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final lockOpacity = (1 - (t * 2)).clamp(0.0, 1.0);
        final premiumOpacity = ((t - 0.45) * 2).clamp(0.0, 1.0);
        final shake = t < 0.45 ? (1 - t / 0.45) * 3.0 : 0.0;

        return Transform.translate(
          offset: Offset(shake * ((t * 20).floor().isEven ? 1 : -1), 0),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: lockOpacity,
                child: Transform.scale(
                  scale: 1 - (t * 0.35),
                  child: const Icon(Icons.lock_rounded, color: Colors.grey, size: 18),
                ),
              ),
              Opacity(
                opacity: premiumOpacity,
                child: const Icon(Icons.workspace_premium_rounded, color: AppColors.primaryDark, size: 18),
              ),
            ],
          ),
        );
      },
    );
  }
}

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _loading = true;
  bool push = true;
  bool priceAlerts = true;
  bool campaign = true;
  bool quietHours = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final prefs = Map<String, dynamic>.from((doc.data()?['prefs'] ?? {}) as Map);
    if (!mounted) return;
    setState(() {
      push = prefs['pushNotifications'] != false;
      priceAlerts = prefs['priceAlerts'] != false;
      campaign = prefs['campaignNotifications'] != false;
      quietHours = prefs['quietHours'] == true;
      _loading = false;
    });
  }

  Future<void> _saveKey(String key, bool value) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'prefs': {key: value},
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bildirim Ayarları')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _toggleTile('Push bildirimleri', push, (v) async {
                  setState(() => push = v);
                  await _saveKey('pushNotifications', v);
                }),
                _toggleTile('Fiyat alarmı bildirimleri', priceAlerts, (v) async {
                  setState(() => priceAlerts = v);
                  await _saveKey('priceAlerts', v);
                }),
                _toggleTile('Kampanya bildirimleri', campaign, (v) async {
                  setState(() => campaign = v);
                  await _saveKey('campaignNotifications', v);
                }),
                _toggleTile('Sessiz saatler', quietHours, (v) async {
                  setState(() => quietHours = v);
                  await _saveKey('quietHours', v);
                }),
              ],
            ),
    );
  }

  Widget _toggleTile(String title, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
      ),
      child: SwitchListTile.adaptive(
        value: value,
        onChanged: onChanged,
        title: Text(title),
      ),
    );
  }
}

class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Güvenlik')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SimpleActionCard(
            title: 'Profili Düzenle',
            icon: Icons.edit_rounded,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
            ),
          ),
          _SimpleActionCard(
            title: 'Şifre sıfırlama e-postası gönder',
            icon: Icons.lock_reset_rounded,
            onTap: () async {
              final email = FirebaseAuth.instance.currentUser?.email;
              if (email == null) return;
              await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Şifre sıfırlama e-postası gönderildi.')),
              );
            },
          ),
          _SimpleActionCard(
            title: 'Veri & Gizlilik',
            icon: Icons.privacy_tip_rounded,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AboutScreen()),
            ),
          ),
          _SimpleActionCard(
            title: 'Hesabı sil',
            icon: Icons.delete_forever_rounded,
            isDanger: true,
            onTap: () async {
              final result = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Hesabı sil'),
                      content: const Text('Bu işlem geri alınamaz. Devam etmek istiyor musun?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
                        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sil')),
                      ],
                    ),
                  ) ??
                  false;
              if (!result) return;
              final user = FirebaseAuth.instance.currentUser;
              final uid = user?.uid;
              if (uid != null) {
                await FirebaseFirestore.instance.collection('users').doc(uid).update({'deletionRequestedAt': FieldValue.serverTimestamp()});
              }
              await user?.delete();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SimpleActionCard extends StatelessWidget {
  const _SimpleActionCard({
    required this.title,
    required this.icon,
    required this.onTap,
    this.isDanger = false,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: (isDanger ? AppColors.error : AppColors.outlineVariant).withOpacity(0.5)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: isDanger ? AppColors.error : AppColors.primaryDark),
        title: Text(title, style: TextStyle(color: isDanger ? AppColors.error : null)),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class MyPricesScreen extends StatefulWidget {
  const MyPricesScreen({super.key, required this.userId});

  final String userId;

  @override
  State<MyPricesScreen> createState() => _MyPricesScreenState();
}

class _MyPricesScreenState extends State<MyPricesScreen> {
  String _filter = '30';

  @override
  Widget build(BuildContext context) {
    final base = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('prices')
        .orderBy('date', descending: true);

    final stream = _filter == 'all'
        ? base.snapshots()
        : base.where(
            'date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now().subtract(Duration(days: _filter == '7' ? 7 : 30))),
          ).snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('Fiyatlarım')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: '7', label: Text('Son 7 gün')),
                ButtonSegment(value: '30', label: Text('Son 30 gün')),
                ButtonSegment(value: 'all', label: Text('Tümü')),
              ],
              selected: {_filter},
              onSelectionChanged: (value) => setState(() => _filter = value.first),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Bir hata oluştu, tekrar dene.'));
                }
                final docs = snapshot.data?.docs ?? const [];
                if (docs.isEmpty) {
                  return const Center(child: Text('Henüz fiyat eklemedin.'));
                }
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final name = _stringFromAny(data['productName']) ?? 'Ürün adı yok';
                    final store = _stringFromAny(data['store']) ?? 'Mağaza belirtilmedi';
                    final price = _numFromAny(data['price']);
                    final date = data['date'];
                    final dateText = date is Timestamp
                        ? '${date.toDate().day}.${date.toDate().month}.${date.toDate().year} ${date.toDate().hour.toString().padLeft(2, '0')}:${date.toDate().minute.toString().padLeft(2, '0')}'
                        : 'Tarih yok';

                    return ListTile(
                      title: Text(name),
                      subtitle: Text('$store • $dateText'),
                      trailing: Text(price == null ? '₺0' : '₺${price.toStringAsFixed(2)}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favoriler')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').doc(userId).collection('favorites').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Bir hata oluştu, tekrar dene.'));
          }
          final docs = snapshot.data?.docs ?? const [];
          if (docs.isEmpty) {
            return const Center(child: Text('Henüz favorin yok'));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.86,
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final title = _stringFromAny(data['name']) ?? 'Ürün';
              final image = _stringFromAny(data['imageUrl']);

              return InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  final productId = _stringFromAny(data['productId']) ?? doc.id;
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: productId)),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Theme.of(context).colorScheme.surface,
                    border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
                  ),
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        child: image == null
                            ? Container(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                child: const Icon(Icons.image_not_supported_rounded),
                              )
                            : Image.network(image, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          IconButton(
                            onPressed: () => doc.reference.delete(),
                            icon: const Icon(Icons.favorite, color: AppColors.error),
                            tooltip: 'Favoriden kaldır',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
            },
          );
        },
      ),
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hakkında')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ListTile(title: Text('FiyatRadar'), subtitle: Text('Sürüm: 1.0.0')),
          const ListTile(title: Text('Geliştirici'), subtitle: Text('FiyatRadar Ekibi')),
          ListTile(
            title: const Text('Gizlilik Politikası'),
            trailing: const Icon(Icons.open_in_new_rounded),
            onTap: () => launchUrl(Uri.parse('https://fiyatradar.app/privacy')),
          ),
          ListTile(
            title: const Text('Kullanım Şartları'),
            trailing: const Icon(Icons.open_in_new_rounded),
            onTap: () => launchUrl(Uri.parse('https://fiyatradar.app/terms')),
          ),
          ListTile(
            title: const Text('Lisanslar'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => showLicensePage(context: context),
          ),
        ],
      ),
    );
  }
}

class ReceiptsScreen extends StatelessWidget {
  const ReceiptsScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fişlerim')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('receipts')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Bir hata oluştu, tekrar dene.'));
          }
          final docs = snapshot.data?.docs ?? const [];
          if (docs.isEmpty) {
            return const Center(child: Text('Henüz fiş eklemedin.'));
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final market = _stringFromAny(data['market']) ?? 'Market belirtilmedi';
              final total = _numFromAny(data['total']);
              final ts = data['createdAt'];
              final dateText = ts is Timestamp ? '${ts.toDate().day}.${ts.toDate().month}.${ts.toDate().year}' : 'Tarih yok';
              return ListTile(
                leading: const Icon(Icons.receipt_long_rounded),
                title: Text(market),
                subtitle: Text(dateText),
                trailing: Text(total == null ? '₺0' : '₺${total.toStringAsFixed(2)}'),
              );
            },
          );
        },
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: color ?? AppColors.primaryDark),
        title: Text(title, style: TextStyle(color: color)),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class EmptyStateCard extends StatelessWidget {
  const EmptyStateCard({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
      ),
      child: Text(message),
    );
  }
}

class ErrorCard extends StatelessWidget {
  const ErrorCard({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.red.withOpacity(0.08),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          const SizedBox(height: 8),
          FilledButton.tonal(onPressed: onRetry, child: const Text('Tekrar Dene')),
        ],
      ),
    );
  }
}

class _ProfileLoadingView extends StatelessWidget {
  const _ProfileLoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _SectionSkeleton(height: 230),
        SizedBox(height: 12),
        _SectionSkeleton(height: 90),
        SizedBox(height: 12),
        _SectionSkeleton(height: 88),
        SizedBox(height: 12),
        _SectionSkeleton(height: 132),
        SizedBox(height: 12),
        _SectionSkeleton(height: 200),
      ],
    );
  }
}

class _SectionSkeleton extends StatelessWidget {
  const _SectionSkeleton({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
    );
  }
}

class _QuickActionData {
  const _QuickActionData({required this.title, required this.icon});

  final String title;
  final IconData icon;
}

class _TimelineIconData {
  const _TimelineIconData(this.icon, this.color);

  final IconData icon;
  final Color color;
}

_TimelineIconData _timelineIcon(String title) {
  final lower = title.toLowerCase();
  if (lower.contains('doğrul')) {
    return const _TimelineIconData(Icons.verified_rounded, AppColors.success);
  }
  if (lower.contains('katkı')) {
    return const _TimelineIconData(Icons.trending_up_rounded, AppColors.primaryDark);
  }
  if (lower.contains('rapor')) {
    return const _TimelineIconData(Icons.flag_rounded, AppColors.warning);
  }
  return const _TimelineIconData(Icons.bolt_rounded, AppColors.primaryDark);
}

IconData _badgeIconFromCodePoint(int? codePoint) {
  switch (codePoint) {
    case null:
      return Icons.workspace_premium_rounded;
    case 0xe80f:
      return Icons.emoji_events_rounded;
    case 0xe8f9:
      return Icons.workspace_premium_rounded;
    case 0xe838:
      return Icons.stars_rounded;
    case 0xe153:
      return Icons.local_fire_department_rounded;
    case 0xe865:
      return Icons.check_circle_rounded;
    case 0xe8dc:
      return Icons.verified_rounded;
    default:
      return Icons.workspace_premium_rounded;
  }
}

class ProfileBundle {
  ProfileBundle({
    required this.profile,
    required this.activities,
    this.errorMessage,
    required this.justUnlockedBadge,
    required this.unlockedBadge,
  });

  final ProfileViewData profile;
  final List<Map<String, dynamic>> activities;
  final String? errorMessage;
  final bool justUnlockedBadge;
  final Map<String, dynamic>? unlockedBadge;

  factory ProfileBundle.empty(UserModel fallbackUser) {
    return ProfileBundle(
      profile: ProfileViewData.fromSources(
        fallbackUser: fallbackUser,
        profileData: const <String, dynamic>{},
      ),
      activities: const [],
      justUnlockedBadge: false,
      unlockedBadge: null,
    );
  }

  factory ProfileBundle.error(UserModel fallbackUser, String message) {
    return ProfileBundle(
      profile: ProfileViewData.fromSources(
        fallbackUser: fallbackUser,
        profileData: const <String, dynamic>{},
      ),
      activities: const [],
      errorMessage: message,
      justUnlockedBadge: false,
      unlockedBadge: null,
    );
  }

  factory ProfileBundle.fromData({
    required UserModel fallbackUser,
    required Map<String, dynamic> profileData,
    required List<Map<String, dynamic>> activities,
    required List<Map<String, dynamic>> badgeMaster,
    required Set<String> userBadgeIds,
    required List<Map<String, dynamic>> userPrices,
  }) {
    final profile = ProfileViewData.fromSources(
      fallbackUser: fallbackUser,
      profileData: profileData,
      badgeMaster: badgeMaster,
      userBadgeIds: userBadgeIds,
      userPrices: userPrices,
    );

    final justUnlocked = profileData['justUnlockedBadge'] == true || profileData['newBadgeFlag'] == true;
    final unlockedBadge = _extractUnlockedBadge(profileData);

    return ProfileBundle(
      profile: profile,
      activities: activities,
      justUnlockedBadge: justUnlocked,
      unlockedBadge: unlockedBadge,
    );
  }
}

class ProfileViewData {
  ProfileViewData({
    required this.displayName,
    required this.avatarUrl,
    required this.trustScore,
    required this.levelName,
    required this.streakDays,
    required this.monthlySavings,
    required this.topMarketName,
    required this.badges,
    required this.avatarChangedAt,
  });

  final String displayName;
  final String? avatarUrl;
  final double trustScore;
  final String levelName;
  final int streakDays;
  final String monthlySavings;
  final String topMarketName;
  final List<Map<String, dynamic>> badges;
  final DateTime? avatarChangedAt;

  factory ProfileViewData.fromSources({
    required UserModel fallbackUser,
    required Map<String, dynamic> profileData,
    List<Map<String, dynamic>> badgeMaster = const [],
    Set<String> userBadgeIds = const <String>{},
    List<Map<String, dynamic>> userPrices = const [],
  }) {
    final resolvedDisplayName = _stringFromAny(
      profileData['displayName'] ?? profileData['name'] ?? fallbackUser.name,
    );
    final displayName = resolvedDisplayName ?? 'Kullanıcı';

    final trustScore = _numFromAny(
          profileData['trustScore'] ?? profileData['reliabilityScore'] ?? fallbackUser.reliabilityScore,
        )
            ?.toDouble() ??
        0;

    final derivedStats = _deriveStats(userPrices);
    return ProfileViewData(
      displayName: displayName,
      avatarUrl: _stringFromAny(
        profileData['photoURL'] ?? profileData['photoUrl'] ?? fallbackUser.photoUrl,
      ),
      trustScore: trustScore,
      levelName: _stringFromAny(profileData['levelName']) ?? _computeLevelName(trustScore),
      streakDays: _numFromAny(profileData['streakDays'] ?? profileData['streak'])?.toInt() ?? derivedStats.streakDays,
      monthlySavings: _formatCurrency(profileData['monthlySavings'] ?? derivedStats.monthlySavings),
      topMarketName: _stringFromAny(profileData['topMarketName'] ?? profileData['bestMarket']) ?? derivedStats.topMarket,
      badges: _extractBadges(profileData, badgeMaster, userBadgeIds, fallbackUser.isAdmin || profileData['isAdmin'] == true),
      avatarChangedAt: _dateFromAny(profileData['avatarUpdatedAt']),
    );
  }
}

List<Map<String, dynamic>> _extractBadges(
  Map<String, dynamic> data,
  List<Map<String, dynamic>> badgeMaster,
  Set<String> userBadgeIds,
  bool isAdmin,
) {
  if (badgeMaster.isNotEmpty) {
    return badgeMaster.map((badge) {
      final id = (badge['id'] ?? '').toString();
      final unlocked = isAdmin || userBadgeIds.contains(id);
      return {
        'id': id,
        'name': badge['name'] ?? 'Rozet',
        'description': badge['criteria'] ?? badge['description'] ?? 'Topluluk rozeti',
        'iconCodePoint': badge['iconCodePoint'],
        'isUnlocked': unlocked,
      };
    }).toList(growable: false);
  }

  final rawBadges = data['badgesUnlocked'] ?? data['badges'];
  if (rawBadges is! List || rawBadges.isEmpty) return const [];

  return rawBadges.map<Map<String, dynamic>>((raw) {
    if (raw is String) {
      return {
        'name': raw,
        'description': 'Topluluk katkısı rozeti',
        'isUnlocked': true,
      };
    }
    if (raw is Map) {
      final badge = Map<String, dynamic>.from(raw);
      final unlocked = badge['isUnlocked'] == true || badge['unlocked'] == true;
      return {
        'name': badge['name'] ?? 'Rozet',
        'description': badge['description'] ?? 'Topluluk katkısı rozeti',
        'iconCodePoint': badge['iconCodePoint'],
        'isUnlocked': unlocked,
      };
    }
    return {
      'name': 'Rozet',
      'description': 'Topluluk katkısı rozeti',
      'isUnlocked': false,
    };
  }).toList(growable: false);
}

Map<String, dynamic>? _extractUnlockedBadge(Map<String, dynamic> data) {
  final direct = data['unlockedBadge'] ?? data['newBadge'];
  if (direct is Map) {
    return Map<String, dynamic>.from(direct);
  }

  final badges = _extractBadges(data, const [], const <String>{}, false);
  if (badges.isEmpty) return null;

  final firstUnlocked = badges.where((b) => b['isUnlocked'] == true).cast<Map<String, dynamic>>();
  return firstUnlocked.isNotEmpty ? firstUnlocked.first : null;
}

String _computeLevelName(double trustScore) {
  if (trustScore >= 85) return 'Elmas';
  if (trustScore >= 65) return 'Altın';
  if (trustScore >= 45) return 'Gümüş';
  return 'Başlangıç';
}

String _formatCurrency(dynamic value) {
  final number = _numFromAny(value);
  if (number == null) return '₺0';
  return '₺${number.toStringAsFixed(number % 1 == 0 ? 0 : 2)}';
}

String? _stringFromAny(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  if (text.isEmpty || text.toLowerCase() == 'null') return null;
  return text;
}


DateTime? _dateFromAny(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

_PriceStats _deriveStats(List<Map<String, dynamic>> prices) {
  if (prices.isEmpty) {
    return const _PriceStats(streakDays: 0, monthlySavings: 0, topMarket: 'Belirtilmedi');
  }

  final now = DateTime.now();
  final lastMonth = now.subtract(const Duration(days: 30));
  final marketCounts = <String, int>{};
  var monthlySavings = 0.0;
  final days = <DateTime>{};

  for (final price in prices) {
    final store = _stringFromAny(price['store']) ?? _stringFromAny(price['market']) ?? 'Belirtilmedi';
    marketCounts.update(store, (v) => v + 1, ifAbsent: () => 1);
    final ts = _dateFromAny(price['date']);
    if (ts != null) {
      days.add(DateTime(ts.year, ts.month, ts.day));
      if (ts.isAfter(lastMonth)) {
        final save = _numFromAny(price['saving'])?.toDouble() ?? 0;
        monthlySavings += save;
      }
    }
  }

  int streak = 0;
  var cursor = DateTime(now.year, now.month, now.day);
  while (days.contains(cursor)) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }

  var topMarket = 'Belirtilmedi';
  if (marketCounts.isNotEmpty) {
    topMarket = marketCounts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  return _PriceStats(streakDays: streak, monthlySavings: monthlySavings, topMarket: topMarket);
}

class _PriceStats {
  const _PriceStats({required this.streakDays, required this.monthlySavings, required this.topMarket});

  final int streakDays;
  final double monthlySavings;
  final String topMarket;
}

num? _numFromAny(dynamic value) {
  if (value is num) return value;
  if (value is String) return num.tryParse(value.replaceAll(',', '.'));
  return null;
}
