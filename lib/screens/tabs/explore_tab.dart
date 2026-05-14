import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../state/app_state.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import '../product_detail_screen.dart';

class ExploreTab extends StatefulWidget {
  const ExploreTab({super.key});

  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';
  String _category = 'Tümü';
  int _filter = 0;
  List<Product> _visibleProducts = const [];
  int _lastProductsVersion = -1;
  int _lastFavoritesVersion = -1;
  String _lastQuery = '';
  String _lastCategory = '';
  int _lastFilter = -1;

  static const _filters = ['Hepsi', 'Ucuzlayanlar', 'Yeni', 'Favoriler', 'Yakınımda'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = AppStateScope.of(context);
    final presetFilter = state.consumeExplorePresetFilter();
    final presetCategory = state.consumeExplorePresetCategory();
    if (presetFilter != null) _filter = presetFilter;
    if (presetCategory != null) _category = presetCategory;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Product> _filtered(AppState state) {
    Iterable<Product> list = state.products;
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list.where(
        (p) => p.name.toLowerCase().contains(q) || p.brand.toLowerCase().contains(q),
      );
    }
    if (_category != 'Tümü') {
      list = list.where((p) => p.category == _category);
    }
    if (_filter == 1) {
      list = list.where((p) => (p.priceChangePct ?? 0) < 0);
    } else if (_filter == 2) {
      list = list.toList()
        ..sort((a, b) {
          final ad = a.priceHistory.isEmpty
              ? DateTime(0)
              : a.priceHistory.last.date;
          final bd = b.priceHistory.isEmpty
              ? DateTime(0)
              : b.priceHistory.last.date;
          return bd.compareTo(ad);
        });
    } else if (_filter == 3) {
      list = list.where((p) => state.isFavorite(p.id));
    } else if (_filter == 4) {
      // "Yakınımda": only show products that have a recent regional report in
      // the user's selected city/district. Falls back to the AppState's
      // current scoped product ids (already filtered by region in
      // app_state.dart's `_bindRegionalPriceFeed`).
      final scoped = state.homeScopedProductIds;
      if (scoped.isEmpty) {
        list = const <Product>[];
      } else {
        list = list.where((p) => scoped.contains(p.id));
      }
    }
    return list.toList();
  }

  void _refreshVisibleIfNeeded(AppState state) {
    final unchanged = _lastProductsVersion == state.productsVersion &&
        _lastFavoritesVersion == state.favoritesVersion &&
        _lastQuery == _query &&
        _lastCategory == _category &&
        _lastFilter == _filter;
    if (unchanged) return;
    _visibleProducts = _filtered(state);
    _lastProductsVersion = state.productsVersion;
    _lastFavoritesVersion = state.favoritesVersion;
    _lastQuery = _query;
    _lastCategory = _category;
    _lastFilter = _filter;
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    _refreshVisibleIfNeeded(state);
    final products = _visibleProducts;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsetsDirectional.fromSTEB(FRSpace.xl, 14, FRSpace.xl, 0),
            child: FRPageHeader(
              overline: 'RADARDAKİ ÜRÜNLER',
              title: 'Keşfet',
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Text(
              'Binlerce market ürünü · topluluktan gerçek fiyatlar.',
              style: frText(13, FontWeight.w500, color: FR.ink3, height: 1.5),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: frSurface(radius: FRRad.l),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, color: FR.gold, size: 19),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onChanged: (v) => setState(() => _query = v),
                      style: frText(14, FontWeight.w600),
                      cursorColor: FR.gold,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isCollapsed: true,
                        hintText: 'Ürün, marka veya mağaza…',
                        hintStyle: frText(13, FontWeight.w600, color: FR.ink3),
                      ),
                    ),
                  ),
                  if (_query.isNotEmpty)
                    InkWell(
                      onTap: () {
                        _controller.clear();
                        setState(() => _query = '');
                      },
                      borderRadius: FRRad.all(10),
                      child: Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: FR.surfaceHi,
                          borderRadius: FRRad.all(10),
                          border: Border.all(color: FR.hairline),
                        ),
                        child: Icon(Icons.close_rounded,
                            color: FR.ink2, size: 17),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _filters.length,
              itemBuilder: (_, i) => FRFilterChip(
                _filters[i],
                active: i == _filter,
                onTap: () => setState(() => _filter = i),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: state.categories.length,
              itemBuilder: (_, i) {
                final c = state.categories[i];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => setState(() => _category = c),
                    borderRadius: FRRad.all(10),
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _category == c ? FR.gold.withOpacity(.14) : Colors.transparent,
                        borderRadius: FRRad.all(10),
                        border: Border.all(
                          color: _category == c ? FR.goldDeep : FR.hairline,
                        ),
                      ),
                      child: Text(
                        c,
                        style: frText(11.5, FontWeight.w700,
                            color: _category == c ? FR.gold : FR.ink2),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: products.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(30),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _filter == 4
                                ? Icons.location_off_outlined
                                : Icons.radar_rounded,
                            color: FR.ink3,
                            size: 36,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _filter == 4 &&
                                    ((state.cityName ?? '').trim().isEmpty ||
                                        (state.districtName ?? '')
                                            .trim()
                                            .isEmpty)
                                ? 'Bölgeni seç — yakınındaki ürünler bu listede görünür.'
                                : _filter == 4
                                    ? 'Bu bölgede henüz fiyat paylaşımı olan ürün yok.'
                                    : 'Radar bu filtrede ürün bulamadı.',
                            textAlign: TextAlign.center,
                            style: frText(13, FontWeight.w700, color: FR.ink3),
                          ),
                        ],
                      ),
                    ),
                  )
                : GridView.builder(
                    padding: EdgeInsets.fromLTRB(
                        20, 10, 20, frBottomScrollPadding(context)),
                    itemCount: products.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: .66,
                    ),
                    itemBuilder: (_, i) {
                      final p = products[i];
                      // Per-card fade-in is dropped — every cell was
                      // spinning up an AnimationController + delayed
                      // timer, which spiked frame times when the user
                      // scrolled fast through the catalog.
                      return _ExploreCard(
                        key: ValueKey('explore_${p.id}'),
                        product: p,
                        isFavorite: state.isFavorite(p.id),
                        onFavorite: () => state.toggleFavorite(p.id),
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
        ],
      ),
    );
  }
}

Widget _exploreCardEmojiFallback(String emoji) {
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [FR.surfaceHi, FR.surfaceLo],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Center(child: Text(emoji, style: const TextStyle(fontSize: 54))),
  );
}

class _ExploreCard extends StatelessWidget {
  const _ExploreCard({
    super.key,
    required this.product,
    required this.isFavorite,
    required this.onFavorite,
    required this.onTap,
  });
  final Product product;
  final bool isFavorite;
  final VoidCallback onFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pct = product.priceChangePct;
    return InkWell(
      onTap: onTap,
      borderRadius: FRRad.all(FRRad.xl),
      child: Container(
        decoration: frSurface(radius: FRRad.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(FRRad.xl),
                  ),
                  child: SizedBox(
                    height: 120,
                    width: double.infinity,
                    child: product.imageUrl != null &&
                            product.imageUrl!.isNotEmpty
                        ? Image.network(
                            product.imageUrl!,
                            fit: BoxFit.cover,
                            cacheWidth: 420,
                            cacheHeight: 420,
                            filterQuality: FilterQuality.medium,
                            frameBuilder: frFadeFrameBuilder,
                            errorBuilder: (_, __, ___) =>
                                _exploreCardEmojiFallback(product.emoji),
                          )
                        : _exploreCardEmojiFallback(product.emoji),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: InkWell(
                    onTap: onFavorite,
                    borderRadius: FRRad.all(999),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: FR.surface.withOpacity(FR.isDark ? .62 : .9),
                        shape: BoxShape.circle,
                        border: Border.all(color: FR.hairline),
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        size: 14,
                        color: isFavorite ? FR.bad : FR.ink2,
                      ),
                    ),
                  ),
                ),
                if (pct != null)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: FRTrendPill(pct: pct, dense: true),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.category.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: frOverline(color: FR.ink3, size: 9)),
                  const SizedBox(height: 4),
                  Text(product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: frText(12.5, FontWeight.w800, height: 1.25)),
                  const SizedBox(height: 6),
                  FRPriceText(product.lowestPrice, size: 21, color: FR.gold),
                  Text(
                    '${product.brand} · ${product.unit}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: frText(11, FontWeight.w600, color: FR.ink3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
