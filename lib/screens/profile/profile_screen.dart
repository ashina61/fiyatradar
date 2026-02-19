import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/product_model.dart';
import '../../utils/formatters.dart';
import '../../utils/elite_level_engine.dart';
import '../../utils/level_style.dart';
import '../../utils/theme.dart';
import '../../services/firestore_service.dart';
import '../admin/admin_panel_screen.dart';
import '../auth/login_screen.dart';
import '../notifications/notifications_screen.dart';
import '../points/points_screen.dart';
import '../product/product_detail_screen.dart';
import 'edit_profile_screen.dart';
import 'update_history_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int _reloadKey = 0;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final userAsync = ref.watch(userModelStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _ErrorState(onRetry: () => setState(() => _reloadKey++)),
        data: (userModel) {
          return FutureBuilder<_ProfileData>(
            key: ValueKey(_reloadKey),
            future: _loadProfile(uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return _ErrorState(onRetry: () => setState(() => _reloadKey++));
              }
              final data = snapshot.data;
              if (data == null) {
                return _ErrorState(onRetry: () => setState(() => _reloadKey++));
              }

              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async => setState(() => _reloadKey++),
                child: CustomScrollView(
                  slivers: [
                    // Premium header
                    _PremiumProfileHeader(
                      data: data,
                      isAdmin: userModel?.isAdmin == true,
                      onEdit: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                        );
                        if (mounted) setState(() => _reloadKey++);
                      },
                    ),
                    // Content
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            _TrustScoreCard(
                              score: data.trustScore,
                              totalVotes: data.trustTotalVotes,
                            ),
                            const SizedBox(height: 16),
                            _PointsAndLevelRow(
                              totalPoints: data.totalPoints,
                              levelName: data.levelName,
                              onPointsTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const PointsScreen()),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _QuickActionsGrid(uid: uid),
                            const SizedBox(height: 16),
                            _SettingsSection(
                              isAdmin: userModel?.isAdmin == true,
                              onReload: () => setState(() => _reloadKey++),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<_ProfileData> _loadProfile(String uid) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final userDoc = await userRef.get();
    if (!userDoc.exists) {
      await userRef.set({
        'displayName': 'Kullanici',
        'photoUrl': '',
        'photoURL': '',
        'verified': false,
        'trustScore': 0,
        'levelName': 'Standart',
        'monthlySavings': '₺0',
        'topMarket': 'Henuz yok',
        'totalPoints': 0,
        'weeklyPoints': 0,
        'streakDays': 0,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    final data = (await userRef.get()).data() ?? <String, dynamic>{};
    final trustProfile = await ref.read(firestoreServiceProvider).getUserTrustProfile(uid);
    final totalPoints = (data['totalPoints'] as num?)?.toInt() ?? (data['pointsTotal'] as num?)?.toInt() ?? (data['points'] as num?)?.toInt() ?? 0;
    final trustTotalVotes = (trustProfile['trustTotalVotes'] as num?)?.toInt() ?? 0;
    final trustPercent = (trustProfile['trustScorePercent'] as num?)?.toInt() ?? 0;
    final finalLevel = EliteLevelEngine.getFinalLevel(totalPoints, trustPercent, trustTotalVotes);

    return _ProfileData(
      displayName: (data['displayName'] ?? data['name'] ?? 'Kullanici').toString(),
      username: (data['username'] ?? '').toString(),
      photoUrl: (data['photoURL'] ?? data['photoUrl'] ?? '').toString(),
      totalPoints: totalPoints,
      levelName: EliteLevelEngine.getLevelStyle(finalLevel).label,
      trustScore: trustPercent.toDouble(),
      trustTotalVotes: trustTotalVotes,
    );
  }
}

// ---------- Premium Profile Header (SliverAppBar) ----------

class _PremiumProfileHeader extends StatelessWidget {
  const _PremiumProfileHeader({
    required this.data,
    required this.isAdmin,
    required this.onEdit,
  });

  final _ProfileData data;
  final bool isAdmin;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final shownUsername = data.username.trim().isEmpty ? data.displayName : data.username.trim();

    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      title: const Text(
        'Profil',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 20,
          color: Colors.white,
          letterSpacing: -0.3,
        ),
      ),
      actions: [
        IconButton(
          onPressed: onEdit,
          icon: const Icon(Icons.edit_rounded, size: 20),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.15),
          ),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFC47A2A),
                Color(0xFFB5651D),
                Color(0xFF8B4513),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Avatar
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _Avatar(
                      avatarUrl: data.photoUrl,
                      displayName: data.displayName,
                      size: 88,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Name
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          shownUsername,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      if (isAdmin) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.verified_rounded, size: 18, color: Colors.white),
                        ),
                      ],
                    ],
                  ),
                  if (data.username.trim().isNotEmpty && data.displayName != data.username.trim()) ...[
                    const SizedBox(height: 2),
                    Text(
                      data.displayName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------- Avatar ----------

class _Avatar extends StatelessWidget {
  const _Avatar({required this.avatarUrl, required this.displayName, this.size = 52});

  final String avatarUrl;
  final String displayName;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: avatarUrl.isEmpty
            ? Container(
                color: const Color(0xFFFFE8B7),
                alignment: Alignment.center,
                child: Text(
                  displayName.isEmpty ? 'K' : displayName[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: size * 0.35,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF3D2A00),
                  ),
                ),
              )
            : CachedNetworkImage(
                imageUrl: avatarUrl,
                fit: BoxFit.cover,
                memCacheWidth: 220,
                memCacheHeight: 220,
                errorWidget: (_, __, ___) => Container(
                  color: const Color(0xFFFFE8B7),
                  alignment: Alignment.center,
                  child: Text(
                    displayName.isEmpty ? 'K' : displayName[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: size * 0.35,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF3D2A00),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

// ---------- Trust Score Card ----------

class _TrustScoreCard extends StatelessWidget {
  const _TrustScoreCard({required this.score, required this.totalVotes});

  final double score;
  final int totalVotes;

  @override
  Widget build(BuildContext context) {
    final clampedScore = (score / 100).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outline.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Circular trust indicator
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              fit: StackFit.expand,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: clampedScore),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return CircularProgressIndicator(
                      value: value,
                      strokeWidth: 5,
                      strokeCap: StrokeCap.round,
                      backgroundColor: AppColors.surfaceVariant,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    );
                  },
                ),
                Center(
                  child: Text(
                    '%${score.round()}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Guven Skoru',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Toplam oy: $totalVotes',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                showDragHandle: true,
                builder: (_) => const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Guven nasil hesaplanir?',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      SizedBox(height: 10),
                      Text('- Dogrulanan fiyat katkilari puani yukseltir.'),
                      Text('- Hatali fiyat geri bildirimleri puani dusurur.'),
                      Text('- Son katki performansi daha yuksek etkidedir.'),
                    ],
                  ),
                ),
              );
            },
            icon: const Icon(Icons.info_outline_rounded, color: AppColors.textTertiary),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Points and Level Row ----------

class _PointsAndLevelRow extends StatelessWidget {
  const _PointsAndLevelRow({
    required this.totalPoints,
    required this.levelName,
    required this.onPointsTap,
  });

  final int totalPoints;
  final String levelName;
  final VoidCallback onPointsTap;

  @override
  Widget build(BuildContext context) {
    final level = LevelStyle.fromLevelLabel(levelName, fallbackTotalPoints: totalPoints);

    return Row(
      children: [
        // Points card
        Expanded(
          child: InkWell(
            onTap: onPointsTap,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFF8EF), Color(0xFFF8EDDB)],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE8D5B8)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.stars_rounded, color: AppColors.primary, size: 18),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textTertiary),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$totalPoints',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Toplam Puan',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Level card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: level.badgeBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(level.emoji, style: const TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  level.label,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: level.badgeForeground,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Seviye',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------- Quick Actions Grid ----------

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outline.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _QuickAction(
            icon: Icons.sell_rounded,
            label: 'Fiyatlarim',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MyPricesScreen(userId: uid)),
            ),
          ),
          _QuickAction(
            icon: Icons.receipt_long_rounded,
            label: 'Fislerim',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ReceiptsScreen(userId: uid)),
            ),
          ),
          _QuickAction(
            icon: Icons.favorite_rounded,
            label: 'Favoriler',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => FavoritesScreen(userId: uid)),
            ),
          ),
          _QuickAction(
            icon: Icons.notifications_active_rounded,
            label: 'Bildirimler',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- Settings Section ----------

class _SettingsSection extends ConsumerWidget {
  const _SettingsSection({required this.isAdmin, required this.onReload});

  final bool isAdmin;
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
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
          _SettingsTile(
            icon: Icons.edit_rounded,
            title: 'Profili Duzenle',
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              );
              onReload();
            },
          ),
          _SettingsDivider(),
          // Dark mode toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.dark_mode_rounded, color: AppColors.textSecondary, size: 18),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Karanlik Mod',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Switch.adaptive(
                  value: themeMode == ThemeMode.dark,
                  onChanged: (_) => ref.read(themeModeProvider.notifier).toggleDarkMode(),
                  activeColor: AppColors.primary,
                ),
              ],
            ),
          ),
          _SettingsDivider(),
          if (isAdmin) ...[
            _SettingsTile(
              icon: Icons.admin_panel_settings_rounded,
              title: 'Admin Paneli',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
              ),
            ),
            _SettingsDivider(),
          ],
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            title: 'Hakkinda',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AboutScreen()),
            ),
          ),
          _SettingsDivider(),
          _SettingsTile(
            icon: Icons.history_rounded,
            title: 'Guncelleme Gecmisi',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UpdateHistoryScreen()),
            ),
          ),
          _SettingsDivider(),
          _SettingsTile(
            icon: Icons.logout_rounded,
            title: 'Cikis Yap',
            isDestructive: true,
            showChevron: false,
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
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
    this.showChevron = true,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error : AppColors.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDestructive
                    ? AppColors.error.withOpacity(0.08)
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDestructive ? AppColors.error : AppColors.textPrimary,
                ),
              ),
            ),
            if (showChevron)
              const Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 20),
          ],
        ),
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        height: 1,
        thickness: 1,
        color: AppColors.outline.withOpacity(0.4),
      ),
    );
  }
}

// ---------- Sub-Screens (unchanged logic, refreshed styling) ----------

class MyPricesScreen extends StatelessWidget {
  const MyPricesScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Fiyatlarim')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('priceReports')
            .where('createdByUid', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ListError(onRetry: () => (context as Element).markNeedsBuild());
          }
          final docs = (snapshot.data?.docs ?? const [])
              .where((doc) => (doc.data()['status'] ?? '').toString() == 'active')
              .toList()
            ..sort((a, b) {
              final aTs = a.data()['createdAt'] as Timestamp?;
              final bTs = b.data()['createdAt'] as Timestamp?;
              final aDt = aTs?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
              final bDt = bTs?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
              return bDt.compareTo(aDt);
            });
          if (docs.isEmpty) {
            return const Center(child: Text('Henuz fiyat eklemedin.'));
          }
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final ts = data['createdAt'];
              final date = ts is Timestamp ? ts.toDate() : null;
              final productName = (data['productName'] ?? data['urunAdi'] ?? data['name'] ?? data['title'] ?? '').toString().trim();
              final displayName = productName.isEmpty ? 'Isimsiz Urun' : productName;
              final formattedDate = date == null ? 'Tarih yok' : '${date.day}.${date.month}.${date.year}';
              return ListTile(
                title: Text(displayName),
                subtitle: Text('${(data['storeName'] ?? 'Market').toString()} - $formattedDate'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(formatTRY((data['price'] ?? 0) as num), style: const TextStyle(fontWeight: FontWeight.w700)),
                    if (data['verified'] == true)
                      const Text('Dogrulandi', style: TextStyle(fontSize: 11, color: Colors.green)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key, required this.userId});

  final String userId;

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final Map<String, ProductModel> _productCache = <String, ProductModel>{};
  Set<String> _loadingIds = <String>{};

  Future<void> _ensureProducts(List<String> productIds) async {
    final missing = productIds.where((id) => id.isNotEmpty && !_productCache.containsKey(id)).toSet();
    if (missing.isEmpty) return;
    if (_loadingIds.containsAll(missing)) return;

    setState(() => _loadingIds = {..._loadingIds, ...missing});
    try {
      final products = await FirestoreService().getProductsByIds(missing.toList());
      if (!mounted) return;
      setState(() {
        for (final product in products) {
          _productCache[product.id] = product;
        }
      });
    } finally {
      if (mounted) {
        setState(() => _loadingIds = _loadingIds.difference(missing));
      }
    }
  }

  Future<void> _removeFavorite(String productId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('favorites')
          .doc(productId)
          .delete();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Favoriler guncellenemedi. Tekrar dene.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Favoriler')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('favorites')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ListError(onRetry: () => (context as Element).markNeedsBuild());
          }

          final docs = snapshot.data?.docs ?? const [];
          if (docs.isEmpty) {
            return Center(
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: AppColors.surfaceVariant,
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite_border, size: 42, color: AppColors.textTertiary),
                    SizedBox(height: 8),
                    Text('Henuz favori urunun yok.'),
                  ],
                ),
              ),
            );
          }

          final productIds = docs
              .map((doc) => (doc.data()['productId'] ?? '').toString())
              .where((id) => id.isNotEmpty)
              .toList();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _ensureProducts(productIds);
          });

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final productId = (data['productId'] ?? '').toString();
              final product = _productCache[productId];
              final title = product?.name ?? (data['productName'] ?? 'Urun').toString();
              final subtitle = product?.brand ?? 'Urun';
              final image = product?.effectiveImage;

              return Dismissible(
                key: ValueKey('fav-$productId'),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red.withOpacity(0.12),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Icon(Icons.delete_outline, color: Colors.red),
                ),
                onDismissed: (_) => _removeFavorite(productId),
                child: ListTile(
                  leading: image == null
                      ? const Icon(Icons.favorite, color: Colors.red)
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(image, width: 44, height: 44, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.favorite, color: Colors.red)),
                        ),
                  title: Text(title),
                  subtitle: Text(subtitle),
                  trailing: IconButton(
                    icon: const Icon(Icons.favorite, color: Colors.red),
                    onPressed: () => _removeFavorite(productId),
                  ),
                  onTap: () {
                    if (productId.isEmpty) return;
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: productId)));
                  },
                ),
              );
            },
          );
        },
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
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Fislerim')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').doc(userId).collection('receipts').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ListError(onRetry: () => (context as Element).markNeedsBuild());
          }
          final docs = snapshot.data?.docs ?? const [];
          if (docs.isEmpty) {
            return const Center(child: Text('Henuz fis eklemedin.'));
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();
              return ListTile(
                leading: const Icon(Icons.receipt_long_rounded),
                title: Text((data['market'] ?? 'Market').toString()),
                subtitle: Text((data['note'] ?? 'Fis').toString()),
                trailing: Text(formatTRY((data['total'] ?? 0) as num)),
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
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Hakkinda')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF8EF), Color(0xFFF8EDDB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: const Color(0xFFE8D5B8)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FiyatRadar',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Surum 1.5.0 - FiyatRadar Ekibi',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Gizlilik Politikasi',
            onTap: () => launchUrl(Uri.parse('https://fiyatradar.app/privacy')),
          ),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.description_outlined,
            title: 'Kullanim Sartlari',
            onTap: () => launchUrl(Uri.parse('https://fiyatradar.app/terms')),
          ),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.history_rounded,
            title: 'Guncelleme Gecmisi',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UpdateHistoryScreen())),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.textTertiary),
          const SizedBox(height: 12),
          const Text(
            'Profil verisi yuklenemedi.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Tekrar dene'),
          ),
        ],
      ),
    );
  }
}

class _ListError extends StatelessWidget {
  const _ListError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.textTertiary),
          const SizedBox(height: 12),
          const Text(
            'Veriler alinamadi.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Tekrar dene'),
          ),
        ],
      ),
    );
  }
}

class _ProfileData {
  const _ProfileData({
    required this.displayName,
    required this.photoUrl,
    required this.username,
    required this.levelName,
    required this.trustScore,
    required this.trustTotalVotes,
    required this.totalPoints,
  });

  final String displayName;
  final String photoUrl;
  final String username;
  final String levelName;
  final double trustScore;
  final int trustTotalVotes;
  final int totalPoints;
}
