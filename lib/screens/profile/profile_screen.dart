import 'dart:async';

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
  bool _badgeModalShown = false;

  Future<SectionResult<Map<String, dynamic>>> _loadProfileData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return const SectionResult.empty();

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 8));
      final data = doc.data();
      if (data == null) return const SectionResult.empty();

      _checkAndShowBadgeModal(data);
      return SectionResult.data(data);
    } on TimeoutException {
      return const SectionResult.error('Profil verisi zaman aşımına uğradı.');
    } catch (_) {
      return const SectionResult.error('Profil verisi alınamadı.');
    }
  }

  Future<SectionResult<List<Map<String, dynamic>>>> _loadBadges() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return const SectionResult.empty();

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 8));
      final raw = doc.data()?['badges'];
      if (raw is! List) return const SectionResult.empty();

      final badges = raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(growable: false);
      if (badges.isEmpty) return const SectionResult.empty();
      return SectionResult.data(badges);
    } on TimeoutException {
      return const SectionResult.error('Rozetler yüklenirken zaman aşımı oluştu.');
    } catch (_) {
      return const SectionResult.error('Rozetler alınamadı.');
    }
  }

  Future<SectionResult<List<Map<String, dynamic>>>> _loadActivities() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return const SectionResult.empty();

      final query = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('activities')
          .orderBy('createdAt', descending: true)
          .limit(8)
          .get()
          .timeout(const Duration(seconds: 8));
      if (query.docs.isEmpty) return const SectionResult.empty();

      return SectionResult.data(
        query.docs.map((doc) => doc.data()).toList(growable: false),
      );
    } on TimeoutException {
      return const SectionResult.error('Aktivite akışı zaman aşımına uğradı.');
    } catch (_) {
      return const SectionResult.error('Aktivite akışı alınamadı.');
    }
  }

  void _checkAndShowBadgeModal(Map<String, dynamic> data) {
    if (_badgeModalShown || !mounted) return;
    final hasNewBadge = data['newBadgeFlag'] == true;
    final badge = data['newBadge'];
    if (!hasNewBadge || badge is! Map) return;

    _badgeModalShown = true;
    final badgeName = (badge['name'] ?? 'Doğrulayıcı').toString();
    final badgeDescription =
        (badge['description'] ?? 'Topluluk katkınla yeni seviyeye ulaştın.').toString();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _BadgeCelebrationDialog(
          badgeName: badgeName,
          badgeDescription: badgeDescription,
          iconCodePoint: badge['iconCodePoint'] is int ? badge['iconCodePoint'] as int : null,
          onDone: () async {
            Navigator.of(context).pop();
            await _clearNewBadgeFlag();
          },
          onShare: () async {
            Navigator.of(context).pop();
            await _clearNewBadgeFlag();
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Paylaşım özelliği yakında aktif olacak.')),
            );
          },
        ),
      );
    });
  }

  Future<void> _clearNewBadgeFlag() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'newBadgeFlag': false,
      }).timeout(const Duration(seconds: 8));
    } catch (_) {
      // Bilerek sessiz geçiliyor.
    }
  }

  Future<void> _openEditProfile() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );
    if (!mounted) return;
    setState(() {
      _reloadKey++;
      _badgeModalShown = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userModelStreamProvider);

    final fallbackUser = UserModel(
      uid: 'misafir',
      email: '',
      name: 'Misafir Kullanıcı',
      createdAt: DateTime.now(),
      reliabilityScore: 42,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: userAsync.when(
        loading: () => const _ProfileLoadingView(),
        error: (_, __) => _ProfileContent(
          user: fallbackUser,
          profileFuture: Future.value(const SectionResult.empty()),
          badgesFuture: Future.value(const SectionResult.empty()),
          activitiesFuture: Future.value(const SectionResult.empty()),
          onEditProfile: _openEditProfile,
          onRetry: () => setState(() => _reloadKey++),
        ),
        data: (user) {
          final safeUser = user ?? fallbackUser;
          return _ProfileContent(
            key: ValueKey(_reloadKey),
            user: safeUser,
            profileFuture: _loadProfileData(),
            badgesFuture: _loadBadges(),
            activitiesFuture: _loadActivities(),
            onEditProfile: _openEditProfile,
            onRetry: () => setState(() => _reloadKey++),
          );
        },
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    super.key,
    required this.user,
    required this.profileFuture,
    required this.badgesFuture,
    required this.activitiesFuture,
    required this.onEditProfile,
    required this.onRetry,
  });

  final UserModel user;
  final Future<SectionResult<Map<String, dynamic>>> profileFuture;
  final Future<SectionResult<List<Map<String, dynamic>>>> badgesFuture;
  final Future<SectionResult<List<Map<String, dynamic>>>> activitiesFuture;
  final VoidCallback onEditProfile;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SectionResult<Map<String, dynamic>>>(
      future: profileFuture,
      builder: (context, profileSnapshot) {
        final profileResult = profileSnapshot.data;
        final profileData = profileResult?.value ?? <String, dynamic>{};

        final displayName = (profileData['name'] ?? user.name).toString().trim();
        final avatar = (profileData['photoUrl'] ?? user.photoUrl)?.toString();
        final trustScore =
            ((profileData['reliabilityScore'] ?? user.reliabilityScore) as num?)?.toDouble() ?? 0;
        final monthlySavings = (profileData['monthlySavings'] ?? '₺980').toString();
        final streak = (profileData['streak'] ?? 12).toString();
        final bestMarket = (profileData['bestMarket'] ?? 'Migros').toString();

        if (profileSnapshot.connectionState == ConnectionState.waiting) {
          return const _ProfileLoadingView();
        }

        return RefreshIndicator(
          onRefresh: () async => onRetry(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              if (profileResult?.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ErrorBanner(message: profileResult?.error ?? 'Profil bilgisi okunamadı.'),
                ),
              ProfileHeaderCard(
                name: displayName.isEmpty ? 'Misafir Kullanıcı' : displayName,
                avatarUrl: avatar,
                trustScore: trustScore,
                monthlySavings: monthlySavings,
                streak: streak,
                bestMarket: bestMarket,
                onEdit: onEditProfile,
              ),
              const SizedBox(height: 16),
              ProfileQuickShortcuts(
                shortcuts: [
                  QuickActionItem(
                    title: 'Fiyatlarım',
                    icon: Icons.sell_rounded,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const _PlaceholderScreen(title: 'Fiyatlarım')),
                    ),
                  ),
                  QuickActionItem(
                    title: 'Fişlerim',
                    icon: Icons.receipt_long_rounded,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const _PlaceholderScreen(title: 'Fişlerim')),
                    ),
                  ),
                  QuickActionItem(
                    title: 'Favoriler',
                    icon: Icons.favorite_rounded,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const _PlaceholderScreen(title: 'Favoriler')),
                    ),
                  ),
                  QuickActionItem(
                    title: 'Bildirimler',
                    icon: Icons.notifications_active_rounded,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FutureBuilder<SectionResult<List<Map<String, dynamic>>>>(
                future: badgesFuture,
                builder: (context, badgeSnapshot) {
                  if (badgeSnapshot.connectionState == ConnectionState.waiting) {
                    return const _SectionSkeleton(height: 180);
                  }
                  if (badgeSnapshot.data?.error != null) {
                    return ErrorCard(
                      message: badgeSnapshot.data?.error ?? 'Rozetler getirilemedi.',
                      onRetry: onRetry,
                    );
                  }
                  return BadgeGrid(badges: badgeSnapshot.data?.value ?? const []);
                },
              ),
              const SizedBox(height: 16),
              FutureBuilder<SectionResult<List<Map<String, dynamic>>>>(
                future: activitiesFuture,
                builder: (context, activitySnapshot) {
                  if (activitySnapshot.connectionState == ConnectionState.waiting) {
                    return const _SectionSkeleton(height: 200);
                  }
                  if (activitySnapshot.data?.error != null) {
                    return ErrorCard(
                      message: activitySnapshot.data?.error ?? 'Aktiviteler getirilemedi.',
                      onRetry: onRetry,
                    );
                  }
                  return ActivityFeed(activities: activitySnapshot.data?.value ?? const []);
                },
              ),
              const SizedBox(height: 16),
              SettingsSection(user: user, onEditProfile: onEditProfile),
            ],
          ),
        );
      },
    );
  }
}

class ProfileHeaderCard extends StatelessWidget {
  const ProfileHeaderCard({
    super.key,
    required this.name,
    required this.avatarUrl,
    required this.trustScore,
    required this.monthlySavings,
    required this.streak,
    required this.bestMarket,
    required this.onEdit,
  });

  final String name;
  final String? avatarUrl;
  final double trustScore;
  final String monthlySavings;
  final String streak;
  final String bestMarket;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final level = trustScore >= 85
        ? 'Elmas'
        : trustScore >= 65
            ? 'Altın'
            : trustScore >= 45
                ? 'Gümüş'
                : 'Başlangıç';

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.surface,
                  AppColors.secondary.withOpacity(0.16),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: AppColors.primary.withOpacity(0.14)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: (avatarUrl ?? '').isNotEmpty ? NetworkImage(avatarUrl!) : null,
                      child: (avatarUrl ?? '').isEmpty
                          ? Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'M',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.verified_rounded, color: AppColors.accentDark, size: 18),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: onEdit,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.7),
                      ),
                      icon: const Icon(Icons.edit_rounded),
                      tooltip: 'Profili Düzenle',
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Icon(Icons.shield_rounded, size: 18, color: AppColors.primaryDark),
                    const SizedBox(width: 8),
                    Text('Güven Skoru %${trustScore.round()} • $level'),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: (trustScore / 100).clamp(0, 1),
                    minHeight: 8,
                    backgroundColor: AppColors.outlineVariant,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryDark),
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoChip(label: 'Aylık Tasarruf', value: monthlySavings),
                    _InfoChip(label: 'Seri', value: '$streak gün'),
                    _InfoChip(label: 'En iyi market', value: bestMarket),
                  ],
                ),
              ],
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.18),
                      Colors.transparent,
                      Colors.white.withOpacity(0.08),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileQuickShortcuts extends StatelessWidget {
  const ProfileQuickShortcuts({super.key, required this.shortcuts});

  final List<QuickActionItem> shortcuts;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: shortcuts
            .map(
              (item) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: item.onTap,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(item.icon, size: 20, color: AppColors.primaryDark),
                          const SizedBox(height: 4),
                          Text(
                            item.title,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
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

class BadgeGrid extends StatelessWidget {
  const BadgeGrid({super.key, required this.badges});

  final List<Map<String, dynamic>> badges;

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) {
      return const EmptyStateCard(
        message: 'Henüz rozetin yok. İlk rozetin için fiyat doğrulaması yapmaya devam et.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Rozetler', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Column(
          children: badges.map((badge) {
            final level = (badge['level'] ?? 'Seviye 1').toString();
            final progress = ((badge['progress'] ?? 0.5) as num).toDouble().clamp(0, 1);
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accent.withOpacity(0.2),
                    ),
                    child: Icon(_badgeIconFromCodePoint(badge['iconCodePoint'] as int?)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text((badge['name'] ?? 'Doğrulayıcı').toString(),
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text((badge['description'] ?? 'Topluluk katkısı rozeti').toString()),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            minHeight: 6,
                            value: progress,
                            backgroundColor: AppColors.outlineVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(level, style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            );
          }).toList(growable: false),
        ),
      ],
    );
  }
}

class ActivityFeed extends StatelessWidget {
  const ActivityFeed({super.key, required this.activities});

  final List<Map<String, dynamic>> activities;

  @override
  Widget build(BuildContext context) {
    final fallbackActivities = [
      {
        'title': 'Fiyat doğrulandı',
        'description': 'Paylaştığın süt fiyatı topluluk tarafından doğrulandı.'
      },
      {
        'title': 'Katkı kazanıldı',
        'description': 'Bugün 24 katkı puanı kazandın.'
      },
      {
        'title': 'Rapor alındı',
        'description': 'Gönderdiğin fiyat raporu incelemeye alındı.'
      },
    ];

    final list = activities.isEmpty ? fallbackActivities : activities;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Canlı Aktivite Akışı', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        ...list.map(
          (activity) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
            ),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.surfaceVariant,
                child: Icon(Icons.bolt_rounded, color: AppColors.primaryDark),
              ),
              title: Text((activity['title'] ?? 'Aktivite').toString()),
              subtitle: Text((activity['description'] ?? 'Detay bulunamadı.').toString()),
            ),
          ),
        ),
      ],
    );
  }
}

class SettingsSection extends ConsumerWidget {
  const SettingsSection({super.key, required this.user, required this.onEditProfile});

  final UserModel user;
  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ayarlar', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        _SettingsTile(
          icon: Icons.edit_rounded,
          title: 'Profili Düzenle',
          onTap: onEditProfile,
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
          ),
          child: SwitchListTile.adaptive(
            title: const Text('Karanlık Mod'),
            value: themeMode == ThemeMode.dark,
            onChanged: (_) => ref.read(themeModeProvider.notifier).toggleDarkMode(),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
          icon: Icons.lock_rounded,
          title: 'Güvenlik',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const _PlaceholderScreen(title: 'Güvenlik')),
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
          icon: Icons.logout_rounded,
          title: 'Çıkış Yap',
          color: Colors.red.shade600,
          onTap: () async {
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

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withOpacity(0.66),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodySmall,
          children: [
            TextSpan(text: '$label: '),
            TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.orange.withOpacity(0.15),
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
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Text(message),
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

class _ProfileLoadingView extends StatelessWidget {
  const _ProfileLoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _SectionSkeleton(height: 230),
        SizedBox(height: 12),
        _SectionSkeleton(height: 88),
        SizedBox(height: 12),
        _SectionSkeleton(height: 170),
        SizedBox(height: 12),
        _SectionSkeleton(height: 200),
      ],
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
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Icon(icon, color: color),
        title: Text(title, style: TextStyle(color: color)),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('$title sayfası hazırlanıyor.')),
    );
  }
}

class _BadgeCelebrationDialog extends StatefulWidget {
  const _BadgeCelebrationDialog({
    required this.badgeName,
    required this.badgeDescription,
    required this.onDone,
    required this.onShare,
    this.iconCodePoint,
  });

  final String badgeName;
  final String badgeDescription;
  final int? iconCodePoint;
  final VoidCallback onDone;
  final VoidCallback onShare;

  @override
  State<_BadgeCelebrationDialog> createState() => _BadgeCelebrationDialogState();
}

class _BadgeCelebrationDialogState extends State<_BadgeCelebrationDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconData = _badgeIconFromCodePoint(widget.iconCodePoint);
    return ScaleTransition(
      scale: CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
      child: FadeTransition(
        opacity: CurvedAnimation(parent: _controller, curve: Curves.easeOut),
        child: AlertDialog(
          title: const Text('🎉 Yeni rozet kazandın!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                ),
                child: Icon(iconData, size: 34),
              ),
              const SizedBox(height: 10),
              Text(widget.badgeName, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(widget.badgeDescription, textAlign: TextAlign.center),
            ],
          ),
          actions: [
            TextButton(onPressed: widget.onShare, child: const Text('Paylaş')),
            FilledButton(onPressed: widget.onDone, child: const Text('Tamam')),
          ],
        ),
      ),
    );
  }
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

class QuickActionItem {
  const QuickActionItem({required this.title, required this.icon, required this.onTap});

  final String title;
  final IconData icon;
  final VoidCallback onTap;
}

class SectionResult<T> {
  const SectionResult._({this.value, this.error});

  const SectionResult.data(T this.value) : error = null;

  const SectionResult.error(String this.error) : value = null;

  const SectionResult.empty()
      : value = null,
        error = null;

  final T? value;
  final String? error;
}
