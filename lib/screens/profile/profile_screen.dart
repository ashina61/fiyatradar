import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/theme.dart';
import '../admin/admin_panel_screen.dart';
import '../auth/login_screen.dart';
import '../notifications/notifications_screen.dart';
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

  Future<ProfileBundle> _loadProfileBundle(UserModel fallbackUser) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        return ProfileBundle.empty(fallbackUser);
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 8));

      final profileData = (doc.data() ?? <String, dynamic>{});

      List<Map<String, dynamic>> activities = const [];
      try {
        final query = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('activities')
            .orderBy('createdAt', descending: true)
            .limit(8)
            .get()
            .timeout(const Duration(seconds: 8));
        activities = query.docs.map((e) => e.data()).toList(growable: false);
      } catch (_) {
        activities = _readActivityListFromUserDoc(profileData);
      }

      return ProfileBundle.fromData(
        fallbackUser: fallbackUser,
        profileData: profileData,
        activities: activities,
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
    if (_unlockHandled || !bundle.justUnlockedBadge || bundle.unlockedBadge == null || !mounted) {
      return;
    }

    _unlockHandled = true;
    _markUnlockAsSeen();
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

    final fallbackUser = UserModel(
      uid: 'misafir',
      email: '',
      name: 'Kullanıcı',
      createdAt: DateTime.now(),
      reliabilityScore: 0,
    );

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text('Profil')),
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

class _ProfileScaffoldBody extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final profile = bundle.profile;

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () async => onRetry(),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.background,
                  Theme.of(context).colorScheme.surface,
                ],
              ),
            ),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                if (bundle.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ErrorCard(
                      message: bundle.errorMessage!,
                      onRetry: onRetry,
                    ),
                  ),
                ProfileHeroCard(
                  displayName: profile.displayName,
                  avatarUrl: profile.avatarUrl,
                  trustScore: profile.trustScore,
                  levelName: profile.levelName,
                  onEditProfile: onEditProfile,
                ),
                const SizedBox(height: 16),
                StatChipsRow(
                  streakDays: profile.streakDays,
                  monthlySavings: profile.monthlySavings,
                  topMarketName: profile.topMarketName,
                ),
                const SizedBox(height: 16),
                QuickActionsBar(),
                const SizedBox(height: 16),
                BadgeCinema(badges: profile.badges),
                const SizedBox(height: 16),
                LiveActivityTimeline(activities: bundle.activities),
                const SizedBox(height: 16),
                PremiumSettingsPanel(user: user, onEditProfile: onEditProfile),
              ],
            ),
          ),
        ),
        UnlockBadgeToastOverlay(
          visible: showUnlockOverlay,
          badge: unlockedBadge,
          onDismiss: onDismissOverlay,
        ),
      ],
    );
  }
}

class ProfileHeroCard extends StatelessWidget {
  const ProfileHeroCard({
    super.key,
    required this.displayName,
    required this.avatarUrl,
    required this.trustScore,
    required this.levelName,
    required this.onEditProfile,
  });

  final String displayName;
  final String? avatarUrl;
  final double trustScore;
  final String levelName;
  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final safeScore = trustScore.clamp(0, 100);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            cs.surface.withOpacity(0.92),
            cs.secondaryContainer.withOpacity(0.25),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: cs.surface,
                backgroundImage: (avatarUrl ?? '').isNotEmpty ? NetworkImage(avatarUrl!) : null,
                child: (avatarUrl ?? '').isEmpty
                    ? Text(
                        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'K',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 22),
                      )
                    : null,
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
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                        const Icon(Icons.verified_rounded, color: AppColors.primaryDark, size: 20),
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
                        '$levelName seviyesi',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: onEditProfile,
                icon: const Icon(Icons.edit_rounded),
                tooltip: 'Profili Düzenle',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 74,
                height: 74,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: safeScore / 100,
                      strokeWidth: 7,
                      backgroundColor: cs.outlineVariant.withOpacity(0.4),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryDark),
                    ),
                    Text('%${safeScore.round()}', style: const TextStyle(fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
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

class BadgeCinema extends StatelessWidget {
  const BadgeCinema({super.key, required this.badges});

  final List<Map<String, dynamic>> badges;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Rozet Sineması', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 10),
        if (badges.isEmpty)
          const EmptyStateCard(message: 'Henüz rozetin yok. Katkı yaptıkça yeni rozetler açılacak.')
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
                          Icon(
                            unlocked ? Icons.workspace_premium_rounded : Icons.lock_rounded,
                            color: unlocked ? AppColors.primaryDark : Colors.grey,
                            size: 18,
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
  QuickActionsBar({super.key});

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
    final fallback = [
      {
        'title': 'Fiyat doğrulandı',
        'description': 'Paylaştığın fiyat topluluk tarafından doğrulandı.',
      },
      {
        'title': 'Katkı kazanıldı',
        'description': 'Bugün yeni katkı puanları kazandın.',
      },
      {
        'title': 'Rapor alındı',
        'description': 'Gönderdiğin bildirim başarıyla alındı.',
      },
    ];

    final list = activities.isEmpty ? fallback : activities;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Canlı Aktivite Akışı', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 10),
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
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          ),
        ),
        _SettingsTile(
          icon: Icons.security_rounded,
          title: 'Güvenlik',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Güvenlik ayarları yakında.')),
            );
          },
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
          icon: Icons.logout_rounded,
          title: 'Çıkış Yap',
          color: Colors.red.shade600,
          onTap: () async {
            final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Çıkış yapılsın mı?'),
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
                        const Text('🏆 Yeni Rozet Kazandın', style: TextStyle(fontWeight: FontWeight.w800)),
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
  }) {
    final profile = ProfileViewData.fromSources(
      fallbackUser: fallbackUser,
      profileData: profileData,
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
  });

  final String displayName;
  final String? avatarUrl;
  final double trustScore;
  final String levelName;
  final int streakDays;
  final String monthlySavings;
  final String topMarketName;
  final List<Map<String, dynamic>> badges;

  factory ProfileViewData.fromSources({
    required UserModel fallbackUser,
    required Map<String, dynamic> profileData,
  }) {
    final displayName = _stringFromAny(
          profileData['displayName'] ?? profileData['name'] ?? fallbackUser.name,
        )
            .trim()
            .isEmpty
        ? 'Kullanıcı'
        : _stringFromAny(profileData['displayName'] ?? profileData['name'] ?? fallbackUser.name);

    final trustScore = _numFromAny(
          profileData['trustScore'] ?? profileData['reliabilityScore'] ?? fallbackUser.reliabilityScore,
        )
            ?.toDouble() ??
        0;

    return ProfileViewData(
      displayName: displayName,
      avatarUrl: _stringFromAny(
        profileData['photoURL'] ?? profileData['photoUrl'] ?? fallbackUser.photoUrl,
      ),
      trustScore: trustScore,
      levelName: _stringFromAny(profileData['levelName']) ?? _computeLevelName(trustScore),
      streakDays: _numFromAny(profileData['streakDays'] ?? profileData['streak'])?.toInt() ?? 0,
      monthlySavings: _formatCurrency(profileData['monthlySavings']),
      topMarketName: _stringFromAny(profileData['topMarketName'] ?? profileData['bestMarket']) ?? 'Belirtilmedi',
      badges: _extractBadges(profileData),
    );
  }
}

List<Map<String, dynamic>> _extractBadges(Map<String, dynamic> data) {
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

  final badges = _extractBadges(data);
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

num? _numFromAny(dynamic value) {
  if (value is num) return value;
  if (value is String) return num.tryParse(value.replaceAll(',', '.'));
  return null;
}
