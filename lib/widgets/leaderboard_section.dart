import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../providers/leaderboard_provider.dart';

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
    final leaderboardAsync = ref.watch(leaderboardStreamProvider(filter));
    final currentUser = ref.watch(authStateProvider).valueOrNull;

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
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Zirvedekiler',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF3E2A0F)),
                ),
              ),
              _FilterChip(
                label: 'Türkiye',
                selected: filter == LeaderboardFilter.global,
                onTap: () => ref.read(leaderboardFilterProvider.notifier).state = LeaderboardFilter.global,
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Şehrim',
                selected: filter == LeaderboardFilter.city,
                onTap: () => ref.read(leaderboardFilterProvider.notifier).state = LeaderboardFilter.city,
              ),
            ],
          ),
          SizedBox(height: headerToContentSpacing),
          leaderboardAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return _EmptyLeaderboard(isCityFilter: filter == LeaderboardFilter.city);
              }

              final topThree = items.take(3).toList();
              final rows = items.skip(3).take(7).toList();
              final currentUid = currentUser?.uid;
              final myIndex = currentUid == null ? -1 : items.indexWhere((e) => e.uid == currentUid);
              final myItem = myIndex >= 0 ? items[myIndex] : null;

              return Column(
                children: [
                  if (topThree.isNotEmpty) _TopThreeRow(items: topThree, minHeight: topThreeMinHeight),
                  if (rows.isNotEmpty) const SizedBox(height: 14),
                  ...rows.asMap().entries.map((entry) {
                    final index = entry.key + 4;
                    final item = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _LeaderboardRow(rank: index, item: item, isMe: item.uid == currentUid),
                    );
                  }),
                  const SizedBox(height: 14),
                  _MyRankCard(
                    filter: filter,
                    rank: myIndex >= 0 ? myIndex + 1 : null,
                    item: myItem,
                    height: myRankBarHeight,
                    padding: myRankBarPadding,
                  ),
                  const SizedBox(height: 16),
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: selected ? const Color(0xFF2E7DFF) : Colors.white,
          border: Border.all(color: selected ? const Color(0xFF2E7DFF) : const Color(0xFFD8C7A8)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : const Color(0xFF6F5A3C),
          ),
        ),
      ),
    );
  }
}

class _TopThreeRow extends StatelessWidget {
  const _TopThreeRow({required this.items, required this.minHeight});

  final List<UserLeaderboardItem> items;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final medals = ['🥇', '🥈', '🥉'];
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
                  radius: 20,
                  backgroundImage: item.photoUrl.isNotEmpty ? NetworkImage(item.photoUrl) : null,
                  child: item.photoUrl.isEmpty ? Text(item.name.isEmpty ? '?' : item.name.substring(0, 1).toUpperCase()) : null,
                ),
                const SizedBox(height: 10),
                Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('+${item.weeklyPoints}', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF8A5C19))),
                const SizedBox(height: 8),
                _ReliabilityBadge(item: item),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({required this.rank, required this.item, required this.isMe});

  final int rank;
  final UserLeaderboardItem item;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFFFFF3DD) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isMe ? const Color(0xFFE4BC75) : const Color(0xFFE6DAC4)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(rank.toString().padLeft(2, '0'), style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF7E6140))),
          ),
          Expanded(
            child: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          _ReliabilityBadge(item: item),
          const SizedBox(width: 10),
          Text('+${item.weeklyPoints}', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF8A5C19))),
        ],
      ),
    );
  }
}

class _ReliabilityBadge extends StatelessWidget {
  const _ReliabilityBadge({required this.item});

  final UserLeaderboardItem item;

  @override
  Widget build(BuildContext context) {
    final score = item.reliabilityScore.clamp(0, 100);
    final icon = switch (score) {
      <= 19 => '○',
      <= 39 => '🥉',
      <= 59 => '🥈',
      <= 79 => '🥇',
      _ => '💎',
    };

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () {
        showModalBottomSheet<void>(
          context: context,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (_) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Güvenirlik: %$score', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                const Text('Bu skor kullanıcının fiyat katkılarının doğrulanma oranına göre hesaplanır.'),
              ],
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: const Color(0xFFF6EFE2),
        ),
        child: Text(icon),
      ),
    );
  }
}

class _MyRankCard extends StatelessWidget {
  const _MyRankCard({
    required this.filter,
    required this.rank,
    required this.item,
    required this.height,
    required this.padding,
  });

  final LeaderboardFilter filter;
  final int? rank;
  final UserLeaderboardItem? item;
  final double height;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final isTop50 = rank != null && item != null;
    return Container(
      width: double.infinity,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFF1D2A38),
      ),
      child: Text(
        isTop50
            ? 'Sen: #$rank • ${item!.weeklyPoints} puan • Şehir: ${item!.cityName.isEmpty ? 'Belirtilmemiş' : item!.cityName}'
            : filter == LeaderboardFilter.city
                ? 'Sen: İlk 50\'de değilsin (Şehrim)'
                : 'Sen: İlk 50\'de değilsin',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, height: 1.25),
      ),
    );
  }
}

class _EmptyLeaderboard extends StatelessWidget {
  const _EmptyLeaderboard({required this.isCityFilter});

  final bool isCityFilter;

  @override
  Widget build(BuildContext context) {
    if (isCityFilter) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Text('Bu şehirde henüz lider yok. İlk sen ol!', style: TextStyle(fontWeight: FontWeight.w700)),
      );
    }

    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Text('Liderlik tablosu hazırlanıyor...'),
    );
  }
}
