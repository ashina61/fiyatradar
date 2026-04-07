import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/design.dart';
import '../product_detail_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  String _activeFilter = 'Hepsi';

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final products = state.products;

    final drops = products.where((p) {
      final c = p.priceChangePct;
      return c != null && c < 0;
    }).toList();
    final rises = products.where((p) {
      final c = p.priceChangePct;
      return c != null && c > 0;
    }).toList();

    List<Product> featured;
    if (_activeFilter == 'Düşenler') {
      featured = drops;
    } else if (_activeFilter == 'Yükselenler') {
      featured = rises;
    } else {
      featured = [...products]
        ..sort((a, b) {
          final ca = a.priceChangePct?.abs() ?? 0;
          final cb = b.priceChangePct?.abs() ?? 0;
          return cb.compareTo(ca);
        });
    }

    final storeCount = <String, int>{};
    for (final p in products) {
      final s = p.cheapestStore;
      if (s != null) storeCount[s] = (storeCount[s] ?? 0) + 1;
    }
    String? bestStore;
    if (storeCount.isNotEmpty) {
      bestStore = storeCount.entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;
    }

    final allEntries = <_RecentEntry>[];
    final contributors = <String>{};
    final allStores = <String>{};
    for (final p in products) {
      for (final e in p.priceHistory) {
        allEntries.add(_RecentEntry(product: p, entry: e));
        contributors.add(e.reportedBy);
        allStores.add(e.store);
      }
    }
    allEntries.sort((a, b) => b.entry.date.compareTo(a.entry.date));
    final recentTop = allEntries.take(5).toList();
    final last24h = allEntries
        .where((e) =>
            DateTime.now().difference(e.entry.date).inHours < 24)
        .length;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          // ── Header ───────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Günaydın',
                            style: TextStyle(
                                color: CoffeeColors.cocoa,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(width: 6),
                        LiveDot(),
                      ],
                    ),
                    const SizedBox(height: 1),
                    const Text(
                      'FiyatRadar',
                      style: TextStyle(
                          color: CoffeeColors.espresso,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6),
                    ),
                  ],
                ),
              ),
              _PointsPill(points: state.points),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none,
                    color: CoffeeColors.darkRoast, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ── Radar hero ────────────────────────────────────────────
          _RadarHeroCard(
            dropCount: drops.length,
            riseCount: rises.length,
            last24h: last24h,
            bestStore: bestStore,
            sparkValues: _aggregateSpark(allEntries),
          ),
          const SizedBox(height: 12),

          // ── Signal strip ──────────────────────────────────────────
          _SignalStrip(
            products: products.length,
            stores: allStores.length,
            contributors: contributors.length,
          ),
          const SizedBox(height: 22),

          // ── Filter chips ──────────────────────────────────────────
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: ['Hepsi', 'Düşenler', 'Yükselenler'].map((f) {
                final selected = _activeFilter == f;
                Color chipColor = CoffeeColors.espresso;
                if (f == 'Düşenler') chipColor = const Color(0xFF2E7D32);
                if (f == 'Yükselenler') chipColor = const Color(0xFFC62828);
                final n = f == 'Düşenler'
                    ? drops.length
                    : f == 'Yükselenler'
                        ? rises.length
                        : products.length;
                return GestureDetector(
                  onTap: () => setState(() => _activeFilter = f),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: selected ? chipColor : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: selected ? chipColor : CoffeeColors.crema),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (f == 'Düşenler')
                          const Icon(Icons.trending_down,
                              size: 14, color: Colors.white),
                        if (f == 'Yükselenler')
                          const Icon(Icons.trending_up,
                              size: 14, color: Colors.white),
                        if (f != 'Hepsi') const SizedBox(width: 4),
                        Text(
                          f,
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : CoffeeColors.darkRoast,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: selected
                                ? Colors.white.withOpacity(0.22)
                                : CoffeeColors.foam,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$n',
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : CoffeeColors.cocoa,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 18),

          // ── Featured ──────────────────────────────────────────────
          SectionHeader(
            title: 'Öne Çıkanlar',
            subtitle: 'Bugün hareketli olanlar',
            trailing: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Tümü →',
                style: TextStyle(
                    color: CoffeeColors.caramel,
                    fontSize: 13,
                    fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (featured.isEmpty)
            _EmptyBlock(
              text: _activeFilter == 'Düşenler'
                  ? 'Bugün fiyat düşüşü yok'
                  : _activeFilter == 'Yükselenler'
                      ? 'Bugün fiyat artışı yok'
                      : 'Ürünler yükleniyor…',
            )
          else
            SizedBox(
              height: 232,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: featured.take(8).length,
                itemBuilder: (context, i) {
                  final p = featured[i];
                  return _FeaturedCard(
                    product: p,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductDetailScreen(product: p),
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 28),

          // ── Recent entries ────────────────────────────────────────
          SectionHeader(
            title: 'Son Fiyat Eklemeleri',
            subtitle: '$last24h kayıt · son 24 saat',
            trailing: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Akış →',
                style: TextStyle(
                    color: CoffeeColors.caramel,
                    fontSize: 13,
                    fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (recentTop.isEmpty)
            _EmptyBlock(text: 'Henüz fiyat eklenmemiş')
          else
            ...recentTop.map((r) => _RecentEntryTile(entry: r)),
        ],
      ),
    );
  }

  List<double> _aggregateSpark(List<_RecentEntry> entries) {
    if (entries.length < 4) return const [];
    // Use last 14 entries' prices as a rough community pulse line.
    final last = entries.take(14).toList().reversed.toList();
    return last.map((e) => e.entry.price).toList();
  }
}

class _RecentEntry {
  final Product product;
  final PriceEntry entry;
  const _RecentEntry({required this.product, required this.entry});
}

// ─── Points pill ─────────────────────────────────────────────────────────────

class _PointsPill extends StatelessWidget {
  const _PointsPill({required this.points});
  final int points;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: CoffeeColors.caramel,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: CoffeeColors.caramel.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded,
              size: 14, color: CoffeeColors.espresso),
          const SizedBox(width: 4),
          Text(
            '$points',
            style: const TextStyle(
                color: CoffeeColors.espresso,
                fontWeight: FontWeight.w800,
                fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─── Hero card ───────────────────────────────────────────────────────────────

class _RadarHeroCard extends StatelessWidget {
  const _RadarHeroCard({
    required this.dropCount,
    required this.riseCount,
    required this.last24h,
    required this.bestStore,
    required this.sparkValues,
  });

  final int dropCount;
  final int riseCount;
  final int last24h;
  final String? bestStore;
  final List<double> sparkValues;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [CoffeeColors.espresso, CoffeeColors.darkRoast],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: CoffeeColors.espresso.withOpacity(0.30),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const EyebrowLabel('RADAR ÖZETİ'),
              const Spacer(),
              LiveDot(color: CoffeeColors.caramel),
              const SizedBox(width: 6),
              const Text(
                'CANLI',
                style: TextStyle(
                  color: CoffeeColors.caramel,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$last24h',
                      style: const TextStyle(
                        color: CoffeeColors.cream,
                        fontSize: 44,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.5,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'son 24 saatte yeni fiyat',
                      style: TextStyle(
                          color: CoffeeColors.latte, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (sparkValues.length >= 2)
                SizedBox(
                  width: 120,
                  child: Sparkline(
                    values: sparkValues,
                    height: 50,
                    color: CoffeeColors.caramel,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _HeroStat(
                label: 'düşen',
                value: '$dropCount',
                icon: Icons.trending_down,
                accent: const Color(0xFF8FB36A),
              ),
              const SizedBox(width: 10),
              _HeroStat(
                label: 'yükselen',
                value: '$riseCount',
                icon: Icons.trending_up,
                accent: const Color(0xFFE57B6F),
              ),
              const SizedBox(width: 10),
              _HeroStat(
                label: 'en ucuz',
                value: bestStore ?? '–',
                icon: Icons.emoji_events_outlined,
                accent: CoffeeColors.caramel,
                highlight: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    this.highlight = false,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
        decoration: BoxDecoration(
          color: highlight
              ? accent.withOpacity(0.18)
              : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: highlight
                ? accent.withOpacity(0.4)
                : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: accent, size: 14),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: highlight ? accent : CoffeeColors.cream,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: -0.2,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                  color: CoffeeColors.latte, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Signal strip ────────────────────────────────────────────────────────────

class _SignalStrip extends StatelessWidget {
  const _SignalStrip({
    required this.products,
    required this.stores,
    required this.contributors,
  });
  final int products;
  final int stores;
  final int contributors;

  @override
  Widget build(BuildContext context) {
    Widget cell(String value, String label, IconData icon) {
      return Expanded(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: CoffeeColors.caramel),
            const SizedBox(width: 6),
            Text(
              value,
              style: const TextStyle(
                color: CoffeeColors.espresso,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: CoffeeColors.cocoa,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(FR.radiusL),
        border: Border.all(color: CoffeeColors.crema),
        boxShadow: FR.softShadow,
      ),
      child: Row(
        children: [
          cell('$products', 'ürün', Icons.inventory_2_outlined),
          Container(
              width: 1, height: 18, color: CoffeeColors.crema),
          cell('$stores', 'market', Icons.storefront_outlined),
          Container(
              width: 1, height: 18, color: CoffeeColors.crema),
          cell('$contributors', 'katkıcı', Icons.people_alt_outlined),
        ],
      ),
    );
  }
}

// ─── Featured card ───────────────────────────────────────────────────────────

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.product, required this.onTap});
  final Product product;
  final VoidCallback onTap;

  DateTime? get _latest {
    if (product.priceHistory.isEmpty) return null;
    final s = [...product.priceHistory]
      ..sort((a, b) => b.date.compareTo(a.date));
    return s.first.date;
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final isFav = state.isFavorite(product.id);
    final changePct = product.priceChangePct;
    final lowest = product.lowestPrice;
    final stores =
        product.priceHistory.map((e) => e.store).toSet().length;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 168,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(FR.radiusXl),
          border: Border.all(color: CoffeeColors.crema),
          boxShadow: FR.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 70,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [CoffeeColors.foam, CoffeeColors.crema],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(product.emoji,
                      style: const TextStyle(fontSize: 36)),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => state.toggleFavorite(product.id),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFav
                            ? Icons.favorite_rounded
                            : Icons.favorite_border,
                        color: isFav
                            ? CoffeeColors.accent
                            : CoffeeColors.darkRoast,
                        size: 14,
                      ),
                    ),
                  ),
                ),
                if (changePct != null)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: TrendPill(pct: changePct, dense: true),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: CoffeeColors.espresso,
                fontSize: 13,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              product.brand,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: CoffeeColors.cocoa,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            const Divider(height: 12, color: CoffeeColors.crema),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                PriceText(value: lowest, size: 16),
                const Spacer(),
                if (product.cheapestStore != null)
                  StoreBadge(product.cheapestStore!),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                FreshnessChip(date: _latest),
                const Spacer(),
                Text(
                  '$stores market',
                  style: const TextStyle(
                    color: CoffeeColors.cocoa,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Recent entry tile ────────────────────────────────────────────────────────

class _RecentEntryTile extends StatelessWidget {
  const _RecentEntryTile({required this.entry});
  final _RecentEntry entry;

  @override
  Widget build(BuildContext context) {
    final isLow = entry.product.lowestPrice != null &&
        entry.entry.price <= entry.product.lowestPrice!;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(product: entry.product),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(FR.radiusL),
          border: Border.all(
            color: isLow
                ? CoffeeColors.caramel.withOpacity(0.45)
                : CoffeeColors.crema,
          ),
          boxShadow: FR.softShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [CoffeeColors.foam, CoffeeColors.crema],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(entry.product.emoji,
                  style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: CoffeeColors.espresso,
                        fontSize: 13),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      StoreBadge(entry.entry.store, dark: false),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          entry.entry.reportedBy,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: CoffeeColors.cocoa,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                PriceText(
                  value: entry.entry.price,
                  size: 15,
                  color: isLow
                      ? CoffeeColors.success
                      : CoffeeColors.espresso,
                ),
                const SizedBox(height: 3),
                FreshnessChip(date: entry.entry.date),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  const _EmptyBlock({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(FR.radiusL),
        border: Border.all(color: CoffeeColors.crema),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(color: CoffeeColors.cocoa, fontSize: 13),
      ),
    );
  }
}
