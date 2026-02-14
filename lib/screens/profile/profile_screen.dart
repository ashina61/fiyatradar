import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
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
  int _impactReload = 0;
  int _badgeReload = 0;
  int _activityReload = 0;
  bool _badgeModalShown = false;

  Future<SectionResult<Map<String, dynamic>>> _loadProfileData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        return const SectionResult.empty();
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 8));

      final data = doc.data();
      if (data == null) {
        return const SectionResult.empty();
      }

      _checkAndShowBadgeModal(data);
      return SectionResult.data(data);
    } on TimeoutException {
      return const SectionResult.error('Sunucu zaman aşımına uğradı. Lütfen tekrar deneyin.');
    } catch (_) {
      return const SectionResult.error('Profil verileri alınamadı.');
    }
  }

  Future<SectionResult<List<Map<String, dynamic>>>> _loadBadges() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        return const SectionResult.empty();
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 8));

      final raw = doc.data()?['badges'];
      if (raw is! List) {
        return const SectionResult.empty();
      }

      final badges = raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(growable: false);
      if (badges.isEmpty) {
        return const SectionResult.empty();
      }

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
      if (uid == null) {
        return const SectionResult.empty();
      }

      final query = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('activities')
          .orderBy('createdAt', descending: true)
          .limit(8)
          .get()
          .timeout(const Duration(seconds: 8));

      if (query.docs.isEmpty) {
        return const SectionResult.empty();
      }

      return SectionResult.data(
        query.docs.map((doc) => doc.data()).toList(growable: false),
      );
    } on TimeoutException {
      return const SectionResult.error('Aktiviteler yüklenirken zaman aşımı oluştu.');
    } catch (_) {
      return const SectionResult.error('Aktivite akışı alınamadı.');
    }
  }

  void _checkAndShowBadgeModal(Map<String, dynamic> data) {
    if (_badgeModalShown || !mounted) {
      return;
    }

    final hasNewBadge = data['newBadgeFlag'] == true;
    final badge = data['newBadge'];
    if (!hasNewBadge || badge is! Map) {
      return;
    }

    _badgeModalShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _BadgeCelebrationSheet(
          badgeName: (badge['name'] ?? 'Gizemli Rozet').toString(),
          iconCodePoint: badge['iconCodePoint'] is int ? badge['iconCodePoint'] as int : null,
          onOk: () async {
            Navigator.of(context).pop();
            await _clearNewBadgeFlag();
          },
          onShare: () async {
            Navigator.of(context).pop();
            await _clearNewBadgeFlag();
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Rozet paylaşımı yakında aktif olacak.')),
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
      // Sessizce geç.
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userModelStreamProvider);
    final theme = Theme.of(context);

    final fallbackGuest = UserModel(
      uid: 'misafir',
      email: '',
      name: 'Misafir',
      createdAt: DateTime.now(),
      reliabilityScore: 0,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      backgroundColor: theme.colorScheme.surface,
      body: userAsync.when(
        loading: () => const _ProfileLoadingView(),
        error: (_, __) => _ProfileFallbackView(
          title: 'Profil yüklenemedi',
          message: 'Bir sorun oluştu. Yine de temel profil görünümü hazır.',
          child: _ProfileContent(
            user: fallbackGuest,
            profileResult: Future.value(const SectionResult.empty()),
            impactReload: _impactReload,
            badgeReload: _badgeReload,
            activityReload: _activityReload,
            onEdit: _openEdit,
            onRetryImpact: () => setState(() => _impactReload++),
            onRetryBadges: () => setState(() => _badgeReload++),
            onRetryActivity: () => setState(() => _activityReload++),
          ),
        ),
        data: (userData) {
          final safeUser = userData ?? fallbackGuest;
          return _ProfileContent(
            user: safeUser,
            profileResult: _loadProfileData(),
            impactReload: _impactReload,
            badgeReload: _badgeReload,
            activityReload: _activityReload,
            onEdit: _openEdit,
            onRetryImpact: () => setState(() => _impactReload++),
            onRetryBadges: () => setState(() => _badgeReload++),
            onRetryActivity: () => setState(() => _activityReload++),
            loadBadges: _loadBadges,
            loadActivities: _loadActivities,
          );
        },
      ),
    );
  }

  Future<void> _openEdit() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditProfileScreen()));
    if (!mounted) return;
    setState(() {
      _impactReload++;
      _badgeReload++;
      _activityReload++;
      _badgeModalShown = false;
    });
  }
}

class _ProfileContent extends ConsumerWidget {
  const _ProfileContent({
    required this.user,
    required this.profileResult,
    required this.impactReload,
    required this.badgeReload,
    required this.activityReload,
    required this.onEdit,
    required this.onRetryImpact,
    required this.onRetryBadges,
    required this.onRetryActivity,
    this.loadBadges,
    this.loadActivities,
  });

  final UserModel user;
  final Future<SectionResult<Map<String, dynamic>>> profileResult;
  final int impactReload;
  final int badgeReload;
  final int activityReload;
  final VoidCallback onEdit;
  final VoidCallback onRetryImpact;
  final VoidCallback onRetryBadges;
  final VoidCallback onRetryActivity;
  final Future<SectionResult<List<Map<String, dynamic>>>> Function()? loadBadges;
  final Future<SectionResult<List<Map<String, dynamic>>>> Function()? loadActivities;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        FutureBuilder<SectionResult<Map<String, dynamic>>>(
          future: profileResult,
          builder: (context, snapshot) {
            final result = snapshot.data;
            final data = result?.value ?? <String, dynamic>{};
            final displayName = (data['name'] ?? user.name).toString().trim();
            final subtitle = (data['username'] ?? 'Topluluk Katılımcısı').toString();
            final bio = (data['bio'] ?? 'FiyatRadar ile fiyat katkısı yapmaya devam et.').toString();
            final trust = ((data['reliabilityScore'] ?? user.reliabilityScore) as num?)?.toDouble() ?? 0;

            return ProfileHeaderCard(
              name: displayName.isEmpty ? 'Misafir' : displayName,
              badgeTitle: subtitle.isEmpty ? 'Topluluk Katılımcısı' : subtitle,
              description: bio,
              trustScore: trust.clamp(0, 100),
              avatarUrl: (data['photoUrl'] ?? user.photoUrl)?.toString(),
              onEdit: onEdit,
            );
          },
        ),
        const SizedBox(height: 16),
        QuickActionsGrid(actions: _quickActions(context)),
        const SizedBox(height: 16),
        FutureBuilder<SectionResult<Map<String, dynamic>>>(
          key: ValueKey(impactReload),
          future: profileResult,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const _SectionSkeleton(height: 120);
            }
            final result = snapshot.data;
            if (result == null) {
              return ErrorCard(
                message: 'Impact bilgileri alınamadı.',
                onRetry: onRetryImpact,
              );
            }
            if (result.error != null) {
              return ErrorCard(message: result.error ?? 'Bilinmeyen hata', onRetry: onRetryImpact);
            }

            final data = result.value;
            if (data == null || data.isEmpty) {
              return const EmptyStateCard(message: 'Impact verisi henüz oluşmadı. Katkı yapmaya başla!');
            }

            final monthlySavings = (data['monthlySavings'] ?? user.points * 2).toString();
            final bestMarket = (data['bestMarket'] ?? 'Henüz yok').toString();
            final streak = (data['streak'] ?? user.validations ~/ 2).toString();

            return ImpactCards(
              monthlySavings: monthlySavings,
              bestMarket: bestMarket,
              streak: streak,
            );
          },
        ),
        const SizedBox(height: 16),
        FutureBuilder<SectionResult<List<Map<String, dynamic>>>>(
          key: ValueKey(badgeReload),
          future: loadBadges?.call() ?? Future.value(const SectionResult.empty()),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const _SectionSkeleton(height: 110);
            }
            final result = snapshot.data;
            if (result?.error != null) {
              return ErrorCard(message: result?.error ?? 'Rozetler alınamadı', onRetry: onRetryBadges);
            }
            final badges = result?.value;
            return BadgesSection(badges: badges ?? const []);
          },
        ),
        const SizedBox(height: 16),
        FutureBuilder<SectionResult<List<Map<String, dynamic>>>>(
          key: ValueKey(activityReload),
          future: loadActivities?.call() ?? Future.value(const SectionResult.empty()),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const _SectionSkeleton(height: 180);
            }
            final result = snapshot.data;
            if (result?.error != null) {
              return ErrorCard(
                message: result?.error ?? 'Aktivite listesi alınamadı',
                onRetry: onRetryActivity,
              );
            }
            return ActivityFeed(activities: result?.value ?? const []);
          },
        ),
        const SizedBox(height: 16),
        SettingsSection(user: user),
      ],
    );
  }

  List<QuickActionItem> _quickActions(BuildContext context) {
    return [
      QuickActionItem(
        title: 'Fiyatlarım',
        icon: Icons.sell_rounded,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const _PlaceholderScreen(title: 'Fiyatlarım'),
          ),
        ),
      ),
      QuickActionItem(
        title: 'Fişlerim',
        icon: Icons.receipt_long_rounded,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const _PlaceholderScreen(title: 'Fişlerim'),
          ),
        ),
      ),
      QuickActionItem(
        title: 'Favoriler',
        icon: Icons.favorite_rounded,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const _PlaceholderScreen(title: 'Favoriler'),
          ),
        ),
      ),
      QuickActionItem(
        title: 'Bildirimler',
        icon: Icons.notifications_active_rounded,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
        ),
      ),
    ];
  }
}

class ProfileHeaderCard extends StatelessWidget {
  const ProfileHeaderCard({
    super.key,
    required this.name,
    required this.badgeTitle,
    required this.description,
    required this.trustScore,
    required this.avatarUrl,
    required this.onEdit,
  });

  final String name;
  final String badgeTitle;
  final String description;
  final double trustScore;
  final String? avatarUrl;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.secondaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 32,
                backgroundImage:
                    (avatarUrl ?? '').isNotEmpty ? NetworkImage(avatarUrl ?? '') : null,
                child: (avatarUrl ?? '').isEmpty
                    ? Text(name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'M')
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(badgeTitle, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: onEdit,
                tooltip: 'Profil Düzenle',
                icon: const Icon(Icons.edit_rounded),
              )
            ],
          ),
          const SizedBox(height: 14),
          Text('Güven Skoru: %${trustScore.toStringAsFixed(0)}'),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(value: trustScore / 100, minHeight: 10),
          ),
          const SizedBox(height: 10),
          Text(description, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key, required this.actions});

  final List<QuickActionItem> actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Hızlı Aksiyonlar', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.7,
          ),
          itemBuilder: (_, index) {
            final action = actions[index];
            return InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: action.onTap,
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(action.icon),
                    const SizedBox(width: 8),
                    Text(action.title),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class ImpactCards extends StatelessWidget {
  const ImpactCards({
    super.key,
    required this.monthlySavings,
    required this.bestMarket,
    required this.streak,
  });

  final String monthlySavings;
  final String bestMarket;
  final String streak;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Impact', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _MiniImpactCard(title: 'Aylık Tasarruf', value: '₺$monthlySavings')),
            const SizedBox(width: 8),
            Expanded(child: _MiniImpactCard(title: 'En İyi Market', value: bestMarket)),
            const SizedBox(width: 8),
            Expanded(child: _MiniImpactCard(title: 'Seri', value: '$streak gün')),
          ],
        ),
      ],
    );
  }
}

class BadgesSection extends StatelessWidget {
  const BadgesSection({super.key, required this.badges});

  final List<Map<String, dynamic>> badges;

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) {
      return const EmptyStateCard(
        message: 'Henüz rozetin yok. İlk rozetini kazanmak için katkı yap ve premium seviyeye ilerle!',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Rozetler', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: badges.map((badge) {
            final iconCode = badge['iconCodePoint'];
            return Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Theme.of(context).colorScheme.tertiaryContainer,
              ),
              child: Icon(
                _badgeIconFromCodePoint(iconCode is int ? iconCode : null),
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
    if (activities.isEmpty) {
      return const EmptyStateCard(message: 'Canlı aktivite henüz yok. İlk etkinlik burada görünecek.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Canlı Aktivite', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        ...activities.map(
          (activity) => ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            tileColor: Theme.of(context).colorScheme.surfaceContainerHigh,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            leading: const Icon(Icons.bolt_rounded),
            title: Text((activity['title'] ?? 'Katkı olayı').toString()),
            subtitle: Text((activity['description'] ?? 'Detay bulunamadı').toString()),
          ),
        ),
      ],
    );
  }
}

class SettingsSection extends ConsumerWidget {
  const SettingsSection({super.key, required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ayarlar', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        SwitchListTile.adaptive(
          title: const Text('Karanlık Mod'),
          value: themeMode == ThemeMode.dark,
          onChanged: (_) => ref.read(themeModeProvider.notifier).toggleDarkMode(),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
          color: Colors.red,
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
        _SectionSkeleton(height: 190),
        SizedBox(height: 12),
        _SectionSkeleton(height: 170),
        SizedBox(height: 12),
        _SectionSkeleton(height: 120),
        SizedBox(height: 12),
        _SectionSkeleton(height: 110),
      ],
    );
  }
}

class _ProfileFallbackView extends StatelessWidget {
  const _ProfileFallbackView({
    required this.title,
    required this.message,
    required this.child,
  });

  final String title;
  final String message;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.orange.withOpacity(0.12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(message),
            ],
          ),
        ),
        Expanded(child: child),
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
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}

class _MiniImpactCard extends StatelessWidget {
  const _MiniImpactCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
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
      body: Center(
        child: Text('$title sayfası hazırlanıyor.'),
      ),
    );
  }
}

class _BadgeCelebrationSheet extends StatelessWidget {
  const _BadgeCelebrationSheet({
    required this.badgeName,
    required this.onOk,
    required this.onShare,
    this.iconCodePoint,
  });

  final String badgeName;
  final int? iconCodePoint;
  final VoidCallback onOk;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final iconData = _badgeIconFromCodePoint(iconCodePoint);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Tebrikler! Yeni rozet kazandın', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.7, end: 1),
            duration: const Duration(milliseconds: 850),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(iconData, size: 42),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Text(badgeName),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: onOk, child: const Text('Tamam'))),
              const SizedBox(width: 8),
              Expanded(child: FilledButton(onPressed: onShare, child: const Text('Paylaş'))),
            ],
          )
        ],
      ),
    );
  }
}

IconData _badgeIconFromCodePoint(int? codePoint) {
  switch (codePoint) {
    case null:
      return Icons.workspace_premium;
    case 0xe80f:
      return Icons.emoji_events_rounded;
    case 0xe8f9:
      return Icons.workspace_premium;
    case 0xe838:
      return Icons.star_rounded;
    case 0xe153:
      return Icons.local_fire_department_rounded;
    case 0xe865:
      return Icons.check_circle_rounded;
    case 0xe8dc:
      return Icons.verified_rounded;
    default:
      return Icons.workspace_premium;
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
