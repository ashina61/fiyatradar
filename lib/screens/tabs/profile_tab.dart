import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/design.dart';
import '../settings_screen.dart';
import '../profile/favorites_screen.dart';
import '../profile/history_screen.dart';
import '../profile/alerts_screen.dart';
import '../admin_screen.dart';

// ─── Level system ─────────────────────────────────────────────────────────────

class _Level {
  final String name;
  final String emoji;
  final int minPoints;
  final int? maxPoints;
  final Color color;

  const _Level({
    required this.name,
    required this.emoji,
    required this.minPoints,
    this.maxPoints,
    required this.color,
  });
}

const _levels = [
  _Level(
    name: 'Gözlemci',
    emoji: '👁️',
    minPoints: 0,
    maxPoints: 99,
    color: Color(0xFF9E9E9E),
  ),
  _Level(
    name: 'Avcı',
    emoji: '🎯',
    minPoints: 100,
    maxPoints: 299,
    color: Color(0xFF8D6E63),
  ),
  _Level(
    name: 'Tasarrufçu',
    emoji: '💡',
    minPoints: 300,
    maxPoints: 699,
    color: Color(0xFF2E7D32),
  ),
  _Level(
    name: 'Market Ustası',
    emoji: '⭐',
    minPoints: 700,
    maxPoints: 1499,
    color: Color(0xFF1565C0),
  ),
  _Level(
    name: 'Fiyat Lordu',
    emoji: '🔥',
    minPoints: 1500,
    maxPoints: 2999,
    color: Color(0xFF7B1FA2),
  ),
  _Level(
    name: 'Radar Efsanesi',
    emoji: '💎',
    minPoints: 3000,
    maxPoints: null,
    color: Color(0xFFB07B4F),
  ),
];

_Level _currentLevel(int points) {
  for (var i = _levels.length - 1; i >= 0; i--) {
    if (points >= _levels[i].minPoints) return _levels[i];
  }
  return _levels.first;
}

_Level? _nextLevel(int points) {
  final cur = _currentLevel(points);
  final idx = _levels.indexOf(cur);
  if (idx < _levels.length - 1) return _levels[idx + 1];
  return null;
}

double _levelProgress(int points) {
  final cur = _currentLevel(points);
  final next = _nextLevel(points);
  if (next == null) return 1.0;
  final rangeStart = cur.minPoints;
  final rangeEnd = next.minPoints;
  return ((points - rangeStart) / (rangeEnd - rangeStart)).clamp(0.0, 1.0);
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final points = state.points;
    final level = _currentLevel(points);
    final nextLvl = _nextLevel(points);
    final progress = _levelProgress(points);

    final addedCount = state.products
        .where((p) => p.priceHistory.any(
              (e) =>
                  e.reportedBy == 'Sen' ||
                  e.reportedBy == (state.user?.displayName ?? ''),
            ))
        .length;

    final favCount = state.favorites.length;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          // ── Header ───────────────────────────────────────────────
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profil',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: CoffeeColors.espresso,
                        letterSpacing: -0.7,
                      ),
                    ),
                    Text(
                      'Kişisel merkezin',
                      style: TextStyle(
                        color: CoffeeColors.cocoa,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Identity + Level hero ─────────────────────────────────
          _ProfileHero(
            points: points,
            level: level,
            nextLevel: nextLvl,
            progress: progress,
          ),
          const SizedBox(height: 14),

          // ── Combined stats + actions card ──────────────────────────
          _StatsActionsCard(
            addedCount: addedCount,
            favCount: favCount,
            points: points,
            onContributions: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            ),
            onFavorites: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FavoritesScreen()),
            ),
            onAlerts: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AlertsScreen()),
            ),
            onSettings: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          const SizedBox(height: 14),

          // ── Level journey ─────────────────────────────────────────
          _LevelJourneyCard(currentLevel: level),
          const SizedBox(height: 14),

          // ── Contribution ways ─────────────────────────────────────
          _ContributionCard(),
          const SizedBox(height: 14),

          // ── Navigation menu ───────────────────────────────────────
          _MenuSection(
            title: 'Kütüphanem',
            items: [
              _MenuItem(
                icon: Icons.bookmark_outline,
                title: 'Kayıtlı Ürünler',
                subtitle: '$favCount ürün takipte',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const FavoritesScreen()),
                ),
              ),
              _MenuItem(
                icon: Icons.notifications_none,
                title: 'Fiyat Alarmlarım',
                subtitle: 'Düşüş bildirimlerini yönet',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AlertsScreen()),
                ),
              ),
              _MenuItem(
                icon: Icons.history,
                title: 'Katkı Geçmişim',
                subtitle: '$addedCount fiyat katkısı',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _MenuSection(
            title: 'Hesap',
            items: [
              _MenuItem(
                icon: Icons.settings_outlined,
                title: 'Ayarlar',
                subtitle: 'Hesap, bildirim, gizlilik',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
              _MenuItem(
                icon: Icons.admin_panel_settings_outlined,
                title: 'Yönetim Paneli',
                subtitle: 'Admin & içerik yönetimi',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _MenuSection(
            items: [
              _MenuItem(
                icon: Icons.logout,
                title: 'Çıkış Yap',
                isDestructive: true,
                onTap: () => _showLogoutDialog(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Çıkış Yap',
          style: TextStyle(
              fontWeight: FontWeight.w800, color: CoffeeColors.espresso),
        ),
        content: const Text(
          'Hesabından çıkmak istediğine emin misin?',
          style: TextStyle(color: CoffeeColors.cocoa),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal',
                style: TextStyle(color: CoffeeColors.cocoa)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final state = AppStateScope.of(context);
              await state.logout();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Oturum kapatıldı.'),
                  backgroundColor: CoffeeColors.darkRoast,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: CoffeeColors.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Çık',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ─── Profile hero card ────────────────────────────────────────────────────────

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.points,
    required this.level,
    required this.nextLevel,
    required this.progress,
  });

  final int points;
  final _Level level;
  final _Level? nextLevel;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [CoffeeColors.espresso, CoffeeColors.darkRoast],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: CoffeeColors.espresso.withOpacity(0.28),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: level.color.withOpacity(0.20),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: level.color.withOpacity(0.50), width: 2),
                ),
                alignment: Alignment.center,
                child: Text(level.emoji,
                    style: const TextStyle(fontSize: 28)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kahve Avcısı',
                      style: TextStyle(
                        color: CoffeeColors.cream,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '@fiyatradar_user',
                      style: TextStyle(
                          color: CoffeeColors.latte, fontSize: 13),
                    ),
                  ],
                ),
              ),
              // Level badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: level.color.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: level.color.withOpacity(0.45)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(level.emoji,
                        style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 5),
                    Text(
                      level.name,
                      style: TextStyle(
                        color: level.color == const Color(0xFFB07B4F)
                            ? CoffeeColors.caramel
                            : Color.lerp(level.color, Colors.white, 0.5)!,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (nextLevel != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  '$points puan',
                  style: const TextStyle(
                      color: CoffeeColors.latte,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  '${nextLevel!.minPoints} puan → ${nextLevel!.emoji} ${nextLevel!.name}',
                  style: const TextStyle(
                      color: CoffeeColors.latte, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 7),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 7,
                backgroundColor: Colors.white.withOpacity(0.12),
                valueColor: AlwaysStoppedAnimation<Color>(
                  level.color == const Color(0xFFB07B4F)
                      ? CoffeeColors.caramel
                      : level.color,
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: CoffeeColors.caramel.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('💎 ', style: TextStyle(fontSize: 14)),
                  Text(
                    'En yüksek seviyedesin · Radar Efsanesi',
                    style: TextStyle(
                        color: CoffeeColors.caramel,
                        fontWeight: FontWeight.w700,
                        fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Combined stats + actions card ────────────────────────────────────────────

class _StatsActionsCard extends StatelessWidget {
  const _StatsActionsCard({
    required this.addedCount,
    required this.favCount,
    required this.points,
    required this.onContributions,
    required this.onFavorites,
    required this.onAlerts,
    required this.onSettings,
  });

  final int addedCount;
  final int favCount;
  final int points;
  final VoidCallback onContributions;
  final VoidCallback onFavorites;
  final VoidCallback onAlerts;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CoffeeColors.crema),
        boxShadow: FR.softShadow,
      ),
      child: Column(
        children: [
          // Stats row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                _StatCell(
                  label: 'Katkı',
                  value: '$addedCount',
                  icon: Icons.add_chart,
                  onTap: onContributions,
                ),
                Container(
                    width: 1, height: 40, color: CoffeeColors.crema),
                _StatCell(
                  label: 'Favori',
                  value: '$favCount',
                  icon: Icons.favorite_border,
                  onTap: onFavorites,
                ),
                Container(
                    width: 1, height: 40, color: CoffeeColors.crema),
                _StatCell(
                  label: 'Puan',
                  value: '$points',
                  icon: Icons.star_border,
                  onTap: null,
                  accent: CoffeeColors.caramel,
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: CoffeeColors.crema),

          // Quick actions row
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Row(
              children: [
                _ActionBtn(
                  icon: Icons.notifications_none,
                  label: 'Alarmlar',
                  onTap: onAlerts,
                ),
                const SizedBox(width: 8),
                _ActionBtn(
                  icon: Icons.history,
                  label: 'Geçmiş',
                  onTap: onContributions,
                ),
                const SizedBox(width: 8),
                _ActionBtn(
                  icon: Icons.settings_outlined,
                  label: 'Ayarlar',
                  onTap: onSettings,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
    required this.icon,
    this.onTap,
    this.accent = CoffeeColors.caramel,
  });
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Icon(icon, color: accent, size: 18),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: CoffeeColors.espresso),
            ),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 11, color: CoffeeColors.cocoa),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
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
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: CoffeeColors.foam,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CoffeeColors.crema),
          ),
          child: Column(
            children: [
              Icon(icon, color: CoffeeColors.darkRoast, size: 18),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: CoffeeColors.espresso,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Menu section ─────────────────────────────────────────────────────────────

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.items, this.title});
  final List<_MenuItem> items;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title!.toUpperCase(),
              style: const TextStyle(
                color: CoffeeColors.cocoa,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
          ),
        ],
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: CoffeeColors.crema),
            boxShadow: FR.softShadow,
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  _MenuTile(item: item),
                  if (i < items.length - 1)
                    const Divider(
                        height: 1, indent: 54, color: CoffeeColors.crema),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  const _MenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.item});
  final _MenuItem item;

  @override
  Widget build(BuildContext context) {
    final isDestructive = item.isDestructive;
    return ListTile(
      onTap: item.onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isDestructive
              ? CoffeeColors.danger.withOpacity(0.10)
              : CoffeeColors.foam,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          item.icon,
          color: isDestructive
              ? CoffeeColors.danger
              : CoffeeColors.darkRoast,
          size: 19,
        ),
      ),
      title: Text(
        item.title,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: isDestructive
              ? CoffeeColors.danger
              : CoffeeColors.espresso,
          fontSize: 14,
        ),
      ),
      subtitle: item.subtitle != null
          ? Text(
              item.subtitle!,
              style: const TextStyle(
                  color: CoffeeColors.cocoa, fontSize: 12),
            )
          : null,
      trailing: isDestructive
          ? null
          : const Icon(Icons.chevron_right,
              color: CoffeeColors.cocoa, size: 20),
    );
  }
}

// ─── Level journey card ───────────────────────────────────────────────────────

class _LevelJourneyCard extends StatelessWidget {
  const _LevelJourneyCard({required this.currentLevel});
  final _Level currentLevel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CoffeeColors.crema),
        boxShadow: FR.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🏅', style: TextStyle(fontSize: 18)),
              SizedBox(width: 8),
              Text(
                'Seviye Yolculuğu',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: CoffeeColors.espresso,
                    fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ..._levels.map((l) {
            final isCurrent = l.name == currentLevel.name;
            final isPast =
                _levels.indexOf(l) < _levels.indexOf(currentLevel);
            return Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? l.color.withOpacity(0.18)
                          : isPast
                              ? CoffeeColors.foam
                              : CoffeeColors.foam,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isCurrent ? l.color : CoffeeColors.crema,
                        width: isCurrent ? 2 : 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: isPast
                        ? const Icon(Icons.check,
                            color: Color(0xFF2E7D32), size: 14)
                        : Text(l.emoji,
                            style: const TextStyle(fontSize: 14)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l.name,
                      style: TextStyle(
                        fontWeight: isCurrent
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: isCurrent
                            ? CoffeeColors.espresso
                            : isPast
                                ? CoffeeColors.cocoa
                                : CoffeeColors.cocoa.withOpacity(0.6),
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Text(
                    l.maxPoints == null
                        ? '${l.minPoints}+'
                        : '${l.minPoints}–${l.maxPoints}',
                    style: TextStyle(
                      color: isCurrent ? l.color : CoffeeColors.crema,
                      fontSize: 11,
                      fontWeight: isCurrent
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (isCurrent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: l.color,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Şu an',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800),
                      ),
                    )
                  else
                    const SizedBox(width: 36),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Contribution card ────────────────────────────────────────────────────────

class _ContributionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CoffeeColors.crema),
        boxShadow: FR.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emoji_events_outlined,
                  color: CoffeeColors.caramel, size: 18),
              SizedBox(width: 8),
              Text(
                'Puan Kazan',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: CoffeeColors.espresso,
                    fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _rewardRow(Icons.add_circle_outline, 'Fiyat ekle',
              '+${PointsRules.addPrice} puan'),
          _rewardRow(Icons.inventory_2_outlined, 'Yeni ürün ekle',
              '+${PointsRules.addProduct} puan'),
          _rewardRow(Icons.favorite_border, 'Favorilere ekle',
              '+${PointsRules.favorite} puan'),
          _rewardRow(Icons.login_outlined, 'Günlük giriş',
              '+${PointsRules.dailyLogin} puan'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: CoffeeColors.foam,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline,
                    size: 14, color: CoffeeColors.cocoa),
                SizedBox(width: 6),
                Text(
                  '100 puan = ₺5 değerinde',
                  style:
                      TextStyle(color: CoffeeColors.cocoa, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _rewardRow(IconData icon, String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Icon(icon, size: 16, color: CoffeeColors.darkRoast),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
                color: CoffeeColors.espresso,
                fontSize: 13,
                fontWeight: FontWeight.w600),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: CoffeeColors.caramel.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: const TextStyle(
              color: CoffeeColors.caramel,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
      ],
    ),
  );
}
