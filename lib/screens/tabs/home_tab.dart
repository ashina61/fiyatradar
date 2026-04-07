import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../product_detail_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  String _activeFilter = 'Hepsi'; // Düşenler | Yükselenler | Hepsi

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
      featured = products;
    }

    // Cheapest store by number of cheapest-store occurrences
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

    final recentEntries = <_RecentEntry>[];
    for (final p in products) {
      for (final e in p.priceHistory) {
        recentEntries.add(_RecentEntry(product: p, entry: e));
      }
    }
    recentEntries.sort((a, b) => b.entry.date.compareTo(a.entry.date));
    final recentTop = recentEntries.take(4).toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          // ── Header ────────────────────────────────────────────────
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Günaydın',
                      style: TextStyle(
                          color: CoffeeColors.cocoa,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 1),
                    Text(
                      'FiyatRadar',
                      style: TextStyle(
                          color: CoffeeColors.espresso,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5),
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
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Radar Özeti (Hero) ────────────────────────────────────
          _RadarHeroCard(
            dropCount: drops.length,
            totalNew: recentTop.length,
            bestStore: bestStore,
          ),
          const SizedBox(height: 20),

          // ── Quick filter chips ────────────────────────────────────
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: ['Hepsi', 'Düşenler', 'Yükselenler'].map((f) {
                final selected = _activeFilter == f;
                Color chipColor = CoffeeColors.espresso;
                if (f == 'Düşenler') chipColor = const Color(0xFF2E7D32);
                if (f == 'Yükselenler') chipColor = const Color(0xFFC62828);
                return GestureDetector(
                  onTap: () => setState(() => _activeFilter = f),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      color:
                          selected ? chipColor : CoffeeColors.foam,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: selected ? chipColor : CoffeeColors.crema),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (f == 'Düşenler')
                          const Text('📉 ',
                              style: TextStyle(fontSize: 13)),
                        if (f == 'Yükselenler')
                          const Text('📈 ',
                              style: TextStyle(fontSize: 13)),
                        Text(
                          f,
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : CoffeeColors.darkRoast,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // ── Featured products (horizontal scroll) ─────────────────
          _SectionHeader(title: 'Öne Çıkanlar', onMore: () {}),
          const SizedBox(height: 12),
          if (featured.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: CoffeeColors.foam,
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.center,
              child: Text(
                _activeFilter == 'Düşenler'
                    ? 'Bugün fiyat düşüşü yok'
                    : _activeFilter == 'Yükselenler'
                        ? 'Bugün fiyat artışı yok'
                        : 'Ürünler yükleniyor…',
                style: const TextStyle(
                    color: CoffeeColors.cocoa, fontSize: 14),
              ),
            )
          else
            SizedBox(
              height: 204,
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

          // ── Recent community entries ───────────────────────────────
          _SectionHeader(title: 'Son Fiyat Eklemeleri', onMore: () {}),
          const SizedBox(height: 12),
          if (recentTop.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: CoffeeColors.foam,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: const Text('Henüz fiyat eklenmemiş',
                  style: TextStyle(color: CoffeeColors.cocoa)),
            )
          else
            ...recentTop.map((r) => _RecentEntryTile(entry: r)),
        ],
      ),
    );
  }
}

// ─── Data class ──────────────────────────────────────────────────────────────

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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: CoffeeColors.caramel,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 14, color: CoffeeColors.espresso),
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
    required this.totalNew,
    required this.bestStore,
  });

  final int dropCount;
  final int totalNew;
  final String? bestStore;

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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: CoffeeColors.caramel.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'RADAR ÖZETİ',
                  style: TextStyle(
                    color: CoffeeColors.caramel,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _HeroStat(
                label: 'Düşen fiyat',
                value: '$dropCount ürün',
                icon: '📉',
                highlight: dropCount > 0,
              ),
              const SizedBox(width: 12),
              _HeroStat(
                label: 'Son ekleme',
                value: '$totalNew kayıt',
                icon: '🆕',
              ),
              if (bestStore != null) ...[
                const SizedBox(width: 12),
                _HeroStat(
                  label: 'En ucuz',
                  value: bestStore!,
                  icon: '🏆',
                  highlight: true,
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Topluluk güncelledi. Fiyatlar canlı.',
            style: TextStyle(
              color: CoffeeColors.latte,
              fontSize: 12,
            ),
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
    this.highlight = false,
  });

  final String label;
  final String value;
  final String icon;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: highlight
              ? CoffeeColors.caramel.withOpacity(0.18)
              : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: highlight
                ? CoffeeColors.caramel.withOpacity(0.35)
                : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: highlight ? CoffeeColors.caramel : CoffeeColors.cream,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: CoffeeColors.latte,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Featured product card (horizontal scroll) ───────────────────────────────

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final isFav = state.isFavorite(product.id);
    final changePct = product.priceChangePct;
    final hasDrop = changePct != null && changePct < 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 154,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasDrop
                ? const Color(0xFF2E7D32).withOpacity(0.3)
                : CoffeeColors.crema,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: CoffeeColors.foam,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(product.emoji,
                        style: const TextStyle(fontSize: 30)),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => state.toggleFavorite(product.id),
                  child: Icon(
                    isFav ? Icons.favorite_rounded : Icons.favorite_border,
                    color: isFav
                        ? CoffeeColors.accent
                        : CoffeeColors.crema,
                    size: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: CoffeeColors.espresso,
                fontSize: 13,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              product.cheapestStore ?? '–',
              style: const TextStyle(
                  color: CoffeeColors.cocoa, fontSize: 11),
            ),
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  product.lowestPrice == null
                      ? '–'
                      : '₺${product.lowestPrice!.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: CoffeeColors.accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                if (hasDrop)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${changePct.abs().toStringAsFixed(0)}%',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800),
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

  String _ago(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inDays > 0) return '${diff.inDays}g önce';
    if (diff.inHours > 0) return '${diff.inHours}s önce';
    return 'az önce';
  }

  @override
  Widget build(BuildContext context) {
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
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CoffeeColors.crema),
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
              child: Text(entry.product.emoji,
                  style: const TextStyle(fontSize: 20)),
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
                        fontWeight: FontWeight.w700,
                        color: CoffeeColors.espresso,
                        fontSize: 13),
                  ),
                  Text(
                    '${entry.entry.store} · ${entry.entry.reportedBy}',
                    style: const TextStyle(
                        color: CoffeeColors.cocoa, fontSize: 11),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₺${entry.entry.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: CoffeeColors.espresso,
                      fontWeight: FontWeight.w800,
                      fontSize: 14),
                ),
                Text(
                  _ago(entry.entry.date),
                  style: const TextStyle(
                      color: CoffeeColors.cocoa, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onMore});
  final String title;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: CoffeeColors.espresso,
            ),
          ),
        ),
        TextButton(
          onPressed: onMore,
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
                fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
