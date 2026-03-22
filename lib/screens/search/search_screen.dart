import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/category_model.dart';
import '../../models/product_model.dart';
import '../../models/store_model.dart';
import '../../models/user_model.dart';
import '../../providers/actual_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/explore_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/user_provider.dart';
import '../actual/actuals_screen.dart';
import '../add_price/add_price_screen.dart';
import '../product/product_detail_screen.dart';

const _bg = Color(0xFFEDEAE3);
const _dk = Color(0xFF18100A);
const _w = Color(0xFFFAFAF8);
const _tan = Color(0xFFB08848);
const _tc = Color(0xFFBF9470);
const _tcl = Color(0xFFD0A882);
const _grn = Color(0xFF27A85A);
const _red = Color(0xFFE53935);
const _t1 = Color(0xFF18100A);
const _t2 = Color(0xFF5E4A38);
const _t3 = Color(0xFFA0887A);
const _s2 = Color(0xFFF5F0E8);

TextStyle _txt({
  double size = 14,
  FontWeight weight = FontWeight.w500,
  Color color = _t1,
  double? height,
  FontStyle? fontStyle,
  double? letterSpacing,
}) {
  return GoogleFonts.plusJakartaSans(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    fontStyle: fontStyle,
    letterSpacing: letterSpacing,
  );
}

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final Set<String> _favoriteIds = <String>{};
  String _selectedCategory = 'Tumu';
  String _selectedMarket = 'Tümü';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exploreState = ref.watch(exploreControllerProvider);
    final categories = ref.watch(orderedCategoriesProvider);
    final nearbyStores = ref.watch(nearbyStoresProvider).valueOrNull ?? const <StoreModel>[];
    final user = ref.watch(userModelStreamProvider).valueOrNull;
    final activeActual = ref.watch(latestActiveActualProvider).valueOrNull;
    ref.watch(authStateProvider);

    final locationLabel = _resolveLocation(user, nearbyStores);
    final products = _visibleItems(exploreState.items);
    final marketFilters = _marketFilters(exploreState.items);
    final categoryTabs = _categoryTabs(exploreState);
    final categoryIcons = _categoryTiles(categories);
    final campaignDuration = _campaignDuration(activeActual?.endDate);

    return Scaffold(
      backgroundColor: _bg,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _dk,
        foregroundColor: _w,
        elevation: 4,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const AddPriceScreen()),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: Text('Fiyat Ekle', style: _txt(size: 13, weight: FontWeight.w800, color: _w)),
      ),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(locationLabel)),
            SliverToBoxAdapter(child: _RadarHero(totalItems: exploreState.items.length)),
            SliverToBoxAdapter(child: _buildCategoryTabs(categoryTabs)),
            SliverToBoxAdapter(child: _buildSectionTitle('Ürünler')),
            SliverToBoxAdapter(child: _buildMarketTabs(marketFilters)),
            if (exploreState.loading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator(color: _tc)),
                ),
              )
            else if (exploreState.error != null)
              SliverToBoxAdapter(child: _StatusCard(title: 'Keşfet yüklenemedi', subtitle: exploreState.error!))
            else if (products.isEmpty)
              const SliverToBoxAdapter(
                child: _StatusCard(
                  title: 'Ürün bulunamadı',
                  subtitle: 'Arama, kategori veya market seçimini değiştirerek tekrar deneyin.',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = products[index];
                      return _ProductCard(
                        item: item,
                        isFavorite: _favoriteIds.contains(item.product.id),
                        onFavorite: () {
                          setState(() {
                            if (!_favoriteIds.add(item.product.id)) {
                              _favoriteIds.remove(item.product.id);
                            }
                          });
                        },
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => ProductDetailScreen(productId: item.product.id),
                            ),
                          );
                        },
                      );
                    },
                    childCount: products.length > 6 ? 6 : products.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.56,
                  ),
                ),
              ),
            SliverToBoxAdapter(child: _buildSectionTitle('Kampanya Sayacı')),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: _CampaignCard(
                  days: campaignDuration.$1,
                  hours: campaignDuration.$2,
                  onTap: activeActual == null
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(builder: (_) => const ActualsScreen()),
                          );
                        },
                ),
              ),
            ),
            SliverToBoxAdapter(child: _buildSectionTitle('Kategoriler')),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: _CategoryIconGrid(items: categoryIcons),
              ),
            ),
            SliverToBoxAdapter(child: _buildSectionTitle('Yakın Marketler')),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 36),
                child: _NearbyMarkets(locationLabel: locationLabel, stores: _nearbyTiles(nearbyStores, products)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String locationLabel) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
      decoration: const BoxDecoration(
        color: _dk,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(24, 16, 10, 0.10),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_t2, _tan],
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      child: const Icon(Icons.radar_rounded, color: _w, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('FiyatRadar', style: _txt(size: 11, weight: FontWeight.w700, color: _tcl)),
                        RichText(
                          text: TextSpan(
                            style: _txt(size: 22, weight: FontWeight.w900, color: _w, height: 1.1),
                            children: [
                              const TextSpan(text: 'Keşfet '),
                              TextSpan(text: '&', style: _txt(size: 22, weight: FontWeight.w900, color: _tc, fontStyle: FontStyle.italic)),
                              const TextSpan(text: ' Karşılaştır'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _tc.withOpacity(0.20)),
                ),
                child: Text(locationLabel, style: _txt(size: 12, weight: FontWeight.w700, color: _tcl)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: _w,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => ref.read(exploreControllerProvider.notifier).updateSearchQuery(value),
              style: _txt(size: 14, weight: FontWeight.w600, color: _t1),
              decoration: InputDecoration(
                hintText: 'Ürün, marka veya mağaza ara...',
                hintStyle: _txt(size: 14, color: _t3),
                prefixIcon: const Icon(Icons.search_rounded, color: _t3, size: 20),
                suffixIcon: IconButton(
                  onPressed: () {
                    _searchController.clear();
                    ref.read(exploreControllerProvider.notifier).updateSearchQuery('');
                  },
                  icon: const Icon(Icons.tune_rounded, color: _dk, size: 18),
                ),
                contentPadding: const EdgeInsets.fromLTRB(0, 12, 16, 12),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(List<String> tabs) {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final raw = tabs[index];
          final key = raw == 'Tümü' ? 'Tumu' : raw;
          final selected = _selectedCategory == key;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedCategory = key);
              ref.read(exploreControllerProvider.notifier).updateCategory(key);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? _dk : _w,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: selected ? _dk : _dk.withOpacity(0.08)),
              ),
              child: Center(
                child: Text(raw, style: _txt(size: 13, weight: FontWeight.w800, color: selected ? _w : _t2)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
      child: Text(title, style: _txt(size: 18, weight: FontWeight.w900, color: _t1)),
    );
  }

  Widget _buildMarketTabs(List<String> filters) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final label = filters[index];
          final selected = _selectedMarket == label;
          return GestureDetector(
            onTap: () => setState(() => _selectedMarket = label),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? _dk : _w,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: selected ? _dk : _dk.withOpacity(0.08)),
              ),
              child: Center(
                child: Text(label, style: _txt(size: 12, weight: FontWeight.w800, color: selected ? _w : _t2)),
              ),
            ),
          );
        },
      ),
    );
  }

  List<ExploreFeedItem> _visibleItems(List<ExploreFeedItem> items) {
    return items.where((item) {
      final marketMatch = _selectedMarket == 'Tümü' || item.storeName.toLowerCase() == _selectedMarket.toLowerCase();
      final categoryMatch = _selectedCategory == 'Tumu' || item.product.categories.any((category) => category.toLowerCase() == _selectedCategory.toLowerCase());
      return marketMatch && categoryMatch;
    }).toList();
  }

  List<String> _categoryTabs(ExploreState state) {
    final values = <String>{'Tümü'};
    values.addAll(state.categories.where((e) => e != 'Tumu'));
    return values.take(6).toList();
  }

  List<String> _marketFilters(List<ExploreFeedItem> items) {
    final values = <String>{'Tümü'};
    for (final item in items) {
      final name = item.storeName.trim();
      if (name.isNotEmpty) values.add(name);
    }
    return values.take(6).toList();
  }

  List<_CategoryTileData> _categoryTiles(List<CategoryModel> categories) {
    final source = categories.take(8).map((category) {
      return _CategoryTileData(
        label: category.title,
        icon: _categoryIcon(category.title),
      );
    }).toList();

    if (source.isNotEmpty) return source;
    return const [
      _CategoryTileData(label: 'Gıda', icon: Icons.restaurant_rounded),
      _CategoryTileData(label: 'Bakım', icon: Icons.spa_rounded),
      _CategoryTileData(label: 'Temizlik', icon: Icons.local_laundry_service_rounded),
      _CategoryTileData(label: 'İçecek', icon: Icons.local_drink_rounded),
    ];
  }

  List<_NearbyTileData> _nearbyTiles(List<StoreModel> stores, List<ExploreFeedItem> items) {
    final list = <_NearbyTileData>[];
    for (final store in stores.take(4)) {
      list.add(_NearbyTileData(
        badge: store.displayName.isEmpty ? '?' : store.displayName.characters.first.toUpperCase(),
        name: store.displayName,
        subtitle: store.neighborhood.isNotEmpty ? store.neighborhood : store.district,
      ));
    }
    if (list.isNotEmpty) return list;
    for (final item in items.take(4)) {
      final name = item.storeName;
      list.add(_NearbyTileData(
        badge: name.characters.first.toUpperCase(),
        name: name,
        subtitle: item.distanceLabel ?? item.locationLabel,
      ));
    }
    if (list.isNotEmpty) return list;
    return const [_NearbyTileData(badge: 'A', name: 'A-101', subtitle: 'Yakında mağaza yok')];
  }

  String _resolveLocation(UserModel? user, List<StoreModel> stores) {
    final hood = user?.neighborhood?.trim();
    if (hood != null && hood.isNotEmpty) return hood;
    final city = user?.city?.trim();
    if (city != null && city.isNotEmpty) return city;
    if (stores.isNotEmpty && stores.first.district.isNotEmpty) return stores.first.district;
    return 'Çekmeköy';
  }

  (String, String) _campaignDuration(DateTime? endDate) {
    if (endDate == null) return ('02', '14');
    final diff = endDate.difference(DateTime.now());
    final days = diff.isNegative ? 0 : diff.inDays;
    final hours = diff.isNegative ? 0 : diff.inHours.remainder(24);
    return (days.toString().padLeft(2, '0'), hours.toString().padLeft(2, '0'));
  }
}

class _RadarHero extends StatelessWidget {
  const _RadarHero({required this.totalItems});

  final int totalItems;

  @override
  Widget build(BuildContext context) {
    final updated = totalItems == 0 ? 1240 : totalItems * 31;
    final drops = (updated * 0.65).round();
    final rises = updated - drops;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: _dk,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _tc.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 6, height: 6, decoration: const BoxDecoration(color: _grn, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text('Canlı Takip', style: _txt(size: 12, weight: FontWeight.w800, color: _w)),
            ],
          ),
          const SizedBox(height: 14),
          RichText(
            text: TextSpan(
              style: _txt(size: 42, weight: FontWeight.w900, color: _w, height: 1),
              children: [
                TextSpan(text: _formatNumber(updated)),
                TextSpan(text: ' fiyat', style: _txt(size: 18, weight: FontWeight.w800, color: _tc)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text('bugün güncellendi', style: _txt(size: 13, weight: FontWeight.w600, color: _tcl)),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _StatPill(value: '$drops', label: 'düşen', color: _grn)),
              const SizedBox(width: 10),
              Expanded(child: _StatPill(value: '$rises', label: 'yükselen', color: _red)),
            ],
          ),
        ],
      ),
    );
  }

  String _formatNumber(int value) {
    final text = value.toString();
    if (text.length <= 3) return text;
    final head = text.substring(0, text.length - 3);
    final tail = text.substring(text.length - 3);
    return '$head.$tail';
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.value, required this.label, required this.color});

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _tc.withOpacity(0.10)),
      ),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: _txt(size: 16, weight: FontWeight.w900, color: _w)),
              Text(label, style: _txt(size: 11, weight: FontWeight.w700, color: _tcl)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.item,
    required this.isFavorite,
    required this.onFavorite,
    required this.onTap,
  });

  final ExploreFeedItem item;
  final bool isFavorite;
  final VoidCallback onFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final priceDiff = (item.priceChangePercent ?? item.dropPercent).abs().round();
    final isUp = (item.priceChangePercent ?? item.dropPercent) > 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: _w,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _dk.withOpacity(0.07)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: const BoxDecoration(
                    color: _s2,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 0,
                        left: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: (isUp ? _red : _grn).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text('%$priceDiff', style: _txt(size: 9, weight: FontWeight.w900, color: isUp ? _red : _grn)),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: InkWell(
                          onTap: onFavorite,
                          borderRadius: BorderRadius.circular(99),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.90),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: _dk, size: 16),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: ColorFiltered(
                            colorFilter: const ColorFilter.mode(_s2, BlendMode.multiply),
                            child: _ProductImage(product: item.product),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 11, 12, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.product.brand.toUpperCase(), style: _txt(size: 9, weight: FontWeight.w800, color: _tc, letterSpacing: 0.4)),
                    const SizedBox(height: 4),
                    Text(item.product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: _txt(size: 13, weight: FontWeight.w800, color: _t1, height: 1.3)),
                    const SizedBox(height: 8),
                    Text('${item.displayPrice.toStringAsFixed(2).replaceAll('.', ',')}₺', style: _txt(size: 20, weight: FontWeight.w900, color: _t1)),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Row(
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: _tc, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Expanded(child: Text(item.storeName, overflow: TextOverflow.ellipsis, style: _txt(size: 11, weight: FontWeight.w800, color: _t2))),
                    const SizedBox(width: 6),
                    Text(item.distanceLabel ?? item.locationLabel, style: _txt(size: 11, weight: FontWeight.w700, color: _t3)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.mainImage ?? product.imageUrl ?? product.imageMediumUrl ?? product.imageThumbUrl;
    if (imageUrl == null || imageUrl.isEmpty) {
      return const Center(child: Icon(Icons.inventory_2_rounded, size: 56, color: _tan));
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image_rounded, size: 56, color: _tan)),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(child: CircularProgressIndicator(color: _tc, strokeWidth: 2));
      },
    );
  }
}

class _CampaignCard extends StatelessWidget {
  const _CampaignCard({required this.days, required this.hours, this.onTap});

  final String days;
  final String hours;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: _dk, borderRadius: BorderRadius.circular(22)),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(color: _tc.withOpacity(0.15), borderRadius: BorderRadius.circular(7)),
                      child: Text('BİM Aktüeli', style: _txt(size: 11, weight: FontWeight.w800, color: _tcl)),
                    ),
                    const SizedBox(height: 12),
                    RichText(
                      text: TextSpan(
                        style: _txt(size: 18, weight: FontWeight.w900, color: _w, height: 1.2),
                        children: [
                          const TextSpan(text: 'Haftalık Fırsatlar\n'),
                          TextSpan(text: 'Bitiyor!', style: _txt(size: 18, weight: FontWeight.w900, color: _tc, fontStyle: FontStyle.italic)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onTap,
                style: TextButton.styleFrom(
                  backgroundColor: _w,
                  foregroundColor: _dk,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                child: Text('Kataloğu Gör', style: _txt(size: 12, weight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _CountdownBlock(number: days, unit: 'Gün'),
              const SizedBox(width: 10),
              _CountdownBlock(number: hours, unit: 'Saat'),
            ],
          ),
        ],
      ),
    );
  }
}

class _CountdownBlock extends StatelessWidget {
  const _CountdownBlock({required this.number, required this.unit});

  final String number;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: _tc.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(number, style: _txt(size: 19, weight: FontWeight.w900, color: _w)),
          Text(unit, style: _txt(size: 11, weight: FontWeight.w700, color: _tcl)),
        ],
      ),
    );
  }
}

class _CategoryIconGrid extends StatelessWidget {
  const _CategoryIconGrid({required this.items});

  final List<_CategoryTileData> items;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.92,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          padding: const EdgeInsets.fromLTRB(6, 12, 6, 10),
          decoration: BoxDecoration(
            color: _w,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _dk.withOpacity(0.06)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: _tc.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(item.icon, color: _tc, size: 18),
              ),
              const SizedBox(height: 10),
              Text(item.label, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: _txt(size: 9, weight: FontWeight.w800, color: _t2)),
            ],
          ),
        );
      },
    );
  }
}

class _NearbyMarkets extends StatelessWidget {
  const _NearbyMarkets({required this.locationLabel, required this.stores});

  final String locationLabel;
  final List<_NearbyTileData> stores;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _dk, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$locationLabel, İstanbul', style: _txt(size: 13, weight: FontWeight.w800, color: _w)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: stores.map((store) {
              return Container(
                width: 146,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: _tc.withOpacity(0.16), borderRadius: BorderRadius.circular(10)),
                      child: Text(store.badge, style: _txt(size: 13, weight: FontWeight.w900, color: _tc)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(store.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: _txt(size: 12, weight: FontWeight.w800, color: _w)),
                          Text(store.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: _txt(size: 10, weight: FontWeight.w700, color: _tcl)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: _w, borderRadius: BorderRadius.circular(18), border: Border.all(color: _dk.withOpacity(0.06))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: _txt(size: 15, weight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(subtitle, style: _txt(size: 12, weight: FontWeight.w600, color: _t2, height: 1.5)),
          ],
        ),
      ),
    );
  }
}

class _CategoryTileData {
  const _CategoryTileData({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class _NearbyTileData {
  const _NearbyTileData({required this.badge, required this.name, required this.subtitle});

  final String badge;
  final String name;
  final String subtitle;
}

IconData _categoryIcon(String label) {
  switch (label.toLowerCase()) {
    case 'gıda':
      return Icons.restaurant_menu_rounded;
    case 'bakım':
      return Icons.spa_outlined;
    case 'temizlik':
      return Icons.cleaning_services_rounded;
    case 'içecek':
      return Icons.local_drink_outlined;
    case 'atıştırmalık':
      return Icons.cookie_outlined;
    case 'ev':
      return Icons.chair_outlined;
    default:
      return Icons.grid_view_rounded;
  }
}
