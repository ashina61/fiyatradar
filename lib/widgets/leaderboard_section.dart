import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/leaderboard_item.dart';
import '../providers/auth_provider.dart';
import '../providers/leaderboard_provider.dart';
import '../utils/cities_tr.dart';
import '../utils/level_style.dart';
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
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF7FAFF), Color(0xFFEEF4FF)],
        ),
        border: Border.all(color: const Color(0xFFD4E2F8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Zirvedekiler', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1E3A5F))),
          const SizedBox(height: 12),
          Row(
            children: [
              _SegmentButton(
                label: 'Türkiye',
                selected: filter == LeaderboardFilter.global,
                onTap: () => ref.read(leaderboardFilterProvider.notifier).state = LeaderboardFilter.global,
              ),
              const SizedBox(width: 8),
              _SegmentButton(
                label: 'Şehrim',
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
                        const Text('Şehir seç', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
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
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE7D7BC)),
                    ),
                    child: Column(
                      children: rows.asMap().entries.map((entry) {
                        final rank = entry.key + 4;
                        final item = entry.value;
                        return Padding(
                          padding: EdgeInsets.only(bottom: entry.key == rows.length - 1 ? 0 : 10),
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
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, __) => const Text('Liderlik tablosu yüklenirken bir hata oluştu.'),
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
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: selected ? const Color(0xFF2563EB) : Colors.white,
          border: Border.all(color: selected ? const Color(0xFF2563EB) : const Color(0xFFD5E2F7)),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: selected ? Colors.white : const Color(0xFF355070))),
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
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE8F0FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? const Color(0xFFAEC8F4) : const Color(0xFFDCE7F8)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF2C4F7A))),
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

  @override
  Widget build(BuildContext context) {
    final level = LevelStyle.fromFinalLevel(totalPoints: item.totalPoints, trustPercent: item.trustScorePercent, totalVotes: item.trustTotalVotes);
    return Container(
      margin: EdgeInsets.only(bottom: compact ? 0 : 22),
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD9E6F8)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('#$rank', style: TextStyle(fontSize: compact ? 16 : 20, fontWeight: FontWeight.w900, color: const Color(0xFF2D5B8F))),
          const SizedBox(height: 8),
          CircleAvatar(
            radius: compact ? 20 : 26,
            backgroundImage: item.photoUrl.isNotEmpty ? NetworkImage(item.photoUrl) : null,
            child: item.photoUrl.isEmpty ? Text(item.name.isEmpty ? '?' : item.name.substring(0, 1).toUpperCase()) : null,
          ),
          const SizedBox(height: 8),
          Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('+$score puan', style: TextStyle(fontSize: compact ? 14 : 18, fontWeight: FontWeight.w900, color: const Color(0xFF2D5B8F))),
          const SizedBox(height: 2),
          Text('${item.totalPoints} toplam', style: const TextStyle(fontSize: 12, color: Color(0xFF6F5A3C), fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          LevelBadge(level: level, compact: true),
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
        color: isMe ? const Color(0xFFEFF6FF) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isMe ? const Color(0xFF9FC2F6) : const Color(0xFFDCE7F8)),
      ),
      child: Row(
        children: [
          SizedBox(width: 34, child: Text(rank.toString().padLeft(2, '0'), style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF7E6140)))),
          CircleAvatar(
            radius: 14,
            backgroundImage: item.photoUrl.isNotEmpty ? NetworkImage(item.photoUrl) : null,
            child: item.photoUrl.isEmpty ? Text(item.name.isEmpty ? '?' : item.name.substring(0, 1).toUpperCase(), style: const TextStyle(fontSize: 11)) : null,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700))),
          LevelBadge(level: level, compact: true),
          const SizedBox(width: 8),
          Text('+$score', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF8A5C19))),
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
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: const Color(0xFF1D2A38)),
      child: Row(
        children: [
          Expanded(
            child: Text(
              isTop ? 'Sen • #$rank' : filter == LeaderboardFilter.city ? 'Sen • Şehrimde ilk 50 dışı' : 'Sen • İlk 50 dışı',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
          if (isTop) ...[
            Text(scoreLabel ?? '', style: const TextStyle(color: Color(0xFFFFD793), fontWeight: FontWeight.w800)),
            const SizedBox(width: 10),
            Text(item!.cityName.isEmpty ? 'Şehir yok' : item!.cityName, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
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
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.75), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFDCE7F8))),
      child: const Column(
        children: [
          Icon(Icons.emoji_events_rounded, size: 30, color: Color(0xFF2F67A5)),
          SizedBox(height: 8),
          Text('Bu hafta puan toplayıp zirveye çık', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF20456E))),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.82), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFDCE7F8))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Şehrim sıralaması için şehir seçmelisin.', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF2A4E78))),
          const SizedBox(height: 10),
          FilledButton.icon(onPressed: onTap, icon: const Icon(Icons.location_city_rounded), label: const Text('Şehir seç')),
        ],
      ),
    );
  }
}
