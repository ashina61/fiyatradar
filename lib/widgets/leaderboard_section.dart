import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../providers/leaderboard_provider.dart';
import '../utils/cities_tr.dart';
import '../utils/trust_tier.dart';

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
          colors: [Color(0xFFFFFCF7), Color(0xFFF8F0E3)],
        ),
        border: Border.all(color: const Color(0xFFE7D4B3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Zirvedekiler', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF3E2A0F))),
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
          color: selected ? const Color(0xFFB8863B) : Colors.white,
          border: Border.all(color: selected ? const Color(0xFFB8863B) : const Color(0xFFD8C7A8)),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: selected ? Colors.white : const Color(0xFF6F5A3C))),
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
          color: selected ? const Color(0xFFF2DFC0) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? const Color(0xFFD8B87D) : const Color(0xFFE7DAC5)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6B4D1E))),
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
    const medals = ['🥇', '🥈', '🥉'];
    return Row(
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final trustTier = trustTierFromScore(item.reliabilityScore);
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index == items.length - 1 ? 0 : 8),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
            constraints: BoxConstraints(minHeight: minHeight),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE4D7C0)),
            ),
            child: Column(
              children: [
                Text(medals[index], style: const TextStyle(fontSize: 22)),
                const SizedBox(height: 10),
                CircleAvatar(
                  radius: 24,
                  backgroundImage: item.photoUrl.isNotEmpty ? NetworkImage(item.photoUrl) : null,
                  child: item.photoUrl.isEmpty ? Text(item.name.isEmpty ? '?' : item.name.substring(0, 1).toUpperCase()) : null,
                ),
                const SizedBox(height: 10),
                Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('+${scoreOf(item)}', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF8A5C19))),
                const SizedBox(height: 8),
                _TierChip(tierLabel: trustTier.label, color: trustTier.color),
              ],
            ),
          ),
        );
      }).toList(),
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
    final trustTier = trustTierFromScore(item.reliabilityScore);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFFFFF3DD) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isMe ? const Color(0xFFE4BC75) : const Color(0xFFE6DAC4)),
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
          _TierChip(tierLabel: trustTier.label, color: trustTier.color),
          const SizedBox(width: 8),
          Text('+$score', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF8A5C19))),
        ],
      ),
    );
  }
}

class _TierChip extends StatelessWidget {
  const _TierChip({required this.tierLabel, required this.color});
  final String tierLabel;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withOpacity(0.12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.diamond_rounded, size: 12, color: color),
          const SizedBox(width: 4),
          Text(tierLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
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
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.75), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE4D8C4))),
      child: const Column(
        children: [
          Icon(Icons.emoji_events_rounded, size: 30, color: Color(0xFFAF7B2F)),
          SizedBox(height: 8),
          Text('Bu hafta puan toplayıp zirveye çık', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF5A3D12))),
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
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.82), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE6D8BC))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Şehrim sıralaması için şehir seçmelisin.', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF5B431A))),
          const SizedBox(height: 10),
          FilledButton.icon(onPressed: onTap, icon: const Icon(Icons.location_city_rounded), label: const Text('Şehir seç')),
        ],
      ),
    );
  }
}
