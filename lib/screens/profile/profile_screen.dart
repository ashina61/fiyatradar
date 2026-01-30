import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/theme.dart';
import '../../services/mock_data_service.dart';
import '../admin/admin_panel_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    final mockUser = MockDataService().currentUser;
    // Demo admin flag - set to true to show admin section
    const bool isAdmin = true;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Profile Header with Gradient ---
            _buildProfileHeader(context, mockUser),

            // --- Stats Cards Row (overlapping header) ---
            Transform.translate(
              offset: const Offset(0, -36),
              child: _buildStatsRow(context),
            ),

            // --- Achievements / Badges ---
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Text(
                'Rozetler',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
              ),
            ),
            _buildBadgesSection(context),
            const SizedBox(height: AppSpacing.lg),

            // --- Menu Items Group 1 ---
            _buildMenuCard(
              context,
              items: [
                _MenuItem(
                  icon: Icons.bookmark_outline,
                  title: 'Kaydedilen Urunler',
                  onTap: () {},
                ),
                _MenuItem(
                  icon: Icons.history,
                  title: 'Fiyat Gecmisim',
                  onTap: () {},
                ),
                _MenuItem(
                  icon: Icons.settings_outlined,
                  title: 'Ayarlar',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // --- Menu Items Group 2 ---
            _buildMenuCard(
              context,
              items: [
                _MenuItem(
                  icon: Icons.dark_mode_outlined,
                  title: 'Tema',
                  trailing: Switch(
                    value: _isDarkMode,
                    onChanged: (val) {
                      setState(() => _isDarkMode = val);
                    },
                    activeColor: AppColors.primary,
                  ),
                ),
                _MenuItem(
                  icon: Icons.notifications_outlined,
                  title: 'Bildirim Ayarlari',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // --- Menu Items Group 3 ---
            _buildMenuCard(
              context,
              items: [
                _MenuItem(
                  icon: Icons.help_outline,
                  title: 'Yardim & Destek',
                  onTap: () {},
                ),
                _MenuItem(
                  icon: Icons.feedback_outlined,
                  title: 'Geri Bildirim',
                  onTap: () {},
                ),
                _MenuItem(
                  icon: Icons.info_outline,
                  title: 'Hakkinda',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // --- Admin Section ---
            if (isAdmin) _buildAdminSection(context),

            // --- Sign Out ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  side: BorderSide(
                    color: AppColors.error.withOpacity(0.2),
                  ),
                ),
                child: ListTile(
                  leading: const Icon(Icons.logout, color: AppColors.error),
                  title: const Text(
                    'Cikis Yap',
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Demo modda cikis yapilamaz'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // --- App Version ---
            Center(
              child: Text(
                'FiyatRadar v1.0.0',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Profile Header
  // ---------------------------------------------------------------------------
  Widget _buildProfileHeader(BuildContext context, MockUser user) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppSpacing.lg,
        bottom: AppSpacing.xxl + 12,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Edit profile icon button (top right)
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              icon: const Icon(Icons.edit, color: Colors.white70, size: 22),
              onPressed: () {},
            ),
          ),
          // Profile info centered
          Center(
            child: Column(
              children: [
                // Circle avatar with gradient background & initial
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryLight.withOpacity(0.8),
                        AppColors.secondaryLight.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      user.initial,
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // User name
                const Text(
                  'Demo Kullanici',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                // Email
                const Text(
                  'demo@fiyatradar.com',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Stats Row
  // ---------------------------------------------------------------------------
  Widget _buildStatsRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              context,
              value: '45',
              label: 'Fiyat Girisi',
              icon: Icons.price_change,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _buildStatCard(
              context,
              value: '1250',
              label: 'Puan',
              icon: Icons.stars,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _buildStatCard(
              context,
              value: '120',
              label: 'Dogrulama',
              icon: Icons.verified,
              color: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Badges Section
  // ---------------------------------------------------------------------------
  Widget _buildBadgesSection(BuildContext context) {
    final badges = [
      _BadgeItem(
        emoji: '\u{1F3C6}',
        name: 'Fiyat Avcisi',
        description: '50+ fiyat girisi',
        color: AppColors.accent,
      ),
      _BadgeItem(
        emoji: '\u{2B50}',
        name: 'Guvenilir Uye',
        description: '100+ dogrulama',
        color: AppColors.primary,
      ),
      _BadgeItem(
        emoji: '\u{1F525}',
        name: 'Trend Belirleyici',
        description: '10+ trend urun',
        color: AppColors.error,
      ),
      _BadgeItem(
        emoji: '\u{1F6E1}',
        name: 'Dogrulayici',
        description: '50+ dogrulama',
        color: AppColors.secondary,
      ),
    ];

    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: badges.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          final badge = badges[index];
          return SizedBox(
            width: 90,
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: badge.color.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: badge.color.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      badge.emoji,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  badge.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Menu Card
  // ---------------------------------------------------------------------------
  Widget _buildMenuCard(
    BuildContext context, {
    required List<_MenuItem> items,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: List.generate(items.length, (index) {
            final item = items[index];
            final isLast = index == items.length - 1;
            return Column(
              children: [
                ListTile(
                  leading: Icon(
                    item.icon,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  title: Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  trailing: item.trailing ??
                      const Icon(
                        Icons.chevron_right,
                        color: AppColors.textTertiary,
                      ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: index == 0
                          ? const Radius.circular(AppRadius.lg)
                          : Radius.zero,
                      bottom: isLast
                          ? const Radius.circular(AppRadius.lg)
                          : Radius.zero,
                    ),
                  ),
                  onTap: item.onTap,
                ),
                if (!isLast)
                  Divider(
                    height: 1,
                    indent: 56,
                    color: AppColors.outline.withOpacity(0.5),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Admin Section
  // ---------------------------------------------------------------------------
  Widget _buildAdminSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Text(
                'Admin',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Text(
                  'ADMIN',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        _buildMenuCard(
          context,
          items: [
            _MenuItem(
              icon: Icons.build_outlined,
              title: 'Admin Paneli',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AdminPanelScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}

// =============================================================================
// Helper classes
// =============================================================================

class _MenuItem {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _MenuItem({
    required this.icon,
    required this.title,
    this.onTap,
    this.trailing,
  });
}

class _BadgeItem {
  final String emoji;
  final String name;
  final String description;
  final Color color;

  const _BadgeItem({
    required this.emoji,
    required this.name,
    required this.description,
    required this.color,
  });
}
