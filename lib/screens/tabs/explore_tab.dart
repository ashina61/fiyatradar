import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/design.dart';
import '../product_detail_screen.dart';

enum _SortMode { trending, cheapest, freshest }

class ExploreTab extends StatefulWidget {
  const ExploreTab({super.key});

  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab> {
  String _selectedCategory = 'Tümü';
  String _query = '';
  _SortMode _sort = _SortMode.trending;
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final all = state.products.where((p) {
      final matchCat =
          _selectedCategory == 'Tümü' || p.category == _selectedCategory;
      final matchQ = _query.isEmpty ||
          p.name.toLowerCase().contains(_query.toLowerCase()) ||
          p.brand.toLowerCase().contains(_query.toLowerCase());
      return matchCat && matchQ;
    }).toList();

    DateTime? latestDate(Product p) {
      if (p.priceHistory.isEmpty) return null;
      return ([...p.priceHistory]
            ..sort((a, b) => b.date.compareTo(a.date)))
          .first
          .date;
    }

    final filtered = [...all];
    switch (_sort) {
      case _SortMode.trending:
        filtered.sort((a, b) {
          final ca = a.priceChangePct?.abs() ?? -1;
          final cb = b.priceChangePct?.abs() ?? -1;
          return cb.compareTo(ca);
        });
        break;
      case _SortMode.cheapest:
        filtered.sort((a, b) {
          final pa = a.lowestPrice ?? double.infinity;
          final pb = b.lowestPrice ?? double.infinity;
          return pa.compareTo(pb);
        });
        break;
      case _SortMode.freshest:
        filtered.sort((a, b) {
          final la = latestDate(a);
          final lb = latestDate(b);
          if (la == null && lb == null) return 0;
          if (la == null) return 1;
          if (lb == null) return -1;
          return lb.compareTo(la);
        });
        break;
    }

    final stores = <String>{};
    var fresh = 0;
    for (final p in all) {
      for (final e in p.priceHistory) {
        stores.add(e.store);
        if (DateTime.now().difference(e.date).inHours < 24) fresh++;
      }
    }

    return SafeArea(
      child: Column(
        children: [
          // ── Header ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Keşfet',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.7,
                            color: CoffeeColors.espresso),
                      ),
                      Text(
                        'Akıllı fiyat taraması',
                        style: TextStyle(
                            color: CoffeeColors.cocoa, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                // Filter button
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: CoffeeColors.crema),
                    boxShadow: FR.softShadow,
                  ),
                  child: const Icon(Icons.tune,
                      color: CoffeeColors.darkRoast, size: 20),
                ),
              ],
            ),
          ),

          // ── Search bar ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Ürün veya marka ara…',
                prefixIcon: const Icon(Icons.search,
                    color: CoffeeColors.cocoa, size: 20),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close,
                            color: CoffeeColors.cocoa, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // ── Signal strip ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(FR.radiusM),
                border: Border.all(color: CoffeeColors.crema),
                boxShadow: FR.softShadow,
              ),
              child: Row(
                children: [
                  _signalCell(
                      '${all.length}', 'sonuç', Icons.inventory_2_outlined),
                  Container(
                      width: 1, height: 16, color: CoffeeColors.crema),
                  _signalCell('${stores.length}', 'market',
                      Icons.storefront_outlined),
                  Container(
                      width: 1, height: 16, color: CoffeeColors.crema),
                  _signalCell(
                      '$fresh', 'taze bugün', Icons.bolt_outlined),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // ── Category chips ───────────────────────────────────────
          SizedBox(
            height: 38,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: state.categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final cat = state.categories[i];
                final selected = cat == _selectedCategory;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: selected
                          ? CoffeeColors.espresso
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: selected
                              ? CoffeeColors.espresso
                              : CoffeeColors.crema),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color:
                                    CoffeeColors.espresso.withOpacity(0.20),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              )
                            ]
                          : null,
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: selected
                            ? CoffeeColors.cream
                            : CoffeeColors.darkRoast,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // ── Sort toolbar ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: CoffeeColors.crema),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sort_rounded,
                      size: 15, color: CoffeeColors.cocoa),
                  const SizedBox(width: 8),
                  Text(
                    '${filtered.length} ürün',
                    style: const TextStyle(
                      color: CoffeeColors.cocoa,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  ..._SortMode.values.map((m) {
                    final selected = m == _sort;
                    final label = switch (m) {
                      _SortMode.trending => 'Hareketli',
                      _SortMode.cheapest => 'Ucuz',
                      _SortMode.freshest => 'Taze',
                    };
                    final icon = switch (m) {
                      _SortMode.trending => Icons.local_fire_department_outlined,
                      _SortMode.cheapest => Icons.arrow_downward_rounded,
                      _SortMode.freshest => Icons.bolt_outlined,
                    };
                    return Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: GestureDetector(
                        onTap: () => setState(() => _sort = m),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: selected
                                ? CoffeeColors.espresso
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selected
                                  ? CoffeeColors.espresso
                                  : CoffeeColors.crema,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                icon,
                                size: 11,
                                color: selected
                                    ? CoffeeColors.caramel
                                    : CoffeeColors.cocoa,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                label,
                                style: TextStyle(
                                  color: selected
                                      ? CoffeeColors.cream
                                      : CoffeeColors.darkRoast,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── Grid ─────────────────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? _EmptyExplore(query: _query)
                : GridView.builder(
                    padding:
                        const EdgeInsets.fromLTRB(20, 4, 20, 120),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.60,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final p = filtered[i];
                      return _ExploreCard(
                        product: p,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ProductDetailScreen(product: p),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _signalCell(String value, String label, IconData icon) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 13, color: CoffeeColors.caramel),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              color: CoffeeColors.espresso,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              color: CoffeeColors.cocoa,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Premium explore card ─────────────────────────────────────────────────────

class _ExploreCard extends StatelessWidget {
  const _ExploreCard({required this.product, required this.onTap});
  final Product product;
  final VoidCallback onTap;

  DateTime? get _latestDate {
    if (product.priceHistory.isEmpty) return null;
    return ([...product.priceHistory]
          ..sort((a, b) => b.date.compareTo(a.date)))
        .first
        .date;
  }

  List<double> get _sparkValues {
    if (product.priceHistory.length < 3) return [];
    final sorted = [...product.priceHistory]
      ..sort((a, b) => a.date.compareTo(b.date));
    return sorted.map((e) => e.price).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final price = product.lowestPrice;
    final store = product.cheapestStore;
    final changePct = product.priceChangePct;
    final isFav = state.isFavorite(product.id);
    final entries = product.priceHistory.length;
    final storeCount =
        product.priceHistory.map((e) => e.store).toSet().length;
    final hasPrice = price != null;
    final spark = _sparkValues;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(FR.radiusXl),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(FR.radiusXl),
          border: Border.all(
            color: changePct != null && changePct < -5
                ? CoffeeColors.caramel.withOpacity(0.35)
                : CoffeeColors.crema,
            width: changePct != null && changePct < -5 ? 1.5 : 1,
          ),
          boxShadow: FR.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image area ────────────────────────────────────────
            Stack(
              children: [
                Container(
                  height: 88,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: hasPrice
                          ? [CoffeeColors.foam, CoffeeColors.crema]
                          : [
                              CoffeeColors.foam.withOpacity(0.5),
                              CoffeeColors.crema.withOpacity(0.5)
                            ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(FR.radiusXl)),
                  ),
                  alignment: Alignment.center,
                  child: Text(product.emoji,
                      style: const TextStyle(fontSize: 42)),
                ),
                // Trend pill
                if (changePct != null)
                  Positioned(
                    top: 7,
                    left: 7,
                    child: TrendPill(pct: changePct, dense: true),
                  ),
                // Fav button
                Positioned(
                  top: 5,
                  right: 5,
                  child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 0,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => state.toggleFavorite(product.id),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          size: 14,
                          color: isFav
                              ? CoffeeColors.accent
                              : CoffeeColors.darkRoast,
                        ),
                      ),
                    ),
                  ),
                ),
                // Freshness chip
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: FreshnessChip(date: _latestDate),
                ),
              ],
            ),

            // ── Content ───────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(11, 9, 11, 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: CoffeeColors.foam,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: CoffeeColors.crema),
                      ),
                      child: Text(
                        product.brand.isNotEmpty
                            ? product.brand
                            : product.category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: CoffeeColors.cocoa,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),

                    // Name
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: CoffeeColors.espresso,
                        fontSize: 13,
                        height: 1.2,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.unit,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: CoffeeColors.cocoa,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    // Sparkline (if available)
                    if (spark.length >= 3) ...[
                      const SizedBox(height: 6),
                      Sparkline(
                        values: spark,
                        height: 28,
                        color: changePct != null && changePct < 0
                            ? CoffeeColors.success
                            : CoffeeColors.caramel,
                      ),
                    ],

                    const Spacer(),
                    const Divider(height: 10, color: CoffeeColors.crema),

                    // ── Price area ────────────────────────────────
                    if (hasPrice) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'EN İYİ',
                                  style: TextStyle(
                                    color: CoffeeColors.cocoa,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                PriceText(price, size: 16),
                              ],
                            ),
                          ),
                          if (store != null) StoreBadge(store),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(Icons.people_alt_outlined,
                              size: 10, color: CoffeeColors.cocoa),
                          const SizedBox(width: 3),
                          Text(
                            '$entries kayıt',
                            style: const TextStyle(
                                color: CoffeeColors.cocoa,
                                fontSize: 10,
                                fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.storefront_outlined,
                              size: 10, color: CoffeeColors.cocoa),
                          const SizedBox(width: 3),
                          Text(
                            '$storeCount mkt',
                            style: const TextStyle(
                                color: CoffeeColors.cocoa,
                                fontSize: 10,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ] else ...[
                      // No-price CTA
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: CoffeeColors.caramel.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: CoffeeColors.caramel.withOpacity(0.3),
                                width: 1.5),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_circle_outline,
                                  color: CoffeeColors.caramel, size: 13),
                              SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  'İlk fiyatı ekle →',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: CoffeeColors.caramel,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyExplore extends StatelessWidget {
  const _EmptyExplore({required this.query});
  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: CoffeeColors.foam,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: CoffeeColors.crema),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.search_off,
                  color: CoffeeColors.caramel, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              query.isEmpty
                  ? 'Sonuç bulunamadı'
                  : '"$query" için sonuç yok',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: CoffeeColors.espresso,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Filtreyi değiştir ya da farklı kelime dene',
              textAlign: TextAlign.center,
              style: TextStyle(color: CoffeeColors.cocoa, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
