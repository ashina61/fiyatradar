import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/design.dart';
import '../../widgets/product_card.dart';
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

    DateTime? latest(Product p) {
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
          final la = latest(a);
          final lb = latest(b);
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
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Keşfet',
                          style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                              color: CoffeeColors.espresso)),
                      Text(
                        'Akıllı fiyat taraması',
                        style: TextStyle(
                          color: CoffeeColors.cocoa,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
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

          // ── Search ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Ürün, marka ara…',
                prefixIcon: const Icon(Icons.search,
                    color: CoffeeColors.cocoa),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close,
                            color: CoffeeColors.cocoa, size: 18),
                        onPressed: () => setState(() => _query = ''),
                      ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Signal strip ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(FR.radiusM),
                border: Border.all(color: CoffeeColors.crema),
              ),
              child: Row(
                children: [
                  _signalCell('${all.length}', 'sonuç',
                      Icons.inventory_2_outlined),
                  Container(
                      width: 1, height: 16, color: CoffeeColors.crema),
                  _signalCell(
                      '${stores.length}', 'market', Icons.storefront_outlined),
                  Container(
                      width: 1, height: 16, color: CoffeeColors.crema),
                  _signalCell(
                      '$fresh', 'taze', Icons.bolt_outlined),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // ── Categories ───────────────────────────────────────────
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
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: selected
                            ? CoffeeColors.cream
                            : CoffeeColors.darkRoast,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // ── Sort row ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
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
                    _SortMode.cheapest => 'En ucuz',
                    _SortMode.freshest => 'En taze',
                  };
                  return Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: GestureDetector(
                      onTap: () => setState(() => _sort = m),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected
                              ? CoffeeColors.caramel
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected
                                ? CoffeeColors.caramel
                                : CoffeeColors.crema,
                          ),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            color: selected
                                ? CoffeeColors.espresso
                                : CoffeeColors.darkRoast,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: filtered.isEmpty
                ? _EmptyExplore(query: _query)
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.66,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final p = filtered[i];
                      return ProductCard(
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
          const SizedBox(width: 5),
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
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyExplore extends StatelessWidget {
  const _EmptyExplore({required this.query});
  final String query;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: CoffeeColors.foam,
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.search_off,
                color: CoffeeColors.cocoa, size: 30),
          ),
          const SizedBox(height: 14),
          Text(
            query.isEmpty ? 'Sonuç bulunamadı' : '"$query" için sonuç yok',
            style: const TextStyle(
              color: CoffeeColors.espresso,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Filtreyi değiştir ya da farklı bir kelime dene',
            style: TextStyle(color: CoffeeColors.cocoa, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
