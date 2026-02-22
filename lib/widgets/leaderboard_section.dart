import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/leaderboard_item.dart';
import '../providers/auth_provider.dart';
import '../providers/leaderboard_provider.dart';
import '../utils/cities_tr.dart';
import '../utils/level_style.dart';
import '../utils/theme.dart';
import 'level_badge.dart';

class LeaderboardSection extends ConsumerWidget {
  const LeaderboardSection({
    super.key,
    this.outerPadding = const EdgeInsets.all(20),
    this.headerToContentSpacing = 22,
    this.topThreeMinHeight = 220,
    this.myRankBarHeight = 54,
    this.myRankBarPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  });

  final EdgeInsets outerPadding;
  final double headerToContentSpacing;
  final double topThreeMinHeight;
  final double myRankBarHeight;
  final EdgeInsets myRankBarPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(leaderboardFilterProvider);
    final period = ref.watch(leaderboardPeriodProvider);
    final leaderboardAsync = ref.watch(leaderboardStreamProvider(filter));
    final currentUser = ref.watch(authStateProvider).valueOrNull;
    final userModel = ref.watch(userModelStreamProvider).valueOrNull;
    final hasCity = (userModel?.city ?? userModel?.cityName ?? '').trim().isNotEmpty;

    int score(UserLeaderboardItem item) => period == LeaderboardPeriod.week ? item.weeklyPoints : item.monthlyPoints;

    return Container(
      padding: outerPadding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: AppColors.surface,
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
          const Text(
            'Zirvedekiler',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 14),
          // Filters
          Row(
            children: [
              _SegmentButton(
                label: 'Turkiye',
                selected: filter == LeaderboardFilter.global,
                onTap: () => ref.read(leaderboardFilterProvider.notifier).state = LeaderboardFilter.global,
              ),
              const SizedBox(width: 8),
              _SegmentButton(
                label: 'Sehrim',
                selected: filter == LeaderboardFilter.city,
                onTap: () => ref.read(leaderboardFilterProvider.notifier).state = LeaderboardFilter.city,
              ),
              const Spacer(),
              _MiniToggle(
                label: 'Bu Hafta',
                selected: period == LeaderboardPeriod.week,
                onTap: () => ref.read(leaderboardPeriodProvider.notifier).state = LeaderboardPeriod.week,
              ),
              const SizedBox(width: 6),
              _MiniToggle(
                label: 'Bu Ay',
                selected: period == LeaderboardPeriod.month,
                onTap: () => ref.read(leaderboardPeriodProvider.notifier).state = LeaderboardPeriod.month,
              ),
            ],
          ),
          SizedBox(height: headerToContentSpacing),
          leaderboardAsync.when(
            data: (items) {
              if (filter == LeaderboardFilter.city && !hasCity) {
                return _CityCtaCard(onTap: () async {
                  final selected = await showModalBottomSheet<CityTR>(
                    context: context,
                    showDragHandle: true,
                    builder: (_) => ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        const Text('Sehir sec', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        ...kCitiesTR.map(
                          (city) => ListTile(
                            title: Text(city.name),
                            onTap: () => Navigator.pop(context, city),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (selected == null || currentUser == null) return;
                  await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).set({
                    'cityCode': selected.code,
                    'cityName': selected.name,
                    'city': selected.name,
                  }, SetOptions(merge: true));
                });
              }

              if (items.isEmpty) {
                return const _EmptyLeaderboard();
              }

              final topThree = items.take(3).toList();
              final rows = items.skip(3).take(7).toList();
              final currentUid = currentUser?.uid;
              final myIndex = currentUid == null ? -1 : items.indexWhere((e) => e.uid == currentUid);
              final myItem = myIndex >= 0 ? items[myIndex] : null;

              return Column(
                children: [
                  if (topThree.isNotEmpty) _TopThreeRow(items: topThree, minHeight: topThreeMinHeight, scoreOf: score),
                  if (rows.isNotEmpty) const SizedBox(height: 16),
                  if (rows.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.outline.withOpacity(0.5)),
                      ),
                      child: Column(
                        children: rows.asMap().entries.map((entry) {
                          final rank = entry.key + 4;
                          final item = entry.value;
                          return Padding(
                            padding: EdgeInsets.only(bottom: entry.key == rows.length - 1 ? 0 : 8),
                            child: _LeaderboardRow(rank: rank, item: item, isMe: item.uid == currentUid, score: score(item)),
                          );
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: 14),
                  _MyRankCard(
                    filter: filter,
                    rank: myIndex >= 0 ? myIndex + 1 : null,
                    item: myItem,
                    scoreLabel: myItem == null ? null : '${score(myItem)} puan',
                    height: myRankBarHeight,
                    padding: myRankBarPadding,
                  ),
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
            ),
            error: (_, __) => const Text('Liderlik tablosu yuklenirken bir hata olustu.'),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: selected ? AppColors.primary : AppColors.surfaceVariant,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.outline,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _MiniToggle extends StatelessWidget {
  const _MiniToggle({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary.withOpacity(0.3) : AppColors.outline,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.primary : AppColors.textTertiary,
          ),
        ),
      ),
    );
  }
}

class _TopThreeRow extends StatelessWidget {
  const _TopThreeRow({required this.items, required this.minHeight, required this.scoreOf});
  final List<UserLeaderboardItem> items;
  final double minHeight;
  final int Function(UserLeaderboardItem) scoreOf;

  @override
  Widget build(BuildContext context) {
    final first = items.length > 0 ? items[0] : null;
    final second = items.length > 1 ? items[1] : null;
    final third = items.length > 2 ? items[2] : null;

    return SizedBox(
      height: minHeight + 48,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: second == null ? const SizedBox.shrink() : _PodiumCard(rank: 2, item: second, score: scoreOf(second), compact: true)),
          const SizedBox(width: 8),
          Expanded(child: first == null ? const SizedBox.shrink() : _PodiumCard(rank: 1, item: first, score: scoreOf(first), compact: false)),
          const SizedBox(width: 8),
          Expanded(child: third == null ? const SizedBox.shrink() : _PodiumCard(rank: 3, item: third, score: scoreOf(third), compact: true)),
        ],
      ),
    );
  }
}

class _PodiumCard extends StatelessWidget {
  const _PodiumCard({required this.rank, required this.item, required this.score, required this.compact});

  final int rank;
  final UserLeaderboardItem item;
  final int score;
  final bool compact;

  Color _rankColor() {
    switch (rank) {
      case 1:
        return const Color(0xFFD4A530);
      case 2:
        return const Color(0xFF8E9AAF);
      case 3:
        return const Color(0xFFB87333);
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final level = LevelStyle.fromFinalLevel(totalPoints: item.totalPoints, trustPercent: item.trustScorePercent, totalVotes: item.trustTotalVotes);
    final rankCol = _rankColor();

    return Container(
      margin: EdgeInsets.only(bottom: compact ? 0 : 22),
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12, vertical: compact ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outline.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Rank badge
          Container(
            width: compact ? 28 : 34,
            height: compact ? 28 : 34,
            decoration: BoxDecoration(
              color: rankCol.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: TextStyle(
                  fontSize: compact ? 12 : 14,
                  fontWeight: FontWeight.w900,
                  color: rankCol,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          CircleAvatar(
            radius: compact ? 20 : 28,
            backgroundColor: AppColors.surfaceVariant,
            backgroundImage: item.photoUrl.isNotEmpty ? NetworkImage(item.photoUrl) : null,
            child: item.photoUrl.isEmpty
                ? Text(
                    item.name.isEmpty ? '?' : item.name.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                      fontSize: compact ? 14 : 18,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '+$score',
              style: TextStyle(
                fontSize: compact ? 14 : 18,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${item.totalPoints} toplam',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              LevelBadge(level: level, compact: true, withEmoji: false, uppercase: false),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.outline.withOpacity(0.6)),
                ),
                child: Text(
                  'Trust %${item.trustScorePercent}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({required this.rank, required this.item, required this.isMe, required this.score});

  final int rank;
  final UserLeaderboardItem item;
  final bool isMe;
  final int score;

  @override
  Widget build(BuildContext context) {
    final level = LevelStyle.fromFinalLevel(totalPoints: item.totalPoints, trustPercent: item.trustScorePercent, totalVotes: item.trustTotalVotes);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? AppColors.primary.withOpacity(0.06) : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMe ? AppColors.primary.withOpacity(0.2) : AppColors.outline.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              rank.toString().padLeft(2, '0'),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.textTertiary,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.surfaceVariant,
            backgroundImage: item.photoUrl.isNotEmpty ? NetworkImage(item.photoUrl) : null,
            child: item.photoUrl.isEmpty
                ? Text(
                    item.name.isEmpty ? '?' : item.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
          Flexible(
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 6,
              runSpacing: 4,
              children: [
                LevelBadge(level: level, compact: true, withEmoji: false, uppercase: false),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.outline.withOpacity(0.6)),
                  ),
                  child: Text(
                    'T %${item.trustScorePercent}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '+$score',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _MyRankCard extends StatelessWidget {
  const _MyRankCard({required this.filter, required this.rank, required this.item, required this.scoreLabel, required this.height, required this.padding});

  final LeaderboardFilter filter;
  final int? rank;
  final UserLeaderboardItem? item;
  final String? scoreLabel;
  final double height;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final isTop = rank != null && item != null;
    return Container(
      width: double.infinity,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF5A3E1B),
            Color(0xFF3D2914),
          ],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              isTop ? 'Sen - #$rank' : filter == LeaderboardFilter.city ? 'Sen - Sehrimde ilk 50 disi' : 'Sen - Ilk 50 disi',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
          if (isTop) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                scoreLabel ?? '',
                style: const TextStyle(
                  color: Color(0xFFFFD793),
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              item!.cityName.isEmpty ? 'Sehir yok' : item!.cityName,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyLeaderboard extends StatelessWidget {
  const _EmptyLeaderboard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline.withOpacity(0.5)),
      ),
      child: const Column(
        children: [
          Icon(Icons.emoji_events_rounded, size: 32, color: AppColors.primary),
          SizedBox(height: 10),
          Text(
            'Bu hafta puan toplayip zirveye cik',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _CityCtaCard extends StatelessWidget {
  const _CityCtaCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sehrim siralamasi icin sehir secmelisin.',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.location_city_rounded),
            label: const Text('Sehir sec'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
