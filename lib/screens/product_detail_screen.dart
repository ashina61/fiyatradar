import 'package:flutter/material.dart';
import '../models/product.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/design.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final isFav = state.isFavorite(product.id);
    final history = [...product.priceHistory]
      ..sort((a, b) => b.date.compareTo(a.date));
    final ascHistory = history.reversed.toList();
    final lowest = product.lowestPrice;
    final latest = product.latestPrice;
    final changePct = product.priceChangePct;
    final hasDrop = changePct != null && changePct < 0;

    // Per-store best
    final Map<String, PriceEntry> bestPerStore = {};
    for (final e in product.priceHistory) {
      final cur = bestPerStore[e.store];
      if (cur == null || e.price < cur.price) bestPerStore[e.store] = e;
    }
    final perStoreSorted = bestPerStore.values.toList()
      ..sort((a, b) => a.price.compareTo(b.price));

    final contributors =
        product.priceHistory.map((e) => e.reportedBy).toSet().length;
    final lastDate = history.isNotEmpty ? history.first.date : null;

    // 7-day low
    final sevenDaysAgo =
        DateTime.now().subtract(const Duration(days: 7));
    final recentPrices = history
        .where((e) => e.date.isAfter(sevenDaysAgo))
        .map((e) => e.price)
        .toList();
    final sevenDayLow =
        recentPrices.isEmpty ? null : recentPrices.reduce((a, b) => a < b ? a : b);

    return Scaffold(
      backgroundColor: CoffeeColors.cream,
      appBar: AppBar(
        title: Text(
          product.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isFav ? Icons.favorite_rounded : Icons.favorite_border,
              color: isFav ? CoffeeColors.accent : CoffeeColors.darkRoast,
            ),
            onPressed: () => state.toggleFavorite(product.id),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 160),
            children: [
              // ── Hero ─────────────────────────────────────────────
              Container(
                height: 200,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [CoffeeColors.foam, CoffeeColors.crema],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: CoffeeColors.crema),
                  boxShadow: FR.softShadow,
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Text(product.emoji,
                          style: const TextStyle(fontSize: 100)),
                    ),
                    Positioned(
                      top: 14,
                      left: 14,
                      child: EyebrowLabel(product.category.toUpperCase()),
                    ),
                    if (changePct != null)
                      Positioned(
                        top: 14,
                        right: 14,
                        child: TrendPill(pct: changePct),
                      ),
                    Positioned(
                      bottom: 14,
                      right: 14,
                      child: FreshnessChip(date: lastDate),
                    ),
                    if (hasDrop)
                      Positioned(
                        bottom: 14,
                        left: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: CoffeeColors.success.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: CoffeeColors.success
                                    .withOpacity(0.3)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.trending_down,
                                  color: CoffeeColors.success, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'Fiyat düştü',
                                style: TextStyle(
                                  color: CoffeeColors.success,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // ── Title row ────────────────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: CoffeeColors.espresso,
                      letterSpacing: -0.5,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(product.brand,
                          style: const TextStyle(
                              color: CoffeeColors.darkRoast,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                      const Text('  ·  ',
                          style: TextStyle(color: CoffeeColors.crema)),
                      Text(product.unit,
                          style: const TextStyle(
                              color: CoffeeColors.cocoa,
                              fontSize: 13)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: CoffeeColors.foam,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                              color: CoffeeColors.crema),
                        ),
                        child: Text(
                          '${history.length} kayıt',
                          style: const TextStyle(
                            color: CoffeeColors.cocoa,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Best price hero block ─────────────────────────────
              if (lowest != null)
                _BestPriceBlock(
                  lowest: lowest,
                  store: product.cheapestStore ?? '–',
                  contributors: contributors,
                  entries: history.length,
                  hasDrop: hasDrop,
                  changePct: changePct,
                  latest: latest,
                ),
              const SizedBox(height: 12),

              // ── Stat tiles ────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      label: 'EN DÜŞÜK',
                      value: lowest,
                      sub: 'tüm zamanlar',
                      icon: Icons.trending_down,
                      color: CoffeeColors.success,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatTile(
                      label: '7 GÜN',
                      value: sevenDayLow,
                      sub: 'son 7 gün en düşük',
                      icon: Icons.calendar_today_outlined,
                      color: CoffeeColors.caramel,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatTileRaw(
                      label: 'KATKI',
                      value: '$contributors',
                      sub: 'kullanıcı',
                      icon: Icons.people_alt_outlined,
                      color: CoffeeColors.accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Price history chart ───────────────────────────────
              if (ascHistory.length >= 2) ...[
                const SectionHeader(
                  title: 'Fiyat Hareketi',
                  subtitle: 'Topluluk verisine göre seyir',
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(FR.radiusL),
                    border: Border.all(color: CoffeeColors.crema),
                    boxShadow: FR.softShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          PriceText(latest, size: 22),
                          const SizedBox(width: 10),
                          if (changePct != null)
                            TrendPill(pct: changePct),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: CoffeeColors.foam,
                              borderRadius:
                                  BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${ascHistory.length} veri noktası',
                              style: const TextStyle(
                                color: CoffeeColors.cocoa,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Sparkline(
                        values:
                            ascHistory.map((e) => e.price).toList(),
                        height: 72,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _agoShort(ascHistory.first.date),
                            style: const TextStyle(
                                color: CoffeeColors.cocoa,
                                fontSize: 10),
                          ),
                          Row(
                            children: [
                              if (lowest != null) ...[
                                const Text(
                                  'min ',
                                  style: TextStyle(
                                      color: CoffeeColors.cocoa,
                                      fontSize: 10),
                                ),
                                Text(
                                  '₺${lowest.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      color: CoffeeColors.success,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10),
                                ),
                              ],
                            ],
                          ),
                          const Text(
                            'şimdi',
                            style: TextStyle(
                                color: CoffeeColors.cocoa,
                                fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // ── Per-store breakdown ───────────────────────────────
              if (perStoreSorted.isNotEmpty) ...[
                const SectionHeader(
                  title: 'Marketlere Göre',
                  subtitle: 'Her marketin gözlemlenen en iyi fiyatı',
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(FR.radiusL),
                    border: Border.all(color: CoffeeColors.crema),
                    boxShadow: FR.softShadow,
                  ),
                  child: Column(
                    children: List.generate(perStoreSorted.length, (i) {
                      final e = perStoreSorted[i];
                      final isBest = i == 0;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 13),
                        decoration: BoxDecoration(
                          color: isBest
                              ? CoffeeColors.espresso.withOpacity(0.03)
                              : null,
                          borderRadius: i == 0
                              ? const BorderRadius.vertical(
                                  top: Radius.circular(FR.radiusL))
                              : i == perStoreSorted.length - 1
                                  ? const BorderRadius.vertical(
                                      bottom:
                                          Radius.circular(FR.radiusL))
                                  : null,
                          border: i < perStoreSorted.length - 1
                              ? const Border(
                                  bottom: BorderSide(
                                      color: CoffeeColors.crema))
                              : null,
                        ),
                        child: Row(
                          children: [
                            // Rank circle
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: isBest
                                    ? CoffeeColors.caramel
                                    : CoffeeColors.foam,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${i + 1}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  color: isBest
                                      ? CoffeeColors.espresso
                                      : CoffeeColors.cocoa,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        e.store,
                                        style: TextStyle(
                                          fontWeight: isBest
                                              ? FontWeight.w800
                                              : FontWeight.w700,
                                          color: CoffeeColors.espresso,
                                          fontSize: 14,
                                        ),
                                      ),
                                      if (isBest) ...[
                                        const SizedBox(width: 6),
                                        const EyebrowLabel('EN İYİ'),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${e.reportedBy}  ·  ${_agoShort(e.date)}',
                                    style: const TextStyle(
                                      color: CoffeeColors.cocoa,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PriceText(
                              e.price,
                              size: 16,
                              color: isBest
                                  ? CoffeeColors.success
                                  : CoffeeColors.espresso,
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // ── Full history ──────────────────────────────────────
              SectionHeader(
                title: 'Fiyat Geçmişi',
                subtitle:
                    '${history.length} topluluk kaydı',
              ),
              const SizedBox(height: 12),
              if (history.isEmpty)
                _NoHistoryCard()
              else
                ...history.map((e) => _PriceTile(entry: e, lowest: lowest)),
              const SizedBox(height: 18),

              // ── Trust block ───────────────────────────────────────
              if (history.isNotEmpty)
                _TrustBlock(
                  contributors: contributors,
                  entries: history.length,
                ),
            ],
          ),

          // ── Sticky action bar ─────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _StickyActionBar(product: product),
          ),
        ],
      ),
    );
  }
}

String _agoShort(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inDays > 7) return '${(diff.inDays / 7).floor()}h önce';
  if (diff.inDays > 0) return '${diff.inDays}g önce';
  if (diff.inHours > 0) return '${diff.inHours}sa önce';
  if (diff.inMinutes > 0) return '${diff.inMinutes}dk önce';
  return 'az önce';
}

// ─── Best price hero block ────────────────────────────────────────────────────

class _BestPriceBlock extends StatelessWidget {
  const _BestPriceBlock({
    required this.lowest,
    required this.store,
    required this.contributors,
    required this.entries,
    required this.hasDrop,
    required this.changePct,
    required this.latest,
  });

  final double lowest;
  final String store;
  final int contributors;
  final int entries;
  final bool hasDrop;
  final double? changePct;
  final double? latest;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [CoffeeColors.espresso, CoffeeColors.darkRoast],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: CoffeeColors.espresso.withOpacity(0.32),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label row
          Row(
            children: [
              const EyebrowLabel('EN İYİ MEVCUT FİYAT'),
              const Spacer(),
              LiveDot(color: CoffeeColors.caramel),
              const SizedBox(width: 6),
              const Text(
                'CANLI',
                style: TextStyle(
                  color: CoffeeColors.caramel,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Price
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₺${lowest.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: CoffeeColors.cream,
                  fontSize: 44,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.5,
                  fontFeatures: [FontFeature.tabularFigures()],
                  height: 1,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (hasDrop && changePct != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B8E4E).withOpacity(0.25),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                            color: const Color(0xFF8FB36A)
                                .withOpacity(0.5)),
                      ),
                      child: Text(
                        '${changePct!.toStringAsFixed(1)}% düştü',
                        style: const TextStyle(
                          color: Color(0xFFB7D49A),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  if (latest != null && latest != lowest) ...[
                    const SizedBox(height: 4),
                    Text(
                      'son: ₺${latest!.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: CoffeeColors.latte, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Store + meta row
          Row(
            children: [
              // Store badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: CoffeeColors.caramel,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.storefront_outlined,
                        color: CoffeeColors.espresso, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      store,
                      style: const TextStyle(
                        color: CoffeeColors.espresso,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Meta
              Row(
                children: [
                  const Icon(Icons.verified_outlined,
                      color: CoffeeColors.latte, size: 13),
                  const SizedBox(width: 5),
                  Text(
                    '$contributors katkı · $entries kayıt',
                    style: const TextStyle(
                        color: CoffeeColors.latte, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Stat tiles ───────────────────────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    required this.color,
  });
  final String label;
  final double? value;
  final String sub;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return _StatTileRaw(
      label: label,
      value: value == null ? '–' : '₺${value!.toStringAsFixed(2)}',
      sub: sub,
      icon: icon,
      color: color,
    );
  }
}

class _StatTileRaw extends StatelessWidget {
  const _StatTileRaw({
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final String sub;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(FR.radiusL),
        border: Border.all(color: CoffeeColors.crema),
        boxShadow: FR.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: CoffeeColors.cocoa,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 16,
              letterSpacing: -0.3,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: CoffeeColors.cocoa, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

// ─── Price tile ───────────────────────────────────────────────────────────────

class _PriceTile extends StatelessWidget {
  const _PriceTile({required this.entry, required this.lowest});
  final PriceEntry entry;
  final double? lowest;

  @override
  Widget build(BuildContext context) {
    final isLowest = lowest != null && entry.price <= lowest!;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLowest
              ? CoffeeColors.caramel.withOpacity(0.45)
              : CoffeeColors.crema,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isLowest
                  ? CoffeeColors.caramel.withOpacity(0.12)
                  : CoffeeColors.foam,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.storefront_outlined,
                color: isLowest
                    ? CoffeeColors.caramel
                    : CoffeeColors.darkRoast,
                size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.store,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: isLowest
                        ? CoffeeColors.espresso
                        : CoffeeColors.darkRoast,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: CoffeeColors.foam,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: CoffeeColors.crema),
                      ),
                      child: Text(
                        entry.reportedBy,
                        style: const TextStyle(
                            color: CoffeeColors.darkRoast,
                            fontSize: 10,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _agoShort(entry.date),
                      style: const TextStyle(
                          color: CoffeeColors.cocoa, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isLowest) ...[
                const EyebrowLabel('EN İYİ'),
                const SizedBox(height: 4),
              ],
              PriceText(
                entry.price,
                size: 16,
                color: isLowest
                    ? CoffeeColors.success
                    : CoffeeColors.espresso,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── No history card ──────────────────────────────────────────────────────────

class _NoHistoryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CoffeeColors.foam,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CoffeeColors.crema),
      ),
      child: const Row(
        children: [
          Icon(Icons.lightbulb_outline, color: CoffeeColors.caramel),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Henüz fiyat yok',
                  style: TextStyle(
                      color: CoffeeColors.espresso,
                      fontWeight: FontWeight.w800,
                      fontSize: 14),
                ),
                SizedBox(height: 2),
                Text(
                  'İlk fiyatı ekleyen sen ol — +10 puan kazanırsın.',
                  style: TextStyle(
                      color: CoffeeColors.darkRoast,
                      fontWeight: FontWeight.w600,
                      fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Trust block ─────────────────────────────────────────────────────────────

class _TrustBlock extends StatelessWidget {
  const _TrustBlock(
      {required this.contributors, required this.entries});
  final int contributors;
  final int entries;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CoffeeColors.foam,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CoffeeColors.crema),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: CoffeeColors.success.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.verified_outlined,
                color: CoffeeColors.success, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Topluluk doğrulamalı',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: CoffeeColors.espresso,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$contributors kullanıcı · $entries fiyat kaydı',
                  style: const TextStyle(
                    color: CoffeeColors.cocoa,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sticky action bar ────────────────────────────────────────────────────────

class _StickyActionBar extends StatefulWidget {
  const _StickyActionBar({required this.product});
  final Product product;

  @override
  State<_StickyActionBar> createState() => _StickyActionBarState();
}

class _StickyActionBarState extends State<_StickyActionBar> {
  bool _addingToCompare = false;

  Future<void> _openTargetPriceDialog(AppState state) async {
    final existing = state.alertForProduct(widget.product.id);
    final ctrl = TextEditingController(
      text: existing == null ? '' : existing.targetPrice.toStringAsFixed(2),
    );
    final target = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hedef fiyat'),
          content: TextField(
            controller: ctrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              hintText: 'Örn: 49,90',
              prefixText: '₺ ',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Vazgeç'),
            ),
            ElevatedButton(
              onPressed: () {
                final raw = ctrl.text.trim().replaceAll(',', '.');
                final parsed = double.tryParse(raw);
                if (parsed == null || parsed <= 0) return;
                Navigator.pop(context, parsed);
              },
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );
    ctrl.dispose();
    if (target == null) return;
    await state.setProductAlert(
      productId: widget.product.id,
      targetPrice: target,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${widget.product.name} için hedef fiyat ₺${target.toStringAsFixed(2)} kaydedildi',
        ),
        backgroundColor: CoffeeColors.darkRoast,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final alert = state.alertForProduct(widget.product.id);
    final alarmSet = alert != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      decoration: BoxDecoration(
        color: CoffeeColors.cream.withOpacity(0.97),
        border: const Border(
          top: BorderSide(color: CoffeeColors.crema, width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: CoffeeColors.espresso.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Alarm button
            GestureDetector(
              onTap: () => _openTargetPriceDialog(state),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: alarmSet
                      ? CoffeeColors.espresso
                      : Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: alarmSet
                        ? CoffeeColors.espresso
                        : CoffeeColors.crema,
                  ),
                ),
                child: Icon(
                  alarmSet
                      ? Icons.notifications_active
                      : Icons.notifications_none,
                  color: alarmSet
                      ? CoffeeColors.caramel
                      : CoffeeColors.darkRoast,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Compare button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _addingToCompare
                    ? null
                    : () async {
                        setState(() => _addingToCompare = true);
                        state.addToCart(widget.product);
                        await Future.delayed(
                            const Duration(milliseconds: 400));
                        if (!mounted) return;
                        setState(() => _addingToCompare = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                '${widget.product.name} karşılaştırmaya eklendi'),
                            backgroundColor: CoffeeColors.darkRoast,
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.fromLTRB(
                                16, 0, 16, 80),
                          ),
                        );
                      },
                icon: _addingToCompare
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: CoffeeColors.cream),
                      )
                    : const Icon(Icons.balance_outlined, size: 18),
                label: const Text('Karşılaştırmaya Ekle'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
