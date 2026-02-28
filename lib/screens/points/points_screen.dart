import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/leaderboard_item.dart';
import '../../providers/auth_provider.dart';
import '../../providers/leaderboard_provider.dart';
import '../../utils/elite_level_engine.dart';
import '../../widgets/premium_level_badge.dart';
import 'controllers/points_controller.dart';
import 'models/points_models.dart';
import 'widgets/radar_kingdom_leaderboard_view.dart';

class PointsScreen extends ConsumerStatefulWidget {
  const PointsScreen({super.key});

  @override
  ConsumerState<PointsScreen> createState() => _PointsScreenState();
}

class _PointsScreenState extends ConsumerState<PointsScreen> {
  static const Color _bgCream = Color(0xFFFDFBF9);
  static const Color _textDark = Color(0xFF3A2B24);
  static const Color _textMuted = Color(0xFF8C7A6B);
  static const Color _borderLight = Color(0xFFEBE1D7);

  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFFAF6B3E),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Puanlar',
              style: TextStyle(
                color: Color(0xFF3A2B24),
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
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
    final pointsAsync = ref.watch(pointsStateProvider);
    return pointsAsync.when(
      data: (state) => SingleChildScrollView(
        key: const ValueKey('overview'),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(state),
            const SizedBox(height: 14),
            _buildStatsGrid(state),
            const SizedBox(height: 16),
            _buildSectionTitle('Seviye Ayrıcalıkları'),
            const SizedBox(height: 8),
            _buildPrivilegesList(state),
            const SizedBox(height: 16),
            _buildSectionTitle('Puan Kazan'),
            const SizedBox(height: 8),
            _buildPointTasks(state),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Puan verisi yüklenemedi')),
    );
  }

  Widget _buildStatusCard(PointsState state) {
    final trustProgress = state.requiredMinTrust == 0 ? 1.0 : (state.trustScore / state.requiredMinTrust).clamp(0, 1).toDouble();
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
              PremiumLevelBadge(levelName: state.currentLevelName),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Toplam Puan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textMuted)),
                  const SizedBox(height: 2),
                  Text(_formatFullPoints(state.totalPoints), style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: _textDark, letterSpacing: -0.6)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildProgressSection(
            title: 'Seviye İlerlemesi',
            limit: '${_formatFullPoints(state.totalPoints)} / ${_formatFullPoints(state.nextLevelTargetPoints)}',
            fillColor: const Color(0xFF8B7365),
            progress: state.levelProgressPercent.clamp(0, 1),
            description: 'Sonraki seviyeye +${_formatFullPoints(state.pointsRemainingToNextLevel)} Puan',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: _borderLight, width: 1.5),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                'SONRAKİ SEVİYE: ${state.nextLevelName.toUpperCase()}',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: _textMuted, letterSpacing: 0.4),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildProgressSection(
            title: 'Güven Skoru',
            limit: '%${state.trustScore} / Min %${state.requiredMinTrust}',
            fillColor: state.isTrustGated ? const Color(0xFFD32F2F) : const Color(0xFF00A63E),
            progress: trustProgress,
            description: state.isTrustGated
                ? 'Sonraki seviye için minimum güven şartı sağlanmalı'
                : 'Güven şartı sağlandı',
            danger: state.isTrustGated,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: state.isTrustGated ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9),
                border: Border.all(color: state.isTrustGated ? const Color(0xFFFFCDD2) : const Color(0xFFC8E6C9), width: 1.5),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                state.isTrustGated ? 'GATED' : 'OK',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: state.isTrustGated ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32), letterSpacing: 0.5),
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

  Widget _buildStatsGrid(PointsState state) {
    return Row(
      children: [
        Expanded(child: _MiniStatCard(value: '+${state.pointsThisWeek}', label: 'Bu Hafta', color: const Color(0xFF00C853))),
        const SizedBox(width: 12),
        Expanded(child: _MiniStatCard(value: '${state.trustTotalVotes}', label: 'Onaylı Fiyat', color: _textDark)),
        const SizedBox(width: 12),
        Expanded(child: _MiniStatCard(value: '${state.streakDays}', label: 'Seri Gün', color: const Color(0xFFFFB300))),
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

  Widget _buildPrivilegesList(PointsState state) {
    final currentLevel = EliteLevelEngine.parseLevelLabel(state.currentLevelName);
    final currentOrder = currentLevel.index;

    bool unlocked(EliteLevel level) => currentOrder >= level.index;

    return Column(
      children: [
        _PrivilegeTile(
          title: 'Temel Fiyat Bildirimi',
          subtitle: unlocked(EliteLevel.gozlemci) ? '${state.currentLevelName} (Mevcut Seviye)' : 'Gözlemci Olunca Açılır',
          icon: Icons.sell_rounded,
          unlocked: unlocked(EliteLevel.gozlemci),
        ),
        const SizedBox(height: 8),
        _PrivilegeTile(
          title: 'Özel Favori Market Alarmları',
          subtitle: unlocked(EliteLevel.marketUstasi) ? '${state.currentLevelName} ile açık' : 'Market Ustası Olunca Açılır',
          icon: Icons.notifications_active_rounded,
          unlocked: unlocked(EliteLevel.marketUstasi),
        ),
        const SizedBox(height: 8),
        _PrivilegeTile(
          title: 'Sınırsız Geçmiş Fiyat Analizi',
          subtitle: unlocked(EliteLevel.radarEfsanesi) ? '${state.currentLevelName} ile açık' : 'Radar Efsanesi Olunca Açılır',
          icon: Icons.history_rounded,
          unlocked: unlocked(EliteLevel.radarEfsanesi),
        ),
      ],
    );
  }

  Widget _buildPointTasks(PointsState state) {
    final goals = state.dailyGoals;
    return Column(
      children: goals
          .map(
            (goal) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PointTaskTile(
                title: goal.title,
                subtitle: '${goal.current}/${goal.target} Tamamlandı',
                icon: goal.icon,
                reward: '+${goal.reward} P',
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildLeaderboardTab() {
    return const RadarKingdomLeaderboardView();
  }

  Widget _buildLeaderboardTabLegacy() {
    final leaderboardAsync = ref.watch(leaderboardStreamProvider(LeaderboardFilter.global));
    final authUid = ref.watch(authStateProvider).valueOrNull?.uid;

    return leaderboardAsync.when(
      data: (items) {
        final users = items
            .asMap()
            .entries
            .map((entry) => _LeaderboardUser.fromItem(entry.key + 1, entry.value, isCurrentUser: entry.value.uid == authUid))
            .toList();
        final podiumUsers = users.where((u) => u.rank <= 3).toList()..sort((a, b) => a.rank.compareTo(b.rank));
        final otherUsers = users.where((u) => u.rank > 3).toList();

        return SingleChildScrollView(
          key: const ValueKey('leaderboard'),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPodium(podiumUsers),
              const SizedBox(height: 10),
              _buildLeaderboard(otherUsers),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Liderlik tablosu yüklenemedi')),
    );
  }

  Widget _buildPodium(List<_LeaderboardUser> users) {
    if (users.isEmpty) {
      return const SizedBox.shrink();
    }

    _LeaderboardUser? rank1;
    _LeaderboardUser? rank2;
    _LeaderboardUser? rank3;
    for (final user in users) {
      if (user.rank == 1) rank1 = user;
      if (user.rank == 2) rank2 = user;
      if (user.rank == 3) rank3 = user;
    }

    final ordered = [if (rank2 != null) rank2, if (rank1 != null) rank1, if (rank3 != null) rank3].whereType<_LeaderboardUser>().toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 18, 8, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _borderLight, style: BorderStyle.solid)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: ordered.map(_buildPodiumSlot).toList(),
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
          if (isFirst) const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFC107), size: 30),
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
                child: Text(user.avatar, style: TextStyle(fontSize: isFirst ? 30 : 22, fontWeight: FontWeight.w900)),
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
              Flexible(
                child: Text(
                  user.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: isFirst ? 15 : 13,
                    color: isFirst ? const Color(0xFFFFC107) : _textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(user.points, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _textMuted)),
        ],
      ),
    );
  }

  Widget _buildLeaderboard(List<_LeaderboardUser> users) {
    return Column(
      children: users
          .map(
            (user) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _LeaderboardRow(user: user),
            ),
          )
          .toList(),
    );
  }

  String _formatFullPoints(int points) => points.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.');
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
    final iconColor = unlocked ? const Color(0xFF00A63E) : const Color(0xFFB0A297);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: unlocked ? const Color(0xFFDCEDC8) : const Color(0xFFF1E8DE)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: unlocked ? const Color(0xFFE8F5E9) : const Color(0xFFF7F2ED),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
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
            child: Text(user.avatar, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _PointsScreenState._textDark),
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
    required this.avatar,
    required this.level,
    this.isCurrentUser = false,
  });

  factory _LeaderboardUser.fromItem(int rank, UserLeaderboardItem item, {required bool isCurrentUser}) {
    final finalLevel = EliteLevelEngine.getFinalLevel(item.totalPoints, item.trustScorePercent, item.trustTotalVotes);
    final levelName = EliteLevelEngine.getLevelStyle(finalLevel).label;
    return _LeaderboardUser(
      rank: rank,
      name: item.name,
      points: _shortPoints(item.weeklyPoints),
      avatar: _avatarText(item.name),
      level: isCurrentUser ? '$levelName (Sen)' : levelName,
      isCurrentUser: isCurrentUser,
    );
  }

  final int rank;
  final String name;
  final String points;
  final String avatar;
  final String level;
  final bool isCurrentUser;

  static String _shortPoints(int value) {
    if (value >= 1000) {
      final v = (value / 1000).toStringAsFixed(1);
      return '${v.replaceAll('.0', '')}K';
    }
    return '$value';
  }

  static String _avatarText(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
  }
}
