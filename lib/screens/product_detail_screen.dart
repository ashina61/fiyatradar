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

    return Scaffold(
      backgroundColor: CoffeeColors.cream,
      appBar: AppBar(
        title: const Text('Ürün Detayı'),
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
                height: 210,
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
                          style: const TextStyle(fontSize: 116)),
                    ),
                    Positioned(
                      top: 14,
                      left: 14,
                      child: EyebrowLabel(product.category.toUpperCase()),
                    ),
                    Positioned(
                      bottom: 14,
                      right: 14,
                      child: FreshnessChip(date: lastDate),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // ── Title row ────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: CoffeeColors.espresso,
                            letterSpacing: -0.4,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(children: [
                          Text(product.brand,
                              style: const TextStyle(
                                  color: CoffeeColors.darkRoast,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13)),
                          const Text('  ·  ',
                              style: TextStyle(color: CoffeeColors.crema)),
                          Text(product.unit,
                              style: const TextStyle(
                                  color: CoffeeColors.cocoa, fontSize: 13)),
                        ]),
                      ],
                    ),
                  ),
                  if (changePct != null) TrendPill(pct: changePct),
                ],
              ),
              const SizedBox(height: 20),

              // ── Best price hero block ────────────────────────────
              if (lowest != null)
                _BestPriceBlock(
                  lowest: lowest,
                  store: product.cheapestStore ?? '–',
                  contributors: contributors,
                  entries: history.length,
                  hasDrop: hasDrop,
                  changePct: changePct,
                ),
              const SizedBox(height: 14),

              // ── Stat tiles row ───────────────────────────────────
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
                      label: 'SON GÖRÜLEN',
                      value: latest,
                      sub: lastDate == null
                          ? '–'
                          : _agoShort(lastDate),
                      icon: Icons.access_time_rounded,
                      color: CoffeeColors.accent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatTileRaw(
                      label: 'KATKI',
                      value: '$contributors',
                      sub: 'kullanıcı',
                      icon: Icons.people_alt_outlined,
                      color: CoffeeColors.caramel,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Sparkline / history ──────────────────────────────
              if (ascHistory.length >= 2) ...[
                const SectionHeader(
                  title: 'Fiyat Hareketi',
                  subtitle: 'Topluluk verisine göre seyir',
                ),
                const SizedBox(height: 12),
                PremiumCard(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  elevated: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          PriceText(latest, size: 22),
                          const SizedBox(width: 10),
                          if (changePct != null) TrendPill(pct: changePct),
                          const Spacer(),
                          Text(
                            '${ascHistory.length} kayıt',
                            style: const TextStyle(
                                color: CoffeeColors.cocoa,
                                fontSize: 11,
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Sparkline(
                        values:
                            ascHistory.map((e) => e.price).toList(),
                        height: 64,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _agoShort(ascHistory.first.date),
                            style: const TextStyle(
                                color: CoffeeColors.cocoa, fontSize: 10),
                          ),
                          Text(
                            'şimdi',
                            style: const TextStyle(
                                color: CoffeeColors.cocoa, fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
              ],

              // ── Per-store breakdown ───────────────────────────────
              if (perStoreSorted.isNotEmpty) ...[
                const SectionHeader(
                  title: 'Marketlere Göre',
                  subtitle: 'Her marketin en iyi gözlemlenen fiyatı',
                ),
                const SizedBox(height: 12),
                PremiumCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children:
                        List.generate(perStoreSorted.length, (i) {
                      final e = perStoreSorted[i];
                      final isBest = i == 0;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isBest
                              ? CoffeeColors.foam.withOpacity(0.6)
                              : null,
                          border: i < perStoreSorted.length - 1
                              ? const Border(
                                  bottom: BorderSide(
                                      color: CoffeeColors.crema))
                              : null,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: isBest
                                    ? CoffeeColors.caramel
                                    : CoffeeColors.foam,
                                borderRadius: BorderRadius.circular(8),
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
                                  Text(
                                    e.store,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: CoffeeColors.espresso,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${e.reportedBy} · ${_agoShort(e.date)}',
                                    style: const TextStyle(
                                      color: CoffeeColors.cocoa,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isBest) ...[
                              const EyebrowLabel('EN İYİ'),
                              const SizedBox(width: 8),
                            ],
                            PriceText(e.price, size: 16),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 22),
              ],

              // ── Full history ──────────────────────────────────────
              const SectionHeader(
                title: 'Fiyat Geçmişi',
                subtitle: 'Topluluk gözlemleri',
              ),
              const SizedBox(height: 12),
              if (history.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: CoffeeColors.foam,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: CoffeeColors.crema),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lightbulb_outline,
                          color: CoffeeColors.caramel),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Henüz fiyat eklenmemiş. İlk ekleyen sen ol — +5 puan.',
                          style: TextStyle(
                              color: CoffeeColors.darkRoast,
                              fontWeight: FontWeight.w600,
                              fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...history.map((e) => _PriceTile(entry: e, lowest: lowest)),
              const SizedBox(height: 18),

              // ── Trust block ───────────────────────────────────────
              if (history.isNotEmpty)
                Container(
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
                              '$contributors kullanıcı, ${history.length} fiyat girişi',
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
                ),
            ],
          ),

          // ── Sticky action bar ─────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: BoxDecoration(
                color: CoffeeColors.cream.withOpacity(0.96),
                border: const Border(
                  top: BorderSide(color: CoffeeColors.crema),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: CoffeeColors.crema),
                      ),
                      child: IconButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Alarm kuruldu'),
                              backgroundColor: CoffeeColors.darkRoast,
                              behavior: SnackBarBehavior.floating,
                              margin: EdgeInsets.fromLTRB(16, 0, 16, 80),
                            ),
                          );
                        },
                        icon: const Icon(Icons.notifications_none,
                            color: CoffeeColors.darkRoast, size: 22),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          state.addToCart(product);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Karşılaştırmaya eklendi'),
                              backgroundColor: CoffeeColors.darkRoast,
                              behavior: SnackBarBehavior.floating,
                              margin: EdgeInsets.fromLTRB(16, 0, 16, 80),
                            ),
                          );
                        },
                        icon:
                            const Icon(Icons.balance_outlined, size: 18),
                        label: const Text('Karşılaştırmaya Ekle'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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

// ─── Best price hero ──────────────────────────────────────────────────────────

class _BestPriceBlock extends StatelessWidget {
  const _BestPriceBlock({
    required this.lowest,
    required this.store,
    required this.contributors,
    required this.entries,
    required this.hasDrop,
    required this.changePct,
  });

  final double lowest;
  final String store;
  final int contributors;
  final int entries;
  final bool hasDrop;
  final double? changePct;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [CoffeeColors.espresso, CoffeeColors.darkRoast],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: CoffeeColors.espresso.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₺${lowest.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: CoffeeColors.cream,
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 12),
              if (hasDrop && changePct != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFF6B8E4E).withOpacity(0.25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color:
                              const Color(0xFF8FB36A).withOpacity(0.5)),
                    ),
                    child: Text(
                      '${changePct!.toStringAsFixed(1)}% düşüş',
                      style: const TextStyle(
                        color: Color(0xFFB7D49A),
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: CoffeeColors.caramel,
                  borderRadius: BorderRadius.circular(10),
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
              const Icon(Icons.people_alt_outlined,
                  color: CoffeeColors.latte, size: 13),
              const SizedBox(width: 4),
              Text(
                '$contributors katkı · $entries kayıt',
                style: const TextStyle(
                    color: CoffeeColors.latte, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Stat tile ────────────────────────────────────────────────────────────────

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
              Icon(icon, color: color, size: 16),
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
              fontSize: 17,
              letterSpacing: -0.3,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 1),
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
              ? CoffeeColors.caramel.withOpacity(0.5)
              : CoffeeColors.crema,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: CoffeeColors.foam,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.storefront_outlined,
                color: CoffeeColors.darkRoast, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.store,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: CoffeeColors.espresso,
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
          if (isLowest) ...[
            const EyebrowLabel('EN İYİ'),
            const SizedBox(width: 8),
          ],
          PriceText(entry.price, size: 16),
        ],
      ),
    );
  }
}
