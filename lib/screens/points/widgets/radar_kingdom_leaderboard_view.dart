import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../models/leaderboard_item.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/leaderboard_provider.dart';

class RadarKingdomLeaderboardView extends ConsumerStatefulWidget {
  const RadarKingdomLeaderboardView({super.key});

  @override
  ConsumerState<RadarKingdomLeaderboardView> createState() => _RadarKingdomLeaderboardViewState();
}

class _RadarKingdomLeaderboardViewState extends ConsumerState<RadarKingdomLeaderboardView> {
  static const _bgApp = Color(0xFFFDFBF9);
  static const _textDark = Color(0xFF3A2B24);
  static const _textMuted = Color(0xFF8C7A6B);

  String get _dynamicMonth => toBeginningOfSentenceCase(DateFormat('MMMM', 'tr_TR').format(DateTime.now())) ?? 'Ay';

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(leaderboardFilterProvider);
    final authUid = ref.watch(authStateProvider).valueOrNull?.uid;
    final leaderboardAsync = ref.watch(leaderboardStreamProvider(filter));

    return Container(
      color: const Color(0xFFEFE9E2),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              color: _bgApp,
              child: leaderboardAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Center(child: Text('Liderlik tablosu yüklenemedi')),
                data: (items) {
                  final ranked = items.asMap().entries.map((e) => _RankedUser(rank: e.key + 1, item: e.value, isCurrentUser: e.value.uid == authUid)).toList();
                  final top3 = ranked.where((e) => e.rank <= 3).toList();
                  final others = ranked.where((e) => e.rank > 3).toList();

                  return ListView(
                    padding: const EdgeInsets.only(top: 20, bottom: 30),
                    children: [
                      const Center(
                        child: Text(
                          'Puan Sistemi',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _textDark, letterSpacing: 0.5),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(25, 20, 25, 20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Radar Krallığı', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: _textDark, letterSpacing: -1)),
                                  SizedBox(height: 2),
                                  Text('Rekabet kızışıyor, tahtını al!', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _textMuted)),
                                ],
                              ),
                            ),
                            InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: _showInfoBottomSheet,
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(color: const Color(0xFFF0EBE6), borderRadius: BorderRadius.circular(12)),
                                child: const Icon(Icons.info_outline, size: 20, color: _textMuted),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(25, 0, 25, 20),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0EBE6),
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(color: Colors.white.withOpacity(0.8)),
                          ),
                          child: Row(
                            children: [
                              _ScopeButton(text: 'Türkiye Geneli', icon: Icons.public_rounded, selected: filter == LeaderboardFilter.global, onTap: () => ref.read(leaderboardFilterProvider.notifier).state = LeaderboardFilter.global),
                              _ScopeButton(text: 'Mahallem', icon: Icons.location_on_rounded, selected: filter == LeaderboardFilter.city, onTap: () => ref.read(leaderboardFilterProvider.notifier).state = LeaderboardFilter.city),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(25, 0, 25, 25),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFFFFD54F), Color(0xFFFFB300)]),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: const Color(0xFFFFB300).withOpacity(0.25), blurRadius: 25, offset: const Offset(0, 10))],
                          ),
                          child: Row(
                            children: [
                              const Text('🏆', style: TextStyle(fontSize: 32)),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text('$_dynamicMonth Ayı Şampiyonuna', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xCC4E342E))),
                                  const SizedBox(height: 2),
                                  RichText(
                                    text: const TextSpan(
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF4E342E)),
                                      children: [
                                        TextSpan(text: 'Tam '),
                                        WidgetSpan(
                                          alignment: PlaceholderAlignment.middle,
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(color: Color(0x4DFFFFFF), borderRadius: BorderRadius.all(Radius.circular(6))),
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(horizontal: 6),
                                              child: Text('500₺', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFFD84315))),
                                            ),
                                          ),
                                        ),
                                        TextSpan(text: ' Market Çeki!'),
                                      ],
                                    ),
                                  ),
                                ]),
                              ),
                              const Icon(Icons.chevron_right_rounded, color: Color(0x804E342E)),
                            ],
                          ),
                        ),
                      ),
                      _PodiumSection(users: top3),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(25, 0, 25, 0),
                        child: Column(
                          children: others
                              .take(20)
                              .map(
                                (u) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _LeaderRow(user: u),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showInfoBottomSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
          decoration: const BoxDecoration(
            color: Color(0xFFFDFBF9),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: SizedBox(
                  width: 48,
                  child: Divider(thickness: 4, color: Color(0xFFD1C4B9)),
                ),
              ),
              SizedBox(height: 12),
              Text('Radar Krallığı Nasıl Çalışır?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _textDark)),
              SizedBox(height: 16),
              Text('Barkod okutarak (+10 Puan), Yeni fiyat ekleyerek (+50 Puan), İndirim yakalayarak (+100 Puan).', style: TextStyle(fontSize: 15, height: 1.45, fontWeight: FontWeight.w700, color: _textMuted)),
              SizedBox(height: 14),
              Text('Güven skoru %70 altı olanlar podyuma çıkamaz!', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFFAF6B3E))),
            ],
          ),
        );
      },
    );
  }
}

class _ScopeButton extends StatelessWidget {
  const _ScopeButton({required this.text, required this.icon, required this.selected, required this.onTap});

  static const _textMuted = Color(0xFF8C7A6B);

  final String text;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            gradient: selected ? const LinearGradient(colors: [Color(0xFFAF6B3E), Color(0xFF8B4D22)]) : null,
            boxShadow: selected ? [BoxShadow(color: const Color(0xFFAF6B3E).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 6))] : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: selected ? Colors.white : _textMuted),
              const SizedBox(width: 6),
              Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: selected ? Colors.white : _textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PodiumSection extends StatelessWidget {
  const _PodiumSection({required this.users});

  final List<_RankedUser> users;

  @override
  Widget build(BuildContext context) {
    _RankedUser? rank(int n) {
      for (final user in users) {
        if (user.rank == n) return user;
      }
      return null;
    }

    final rank2 = rank(2);
    final rank1 = rank(1);
    final rank3 = rank(3);

    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      padding: const EdgeInsets.fromLTRB(25, 10, 25, 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white.withOpacity(0), const Color(0x0DAF6B3E)]),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (rank2 != null) _PodiumSlot(user: rank2),
          if (rank1 != null) _PodiumSlot(user: rank1, isFirst: true),
          if (rank3 != null) _PodiumSlot(user: rank3),
        ],
      ),
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  const _PodiumSlot({required this.user, this.isFirst = false});

  final _RankedUser user;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    final medalColor = user.rank == 1 ? const Color(0xFFFFC107) : user.rank == 2 ? const Color(0xFFB0BEC5) : const Color(0xFFCD7F32);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7.5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              if (isFirst)
                const Positioned(top: -30, child: Icon(Icons.workspace_premium_rounded, size: 36, color: Color(0xFFFFC107))),
              Container(
                width: isFirst ? 90 : 65,
                height: isFirst ? 90 : 65,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: medalColor, width: 4),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: Text(user.avatar, style: TextStyle(fontSize: isFirst ? 40 : 30)),
              ),
              Positioned(
                bottom: isFirst ? -12 : -10,
                child: Container(
                  width: isFirst ? 28 : 24,
                  height: isFirst ? 28 : 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: medalColor, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)),
                  child: Text('${user.rank}', style: TextStyle(fontSize: isFirst ? 14 : 12, color: isFirst ? const Color(0xFF4E342E) : Colors.white, fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(user.item.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF3A2B24))),
          Text(_formatPoints(user.item.monthlyPoints), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF8C7A6B))),
        ],
      ),
    );
  }
}

class _LeaderRow extends StatelessWidget {
  const _LeaderRow({required this.user});

  final _RankedUser user;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: user.isCurrentUser ? const Color(0xFFFFF9F5) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: user.isCurrentUser ? const Color(0xFFAF6B3E) : const Color(0x80EBE1D7), width: user.isCurrentUser ? 2 : 1),
        boxShadow: [
          BoxShadow(color: (user.isCurrentUser ? const Color(0xFFAF6B3E) : const Color(0xFF4A3623)).withOpacity(user.isCurrentUser ? 0.12 : 0.04), blurRadius: user.isCurrentUser ? 25 : 15, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Text('${user.rank}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: user.isCurrentUser ? const Color(0xFFAF6B3E) : const Color(0xFFD1C4B9))),
          const SizedBox(width: 16),
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: Color(0xFFF8F5F1), shape: BoxShape.circle),
            child: Text(user.avatar, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.isCurrentUser ? '${user.item.name} (Sen)' : user.item.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF3A2B24))),
                Text(user.levelName, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: user.isCurrentUser ? const Color(0xFFAF6B3E) : const Color(0xFF8C7A6B))),
              ],
            ),
          ),
          Text(_formatCompact(user.item.monthlyPoints), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFFAF6B3E))),
        ],
      ),
    );
  }
}

class _RankedUser {
  const _RankedUser({required this.rank, required this.item, required this.isCurrentUser});

  final int rank;
  final UserLeaderboardItem item;
  final bool isCurrentUser;

  String get avatar {
    final palette = ['😎', '👱🏻\u200d♂️', '👩🏻\u200d🦰', '🧔🏻\u200d♂️', '👨🏻\u200d💻', '🧑🏽\u200d🍳', '👩🏼\u200d🔧'];
    return palette[(rank - 1) % palette.length];
  }

  String get levelName {
    if (item.monthlyPoints >= 25000) return 'Radar Efsanesi';
    if (item.monthlyPoints >= 18000) return 'Fiyat Lordu';
    if (item.monthlyPoints >= 10000) return 'Tasarrufçu';
    if (item.monthlyPoints >= 5000) return 'Avcı';
    return 'Gözlemci';
  }
}

String _formatPoints(int points) => points >= 1000 ? '${(points / 1000).toStringAsFixed(1)}K Puan' : '$points Puan';
String _formatCompact(int points) => points >= 1000 ? '${(points / 1000).toStringAsFixed(1)}K' : '$points';
