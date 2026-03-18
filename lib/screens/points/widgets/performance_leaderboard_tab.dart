import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../models/leaderboard_item.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/leaderboard_provider.dart';
import '../../../theme/fr_colors.dart';

enum _LeaderboardSegment { overview, top }

class PerformanceLeaderboardTab extends ConsumerStatefulWidget {
  const PerformanceLeaderboardTab({super.key});

  @override
  ConsumerState<PerformanceLeaderboardTab> createState() => _PerformanceLeaderboardTabState();
}

class _PerformanceLeaderboardTabState extends ConsumerState<PerformanceLeaderboardTab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;
  _LeaderboardSegment _selectedSegment = _LeaderboardSegment.overview;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authUid = ref.watch(authStateProvider).valueOrNull?.uid;
    final leaderboard = ref.watch(leaderboardStreamProvider(LeaderboardFilter.global));

    return ColoredBox(
      color: FRColors.bgApp,
      child: leaderboard.when(
        loading: () => const Center(child: CircularProgressIndicator(color: FRColors.camel)),
        error: (_, __) => const Center(child: Text('Liderlik tablosu yüklenemedi', style: _FRText.body)),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Henüz zirve verisi yok', style: _FRText.body));
          }

          final ranked = items.asMap().entries.map((entry) {
            final item = entry.value;
            return _RankedItem(
              rank: entry.key + 1,
              item: item,
              isCurrentUser: item.uid == authUid,
            );
          }).toList();

          final topThree = ranked.take(3).toList();
          final others = ranked.skip(3).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
            children: [
              _LuxurySegmentedControl(
                value: _selectedSegment,
                onChanged: (segment) => setState(() => _selectedSegment = segment),
              ),
              const SizedBox(height: 18),
              _VipPrizeCard(controller: _shimmerController),
              const SizedBox(height: 18),
              _SectionIntro(segment: _selectedSegment),
              const SizedBox(height: 18),
              if (topThree.isNotEmpty) _VerticalPodium(items: topThree),
              if (others.isNotEmpty) ...[
                const SizedBox(height: 22),
                _StandardLeaderboardList(
                  items: _selectedSegment == _LeaderboardSegment.overview ? others : ranked,
                  startFromRank: _selectedSegment == _LeaderboardSegment.overview ? 4 : 1,
                  showTopDividerInset: _selectedSegment == _LeaderboardSegment.top,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _LuxurySegmentedControl extends StatelessWidget {
  const _LuxurySegmentedControl({required this.value, required this.onChanged});

  final _LeaderboardSegment value;
  final ValueChanged<_LeaderboardSegment> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: FRColors.background,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: FRColors.borderStrong.withOpacity(0.18)),
        boxShadow: const [
          BoxShadow(
            color: FRColors.shadowSoft,
            blurRadius: 22,
            spreadRadius: 2,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentButton(
              label: 'Genel Bakış',
              selected: value == _LeaderboardSegment.overview,
              onTap: () => onChanged(_LeaderboardSegment.overview),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SegmentButton(
              label: 'Zirvedekiler',
              selected: value == _LeaderboardSegment.top,
              onTap: () => onChanged(_LeaderboardSegment.top),
            ),
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: selected ? FRColors.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        boxShadow: selected
            ? const [
                BoxShadow(
                  color: FRColors.shadowSoft,
                  blurRadius: 20,
                  spreadRadius: 1,
                  offset: Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: _FRText.segment.copyWith(
                color: selected ? FRColors.espresso : FRColors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VipPrizeCard extends StatelessWidget {
  const _VipPrizeCard({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    final month = toBeginningOfSentenceCase(DateFormat('MMMM', 'tr_TR').format(DateTime.now())) ?? 'Mart';

    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [FRColors.espresso, Color(0xFF080504)],
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$month Ayı Şampiyonu',
                        style: _FRText.eyebrow.copyWith(color: FRColors.camel),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        '500 ₺ MARKET ÇEKİ\nKAZANIYOR!',
                        style: _FRText.hero,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Ay boyunca en yüksek puanı toplayan lider, lüks ödülün tek sahibi oluyor.',
                        style: _FRText.body.copyWith(color: FRColors.whiteMuted, height: 1.45),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: FRColors.camelOverlay(0.14),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: FRColors.camelOverlay(0.28)),
                  ),
                  child: const Icon(CupertinoIcons.gift, color: FRColors.camel, size: 34),
                ),
              ],
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: controller,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(MediaQuery.sizeOf(context).width * controller.value - 240, 0),
                    child: child,
                  );
                },
                child: Container(
                  width: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.transparent,
                        FRColors.goldGlowSoft.withOpacity(0.04),
                        FRColors.goldGlow.withOpacity(0.24),
                        FRColors.goldGlowSoft.withOpacity(0.04),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionIntro extends StatelessWidget {
  const _SectionIntro({required this.segment});

  final _LeaderboardSegment segment;

  @override
  Widget build(BuildContext context) {
    final title = segment == _LeaderboardSegment.overview ? 'Dikey Banner Podyumu' : 'Zirvedekiler';
    final subtitle = segment == _LeaderboardSegment.overview
        ? 'İlk üçte yer alan isimler, FiyatRadar V6 sahnesinde tam boy lüks banner kartlarla öne çıkıyor.'
        : 'Sıralamanın tamamını hızlıca takip et; liderler üstte, kalan yarışmacılar ince çizgili listede.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: _FRText.title),
        const SizedBox(height: 6),
        Text(subtitle, style: _FRText.body.copyWith(color: FRColors.textMuted, height: 1.5)),
      ],
    );
  }
}

class _VerticalPodium extends StatelessWidget {
  const _VerticalPodium({required this.items});

  final List<_RankedItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final item in items) ...[
          _PodiumBanner(item: item),
          if (item != items.last) const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _PodiumBanner extends StatelessWidget {
  const _PodiumBanner({required this.item});

  final _RankedItem item;

  @override
  Widget build(BuildContext context) {
    final palette = _PodiumPalette.fromRank(item.rank);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: FRColors.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: palette.borderColor),
        boxShadow: [
          BoxShadow(
            color: palette.shadowColor,
            blurRadius: 30,
            spreadRadius: 1,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: palette.badgeBackground,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.rank == 1 ? CupertinoIcons.crown_fill : CupertinoIcons.star_fill, size: 14, color: palette.accent),
                    const SizedBox(width: 8),
                    Text('${item.rank}. SIRA', style: _FRText.badge.copyWith(color: palette.accent)),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                '${_formatPoints(item.item.totalPoints)} PUAN',
                style: _FRText.badge.copyWith(color: palette.accent),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [palette.accent, palette.accentSoft]),
            ),
            child: CircleAvatar(
              radius: 42,
              backgroundColor: FRColors.espresso,
              child: Text(
                _initials(item.item.name),
                style: _FRText.avatar,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            item.item.name,
            textAlign: TextAlign.center,
            softWrap: true,
            style: _FRText.podiumName.copyWith(
              color: item.isCurrentUser ? palette.accent : FRColors.espresso,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: FRColors.background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              item.isCurrentUser ? 'Bu sensin · Yarışın merkezindesin' : 'Zirvede sağlam duran elit oyuncu',
              textAlign: TextAlign.center,
              style: _FRText.bodySmall.copyWith(color: FRColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _StandardLeaderboardList extends StatelessWidget {
  const _StandardLeaderboardList({
    required this.items,
    required this.startFromRank,
    this.showTopDividerInset = false,
  });

  final List<_RankedItem> items;
  final int startFromRank;
  final bool showTopDividerInset;

  @override
  Widget build(BuildContext context) {
    final filtered = items.where((item) => item.rank >= startFromRank).toList();
    if (filtered.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          startFromRank <= 1 ? 'Tüm Sıralama' : '4. sıra ve sonrası',
          style: _FRText.title,
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              if (showTopDividerInset)
                const Divider(height: 1, thickness: 1, color: FRColors.borderLight),
              for (final item in filtered) _LeaderboardRow(item: item, isLast: item == filtered.last),
            ],
          ),
        ),
      ],
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({required this.item, required this.isLast});

  final _RankedItem item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast ? BorderSide.none : const BorderSide(color: FRColors.borderLight),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text('${item.rank}.', style: _FRText.body.copyWith(fontWeight: FontWeight.w800)),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: FRColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: FRColors.borderLight),
            ),
            alignment: Alignment.center,
            child: Text(_initials(item.item.name), style: _FRText.body.copyWith(fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _FRText.body.copyWith(
                color: item.isCurrentUser ? FRColors.camelDeep : FRColors.espresso,
                fontWeight: item.isCurrentUser ? FontWeight.w800 : FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _formatPoints(item.item.totalPoints),
            textAlign: TextAlign.right,
            style: _FRText.body.copyWith(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _PodiumPalette {
  const _PodiumPalette({
    required this.accent,
    required this.accentSoft,
    required this.borderColor,
    required this.shadowColor,
    required this.badgeBackground,
  });

  final Color accent;
  final Color accentSoft;
  final Color borderColor;
  final Color shadowColor;
  final Color badgeBackground;

  factory _PodiumPalette.fromRank(int rank) {
    switch (rank) {
      case 1:
        return _PodiumPalette(
          accent: FRColors.camel,
          accentSoft: FRColors.goldGlow,
          borderColor: FRColors.camelOverlay(0.34),
          shadowColor: FRColors.camelOverlay(0.14),
          badgeBackground: FRColors.camelOverlay(0.14),
        );
      case 2:
        return _PodiumPalette(
          accent: FRColors.silverDeep,
          accentSoft: FRColors.silver,
          borderColor: FRColors.silver.withOpacity(0.34),
          shadowColor: FRColors.silver.withOpacity(0.12),
          badgeBackground: FRColors.silver.withOpacity(0.12),
        );
      default:
        return _PodiumPalette(
          accent: const Color(0xFFB67444),
          accentSoft: const Color(0xFFD9A07A),
          borderColor: const Color(0x33B67444),
          shadowColor: const Color(0x1FB67444),
          badgeBackground: const Color(0x14B67444),
        );
    }
  }
}

class _FRText {
  static const String _font = 'Plus Jakarta Sans';

  static const TextStyle segment = TextStyle(
    fontFamily: _font,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );

  static const TextStyle eyebrow = TextStyle(
    fontFamily: _font,
    fontSize: 12,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.1,
  );

  static const TextStyle hero = TextStyle(
    fontFamily: _font,
    fontSize: 26,
    fontWeight: FontWeight.w900,
    color: Colors.white,
    height: 1.1,
    letterSpacing: -0.8,
  );

  static const TextStyle title = TextStyle(
    fontFamily: _font,
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: FRColors.espresso,
    letterSpacing: -0.5,
  );

  static const TextStyle badge = TextStyle(
    fontFamily: _font,
    fontSize: 12,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.4,
  );

  static const TextStyle podiumName = TextStyle(
    fontFamily: _font,
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: FRColors.espresso,
    height: 1.3,
    letterSpacing: -0.4,
  );

  static const TextStyle avatar = TextStyle(
    fontFamily: _font,
    fontSize: 22,
    fontWeight: FontWeight.w900,
    color: Colors.white,
  );

  static const TextStyle body = TextStyle(
    fontFamily: _font,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: FRColors.espresso,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: _font,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: FRColors.textMuted,
  );
}

class _RankedItem {
  const _RankedItem({
    required this.rank,
    required this.item,
    required this.isCurrentUser,
  });

  final int rank;
  final LeaderboardItem item;
  final bool isCurrentUser;
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) {
    return parts.first.characters.take(2).toString().toUpperCase();
  }
  return '${parts.first.characters.first}${parts.last.characters.first}'.toUpperCase();
}

String _formatPoints(int value) => NumberFormat.decimalPattern('tr_TR').format(value);
