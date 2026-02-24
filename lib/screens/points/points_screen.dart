import 'package:flutter/material.dart';

import '../../widgets/premium_level_badge.dart';

class PointsScreen extends StatefulWidget {
  const PointsScreen({super.key});

  @override
  State<PointsScreen> createState() => _PointsScreenState();
}

class _PointsScreenState extends State<PointsScreen> {
  static const Color _bgCream = Color(0xFFFDFBF9);
  static const Color _textDark = Color(0xFF3A2B24);
  static const Color _textMuted = Color(0xFF8C7A6B);
  static const Color _borderLight = Color(0xFFEBE1D7);

  int _selectedTab = 0;

  final List<_LeaderboardUser> _podiumUsers = const [
    _LeaderboardUser(rank: 2, name: 'Mert A.', points: '24.5K', emoji: '👱🏻‍♂️', level: 'Market Ustası'),
    _LeaderboardUser(rank: 1, name: 'Elif S.', points: '32.8K', emoji: '😎', level: 'Radar Efsanesi', isVerified: true),
    _LeaderboardUser(rank: 3, name: 'Can Y.', points: '21.2K', emoji: '👩🏻‍🦰', level: 'Fiyat Lordu'),
  ];

  final List<_LeaderboardUser> _leaderboardUsers = const [
    _LeaderboardUser(rank: 4, name: 'Hasan T.', points: '19.1K', emoji: '🧔🏻‍♂️', level: 'Fiyat Lordu'),
    _LeaderboardUser(rank: 5, name: 'Ayşe K.', points: '18.9K', emoji: '👩🏻‍🏫', level: 'Market Ustası'),
    _LeaderboardUser(rank: 6, name: 'Adem K.', points: '18.5K', emoji: '👨🏻‍💻', level: 'Fiyat Lordu (Sen)', isCurrentUser: true, isVerified: true),
    _LeaderboardUser(rank: 7, name: 'Deniz A.', points: '17.8K', emoji: '🧑🏻', level: 'Gözlemci'),
    _LeaderboardUser(rank: 8, name: 'Bora M.', points: '17.1K', emoji: '👨🏼', level: 'Gözlemci'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgCream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: _buildSegmentedTabMenu(),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _selectedTab == 0 ? _buildOverviewTab() : _buildLeaderboardTab(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedTabMenu() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const padding = 6.0;
        final tabWidth = (constraints.maxWidth - (padding * 2)) / 2;

        return Container(
          height: 56,
          padding: const EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: const Color(0xFFF0EBE6),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(color: Color(0x12000000), blurRadius: 4, offset: Offset(0, 1)),
            ],
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                left: _selectedTab == 0 ? 0 : tabWidth,
                top: 0,
                bottom: 0,
                width: tabWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4A3623).withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(child: _buildTabButton(0, 'Genel Bakış')),
                  Expanded(child: _buildTabButton(1, 'Zirvedekiler')),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabButton(int index, String title) {
    final isActive = _selectedTab == index;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => setState(() => _selectedTab = index),
      child: Center(
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? _textDark : _textMuted,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      key: const ValueKey('overview'),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard(),
          const SizedBox(height: 14),
          _buildStatsGrid(),
          const SizedBox(height: 16),
          _buildSectionTitle('Seviye Ayrıcalıkları'),
          const SizedBox(height: 8),
          _buildPrivilegesList(),
          const SizedBox(height: 16),
          _buildSectionTitle('Puan Kazan'),
          const SizedBox(height: 8),
          _buildPointTasks(),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A3623).withOpacity(0.07),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PremiumLevelBadge(levelName: 'Gözlemci'),
              const Spacer(),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Toplam Puan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _PointsScreenState._textMuted)),
                  SizedBox(height: 2),
                  Text('15.000', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: _PointsScreenState._textDark, letterSpacing: -0.6)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildProgressSection(
            title: 'Seviye İlerlemesi',
            limit: '15.000 / 20.000',
            fillColor: const Color(0xFF8B7365),
            progress: 0.75,
            description: 'Sonraki seviyeye +5.000 Puan',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: _borderLight, width: 1.5),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Text(
                'SONRAKİ SEVİYE: RADAR EFSANESİ',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: _textMuted, letterSpacing: 0.4),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildProgressSection(
            title: 'Güven Skoru',
            limit: '%38 / Min %85',
            fillColor: const Color(0xFFD32F2F),
            progress: 0.38,
            description: 'Sonraki seviye için minimum güven şartı sağlanmalı',
            danger: true,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                border: Border.all(color: const Color(0xFFFFCDD2), width: 1.5),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Text(
                'GATED',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFFD32F2F), letterSpacing: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection({
    required String title,
    required String limit,
    required Color fillColor,
    required double progress,
    required String description,
    required Widget trailing,
    bool danger = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _textDark)),
            const Spacer(),
            Text(limit, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textMuted)),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            minHeight: 14,
            value: progress,
            backgroundColor: const Color(0xFFEAE6E1),
            valueColor: AlwaysStoppedAnimation(fillColor),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                  color: danger ? const Color(0xFFD32F2F) : _textMuted,
                ),
              ),
            ),
            const SizedBox(width: 10),
            trailing,
          ],
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: const [
        Expanded(child: _MiniStatCard(value: '+124', label: 'Bu Hafta', color: Color(0xFF00C853))),
        SizedBox(width: 12),
        Expanded(child: _MiniStatCard(value: '86', label: 'Onaylı Fiyat', color: _textDark)),
        SizedBox(width: 12),
        Expanded(child: _MiniStatCard(value: '12', label: 'Seri Gün', color: Color(0xFFFFB300))),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          color: _textMuted,
          letterSpacing: 0.9,
        ),
      ),
    );
  }

  Widget _buildPrivilegesList() {
    return const Column(
      children: [
        _PrivilegeTile(
          title: 'Temel Fiyat Bildirimi',
          subtitle: 'Gözlemci (Mevcut Seviye)',
          icon: Icons.sell_rounded,
          unlocked: true,
        ),
        SizedBox(height: 8),
        _PrivilegeTile(
          title: 'Özel Favori Market Alarmları',
          subtitle: 'Market Ustası Olunca Açılır',
          icon: Icons.notifications_active_rounded,
          unlocked: false,
        ),
        SizedBox(height: 8),
        _PrivilegeTile(
          title: 'Sınırsız Geçmiş Fiyat Analizi',
          subtitle: 'Radar Efsanesi Olunca Açılır',
          icon: Icons.history_rounded,
          unlocked: false,
        ),
      ],
    );
  }

  Widget _buildPointTasks() {
    return const Column(
      children: [
        _PointTaskTile(title: 'Günün Fişini Tara', subtitle: '0/1 Tamamlandı', icon: Icons.qr_code_scanner_rounded, reward: '+100 P'),
        SizedBox(height: 10),
        _PointTaskTile(title: 'Yeni Market Ekle', subtitle: 'Limitsiz', icon: Icons.add_business_rounded, reward: '+50 P'),
        SizedBox(height: 10),
        _PointTaskTile(title: 'Arkadaş Davet Et', subtitle: 'Özel Referans Kodu', icon: Icons.group_add_rounded, reward: '+250 P'),
      ],
    );
  }

  Widget _buildLeaderboardTab() {
    return SingleChildScrollView(
      key: const ValueKey('leaderboard'),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPodium(),
          const SizedBox(height: 10),
          _buildLeaderboard(),
        ],
      ),
    );
  }

  Widget _buildPodium() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 18, 8, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _borderLight, style: BorderStyle.solid)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: _podiumUsers.map(_buildPodiumSlot).toList(),
      ),
    );
  }

  Widget _buildPodiumSlot(_LeaderboardUser user) {
    final bool isFirst = user.rank == 1;
    final Color medalColor = switch (user.rank) {
      1 => const Color(0xFFFFC107),
      2 => const Color(0xFFB0BEC5),
      _ => const Color(0xFFCD7F32),
    };

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isFirst)
            const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFC107), size: 30),
          const SizedBox(height: 2),
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                width: isFirst ? 84 : 64,
                height: isFirst ? 84 : 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: medalColor, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: medalColor.withOpacity(isFirst ? 0.35 : 0.15),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Text(user.emoji, style: TextStyle(fontSize: isFirst ? 34 : 26)),
              ),
              Positioned(
                bottom: -8,
                child: Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: medalColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Text('${user.rank}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                user.name,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: isFirst ? 15 : 13,
                  color: isFirst ? const Color(0xFFFFC107) : _textDark,
                ),
              ),
              if (user.isVerified) ...[
                const SizedBox(width: 4),
                const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF1E88E5)),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(user.points, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _textMuted)),
        ],
      ),
    );
  }

  Widget _buildLeaderboard() {
    return Column(
      children: _leaderboardUsers
          .map(
            (user) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _LeaderboardRow(user: user),
            ),
          )
          .toList(),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({required this.value, required this.label, required this.color});

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A3623).withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _PointsScreenState._textMuted, letterSpacing: 0.4),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PrivilegeTile extends StatelessWidget {
  const _PrivilegeTile({required this.title, required this.subtitle, required this.icon, required this.unlocked});

  final String title;
  final String subtitle;
  final IconData icon;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final Color iconColor = unlocked ? const Color(0xFF00C853) : const Color(0xFF9E9E9E);

    return Opacity(
      opacity: unlocked ? 1 : 0.7,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border(
            left: BorderSide(color: unlocked ? const Color(0xFF00C853) : const Color(0xFFE0E0E0), width: 4),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4A3623).withOpacity(0.03),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: unlocked ? const Color(0xFFE8F5E9) : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _PointsScreenState._textDark)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _PointsScreenState._textMuted)),
                ],
              ),
            ),
            Icon(unlocked ? Icons.check_circle_rounded : Icons.lock_rounded, color: iconColor),
          ],
        ),
      ),
    );
  }
}

class _PointTaskTile extends StatelessWidget {
  const _PointTaskTile({required this.title, required this.subtitle, required this.icon, required this.reward});

  final String title;
  final String subtitle;
  final IconData icon;
  final String reward;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A3623).withOpacity(0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: const Color(0xFFF8F4F0), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: const Color(0xFF3A2B24), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _PointsScreenState._textDark)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _PointsScreenState._textMuted)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(50)),
            child: Text(
              reward,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF00A63E)),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({required this.user});

  final _LeaderboardUser user;

  @override
  Widget build(BuildContext context) {
    final isCurrent = user.isCurrentUser;

    Widget card = Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: isCurrent ? const Color(0x0DE040FB) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isCurrent ? const Color(0xFFE040FB) : Colors.transparent),
        boxShadow: [
          BoxShadow(
            color: (isCurrent ? const Color(0xFFE040FB) : const Color(0xFF4A3623)).withOpacity(isCurrent ? 0.16 : 0.03),
            blurRadius: isCurrent ? 20 : 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '${user.rank}',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: isCurrent ? const Color(0xFFE040FB) : _PointsScreenState._textMuted),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: Color(0xFFF8F4F0), shape: BoxShape.circle),
            child: Text(user.emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _PointsScreenState._textDark),
                      ),
                    ),
                    if (user.isVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF1E88E5)),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  user.level,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isCurrent ? const Color(0xFFE040FB) : _PointsScreenState._textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            user.points,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFFE040FB)),
          ),
        ],
      ),
    );

    if (isCurrent) {
      card = Transform.scale(scale: 1.02, child: card);
    }

    return card;
  }
}

class _LeaderboardUser {
  const _LeaderboardUser({
    required this.rank,
    required this.name,
    required this.points,
    required this.emoji,
    required this.level,
    this.isCurrentUser = false,
    this.isVerified = false,
  });

  final int rank;
  final String name;
  final String points;
  final String emoji;
  final String level;
  final bool isCurrentUser;
  final bool isVerified;
}
