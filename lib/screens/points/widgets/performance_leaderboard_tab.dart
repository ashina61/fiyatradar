import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../models/leaderboard_item.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/leaderboard_provider.dart';
import 'points_palette.dart';

class PerformanceLeaderboardTab extends ConsumerWidget {
  const PerformanceLeaderboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUid = ref.watch(authStateProvider).valueOrNull?.uid;
    final leaderboard = ref.watch(leaderboardStreamProvider(LeaderboardFilter.global));

    return leaderboard.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Liderlik tablosu yüklenemedi')),
      data: (items) {
        if (items.isEmpty) {
          return const Center(child: Text('Henüz zirve verisi yok'));
        }

        final ranked = items.asMap().entries.map((entry) {
          final item = entry.value;
          return _RankedItem(
            rank: entry.key + 1,
            item: item,
            isCurrentUser: item.uid == authUid,
          );
        }).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 2, 20, 34),
          children: [
            const PrizeBanner(),
            const SizedBox(height: 24),
            LeaderboardPodium(items: ranked.take(3).toList()),
            const SizedBox(height: 20),
            LeaderboardList(items: ranked.skip(3).toList()),
          ],
        );
      },
    );
  }
}

class PrizeBanner extends StatelessWidget {
  const PrizeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final month = toBeginningOfSentenceCase(DateFormat('MMMM', 'tr_TR').format(DateTime.now())) ?? 'Bu Ay';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [PointsPalette.espresso, Color(0xFF302016)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [BoxShadow(color: Color(0x331A120E), blurRadius: 30, offset: Offset(0, 12))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$month Ayı Şampiyonu', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: PointsPalette.camel, letterSpacing: 1)),
                const SizedBox(height: 4),
                const Text('500₺ Market Çeki\nKazanıyor!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, height: 1.25, letterSpacing: -0.4)),
              ],
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0x26B88A5B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x4DB88A5B)),
            ),
            child: const Icon(Icons.redeem_rounded, color: PointsPalette.camel),
          ),
        ],
      ),
    );
  }
}

class LeaderboardPodium extends StatelessWidget {
  const LeaderboardPodium({super.key, required this.items});

  final List<_RankedItem> items;

  @override
  Widget build(BuildContext context) {
    _RankedItem? findRank(int rank) {
      for (final item in items) {
        if (item.rank == rank) return item;
      }
      return null;
    }

    final first = findRank(1);
    final second = findRank(2);
    final third = findRank(3);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (second != null) Expanded(child: _PodiumCard(item: second)),
        if (second != null && first != null && third != null) const SizedBox(width: 8),
        if (first != null) Expanded(flex: 12, child: _PodiumCard(item: first, isFirst: true)),
        if (second != null && first != null && third != null) const SizedBox(width: 8),
        if (third != null) Expanded(child: _PodiumCard(item: third)),
      ],
    );
  }
}

class _PodiumCard extends StatelessWidget {
  const _PodiumCard({required this.item, this.isFirst = false});

  final _RankedItem item;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: isFirst ? 210 : 170,
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: isFirst ? Border.all(color: const Color(0x4DB88A5B), width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: isFirst ? const Color(0x33B88A5B) : const Color(0x0F1A120E),
            blurRadius: isFirst ? 30 : 18,
            offset: Offset(0, isFirst ? 14 : 8),
          ),
        ],
      ),
      child: Column(
        children: [
          if (isFirst)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: PointsPalette.camel, borderRadius: BorderRadius.circular(999)),
              child: const Text('500₺ ÖDÜL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: PointsPalette.espresso)),
            ),
          CircleAvatar(
            radius: isFirst ? 32 : 24,
            backgroundColor: isFirst ? PointsPalette.espresso : PointsPalette.textMuted,
            child: Text(_initials(item.item.name), style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: isFirst ? 18 : 14)),
          ),
          const SizedBox(height: 8),
          Text(item.item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: isFirst ? 14 : 12, fontWeight: FontWeight.w800, color: PointsPalette.textDark)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: item.item.trustScorePercent >= 80 ? PointsPalette.greenBg : PointsPalette.goldBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              item.item.trustScorePercent >= 80 ? '✓ Güvenilir' : '⭐ Altın',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: item.item.trustScorePercent >= 80 ? PointsPalette.green : PointsPalette.camel),
            ),
          ),
          const Spacer(),
          Text('${item.rank}.', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: PointsPalette.textMuted)),
          Text(NumberFormat.decimalPattern('tr_TR').format(item.item.totalPoints), style: TextStyle(fontSize: isFirst ? 20 : 16, fontWeight: FontWeight.w900, color: isFirst ? PointsPalette.espresso : PointsPalette.camel)),
        ],
      ),
    );
  }
}

class LeaderboardList extends StatelessWidget {
  const LeaderboardList({super.key, required this.items});

  final List<_RankedItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [BoxShadow(color: Color(0x0D1A120E), blurRadius: 24, offset: Offset(0, 8))],
      ),
      child: Column(
        children: items.map((item) => _LeaderboardRow(item: item)).toList(),
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({required this.item});

  final _RankedItem item;

  @override
  Widget build(BuildContext context) {
    final trustGood = item.item.trustScorePercent >= 80;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x0D1A120E))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text('${item.rank}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: PointsPalette.textMuted)),
          ),
          Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(left: 8, right: 12),
            decoration: BoxDecoration(color: PointsPalette.espresso, borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: Text(_initials(item.item.name), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: PointsPalette.textDark)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: trustGood ? PointsPalette.greenBg : PointsPalette.goldBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        trustGood ? '✓ Güvenilir' : '⭐ Altın',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: trustGood ? PointsPalette.green : PointsPalette.camel),
                      ),
                    ),
                    if (item.isCurrentUser) ...[
                      const SizedBox(width: 6),
                      const Text('Sen', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: PointsPalette.textMuted)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Text(
            NumberFormat.decimalPattern('tr_TR').format(item.item.totalPoints),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: PointsPalette.textDark),
          ),
        ],
      ),
    );
  }
}

class _RankedItem {
  const _RankedItem({required this.rank, required this.item, required this.isCurrentUser});

  final int rank;
  final UserLeaderboardItem item;
  final bool isCurrentUser;
}

String _initials(String name) {
  final words = name.split(' ').where((e) => e.trim().isNotEmpty).take(2);
  final joined = words.map((w) => w.characters.first.toUpperCase()).join();
  return joined.isEmpty ? 'FR' : joined;
}
