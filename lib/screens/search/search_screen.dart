import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  return TextStyle(
    fontFamily: 'Outfit',
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    fontStyle: fontStyle,
    letterSpacing: letterSpacing,
  );
}

TextStyle _serif({
  double size = 18,
  FontWeight weight = FontWeight.w400,
  Color color = _t1,
  double? height,
  FontStyle? fontStyle,
  double? letterSpacing,
}) {
  return TextStyle(
    fontFamily: 'Outfit',
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
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _overlayController = TextEditingController();
  final FocusNode _overlayFocusNode = FocusNode();
  final Set<String> _favoriteIds = <String>{};
  final List<String> _recentSearches = <String>['Ariel 4kg', 'Nutella 400g'];
  bool _overlayOpen = false;
  String _selectedCategory = 'Tumu';
  String _selectedMarket = 'Tümü';
  bool _showAllProducts = false;
  bool _showAllDrops = false;
  bool _showAllCategories = false;
  String _feedMode = 'drops';
  Timer? _countdownTimer;
  Duration _campaignRemaining = Duration.zero;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _searchController.dispose();
    _overlayController.dispose();
    _overlayFocusNode.dispose();
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

    _syncCountdown(activeActual?.endDate);

    final locationLabel = _resolveLocation(user, nearbyStores, exploreState.userLocation);
    final visibleProducts = _visibleItems(exploreState.items);
    final prioritizedProducts = _prioritizeByFeedMode(visibleProducts, _feedMode);
    final categoryTabs = _categoryTabs(exploreState);
    final marketFilters = _marketFilters(exploreState.items);
    final categoryTiles = _categoryTiles(categories);
    final featuredProducts = _featuredProducts(visibleProducts, exploreState.items);
    final personalProducts = _personalizedProducts(visibleProducts, user);
    final nearbyTiles = _nearbyTiles(nearbyStores, visibleProducts.isNotEmpty ? visibleProducts : exploreState.items);
    final trendingSearches = _trendingSearches(exploreState.items);
    final stats = _heroStats(exploreState.items);
    final alertItems = _trackedAlerts(visibleProducts, user);

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
        child: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(locationLabel)),
                SliverToBoxAdapter(child: _RadarHero(stats: stats)),
                SliverToBoxAdapter(child: _buildCategoryTabs(categoryTabs)),
                SliverToBoxAdapter(
                  child: _SectionHeader(
                    title: 'Ürünler',
                    tag: '${marketFilters.length - 1} market',
                    actionLabel: 'Tümünü Gör',
                    onActionTap: () => setState(() => _showAllProducts = true),
                  ),
                ),
                SliverToBoxAdapter(child: _buildMarketTabs(marketFilters)),
                if (exploreState.loading)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator(color: _tc)),
                    ),
                  )
                else if (exploreState.error != null)
                  SliverToBoxAdapter(
                    child: _StatusCard(title: 'Keşfet yüklenemedi', subtitle: exploreState.error!),
                  )
                else if (prioritizedProducts.isEmpty)
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
                          final item = prioritizedProducts[index];
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
                        childCount: _showAllProducts ? prioritizedProducts.length : math.min(prioritizedProducts.length, 6),
                      ),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 0.54,
                      ),
                    ),
                  ),
                SliverToBoxAdapter(child: const _SectionHeader(title: 'Kampanya Sayacı')),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _CampaignCard(
                      remaining: _campaignRemaining,
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
                if (featuredProducts.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: const _SectionHeader(
                      title: 'Fiyatı Düşenler',
                      tag: 'bu hafta',
                      actionLabel: 'Tümü',
                      onActionTap: () => setState(() => _showAllDrops = true),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 238,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, index) => _FeaturedCard(item: featuredProducts[index]),
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemCount: _showAllDrops ? featuredProducts.length : math.min(featuredProducts.length, 4),
                      ),
                    ),
                  ),
                ],
                if (personalProducts.isNotEmpty) ...[
                  const SliverToBoxAdapter(
                    child: _SectionHeader(title: 'Sana Özel Seçimler', tag: 'kişisel'),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 238,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, index) => _FeaturedCard(item: personalProducts[index], personalized: true),
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemCount: math.min(personalProducts.length, 8),
                      ),
                    ),
                  ),
                ],
                SliverToBoxAdapter(
                  child: _SectionHeader(
                    title: 'Kategoriler',
                    actionLabel: 'Tümü',
                    onActionTap: () => setState(() => _showAllCategories = true),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _CategoryGrid(items: _showAllCategories ? categoryTiles : categoryTiles.take(8).toList()),
                  ),
                ),
                SliverToBoxAdapter(
                  child: const Padding(
                    padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Bildirimler', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: _t1)),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: _AlertCard(
                      alertItems: alertItems,
                      onTap: () {
                        if (alertItems.isNotEmpty) {
                          _applySearch(alertItems.first.product.name);
                          return;
                        }
                        _openOverlay();
                      },
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: const _SectionHeader(title: 'Yakın Marketler')),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _NearbyMarkets(locationLabel: locationLabel, stores: nearbyTiles),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: _BarcodeCard(onTap: _openOverlay),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: _AddPriceBanner(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => const AddPriceScreen()),
                        );
                      },
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
            _SearchOverlay(
              open: _overlayOpen,
              controller: _overlayController,
              focusNode: _overlayFocusNode,
              trendingSearches: trendingSearches,
              recentSearches: _recentSearches,
              onClose: _closeOverlay,
              onPick: _applySearch,
              onRemoveRecent: (value) {
                setState(() => _recentSearches.remove(value));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String locationLabel) {
    return Container(
      decoration: const BoxDecoration(
        color: _dk,
        borderRadius: BorderRadius.vertical(bottom: Radius.elliptical(240, 42)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: Text('Keşfet', style: _txt(size: 24, weight: FontWeight.w800, color: _w))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: _tc.withOpacity(0.20)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on_outlined, size: 10, color: _tc),
                      const SizedBox(width: 4),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 90),
                        child: Text(locationLabel, overflow: TextOverflow.ellipsis, style: _txt(size: 11, weight: FontWeight.w700, color: _tcl)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _openOverlay,
              child: AbsorbPointer(
                child: Container(
                  decoration: BoxDecoration(color: _w, borderRadius: BorderRadius.circular(14)),
                  child: TextField(
                    controller: _searchController,
                    style: _txt(size: 13, weight: FontWeight.w600, color: _t1),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Ürün, marka veya mağaza ara...',
                      hintStyle: _txt(size: 13, color: _t3, fontStyle: FontStyle.italic),
                      prefixIcon: const Icon(Icons.search_rounded, size: 16, color: _t3),
                      suffixIcon: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Container(
                          decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(9)),
                          child: const Icon(Icons.qr_code_2_rounded, size: 16, color: _dk),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _QuickFeedRow(
              selectedKey: _feedMode,
              onChanged: (value) => setState(() => _feedMode = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTabs(List<_CategoryTabData> tabs) {
    return SizedBox(
      height: 58,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final selected = tab.key == _selectedCategory;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedCategory = tab.key);
              ref.read(exploreControllerProvider.notifier).updateCategory(tab.key);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? _dk : _w,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: selected ? _dk : _dk.withOpacity(0.10)),
                boxShadow: selected
                    ? const [BoxShadow(color: Color.fromRGBO(28, 17, 8, 0.15), blurRadius: 16, offset: Offset(0, 4))]
                    : null,
              ),
              child: Row(
                children: [
                  Icon(tab.icon, size: 13, color: selected ? _w : _t3),
                  const SizedBox(width: 6),
                  Text(tab.label, style: _txt(size: 12, weight: FontWeight.w700, color: selected ? _w : _t2)),
                ],
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: tabs.length,
      ),
    );
  }

  Widget _buildMarketTabs(List<_MarketFilterData> filters) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final selected = filter.label == _selectedMarket;
          return GestureDetector(
            onTap: () => setState(() => _selectedMarket = filter.label),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? _dk : _w,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: selected ? _dk : _dk.withOpacity(0.10)),
                boxShadow: selected
                    ? const [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.15), blurRadius: 12, offset: Offset(0, 4))]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (filter.color != null) ...[
                    Container(width: 6, height: 6, decoration: BoxDecoration(color: filter.color, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                  ],
                  Text(filter.label, style: _txt(size: 11, weight: FontWeight.w700, color: selected ? _w : _t2)),
                ],
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 7),
        itemCount: filters.length,
      ),
    );
  }

  void _openOverlay() {
    setState(() => _overlayOpen = true);
    _overlayController.text = _searchController.text;
    WidgetsBinding.instance.addPostFrameCallback((_) => _overlayFocusNode.requestFocus());
  }

  void _closeOverlay() {
    setState(() => _overlayOpen = false);
    _overlayController.clear();
    _overlayFocusNode.unfocus();
  }

  void _applySearch(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return;
    _searchController.text = normalized;
    _overlayController.text = normalized;
    ref.read(exploreControllerProvider.notifier).updateSearchQuery(normalized);
    setState(() {
      _recentSearches.remove(normalized);
      _recentSearches.insert(0, normalized);
      if (_recentSearches.length > 5) {
        _recentSearches.removeRange(5, _recentSearches.length);
      }
      _overlayOpen = false;
    });
    _overlayFocusNode.unfocus();
  }

  void _syncCountdown(DateTime? endDate) {
    final target = endDate ?? _nextSunday();
    final next = target.difference(DateTime.now());
    final safe = next.isNegative ? Duration.zero : next;
    if (_campaignRemaining != safe) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _campaignRemaining = safe);
      });
    }
    _countdownTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final diff = target.difference(DateTime.now());
      setState(() => _campaignRemaining = diff.isNegative ? Duration.zero : diff);
    });
  }

  DateTime _nextSunday() {
    final now = DateTime.now();
    final daysUntilSunday = ((7 - now.weekday) % 7 == 0) ? 7 : (7 - now.weekday) % 7;
    return DateTime(now.year, now.month, now.day + daysUntilSunday, 23, 59, 59);
  }

  List<ExploreFeedItem> _visibleItems(List<ExploreFeedItem> items) {
    return items.where((item) {
      final marketMatch = _selectedMarket == 'Tümü' || item.storeName.toLowerCase() == _selectedMarket.toLowerCase();
      final categoryMatch = _selectedCategory == 'Tumu' || item.product.categories.any((category) => category.toLowerCase() == _selectedCategory.toLowerCase());
      return marketMatch && categoryMatch;
    }).toList();
  }

  List<_CategoryTabData> _categoryTabs(ExploreState state) {
    final values = <String>{'Tümü'}..addAll(state.categories.where((e) => e != 'Tumu'));
    return values.take(6).map((label) {
      final key = label == 'Tümü' ? 'Tumu' : label;
      return _CategoryTabData(label: label, key: key, icon: _categoryIcon(label));
    }).toList();
  }

  List<_MarketFilterData> _marketFilters(List<ExploreFeedItem> items) {
    final values = <String>{'Tümü'};
    for (final item in items) {
      final name = item.storeName.trim();
      if (name.isNotEmpty) values.add(name);
    }
    return values.take(6).map((label) => _MarketFilterData(label: label, color: _marketColor(label))).toList();
  }

  List<_CategoryTileData> _categoryTiles(List<CategoryModel> categories) {
    final source = categories.take(8).map((category) {
      return _CategoryTileData(label: category.title, icon: _categoryIcon(category.title));
    }).toList();

    if (source.isNotEmpty) return source;
    return const [
      _CategoryTileData(label: 'Gıda', icon: Icons.restaurant_rounded),
      _CategoryTileData(label: 'Bakım', icon: Icons.favorite_outline_rounded),
      _CategoryTileData(label: 'Ev', icon: Icons.home_outlined),
      _CategoryTileData(label: 'Elektronik', icon: Icons.computer_outlined),
      _CategoryTileData(label: 'Giyim', icon: Icons.checkroom_outlined),
      _CategoryTileData(label: 'Kitap', icon: Icons.menu_book_outlined),
      _CategoryTileData(label: 'Spor', icon: Icons.sports_basketball_outlined),
      _CategoryTileData(label: 'Otomotiv', icon: Icons.local_shipping_outlined),
    ];
  }

  List<_NearbyTileData> _nearbyTiles(List<StoreModel> stores, List<ExploreFeedItem> items) {
    final list = <_NearbyTileData>[];
    for (final store in stores.take(5)) {
      final label = store.displayName.trim();
      if (label.isEmpty) continue;
      list.add(_NearbyTileData(
        badge: label.characters.first.toUpperCase(),
        name: label,
        subtitle: store.neighborhood.isNotEmpty ? store.neighborhood : (store.district.isNotEmpty ? store.district : 'Yakında'),
        color: _marketColor(label) ?? _tc,
      ));
    }
    if (list.isNotEmpty) return list;
    for (final item in items.take(5)) {
      list.add(_NearbyTileData(
        badge: item.storeName.characters.first.toUpperCase(),
        name: item.storeName,
        subtitle: item.distanceLabel ?? item.locationLabel,
        color: _marketColor(item.storeName) ?? _tc,
      ));
    }
    return list;
  }

  String _resolveLocation(UserModel? user, List<StoreModel> stores, dynamic location) {
    if (location != null) {
      final lat = location.latitude;
      final lng = location.longitude;
      if (lat is double && lng is double) {
        return '${lat.toStringAsFixed(2)}, ${lng.toStringAsFixed(2)}';
      }
    }
    final hood = user?.neighborhood?.trim();
    if (hood != null && hood.isNotEmpty) return hood;
    final city = user?.city?.trim();
    if (city != null && city.isNotEmpty) return city;
    if (stores.isNotEmpty && stores.first.district.isNotEmpty) return stores.first.district;
    return 'Çekmeköy';
  }

  List<ExploreFeedItem> _prioritizeByFeedMode(List<ExploreFeedItem> items, String mode) {
    final sorted = [...items];
    if (mode == 'movement') {
      sorted.sort((a, b) => (b.priceChangePercent ?? 0).abs().compareTo((a.priceChangePercent ?? 0).abs()));
    } else if (mode == 'personal') {
      sorted.sort((a, b) => (b.product.viewCount + b.product.priceEntryCount).compareTo(a.product.viewCount + a.product.priceEntryCount));
    } else {
      sorted.sort((a, b) => b.dropPercent.abs().compareTo(a.dropPercent.abs()));
    }
    return sorted;
  }

  List<ExploreFeedItem> _personalizedProducts(List<ExploreFeedItem> items, UserModel? user) {
    final saved = user?.savedProducts.toSet() ?? const <String>{};
    final preferred = items.where((e) => saved.contains(e.product.id)).toList();
    if (preferred.isNotEmpty) return preferred;
    final sorted = [...items]..sort((a, b) => b.product.viewCount.compareTo(a.product.viewCount));
    return sorted.take(6).toList();
  }

  List<ExploreFeedItem> _trackedAlerts(List<ExploreFeedItem> items, UserModel? user) {
    final saved = user?.savedProducts.toSet() ?? const <String>{};
    return items
        .where((e) => saved.contains(e.product.id))
        .where((e) => (e.priceChangePercent ?? -e.dropPercent).abs() > 0)
        .take(2)
        .toList();
  }

  List<ExploreFeedItem> _featuredProducts(List<ExploreFeedItem> visible, List<ExploreFeedItem> all) {
    final source = (visible.isNotEmpty ? visible : all).toList()
      ..sort((a, b) => (b.dropPercent.abs()).compareTo(a.dropPercent.abs()));
    return source.take(4).toList();
  }

  List<String> _trendingSearches(List<ExploreFeedItem> items) {
    final labels = <String>[];
    for (final item in items.take(5)) {
      labels.add(item.product.brand.isNotEmpty ? item.product.brand : item.product.name);
    }
    if (labels.isNotEmpty) return labels;
    return const ['Nutella', 'Zeytinyağı', 'Ariel deterjan', 'Coca-Cola', 'Nescafé'];
  }

  _HeroStats _heroStats(List<ExploreFeedItem> items) {
    final total = items.isEmpty ? 1240 : math.max(items.length * 31, 1240);
    final drops = items.where((e) => (e.priceChangePercent ?? -e.dropPercent) <= 0).length;
    final rising = items.where((e) => (e.priceChangePercent ?? -e.dropPercent) > 0).length;
    return _HeroStats(
      total: total,
      drops: drops == 0 ? (total * .65).round() : drops,
      rises: rising == 0 ? total - ((total * .65).round()) : rising,
    );
  }
}

class _HeroStats {
  const _HeroStats({required this.total, required this.drops, required this.rises});

  final int total;
  final int drops;
  final int rises;
}

class _RadarHero extends StatelessWidget {
  const _RadarHero({required this.stats});

  final _HeroStats stats;

  @override
  Widget build(BuildContext context) {
    return AnimatedRadarHero(
      total: stats.total,
      drops: stats.drops,
      rises: stats.rises,
    );
  }
}

class AnimatedRadarHero extends StatefulWidget {
  const AnimatedRadarHero({
    super.key,
    required this.total,
    required this.drops,
    required this.rises,
  });

  final int total;
  final int drops;
  final int rises;

  @override
  State<AnimatedRadarHero> createState() => _AnimatedRadarHeroState();
}

class _AnimatedRadarHeroState extends State<AnimatedRadarHero> with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _ringController;
  late final AnimationController _sweepController;
  late final Animation<double> _pulseSpread;
  late final Animation<double> _pulseAlpha;
  late final Animation<double> _sweepTurns;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _pulseSpread = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: 8), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 8, end: 0), weight: 50),
    ]).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _pulseAlpha = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: .6, end: 0), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: .6), weight: 50),
    ]).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _ringController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _sweepController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _sweepTurns = Tween<double>(begin: 0, end: 1).animate(_sweepController);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _ringController.dispose();
    _sweepController.dispose();
    super.dispose();
  }

  String _formatNumber(int value) {
    final text = value.toString();
    if (text.length <= 3) return text;
    return '${text.substring(0, text.length - 3)}.${text.substring(text.length - 3)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        color: const Color(0xFF18100A),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _tc.withOpacity(0.15)),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.82, 0),
                    radius: 0.9,
                    colors: [
                      _tc.withOpacity(0.15),
                      Colors.transparent,
                    ],
                    stops: const [0, 0.6],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: -10,
            top: 0,
            bottom: 0,
            child: Center(
              child: SizedBox(
                width: 110,
                height: 110,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _tc.withOpacity(0.2), width: 1),
                      ),
                    ),
                    for (final delay in [0.0, 1.0, 2.0]) _buildRing(delay),
                    RotationTransition(
                      turns: _sweepTurns,
                      child: const _RadarSweepLine(),
                    ),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            _tc.withOpacity(0.3),
                            _tc.withOpacity(0.05),
                          ],
                        ),
                        border: Border.all(color: _tc.withOpacity(0.4), width: 1),
                      ),
                      child: Center(
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: _tc, width: 2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _grn,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _tc.withOpacity(_pulseAlpha.value),
                              spreadRadius: _pulseSpread.value,
                              blurRadius: 0,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 6),
                  Text('Canlı Takip', style: _txt(size: 10, weight: FontWeight.w700, color: Colors.white.withOpacity(0.60), letterSpacing: 0.7)),
                ],
              ),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: _serif(size: 42, color: _w, height: 1, letterSpacing: -2),
                  children: [
                    TextSpan(text: _formatNumber(widget.total)),
                    TextSpan(text: ' fiyat', style: _txt(size: 18, weight: FontWeight.w700, color: _tc, letterSpacing: -0.5)),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text('bugün güncellendi', style: _txt(size: 12, weight: FontWeight.w500, color: Colors.white.withOpacity(0.60))),
              const SizedBox(height: 14),
              Row(
                children: [
                  _StatPill(value: '${widget.drops}', label: 'düşen', color: _grn, icon: Icons.trending_down_rounded),
                  const SizedBox(width: 10),
                  _StatPill(value: '${widget.rises}', label: 'yükselen', color: _red, icon: Icons.trending_up_rounded),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRing(double delaySeconds) {
    const total = 3.0;
    final begin = delaySeconds / total;
    final end = math.min(begin + ((total - delaySeconds) / total), 1.0);
    final curve = CurvedAnimation(
      parent: _ringController,
      curve: Interval(begin, end, curve: Curves.easeOut),
    );
    return FadeTransition(
      opacity: Tween<double>(begin: 0.7, end: 0).animate(curve),
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.4, end: 2.2).animate(curve),
        child: Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFBF9470).withOpacity(0.5), width: 1),
          ),
        ),
      ),
    );
  }
}

class _RadarSweepLine extends StatelessWidget {
  const _RadarSweepLine();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Transform.translate(
        offset: const Offset(27.5, 0),
        child: Container(
          width: 55,
          height: 1,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color(0x99BF9470),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class _StatPill extends StatelessWidget {
  const _StatPill({required this.value, required this.label, required this.color, required this.icon});

  final String value;
  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(value, style: _txt(size: 11, weight: FontWeight.w800, color: _w)),
            const SizedBox(width: 4),
            Text(label, style: _txt(size: 9, weight: FontWeight.w600, color: Colors.white.withOpacity(0.6))),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.tag, this.actionLabel, this.onActionTap});

  final String title;
  final String? tag;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Text(title, style: _serif(size: 19, color: _t1)),
                if (tag != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: _tc.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                    child: Text(tag!, style: _txt(size: 10, weight: FontWeight.w700, color: _tc)),
                  ),
                ],
              ],
            ),
          ),
          if (actionLabel != null)
            InkWell(
              onTap: onActionTap,
              borderRadius: BorderRadius.circular(8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(actionLabel!, style: _txt(size: 12, weight: FontWeight.w700, color: _t3)),
                  const Icon(Icons.chevron_right_rounded, size: 14, color: _t3),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _QuickFeedRow extends StatelessWidget {
  const _QuickFeedRow({required this.selectedKey, required this.onChanged});

  final String selectedKey;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const items = <(String, String)>[
      ('drops', 'En Çok Düşenler'),
      ('movement', '24 Saatte Hareket'),
      ('personal', 'Sana Özel Seçimler'),
    ];
    return SizedBox(
      height: 42,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final item = items[index];
          final selected = selectedKey == item.$1;
          return InkWell(
            onTap: () => onChanged(item.$1),
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? _tc.withOpacity(0.2) : Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: selected ? _tc : _tc.withOpacity(0.25)),
              ),
              child: Center(
                child: Text(
                  item.$2,
                  style: _txt(size: 11, weight: FontWeight.w800, color: _w),
                ),
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: items.length,
      ),
    );
  }
}

class _AddPriceBanner extends StatelessWidget {
  const _AddPriceBanner({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [_dk, _t2]),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            const Icon(Icons.add_chart_rounded, color: _w),
            const SizedBox(width: 10),
            Expanded(child: Text('Fiyat ekle, puan kazan', style: _txt(size: 14, weight: FontWeight.w800, color: _w))),
            Text('Hemen git →', style: _txt(size: 11, weight: FontWeight.w700, color: _tcl)),
          ],
        ),
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
    final priceDelta = item.priceChangePercent ?? -item.dropPercent;
    final isUp = priceDelta > 0;
    final percent = priceDelta.abs().round();
    final storeColor = _marketColor(item.storeName) ?? _tc;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: _w,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _dk.withOpacity(0.07)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 185,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF8F4EE),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (isUp ? _red : _grn).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(color: (isUp ? _red : _grn).withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 8, color: isUp ? _red : _grn),
                            const SizedBox(width: 3),
                            Text('%$percent', style: _txt(size: 9, weight: FontWeight.w900, color: isUp ? _red : _grn)),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: InkWell(
                        onTap: onFavorite,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            border: Border.all(color: _dk.withOpacity(0.05)),
                          ),
                          child: Icon(isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 12, color: isFavorite ? _red : _t3),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(child: _ProductImage(product: item.product)),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 11, 12, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.product.brand.toUpperCase(), style: _txt(size: 9, weight: FontWeight.w800, color: _tc, letterSpacing: 0.7)),
                    const SizedBox(height: 3),
                    Text(item.product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: _txt(size: 13, weight: FontWeight.w800, color: _t1, height: 1.3)),
                    const SizedBox(height: 6),
                    Text('${item.displayPrice.toStringAsFixed(2).replaceAll('.', ',')}₺', style: _serif(size: 20, color: _t1)),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.fromLTRB(12, 7, 12, 10),
                decoration: BoxDecoration(border: Border(top: BorderSide(color: _dk.withOpacity(0.05)))),
                child: Row(
                  children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(color: storeColor, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(item.storeName, maxLines: 1, overflow: TextOverflow.ellipsis, style: _txt(size: 10, weight: FontWeight.w700, color: _t2)),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.location_on_outlined, size: 8, color: _t3),
                    const SizedBox(width: 2),
                    Text(
                      item.isLocalStore ? (item.distanceLabel ?? item.locationLabel) : 'Online',
                      style: _txt(size: 9, weight: FontWeight.w700, color: _t3),
                    ),
                    const SizedBox(width: 3),
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(color: _dk.withOpacity(0.05), borderRadius: BorderRadius.circular(6)),
                      child: const Icon(Icons.chevron_right_rounded, size: 11, color: _t3),
                    ),
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
      return const Icon(Icons.inventory_2_rounded, size: 64, color: _tan);
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded, size: 64, color: _tan),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(child: CircularProgressIndicator(color: _tc, strokeWidth: 2));
      },
    );
  }
}

class _CampaignCard extends StatelessWidget {
  const _CampaignCard({required this.remaining, this.onTap});

  final Duration remaining;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final days = remaining.inDays;
    final hours = remaining.inHours.remainder(24);
    final minutes = remaining.inMinutes.remainder(60);
    final seconds = remaining.inSeconds.remainder(60);

    return Container(
      decoration: BoxDecoration(color: _dk, borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: _tc.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(color: _tc.withOpacity(0.2)),
                        ),
                        child: Text('BİM Aktüeli', style: _txt(size: 9, weight: FontWeight.w800, color: _tcl, letterSpacing: 0.7)),
                      ),
                      const SizedBox(height: 8),
                      RichText(
                        text: TextSpan(
                          style: _serif(size: 18, color: _w, height: 1.2),
                          children: [
                            const TextSpan(text: 'Haftalık Fırsatlar\n'),
                            TextSpan(text: 'Bitiyor!', style: _serif(size: 18, color: _tc, fontStyle: FontStyle.italic)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Pazar gece yarısı sona eriyor', style: _txt(size: 11, weight: FontWeight.w500, color: Colors.white.withOpacity(0.60))),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: onTap,
                  style: TextButton.styleFrom(
                    foregroundColor: _tcl,
                    backgroundColor: _tc.withOpacity(0.10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: _tc.withOpacity(0.3)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  child: Text('Kataloğu Gör', style: _txt(size: 11, weight: FontWeight.w800, color: _tcl)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('Kalan', style: _txt(size: 9, weight: FontWeight.w600, color: Colors.white.withOpacity(0.60), letterSpacing: 0.5)),
                const SizedBox(width: 8),
                _CountdownBlock(number: _pad(days), unit: 'Gün'),
                const SizedBox(width: 6),
                Text(':', style: _txt(size: 14, weight: FontWeight.w700, color: Colors.white.withOpacity(0.60))),
                const SizedBox(width: 6),
                _CountdownBlock(number: _pad(hours), unit: 'Saat'),
                const SizedBox(width: 6),
                Text(':', style: _txt(size: 14, weight: FontWeight.w700, color: Colors.white.withOpacity(0.60))),
                const SizedBox(width: 6),
                _CountdownBlock(number: _pad(minutes), unit: 'Dak'),
                const SizedBox(width: 6),
                Text(':', style: _txt(size: 14, weight: FontWeight.w700, color: Colors.white.withOpacity(0.60))),
                const SizedBox(width: 6),
                _CountdownBlock(number: _pad(seconds), unit: 'Sn'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _pad(int v) => v.toString().padLeft(2, '0');
}

class _CountdownBlock extends StatelessWidget {
  const _CountdownBlock({required this.number, required this.unit});

  final String number;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 40),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: _tc.withOpacity(0.12)),
      ),
      child: Column(
        children: [
          Text(number, style: _serif(size: 19, color: _w, height: 1)),
          const SizedBox(height: 2),
          Text(unit, style: _txt(size: 7, weight: FontWeight.w600, color: Colors.white.withOpacity(0.60), letterSpacing: 0.6)),
        ],
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.item, this.personalized = false});

  final ExploreFeedItem item;
  final bool personalized;

  @override
  Widget build(BuildContext context) {
    final change = (item.priceChangePercent ?? -item.dropPercent).abs().round();
    final labels = const ['KAMPANYA', 'TREND', 'POPÜLER', 'EN DÜŞÜK'];
    final tag = personalized ? 'SANA ÖZEL' : labels[item.product.name.length % labels.length];
    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: _w,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _dk.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 140,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFF8F4EE),
              borderRadius: BorderRadius.vertical(top: Radius.circular(17)),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: _ProductImage(product: item.product),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(color: _dk.withOpacity(0.75)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(tag, style: _txt(size: 8, weight: FontWeight.w800, color: _tcl, letterSpacing: 0.5)),
                        Text('▼%$change', style: _txt(size: 9, weight: FontWeight.w900, color: _grn)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.brand.toUpperCase(), style: _txt(size: 9, weight: FontWeight.w800, color: _tc)),
                const SizedBox(height: 2),
                Text(item.product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: _txt(size: 11, weight: FontWeight.w800, color: _t1, height: 1.3)),
                const SizedBox(height: 5),
                Text('${item.displayPrice.toStringAsFixed(2).replaceAll('.', ',')}₺', style: _serif(size: 16, color: _t1)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.items});

  final List<_CategoryTileData> items;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.96,
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
                child: Icon(item.icon, size: 18, color: _tc),
              ),
              const SizedBox(height: 5),
              Text(item.label, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: _txt(size: 9, weight: FontWeight.w800, color: _t2, height: 1.2)),
            ],
          ),
        );
      },
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.onTap, required this.alertItems});

  final VoidCallback onTap;
  final List<ExploreFeedItem> alertItems;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        decoration: BoxDecoration(
          color: _w,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _tc.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: _tc.withOpacity(0.15), borderRadius: BorderRadius.circular(11)),
              child: const Icon(Icons.notifications_none_rounded, size: 17, color: _dk),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alertItems.isEmpty ? 'Takipte alarm yok' : '${alertItems.length} takip ürününde hareket var',
                    style: _txt(size: 13, weight: FontWeight.w800, color: _dk),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    alertItems.isEmpty
                        ? 'Fiyatı değişen ürün olunca burada göreceksin.'
                        : '${alertItems.map((e) => e.product.name).join(', ')}',
                    style: _txt(size: 11, weight: FontWeight.w500, color: _t2),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _tc.withOpacity(0.15),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: _tc.withOpacity(0.3)),
              ),
              child: Text('Gör →', style: _txt(size: 11, weight: FontWeight.w800, color: _dk)),
            ),
          ],
        ),
      ),
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
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 11, color: _tc),
                    const SizedBox(width: 5),
                    Expanded(child: Text(locationLabel, style: _txt(size: 13, weight: FontWeight.w800, color: _w))),
                  ],
                ),
              ),
              Text('Haritada Gör →', style: _txt(size: 10, weight: FontWeight.w700, color: _tc)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: stores.take(5).map((store) {
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.10)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(color: store.color, borderRadius: BorderRadius.circular(8)),
                        alignment: Alignment.center,
                        child: Text(store.badge, style: _txt(size: 10, weight: FontWeight.w900, color: _w)),
                      ),
                      const SizedBox(height: 4),
                      Text(store.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: _txt(size: 8, weight: FontWeight.w700, color: Colors.white.withOpacity(0.60))),
                      const SizedBox(height: 1),
                      Text(store.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: _txt(size: 9, weight: FontWeight.w900, color: _tc)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _BarcodeCard extends StatelessWidget {
  const _BarcodeCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        decoration: BoxDecoration(color: _dk, borderRadius: BorderRadius.circular(18)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Barkod ile Ara', style: _txt(size: 14, weight: FontWeight.w800, color: _w)),
                  const SizedBox(height: 2),
                  Text('Ürünü okut, anında fiyatı keşfet.', style: _txt(size: 11, weight: FontWeight.w500, color: Colors.white.withOpacity(0.60))),
                ],
              ),
            ),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [_t2, _tc.withOpacity(0.3)]),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.qr_code_2_rounded, color: _w, size: 19),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchOverlay extends StatelessWidget {
  const _SearchOverlay({
    required this.open,
    required this.controller,
    required this.focusNode,
    required this.trendingSearches,
    required this.recentSearches,
    required this.onClose,
    required this.onPick,
    required this.onRemoveRecent,
  });

  final bool open;
  final TextEditingController controller;
  final FocusNode focusNode;
  final List<String> trendingSearches;
  final List<String> recentSearches;
  final VoidCallback onClose;
  final ValueChanged<String> onPick;
  final ValueChanged<String> onRemoveRecent;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !open,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: open ? 1 : 0,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 200),
          offset: open ? Offset.zero : const Offset(0, 0.03),
          child: Container(
            color: _bg,
            child: Column(
              children: [
                Container(
                  color: _dk,
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(color: _w, borderRadius: BorderRadius.circular(13)),
                          child: Row(
                            children: [
                              const Icon(Icons.search_rounded, size: 14, color: _t3),
                              const SizedBox(width: 9),
                              Expanded(
                                child: TextField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  onSubmitted: onPick,
                                  style: _txt(size: 14, weight: FontWeight.w600, color: _t1),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Ürün, marka veya mağaza ara...',
                                    hintStyle: _txt(size: 14, color: _t3, fontStyle: FontStyle.italic),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(onPressed: onClose, child: Text('İptal', style: _txt(size: 13, weight: FontWeight.w700, color: Colors.white.withOpacity(0.60)))),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _OverlaySection(
                        title: 'Trend Aramalar',
                        icon: Icons.local_fire_department_outlined,
                        child: Wrap(
                          spacing: 7,
                          runSpacing: 7,
                          children: trendingSearches.map((term) {
                            final hot = term == trendingSearches.first;
                            return InkWell(
                              onTap: () => onPick(term),
                              borderRadius: BorderRadius.circular(999),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                                decoration: BoxDecoration(
                                  color: hot ? _tc.withOpacity(0.10) : _w,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: hot ? _tc.withOpacity(0.4) : _dk.withOpacity(0.10)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(hot ? Icons.local_fire_department_rounded : Icons.search_rounded, size: 12, color: hot ? _tc : _t3),
                                    const SizedBox(width: 5),
                                    Text(term, style: _txt(size: 13, weight: FontWeight.w700, color: _t1)),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      _OverlaySection(
                        title: 'Son Aramalarım',
                        icon: Icons.history_rounded,
                        child: Column(
                          children: recentSearches.map((term) {
                            return Container(
                              padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 3),
                              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _dk.withOpacity(0.07)))),
                              child: Row(
                                children: [
                                  const Icon(Icons.history_rounded, size: 13, color: _t3),
                                  const SizedBox(width: 9),
                                  Expanded(child: Text(term, style: _txt(size: 14, weight: FontWeight.w800, color: _t1))),
                                  InkWell(
                                    onTap: () => onRemoveRecent(term),
                                    child: const Icon(Icons.close_rounded, size: 16, color: _t3),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OverlaySection extends StatelessWidget {
  const _OverlaySection({required this.title, required this.icon, required this.child});

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 11, color: _tc),
              const SizedBox(width: 6),
              Text(title, style: _txt(size: 11, weight: FontWeight.w700, color: _t3, letterSpacing: 0.8)),
            ],
          ),
          const SizedBox(height: 11),
          child,
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

class _CategoryTabData {
  const _CategoryTabData({required this.label, required this.key, required this.icon});

  final String label;
  final String key;
  final IconData icon;
}

class _MarketFilterData {
  const _MarketFilterData({required this.label, this.color});

  final String label;
  final Color? color;
}

class _CategoryTileData {
  const _CategoryTileData({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class _NearbyTileData {
  const _NearbyTileData({required this.badge, required this.name, required this.subtitle, required this.color});

  final String badge;
  final String name;
  final String subtitle;
  final Color color;
}

Color? _marketColor(String label) {
  final normalized = label.toLowerCase();
  if (normalized.contains('a101') || normalized.contains('a-101')) return const Color(0xFFD44020);
  if (normalized.contains('bim')) return const Color(0xFFD4A000);
  if (normalized.contains('şok') || normalized.contains('sok')) return const Color(0xFF7B3FA0);
  if (normalized.contains('migros')) return const Color(0xFFE07020);
  if (normalized.contains('trendyol')) return const Color(0xFFF27A1A);
  if (normalized.contains('carrefour')) return const Color(0xFF1840C0);
  return null;
}

IconData _categoryIcon(String label) {
  switch (label.toLowerCase()) {
    case 'tümü':
    case 'tumu':
      return Icons.home_outlined;
    case 'gıda':
      return Icons.restaurant_rounded;
    case 'bakım':
      return Icons.favorite_outline_rounded;
    case 'ev':
      return Icons.home_work_outlined;
    case 'teknoloji':
    case 'elektronik':
      return Icons.computer_outlined;
    case 'giyim':
      return Icons.checkroom_outlined;
    case 'kitap':
      return Icons.menu_book_outlined;
    case 'spor':
      return Icons.sports_basketball_outlined;
    case 'otomotiv':
      return Icons.local_shipping_outlined;
    case 'temizlik':
      return Icons.cleaning_services_outlined;
    default:
      return Icons.grid_view_rounded;
  }
}
