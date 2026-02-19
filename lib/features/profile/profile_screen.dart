import 'package:flutter/material.dart';

import 'widgets/badges_list.dart';
import 'widgets/cta_banner.dart';
import 'widgets/level_card.dart';
import 'widgets/profile_header.dart';
import 'widgets/stats_grid.dart';
import 'widgets/trust_score_card.dart';

class BadgeItem {
  const BadgeItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.earned,
    required this.progress,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final bool earned;
  final double progress;
}

class ProfileStats {
  const ProfileStats({
    required this.katki,
    required this.dogrulama,
    required this.uyelikGun,
    required this.seriGun,
    required this.seviye,
    required this.puan,
    required this.puanMax,
    required this.guvenSkor,
    required this.badges,
  });

  final int katki;
  final int dogrulama;
  final int uyelikGun;
  final int seriGun;
  final int seviye;
  final int puan;
  final int puanMax;
  final int guvenSkor;
  final List<BadgeItem> badges;

  int get earnedBadgeCount => badges.where((item) => item.earned).length;
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const Color _background = Color(0xFFF1F4FA);

  ProfileStats _mockStats() {
    return const ProfileStats(
      katki: 34,
      dogrulama: 128,
      uyelikGun: 45,
      seriGun: 5,
      seviye: 3,
      puan: 420,
      puanMax: 600,
      guvenSkor: 87,
      badges: [
        BadgeItem(
          title: 'İlk Katkı',
          description: 'İlk fiyat bildirimini yaptın',
          icon: Icons.star_rounded,
          iconColor: Color(0xFFF59E0B),
          iconBackground: Color(0xFFFFF7E8),
          earned: true,
          progress: 1,
        ),
        BadgeItem(
          title: 'Güvenilir',
          description: 'Güven skorun 80 üzeri',
          icon: Icons.verified_user_rounded,
          iconColor: Color(0xFF00C2A8),
          iconBackground: Color(0xFFEEFCF9),
          earned: true,
          progress: 1,
        ),
        BadgeItem(
          title: 'Aktif Üye',
          description: '7 gün üst üste katkı',
          icon: Icons.local_fire_department_rounded,
          iconColor: Color(0xFFFF5D5D),
          iconBackground: Color(0xFFFFEFEF),
          earned: true,
          progress: 0.72,
        ),
        BadgeItem(
          title: 'Market Uzmanı',
          description: '50 fiyat bildirimi yap',
          icon: Icons.shopping_bag_rounded,
          iconColor: Color(0xFF667085),
          iconBackground: Color(0xFFF3F5F8),
          earned: false,
          progress: 0.68,
        ),
        BadgeItem(
          title: 'Doğrulayıcı',
          description: '100 fiyatı doğrula',
          icon: Icons.check_circle_rounded,
          iconColor: Color(0xFF667085),
          iconBackground: Color(0xFFF3F5F8),
          earned: false,
          progress: 0.54,
        ),
        BadgeItem(
          title: 'Altın Üye',
          description: '1000 puan kazan',
          icon: Icons.emoji_events_rounded,
          iconColor: Color(0xFF667085),
          iconBackground: Color(0xFFF3F5F8),
          earned: false,
          progress: 0.42,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = _mockStats();

    return Scaffold(
      backgroundColor: _background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: ProfileHeader(stats: stats)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: LevelCard(stats: stats)),
                    const SizedBox(width: 12),
                    Expanded(flex: 2, child: TrustScoreCard(score: stats.guvenSkor)),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Performans Panosu',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Topluluk içindeki etkinliğini premium metriklerle takip et.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),
                StatsGrid(stats: stats),
                const SizedBox(height: 26),
                BadgesList(badges: stats.badges),
                const SizedBox(height: 24),
                CtaBanner(points: stats.puan),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
