import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/category_model.dart';
import '../../models/notification_model.dart';
import '../../models/product_model.dart';
import '../../models/store_model.dart';
import '../../models/user_model.dart';
import '../../providers/actual_provider.dart';
import '../../providers/explore_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/app_network_image.dart';
import '../../widgets/barcode_scanner_sheet.dart';
import '../actual/actuals_screen.dart';
import '../add_price/add_price_screen.dart';
import '../notifications/notifications_screen.dart';
import '../product/product_detail_screen.dart';

const _bg = Color(0xFFEDEAE3);
const _dk = Color(0xFF18100A);
const _dk2 = Color(0xFF241608);
const _w = Color(0xFFFAFAF8);
const _tan = Color(0xFFB08848);
const _tc = Color(0xFFBF9470);
const _tcl = Color(0xFFD0A882);
const _grn = Color(0xFF27A85A);
const _red = Color(0xFFE53935);
const _t1 = Color(0xFF18100A);
const _t2 = Color(0xFF5E4A38);
const _t3 = Color(0xFFA0887A);
const _bd = Color(0x1218100A);

TextStyle _pjs({
  double? size,
  FontWeight? weight,
  Color? color,
  double? letterSpacing,
  double? height,
  TextDecoration? decoration,
}) {
  return GoogleFonts.plusJakartaSans(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
    decoration: decoration,
  );
}

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _overlayController = TextEditingController();
  final _overlayFocusNode = FocusNode();
  final Set<String> _dismissedRecentTerms = <String>{};

  bool _overlayOpen = false;
  String? _selectedMarket;
  String _selectedUiCategory = 'Tumu';
  late final Timer _campaignTimer;
  Duration _campaignRemaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _campaignRemaining = _nextSundayCountdown();
    _campaignTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_campaignRemaining > Duration.zero) {
          _campaignRemaining -= const Duration(seconds: 1);
        } else {
          _campaignRemaining = Duration.zero;
        }
      });
    });
  }

  @override
  void dispose() {
    _campaignTimer.cancel();
    _searchController.dispose();
    _overlayController.dispose();
    _overlayFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String>(selectedCategoryFilterProvider, (previous, next) {
      if (next != 'Tumu') {
        ref.read(exploreControllerProvider.notifier).updateCategory(next);
        Future.microtask(() {
          ref.read(selectedCategoryFilterProvider.notifier).state = 'Tumu';
        });
      }
    });

    final state = ref.watch(exploreControllerProvider);
    final categories = ref.watch(orderedCategoriesProvider);
    final history = ref.watch(searchHistoryProvider).valueOrNull ?? const <String>[];
    final notifications =
        ref.watch(notificationsProvider).valueOrNull ?? const <NotificationItem>[];
    final nearbyStores = ref.watch(nearbyStoresProvider).valueOrNull ?? const <StoreModel>[];
    final user = ref.watch(userModelStreamProvider).valueOrNull;
    final dailyDealAsync = ref.watch(dailyDealProductProvider);
    final actual = ref.watch(latestActiveActualProvider).valueOrNull;

    if (_searchController.text != state.searchQuery) {
      _searchController.text = state.searchQuery;
      _searchController.selection =
          TextSelection.collapsed(offset: _searchController.text.length);
    }
    if (!_overlayOpen && _overlayController.text != state.searchQuery) {
      _overlayController.text = state.searchQuery;
      _overlayController.selection =
          TextSelection.collapsed(offset: _overlayController.text.length);
    }

    final filteredItems = _filterByMarket(state.items);
    final droppingItems = [...filteredItems]
      ..removeWhere((item) => item.dropPercent <= 0)
      ..sort((a, b) => b.dropPercent.compareTo(a.dropPercent));
    final raisingItems = [...filteredItems]
      ..removeWhere((item) => (item.priceChangePercent ?? 0) <= 0)
      ..sort((a, b) => (b.priceChangePercent ?? 0).compareTo(a.priceChangePercent ?? 0));
    final marketChips = _buildMarketChips(filteredItems);
    final locationLabel = _resolveLocationLabel(user, state, nearbyStores);
    final recentTerms = history
        .where((e) => e.trim().isNotEmpty)
        .where((e) => !_dismissedRecentTerms.contains(e.trim().toLowerCase()))
        .toList();
    final trends = _buildTrendTerms(history, filteredItems, categories);
    final nearestStores = _resolveNearestStores(state, nearbyStores);
    final alarmNotifications = notifications.where((n) => n.type == 'alarm').toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: _bg,
        textTheme: GoogleFonts.plusJakartaSansTextTheme(),
      ),
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Container(
                color: const Color(0xFFC8C4BC),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: _bg,
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1A000000),
                            blurRadius: 40,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _Header(
                            locationLabel: locationLabel,
                            onSearchTap: _openOverlay,
                            onQrTap: _scanBarcode,
                            query: state.searchQuery,
                          ),
                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.only(bottom: 120),
                              physics: const BouncingScrollPhysics(),
                              children: [
                                const SizedBox(height: 14),
                                _TopChips(
                                  chips: state.categories,
                                  selected: state.selectedCategory,
                                  onTap: (value) {
                                    HapticFeedback.selectionClick();
                                    setState(() => _selectedUiCategory = value);
                                    ref
                                        .read(exploreControllerProvider.notifier)
                                        .updateCategory(value);
                                  },
                                ),
                                if (alarmNotifications.isNotEmpty)
                                  _AlarmBanner(
                                    count: alarmNotifications.length,
                                    subtitle: alarmNotifications
                                        .take(2)
                                        .map((e) => e.productName ?? e.title)
                                        .join(' ve '),
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const NotificationsScreen(),
                                      ),
                                    ),
                                  ),
                                if (actual != null)
                                  _ActualCard(
                                    dateText:
                                        '${_formatDate(actual.startDate)} - ${_formatDate(actual.endDate)}',
                                    subtitle: actual.title.trim().isNotEmpty
                                        ? actual.title
                                        : 'Haftanın en yeni pazar katalogları',
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const ActualsScreen(),
                                      ),
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                                  child: _CampaignCountdownCard(
                                    remaining: _campaignRemaining,
                                    onTap: () {
                                      _applySearch('kampanya');
                                    },
                                  ),
                                ),
                                dailyDealAsync.when(
                                  data: (dailyDealProduct) {
                                    if (dailyDealProduct == null) {
                                      return const SizedBox.shrink();
                                    }

                                    final dailyDealItem = _resolveDailyDealItem(
                                      dailyDealProduct: dailyDealProduct,
                                      allItems: state.items,
                                      filteredItems: filteredItems,
                                    );

                                    if (dailyDealItem == null) {
                                      return const SizedBox.shrink();
                                    }

                                    return _DealOfDaySection(
                                      item: dailyDealItem,
                                      onTap: () => _openProduct(dailyDealItem),
                                    );
                                  },
                                  loading: () => const SizedBox.shrink(),
                                  error: (_, __) => const SizedBox.shrink(),
                                ),
                                if (droppingItems.isNotEmpty) ...[
                                  const _SectionHeader(
                                    title: 'Fiyatı Düşenler',
                                    tagLabel: 'bu hafta',
                                    actionLabel: 'Tümünü Gör',
                                  ),
                                  SizedBox(
                                    height: 206,
                                    child: ListView.builder(
                                      padding: const EdgeInsets.symmetric(horizontal: 14),
                                      scrollDirection: Axis.horizontal,
                                      itemCount: math.min(droppingItems.length, 8),
                                      itemBuilder: (context, index) => Padding(
                                        padding: EdgeInsets.only(right: index == 7 ? 0 : 10),
                                        child: _ShowcaseCard(
                                          item: droppingItems[index],
                                          onTap: () => _openProduct(droppingItems[index]),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                const _SectionHeader(title: 'Ürünler'),
                                _MarketFilters(
                                  chips: marketChips,
                                  selected: _selectedMarket ?? 'Tümü',
                                  onTap: (value) {
                                    setState(() => _selectedMarket = value == 'Tümü' ? null : value);
                                  },
                                ),
                                if (state.loading)
                                  const Padding(
                                    padding: EdgeInsets.all(24),
                                    child: Center(child: CircularProgressIndicator(color: _tc)),
                                  )
                                else if (state.error != null)
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: _InfoCard(
                                      title: 'Keşfet verileri yüklenemedi',
                                      subtitle: state.error!,
                                      action: 'Tekrar Dene',
                                      onTap: () => ref.read(exploreControllerProvider.notifier).retry(),
                                    ),
                                  )
                                else if (filteredItems.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: _InfoCard(
                                      title: 'Bu filtrede ürün bulunamadı',
                                      subtitle: 'Kategori veya market seçimini değiştirerek radarı genişlet.',
                                    ),
                                  )
                                else
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                                    child: GridView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: math.min(filteredItems.length, 6),
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        mainAxisSpacing: 10,
                                        crossAxisSpacing: 10,
                                        childAspectRatio: .72,
                                      ),
                                      itemBuilder: (context, index) => _ProductCard(
                                        item: filteredItems[index],
                                        onTap: () => _openProduct(filteredItems[index]),
                                      ),
                                    ),
                                  ),
                                if (categories.isNotEmpty) ...[
                                  const _SectionHeader(title: 'Kategoriler'),
                                  _CategoryGrid(
                                    categories: categories.take(8).toList(),
                                    selected: _selectedUiCategory,
                                    onTap: (category) {
                                      final value = category.name;
                                      setState(() => _selectedUiCategory = value);
                                      ref
                                          .read(exploreControllerProvider.notifier)
                                          .updateCategory(value);
                                    },
                                  ),
                                ],
                                if (raisingItems.isNotEmpty) ...[
                                  const _SectionHeader(
                                    title: 'Zam Yapanlar',
                                    tagLabel: '🔺 bu hafta',
                                    dangerTag: true,
                                    actionLabel: 'Tümünü Gör',
                                  ),
                                  SizedBox(
                                    height: 102,
                                    child: ListView.builder(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      scrollDirection: Axis.horizontal,
                                      itemCount: math.min(raisingItems.length, 8),
                                      itemBuilder: (context, index) => Padding(
                                        padding: EdgeInsets.only(right: index == 7 ? 0 : 9),
                                        child: _RisingCard(
                                          item: raisingItems[index],
                                          onTap: () => _openProduct(raisingItems[index]),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                if (nearestStores.isNotEmpty) ...[
                                  const _SectionHeader(title: 'Yakınındaki Marketler'),
                                  _NearbyMarkets(
                                    locationLabel: locationLabel,
                                    stores: nearestStores,
                                    onStoreTap: _openStoreMap,
                                  ),
                                ],
                                _StatsStrip(
                                  totalPrices: filteredItems.length * 20 + 1040,
                                  increased: raisingItems.length * 21 + 60,
                                  decreased: droppingItems.length * 17 + 90,
                                ),
                                _CommunityCta(
                                  user: user,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const AddPriceScreen(),
                                    ),
                                  ),
                                ),
                                _BarcodeCta(onTap: _scanBarcode),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              _SearchOverlay(
                open: _overlayOpen,
                controller: _overlayController,
                focusNode: _overlayFocusNode,
                trends: trends,
                recents: recentTerms,
                onClose: _closeOverlay,
                onChanged: _applySearch,
                onSubmitted: (value) async {
                  await _applySearch(value);
                  _closeOverlay();
                },
                onPickTrend: (value) async {
                  await _applySearch(value);
                  _closeOverlay();
                },
                onRemoveRecent: (value) {
                  setState(() => _dismissedRecentTerms.add(value.toLowerCase()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _scanBarcode() async {
    final barcode = await BarcodeScannerSheet.scan(context, title: 'Barkod Tara');
    if (!mounted || barcode == null || barcode.trim().isEmpty) return;
    await _applySearch(barcode.trim());
  }

  void _openOverlay() {
    setState(() {
      _overlayOpen = true;
      _overlayController.text = _searchController.text;
      _overlayController.selection =
          TextSelection.collapsed(offset: _overlayController.text.length);
    });
    Future.microtask(() => _overlayFocusNode.requestFocus());
  }

  void _closeOverlay() {
    _overlayFocusNode.unfocus();
    setState(() => _overlayOpen = false);
  }

  Future<void> _applySearch(String value) async {
    _searchController.text = value;
    _overlayController.text = value;
    ref.read(exploreControllerProvider.notifier).updateSearchQuery(value);
    if (value.trim().isNotEmpty) {
      await ref.read(userNotifierProvider.notifier).saveSearch(value.trim());
    }
  }

  List<ExploreFeedItem> _filterByMarket(List<ExploreFeedItem> items) {
    final selected = _selectedMarket;
    if (selected == null || selected == 'Tümü') return items;
    return items
        .where((item) => item.storeName.toLowerCase() == selected.toLowerCase())
        .toList();
  }

  List<_MarketChipData> _buildMarketChips(List<ExploreFeedItem> items) {
    final unique = <String>{};
    final result = <_MarketChipData>[const _MarketChipData('Tümü', _tc)];
    for (final item in items) {
      final store = item.storeName.trim();
      if (store.isEmpty || !unique.add(store.toLowerCase())) continue;
      result.add(_MarketChipData(store, _storeColor(store)));
    }
    return result;
  }

  List<String> _buildTrendTerms(
    List<String> history,
    List<ExploreFeedItem> items,
    List<CategoryModel> categories,
  ) {
    final values = <String>[];
    final seen = <String>{};

    void add(String raw) {
      final value = raw.trim();
      if (value.isEmpty || !seen.add(value.toLowerCase())) return;
      values.add(value);
    }

    for (final item in history) {
      add(item);
    }
    for (final item in items.take(6)) {
      add(item.product.brand);
      add(item.product.name);
    }
    for (final category in categories.take(4)) {
      add(category.name);
    }
    return values.take(6).toList();
  }

  String _resolveLocationLabel(
    UserModel? user,
    ExploreState state,
    List<StoreModel> nearbyStores,
  ) {
    final address = state.userLocation?.address?.trim() ?? '';
    if (address.isNotEmpty) {
      return address
          .split(',')
          .map((part) => part.trim())
          .where((part) => part.isNotEmpty)
          .take(2)
          .join(', ');
    }

    final neighborhood = user?.neighborhood?.trim() ?? '';
    final city = user?.city?.trim() ?? user?.cityName?.trim() ?? '';
    if (state.userLocation != null && neighborhood.isNotEmpty && city.isNotEmpty) {
      return '$neighborhood, $city';
    }
    if (state.userLocation != null && neighborhood.isNotEmpty) return neighborhood;
    if (state.userLocation != null && city.isNotEmpty) return city;

    if (state.userLocation != null && nearbyStores.isNotEmpty) {
      final store = nearbyStores.first;
      if (store.district.trim().isNotEmpty && store.city.trim().isNotEmpty) {
        return '${store.district.trim()}, ${store.city.trim()}';
      }
    }

    return 'Konum Aranıyor...';
  }

  ExploreFeedItem? _resolveDailyDealItem({
    required ProductModel dailyDealProduct,
    required List<ExploreFeedItem> allItems,
    required List<ExploreFeedItem> filteredItems,
  }) {
    final matches = filteredItems.where((item) => item.product.id == dailyDealProduct.id);
    if (matches.isNotEmpty) {
      final sortedMatches = matches.toList()
        ..sort((a, b) {
          final dropCompare = b.dropPercent.compareTo(a.dropPercent);
          if (dropCompare != 0) return dropCompare;
          return a.displayPrice.compareTo(b.displayPrice);
        });
      return sortedMatches.first;
    }

    final fallbackMatches = allItems.where((item) => item.product.id == dailyDealProduct.id);
    if (fallbackMatches.isEmpty) return null;

    final sortedFallback = fallbackMatches.toList()
      ..sort((a, b) => a.displayPrice.compareTo(b.displayPrice));
    return sortedFallback.first;
  }

  List<_NearbyStoreData> _resolveNearestStores(
    ExploreState state,
    List<StoreModel> stores,
  ) {
    final userLocation = state.userLocation;
    final list = stores
        .map(
          (store) => _NearbyStoreData(
            store: store,
            distanceMeters: userLocation == null
                ? null
                : _distanceMeters(
                    userLocation.geoPoint.latitude,
                    userLocation.geoPoint.longitude,
                    store.lat,
                    store.lng,
                  ),
          ),
        )
        .toList();
    list.sort((a, b) => (a.distanceMeters ?? double.infinity)
        .compareTo(b.distanceMeters ?? double.infinity));
    return list.take(4).toList();
  }

  double _distanceMeters(double startLat, double startLng, double endLat, double endLng) {
    const earthRadius = 6371000.0;
    final dLat = _degToRad(endLat - startLat);
    final dLng = _degToRad(endLng - startLng);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(startLat)) *
            math.cos(_degToRad(endLat)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _degToRad(double degrees) => degrees * (math.pi / 180.0);

  Duration _nextSundayCountdown() {
    final now = DateTime.now();
    final daysUntilSunday = ((7 - now.weekday) % 7 == 0) ? 7 : (7 - now.weekday) % 7;
    final target = DateTime(
      now.year,
      now.month,
      now.day + daysUntilSunday,
      23,
      59,
      59,
    );
    final diff = target.difference(now);
    return diff.isNegative ? Duration.zero : diff;
  }

  void _openProduct(ExploreFeedItem item) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: item.product.id)),
    );
  }

  Future<void> _openStoreMap(StoreModel store) async {
    if (store.lat == 0 && store.lng == 0) return;
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${store.lat},${store.lng}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.locationLabel,
    required this.onSearchTap,
    required this.onQrTap,
    required this.query,
  });

  final String locationLabel;
  final VoidCallback onSearchTap;
  final VoidCallback onQrTap;
  final String query;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _dk,
        borderRadius: BorderRadius.zero,
        boxShadow: [
          BoxShadow(
            color: Color(0x33211510),
            blurRadius: 30,
            offset: Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -24,
            top: -24,
            child: _GlowOrb(size: 180, opacity: .22),
          ),
          Positioned(
            left: -20,
            bottom: -22,
            child: _GlowOrb(size: 100, opacity: .10),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Keşfet',
                        style: _pjs(
                          size: 22,
                          weight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -.5,
                        ),
                      ),
                    ),
                    _LocationPill(label: locationLabel),
                  ],
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: onSearchTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1A18100A),
                          blurRadius: 20,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        _SvgIcon(_luxIcon('search'), size: 16, color: _t3),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            query.trim().isEmpty
                                ? 'Ürün, marka veya mağaza ara...'
                                : query,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _pjs(
                              size: 14,
                              weight: query.trim().isEmpty ? FontWeight.w500 : FontWeight.w800,
                              color: query.trim().isEmpty ? _t3 : _t1,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: onQrTap,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: _bg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: _SvgIcon(_luxIcon('qr'), size: 16, color: _dk),
                            ),
                          ),
                        ),
                      ],
                    ),
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

class _LocationPill extends StatelessWidget {
  const _LocationPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 170),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _tc.withOpacity(.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SvgIcon(_luxIcon('pin'), size: 11, color: _tc, strokeWidth: 2.5),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: _pjs(size: 11, weight: FontWeight.w700, color: _tc),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopChips extends StatelessWidget {
  const _TopChips({required this.chips, required this.selected, required this.onTap});

  final List<String> chips;
  final String selected;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final raw = chips[index];
          final label = raw == 'Tumu' ? 'Tümü' : raw;
          final isSelected = raw == selected;
          return GestureDetector(
            onTap: () => onTap(raw),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? _dk : _w,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  if (isSelected) ...const [
                    BoxShadow(color: Color(0x5218100A), blurRadius: 16, offset: Offset(0, 4)),
                    BoxShadow(color: Color(0x2418100A), blurRadius: 16),
                  ] else
                    const BoxShadow(
                      color: Color(0x141C1108),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                ],
              ),
              child: Row(
                children: [
                  if (index == 0) ...[
                    _SvgIcon(
                      _luxIcon('home'),
                      size: 13,
                      color: isSelected ? Colors.white : _t2,
                      strokeWidth: 2.2,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: _pjs(
                      size: 12,
                      weight: FontWeight.w800,
                      color: isSelected ? Colors.white : _t1,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: chips.length,
      ),
    );
  }
}

class _AlarmBanner extends StatelessWidget {
  const _AlarmBanner({required this.count, required this.subtitle, required this.onTap});

  final int count;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _dk,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Color(0x381C1108), blurRadius: 24, offset: Offset(0, 6)),
          ],
          border: Border.all(color: _tc.withOpacity(.12)),
        ),
        child: Stack(
          children: [
            Positioned(right: -16, top: -16, child: _GlowOrb(size: 90, opacity: .18)),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _tc.withOpacity(.18),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Center(
                    child: _SvgIcon(_luxIcon('bell'), size: 20, color: _tc),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$count fiyat alarmın tetiklendi!',
                        style: _pjs(size: 14, weight: FontWeight.w800, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _pjs(
                          size: 12,
                          weight: FontWeight.w600,
                          color: Colors.white.withOpacity(.45),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: _tc,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: const [
                      BoxShadow(color: Color(0x8CBF9470), blurRadius: 16, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Text(
                    'Gör →',
                    style: _pjs(size: 11, weight: FontWeight.w800, color: _dk),
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

class _ActualCard extends StatelessWidget {
  const _ActualCard({required this.dateText, required this.subtitle, required this.onTap});

  final String dateText;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFC29B78), Color(0xFF8A6030)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Color(0x52B88C50), blurRadius: 28, offset: Offset(0, 8)),
          ],
          border: Border.all(color: _tc.withOpacity(.20)),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -12,
              top: -12,
              child: Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x1FFFFFFF),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: _dk.withOpacity(.30),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Aktif • $dateText',
                              style: _pjs(size: 9, weight: FontWeight.w800, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Aktüel Fırsatlar',
                        style: _pjs(size: 18, weight: FontWeight.w900, color: _dk),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: _pjs(
                          size: 12,
                          weight: FontWeight.w600,
                          color: _dk.withOpacity(.60),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                width: 46,
                height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.90),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(child: _SvgIcon(_luxIcon('book'), size: 24, color: _dk)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


class _CampaignCountdownCard extends StatelessWidget {
  const _CampaignCountdownCard({required this.remaining, required this.onTap});

  final Duration remaining;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final days = remaining.inDays.clamp(0, 99).toString().padLeft(2, '0');
    final hours = (remaining.inHours % 24).clamp(0, 23).toString().padLeft(2, '0');
    final minutes = (remaining.inMinutes % 60).clamp(0, 59).toString().padLeft(2, '0');
    final seconds = (remaining.inSeconds % 60).clamp(0, 59).toString().padLeft(2, '0');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        decoration: BoxDecoration(
          color: _dk,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Color(0x3318100A), blurRadius: 22, offset: Offset(0, 6)),
          ],
          border: Border.all(color: const Color(0x1ABF9470)),
        ),
        child: Stack(
          children: [
            Positioned(
              left: -20,
              bottom: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0x24BF9470), Colors.transparent],
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                              color: _tc.withOpacity(.18),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: const BoxDecoration(
                                    color: _tc,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'BİM Aktüeli',
                                  style: _pjs(
                                    size: 9,
                                    weight: FontWeight.w800,
                                    color: _tcl,
                                    letterSpacing: .6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Haftalık Fırsatlar\nBitiyor!',
                            style: _pjs(
                              size: 16,
                              weight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.15,
                              letterSpacing: -.3,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Bu haftaki kampanyalar sona eriyor',
                            style: _pjs(
                              size: 11,
                              weight: FontWeight.w500,
                              color: Colors.white.withOpacity(.42),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                      decoration: BoxDecoration(
                        color: _tc,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x66BF9470),
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        'Fırsatları Gör',
                        style: _pjs(size: 11, weight: FontWeight.w800, color: _dk),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'Kalan',
                      style: _pjs(
                        size: 9,
                        weight: FontWeight.w700,
                        color: Colors.white.withOpacity(.35),
                        letterSpacing: .4,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _CampaignTimeBlock(label: 'Gün', value: days),
                    _campaignSep(),
                    _CampaignTimeBlock(label: 'Saat', value: hours),
                    _campaignSep(),
                    _CampaignTimeBlock(label: 'Dak', value: minutes),
                    _campaignSep(),
                    _CampaignTimeBlock(label: 'Sn', value: seconds),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CampaignTimeBlock extends StatelessWidget {
  const _CampaignTimeBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 36),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(.06)),
      ),
      child: Column(
        children: [
          Text(value, style: _pjs(size: 16, weight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: _pjs(
              size: 7,
              weight: FontWeight.w700,
              color: Colors.white.withOpacity(.35),
              letterSpacing: .5,
            ),
          ),
        ],
      ),
    );
  }
}

Widget _campaignSep() => Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
      child: Text(
        ':',
        style: _pjs(size: 14, weight: FontWeight.w900, color: Colors.white.withOpacity(.20)),
      ),
    );

class _DealOfDaySection extends StatelessWidget {
  const _DealOfDaySection({required this.item, required this.onTap});

  final ExploreFeedItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Günün Radar Fırsatı',
                  style: _pjs(size: 15, weight: FontWeight.w900, color: _dk),
                ),
              ),
              const _TimeBox(value: '03'),
              _timeSep(),
              const _TimeBox(value: '45'),
              _timeSep(),
              const _TimeBox(value: '12'),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _w,
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(color: Color(0x141C1108), blurRadius: 20, offset: Offset(0, 4)),
                ],
                border: Border.all(color: _tc.withOpacity(.20)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDFDFD),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          top: -5,
                          left: -5,
                          child: Transform.rotate(
                            angle: -0.08,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _red,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x66E53935),
                                    blurRadius: 10,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                '%${math.max(item.dropPercent.round(), 1)} İndirim',
                                style: _pjs(
                                  size: 10,
                                  weight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Center(child: _ProductGlyph(item: item, size: 52)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.product.brand.toUpperCase(),
                          style: _pjs(size: 10, weight: FontWeight.w800, color: _tc),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: _pjs(size: 14, weight: FontWeight.w800, color: _dk, height: 1.3),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatTry(_oldPrice(item)),
                              style: _pjs(
                                size: 12,
                                weight: FontWeight.w700,
                                color: _t3,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _formatTry(item.displayPrice),
                              style: _pjs(size: 20, weight: FontWeight.w900, color: _dk),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _dk.withOpacity(.05),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF27A1A),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                item.storeName,
                                style: _pjs(size: 10, weight: FontWeight.w800, color: _t2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeSep() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(':', style: _pjs(size: 12, weight: FontWeight.w900, color: _dk)),
      );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.tagLabel,
    this.actionLabel,
    this.dangerTag = false,
  });

  final String title;
  final String? tagLabel;
  final String? actionLabel;
  final bool dangerTag;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 15,
                  decoration: BoxDecoration(
                    color: dangerTag ? _red : _tc,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 2,
                    children: [
                      Text(
                        title,
                        style: _pjs(
                          size: 16,
                          weight: FontWeight.w900,
                          color: _t1,
                          letterSpacing: -.3,
                        ),
                      ),
                      if (tagLabel != null)
                        Text(
                          tagLabel!,
                          style: _pjs(
                            size: 10,
                            weight: FontWeight.w600,
                            color: dangerTag ? _red : _t3,
                            height: 1,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (actionLabel != null)
            Text(
              actionLabel!,
              style: _pjs(size: 12, weight: FontWeight.w700, color: _tc),
            ),
        ],
      ),
    );
  }
}

class _ShowcaseCard extends StatelessWidget {
  const _ShowcaseCard({required this.item, required this.onTap});

  final ExploreFeedItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 158,
        decoration: BoxDecoration(
          color: _w,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(color: Color(0x1718100A), blurRadius: 14, offset: Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 94,
              decoration: BoxDecoration(
                color: _surfaceForItem(item),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
                      child: _ProductGlyph(item: item, size: 88),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      color: _dk.withOpacity(.65),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'EN DÜŞÜK',
                            style: _pjs(size: 8, weight: FontWeight.w800, color: _tcl),
                          ),
                          Text(
                            '▼%${math.max(item.dropPercent.round(), 1)}',
                            style: _pjs(size: 9, weight: FontWeight.w900, color: _grn),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 8, 11, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.brand.toUpperCase(),
                    style: _pjs(size: 9, weight: FontWeight.w700, color: _tc),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: _pjs(size: 11.5, weight: FontWeight.w800, color: _t1, height: 1.3),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatTry(item.displayPrice),
                        style:
                            _pjs(size: 13, weight: FontWeight.w900, color: _t1, letterSpacing: -.3),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: _grn.withOpacity(.12),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          '%${math.max(item.dropPercent.round(), 1)}',
                          style: _pjs(size: 9, weight: FontWeight.w800, color: _grn),
                        ),
                      ),
                    ],
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

class _MarketFilters extends StatelessWidget {
  const _MarketFilters({required this.chips, required this.selected, required this.onTap});

  final List<_MarketChipData> chips;
  final String selected;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final chip = chips[index];
          final isSelected = chip.label.toLowerCase() == selected.toLowerCase();
          return GestureDetector(
            onTap: () => onTap(chip.label),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? _dk : _w,
                borderRadius: BorderRadius.circular(999),
                boxShadow: const [
                  BoxShadow(color: Color(0x141C1108), blurRadius: 8, offset: Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  if (chip.label != 'Tümü') ...[
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(color: chip.color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    chip.label,
                    style: _pjs(
                      size: 12,
                      weight: FontWeight.w800,
                      color: isSelected ? Colors.white : _t2,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 7),
        itemCount: chips.length,
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.item, required this.onTap});

  final ExploreFeedItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rising = (item.priceChangePercent ?? 0) > 0;
    final badgeColor = rising ? _red : _grn;
    final badgeValue = ((rising ? item.priceChangePercent : item.dropPercent) ?? item.dropPercent)
        .abs()
        .round();
    final distance = item.distanceLabel?.trim().isNotEmpty == true ? item.distanceLabel! : 'Online';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _w,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(color: Color(0x1418100A), blurRadius: 10, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 118,
              decoration: BoxDecoration(
                color: _surfaceForItem(item),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 7,
                    top: 7,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xEAFBF8F4),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _SvgIcon(
                            _luxIcon(rising ? 'arrowDown' : 'arrowUp'),
                            size: 7,
                            color: badgeColor,
                            strokeWidth: 3,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '%$badgeValue',
                            style: _pjs(size: 9, weight: FontWeight.w900, color: badgeColor),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: 7,
                    top: 7,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xEBFAF8F4),
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1F18100A),
                            blurRadius: 5,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: SizedBox(
                        width: 26,
                        height: 26,
                        child: Center(
                          child: _SvgIcon(
                            _luxIcon('heart'),
                            size: 12,
                            color: const Color(0x4818100A),
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(1),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                        child: Center(
                          child: _ProductGlyph(item: item, size: 116),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(11, 10, 11, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.brand,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _pjs(
                        size: 9,
                        weight: FontWeight.w700,
                        color: _tc,
                        letterSpacing: .45,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        item.product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: _pjs(size: 12, weight: FontWeight.w800, color: _t1, height: 1.3),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      _formatTry(item.displayPrice),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _pjs(size: 17, weight: FontWeight.w900, color: _t1, letterSpacing: -.5),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.fromLTRB(11, 8, 11, 10),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: _dk.withOpacity(.06)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _storeColor(item.storeName),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            item.storeName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _pjs(size: 10, weight: FontWeight.w700, color: _t2),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _SvgIcon(_luxIcon('pin'), size: 8, color: _t3, strokeWidth: 2),
                      const SizedBox(width: 2),
                      Text(
                        distance,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _pjs(size: 9, weight: FontWeight.w700, color: _t3),
                      ),
                    ],
                  ),
                  const SizedBox(width: 3),
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: _bg,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Center(
                      child: _SvgIcon(
                        _luxIcon('chevronRight'),
                        size: 8,
                        color: _t3,
                        strokeWidth: 2.5,
                      ),
                    ),
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

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.categories,
    required this.selected,
    required this.onTap,
  });

  final List<CategoryModel> categories;
  final String selected;
  final ValueChanged<CategoryModel> onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 2),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: categories.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 9,
          crossAxisSpacing: 9,
          childAspectRatio: .88,
        ),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category.name == selected;
          return GestureDetector(
            onTap: () => onTap(category),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.fromLTRB(8, 14, 8, 12),
              decoration: BoxDecoration(
                color: isSelected ? _dk : _w,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  if (isSelected) ...const [
                    BoxShadow(color: Color(0x4D1C1108), blurRadius: 24, offset: Offset(0, 8)),
                    BoxShadow(color: Color(0x261C1108), blurRadius: 20),
                  ] else
                    const BoxShadow(
                      color: Color(0x141C1108),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withOpacity(.12)
                          : _tc.withOpacity(.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: _SvgIcon(
                      _categorySvg(category),
                      size: 20,
                      color: isSelected ? Colors.white : _tc,
                      strokeWidth: 1.5,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    category.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: _pjs(
                      size: 9,
                      weight: FontWeight.w800,
                      color: isSelected ? Colors.white.withOpacity(.80) : _t2,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RisingCard extends StatelessWidget {
  const _RisingCard({required this.item, required this.onTap});

  final ExploreFeedItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final increase = (item.priceChangePercent ?? 0).round();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 152,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        decoration: BoxDecoration(
          color: _w,
          borderRadius: BorderRadius.circular(20),
          border: const Border(left: BorderSide(color: _red, width: 3)),
          boxShadow: const [
            BoxShadow(color: Color(0x171C1108), blurRadius: 12, offset: Offset(0, 3)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _red.withOpacity(.08),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Center(child: _SvgIcon(_luxIcon('priceUp'), size: 18, color: _red, strokeWidth: 1.8)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: _pjs(size: 11, weight: FontWeight.w800, color: _t1, height: 1.3),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        _formatTry(item.displayPrice),
                        style: _pjs(size: 12, weight: FontWeight.w900, color: _red),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _red.withOpacity(.10),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '+%$increase',
                          style: _pjs(size: 9, weight: FontWeight.w800, color: _red),
                        ),
                      ),
                    ],
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

class _NearbyMarkets extends StatelessWidget {
  const _NearbyMarkets({
    required this.locationLabel,
    required this.stores,
    required this.onStoreTap,
  });

  final String locationLabel;
  final List<_NearbyStoreData> stores;
  final ValueChanged<StoreModel> onStoreTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _dk,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(color: Color(0x401C1108), blurRadius: 28, offset: Offset(0, 8)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(right: -24, top: -24, child: _GlowOrb(size: 120, opacity: .18)),
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        _SvgIcon(_luxIcon('pin'), size: 14, color: _tc, strokeWidth: 2.5),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            locationLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _pjs(size: 14, weight: FontWeight.w900, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Haritada gör →',
                    style: _pjs(size: 11, weight: FontWeight.w700, color: _tc),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  for (var i = 0; i < stores.length; i++) ...[
                    Expanded(
                      child: GestureDetector(
                        onTap: () => onStoreTap(stores[i].store),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(.10)),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: _storeColor(stores[i].store.displayName),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: const [
                                    BoxShadow(color: Color(0x4D000000), blurRadius: 8, offset: Offset(0, 2)),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  stores[i].store.displayName.characters.first.toUpperCase(),
                                  style: _pjs(size: 11, weight: FontWeight.w900, color: Colors.white),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                stores[i].store.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: _pjs(
                                  size: 8,
                                  weight: FontWeight.w800,
                                  color: Colors.white.withOpacity(.45),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                stores[i].label,
                                style: _pjs(size: 10, weight: FontWeight.w900, color: _tc),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (i != stores.length - 1) const SizedBox(width: 7),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsStrip extends StatelessWidget {
  const _StatsStrip({
    required this.totalPrices,
    required this.increased,
    required this.decreased,
  });

  final int totalPrices;
  final int increased;
  final int decreased;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 9, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _StatPill(
              value: _formatInt(totalPrices),
              label: 'Bugün fiyat',
              icon: 'bars',
              iconColor: const Color(0xFF1E64DC),
              iconBg: const Color(0x1A1E64DC),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: _StatPill(
              value: _formatInt(increased),
              label: 'Zam yapılan',
              icon: 'trendDown',
              iconColor: _red,
              iconBg: _red.withOpacity(.10),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: _StatPill(
              value: _formatInt(decreased),
              label: 'Düşen ürün',
              icon: 'trendUp',
              iconColor: _grn,
              iconBg: _grn.withOpacity(.10),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommunityCta extends StatelessWidget {
  const _CommunityCta({required this.user, required this.onTap});

  final UserModel? user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = user != null && user!.points > 0
        ? '${_formatInt(user!.points)} puanla katkı sağlamaya devam et'
        : 'Fiyat ekleyerek topluluğa katkı sağla ve puan kazan';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 9, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: _dk,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Color(0x3318100A), blurRadius: 22, offset: Offset(0, 6)),
          ],
        ),
        child: Stack(
          children: [
            Positioned(right: -14, bottom: -14, child: _GlowOrb(size: 80, opacity: .16)),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _tc.withOpacity(.18),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Center(child: _SvgIcon(_luxIcon('user'), size: 19, color: _tc)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fiyat Ekle, Puan Kazan!',
                        softWrap: true,
                        style: _pjs(size: 13, weight: FontWeight.w800, color: Colors.white),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        softWrap: true,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _pjs(
                          size: 11,
                          weight: FontWeight.w500,
                          color: Colors.white.withOpacity(.38),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: _tc,
                    boxShadow: const [
                      BoxShadow(color: Color(0x66BF9470), blurRadius: 12, offset: Offset(0, 3)),
                    ],
                  ),
                  child: Text(
                    '+10 P',
                    style: _pjs(size: 11, weight: FontWeight.w800, color: _dk),
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

class _BarcodeCta extends StatelessWidget {
  const _BarcodeCta({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 9, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: _dk,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _tc.withOpacity(.18)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fırsatı Bulamadın mı?',
                    style: _pjs(size: 14, weight: FontWeight.w800, color: Colors.white, letterSpacing: -.2),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Barkodu okut, anında keşfet.',
                    style: _pjs(
                      size: 11,
                      weight: FontWeight.w500,
                      color: Colors.white.withOpacity(.40),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _tc,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(color: Color(0x73BF9470), blurRadius: 14, offset: Offset(0, 4)),
                ],
              ),
              child: Center(child: _SvgIcon(_luxIcon('qr'), size: 20, color: _dk)),
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
    required this.trends,
    required this.recents,
    required this.onClose,
    required this.onChanged,
    required this.onSubmitted,
    required this.onPickTrend,
    required this.onRemoveRecent,
  });

  final bool open;
  final TextEditingController controller;
  final FocusNode focusNode;
  final List<String> trends;
  final List<String> recents;
  final VoidCallback onClose;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final ValueChanged<String> onPickTrend;
  final ValueChanged<String> onRemoveRecent;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !open,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 220),
        opacity: open ? 1 : 0,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 220),
          offset: open ? Offset.zero : const Offset(0, .03),
          child: Material(
            color: _bg,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
                    decoration: const BoxDecoration(
                      color: _dk,
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x261C1108),
                            blurRadius: 18,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          _SvgIcon(_luxIcon('search'), size: 15, color: _t3),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: controller,
                              focusNode: focusNode,
                              onChanged: onChanged,
                              onSubmitted: onSubmitted,
                              style: _pjs(size: 14, weight: FontWeight.w500, color: _t1),
                              decoration: InputDecoration(
                                hintText: 'Ürün, mağaza veya kategori ara...',
                                hintStyle: _pjs(
                                  size: 14,
                                  weight: FontWeight.w500,
                                  color: _t3,
                                  decoration: TextDecoration.none,
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: onClose,
                            style: TextButton.styleFrom(padding: const EdgeInsets.only(left: 8)),
                            child: Text(
                              'İptal',
                              style: _pjs(
                                size: 13,
                                weight: FontWeight.w700,
                                color: _t3.withOpacity(.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                      children: [
                        if (trends.isNotEmpty) ...[
                          const _OverlaySectionTitle(title: 'Trend Aramalar', icon: 'trendUp'),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (var i = 0; i < trends.length; i++)
                                GestureDetector(
                                  onTap: () => onPickTrend(trends[i]),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                    decoration: BoxDecoration(
                                      color: i == 0 ? _tc.withOpacity(.12) : _w,
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: i == 0 ? _tc.withOpacity(.30) : _bd,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x141C1108),
                                          blurRadius: 8,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      i == 0 ? '🔥 ${trends[i]}' : trends[i],
                                      style: _pjs(
                                        size: 13,
                                        weight: FontWeight.w700,
                                        color: i == 0 ? _tc : _t1,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                        if (recents.isNotEmpty) ...[
                          const _OverlaySectionTitle(title: 'Son Aramalarım', icon: 'clock'),
                          const SizedBox(height: 4),
                          ...recents.map(
                            (term) => GestureDetector(
                              onTap: () => onPickTrend(term),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border(bottom: BorderSide(color: _dk.withOpacity(.07))),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    _SvgIcon(_luxIcon('clock'), size: 16, color: _t3),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        term,
                                        style: _pjs(size: 15, weight: FontWeight.w600, color: _t1),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => onRemoveRecent(term),
                                      child: _SvgIcon(_luxIcon('close'), size: 16, color: _t3),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OverlaySectionTitle extends StatelessWidget {
  const _OverlaySectionTitle({required this.title, required this.icon});

  final String title;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SvgIcon(_luxIcon(icon), size: 12, color: _tc),
        const SizedBox(width: 7),
        Text(
          title,
          style: _pjs(size: 11, weight: FontWeight.w800, color: _t3, letterSpacing: .8),
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });

  final String value;
  final String label;
  final String icon;
  final Color iconColor;
  final Color iconBg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: _w,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Color(0x141C1108), blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(11)),
            child: Center(child: _SvgIcon(_luxIcon(icon), size: 18, color: iconColor)),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: _pjs(size: 14, weight: FontWeight.w900, color: _t1)),
                const SizedBox(height: 1),
                Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _pjs(size: 8, weight: FontWeight.w700, color: _t3, letterSpacing: .4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.subtitle, this.action, this.onTap});

  final String title;
  final String subtitle;
  final String? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _w,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _tc.withOpacity(.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: _pjs(size: 16, weight: FontWeight.w900, color: _t1)),
          const SizedBox(height: 6),
          Text(subtitle, style: _pjs(size: 13, weight: FontWeight.w600, color: _t2)),
          if (action != null && onTap != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onTap,
              child: Text(action!, style: _pjs(size: 13, weight: FontWeight.w800, color: _tc)),
            ),
          ],
        ],
      ),
    );
  }
}

class _SvgIcon extends StatelessWidget {
  const _SvgIcon(this.svg, {required this.size, required this.color, this.strokeWidth = 2});

  final String svg;
  final double size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      svg.replaceAll('{color}', '#${color.value.toRadixString(16).substring(2)}').replaceAll('{stroke}', strokeWidth.toString()),
      width: size,
      height: size,
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [_tc.withOpacity(opacity), Colors.transparent],
        ),
      ),
    );
  }
}

class _TimeBox extends StatelessWidget {
  const _TimeBox({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(color: _dk, borderRadius: BorderRadius.circular(6)),
      child: Text(value, style: _pjs(size: 10, weight: FontWeight.w800, color: _tc)),
    );
  }
}

class _ProductGlyph extends StatelessWidget {
  const _ProductGlyph({required this.item, required this.size});

  final ExploreFeedItem item;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AppNetworkImage(
      imageUrl: item.product.effectiveImage,
      cacheKey: item.product.id,
      width: size,
      height: size,
      fit: BoxFit.contain,
      borderRadius: BorderRadius.circular(12),
    );
  }
}

class _MarketChipData {
  const _MarketChipData(this.label, this.color);

  final String label;
  final Color color;
}

class _NearbyStoreData {
  const _NearbyStoreData({required this.store, required this.distanceMeters});

  final StoreModel store;
  final double? distanceMeters;

  String get label {
    if (distanceMeters == null) return '—';
    if (distanceMeters! < 1000) return '${distanceMeters!.round()}m';
    return '${(distanceMeters! / 1000).toStringAsFixed(1)} km';
  }
}

String _formatDate(DateTime date) {
  const months = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
  return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]}';
}

String _formatTry(double value) {
  final fixed = value.toStringAsFixed(2).replaceAll('.', ',');
  return '$fixed₺';
}

double _oldPrice(ExploreFeedItem item) {
  final drop = item.dropPercent <= 0 ? 0.12 : item.dropPercent / 100;
  return item.displayPrice / (1 - drop.clamp(0.08, 0.80));
}

String _formatInt(int value) {
  final str = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < str.length; i++) {
    final index = str.length - i;
    buffer.write(str[i]);
    if (index > 1 && index % 3 == 1) buffer.write('.');
  }
  return buffer.toString();
}

Color _storeColor(String store) {
  final value = store.toLowerCase();
  if (value.contains('a-101') || value.contains('a101')) return const Color(0xFFD44020);
  if (value.contains('bim')) return const Color(0xFFD4A000);
  if (value.contains('şok') || value.contains('sok')) return const Color(0xFF7B3FA0);
  if (value.contains('migros')) return const Color(0xFFE07020);
  return _tc;
}

Color _surfaceForItem(ExploreFeedItem item) {
  final key = '${item.product.brand} ${item.product.name}'.toLowerCase();
  if (key.contains('ariel')) return const Color(0xFFF0EEF8);
  if (key.contains('cola')) return const Color(0xFFFFF0E8);
  if (key.contains('kahve') || key.contains('nes')) return const Color(0xFFF5F0E0);
  return const Color(0xFFF5F0E8);
}

String _categorySvg(CategoryModel category) {
  final key = '${category.canonicalId} ${category.name}'.toLowerCase();
  if (key.contains('gida') || key.contains('icecek')) return _luxIcon('cup');
  if (key.contains('bakim') || key.contains('kisisel')) return _luxIcon('drop');
  if (key.contains('ev') || key.contains('yasam')) return _luxIcon('home');
  if (key.contains('elektronik')) return _luxIcon('phone');
  if (key.contains('giyim')) return _luxIcon('bag');
  if (key.contains('kitap')) return _luxIcon('book');
  if (key.contains('spor')) return _luxIcon('dumbbell');
  if (key.contains('oto')) return _luxIcon('car');
  return _luxIcon('cup');
}

String _luxIcon(String name) {
  const map = {
    'search': '<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><circle cx="11" cy="11" r="8" stroke="{color}" stroke-width="{stroke}"/><path d="M21 21L16.65 16.65" stroke="{color}" stroke-width="{stroke}" stroke-linecap="round"/></svg>',
    'qr': '<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><rect x="3" y="3" width="5" height="5" rx="1" stroke="{color}" stroke-width="{stroke}"/><rect x="16" y="3" width="5" height="5" rx="1" stroke="{color}" stroke-width="{stroke}"/><rect x="16" y="16" width="5" height="5" rx="1" stroke="{color}" stroke-width="{stroke}"/><rect x="3" y="16" width="5" height="5" rx="1" stroke="{color}" stroke-width="{stroke}"/></svg>',
    'pin': '<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M21 10c0 7-9 13-9 13S3 17 3 10a9 9 0 1118 0Z" stroke="{color}" stroke-width="{stroke}" stroke-linecap="round" stroke-linejoin="round"/><circle cx="12" cy="10" r="3" stroke="{color}" stroke-width="{stroke}"/></svg>',
    'bell': '<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M18 8A6 6 0 006 8c0 7-3 9-3 9h18s-3-2-3-9Z" stroke="{color}" stroke-width="{stroke}" stroke-linecap="round" stroke-linejoin="round"/><path d="M13.73 21a2 2 0 01-3.46 0" stroke="{color}" stroke-width="{stroke}" stroke-linecap="round" stroke-linejoin="round"/></svg>',
    'book': '<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M2 3h6a4 4 0 014 4v14a3 3 0 00-3-3H2V3Z" stroke="{color}" stroke-width="{stroke}" stroke-linecap="round" stroke-linejoin="round"/><path d="M22 3h-6a4 4 0 00-4 4v14a3 3 0 013-3h7V3Z" stroke="{color}" stroke-width="{stroke}" stroke-linecap="round" stroke-linejoin="round"/></svg>',
    'home': '<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M3 9l9-7 9 7v11a2 2 0 01-2 2H5a2 2 0 01-2-2V9Z" stroke="{color}" stroke-width="{stroke}" stroke-linecap="round" stroke-linejoin="round"/><path d="M9 22V12h6v10" stroke="{color}" stroke-width="{stroke}" stroke-linecap="round" stroke-linejoin="round"/></svg>',
    'arrowUp': '<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><polyline points="20 15 12 7 4 15" stroke="{color}" stroke-width="{stroke}" stroke-linecap="round" stroke-linejoin="round"/></svg>',
    'arrowDown': '<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><polyline points="4 9 12 17 20 9" stroke="{color}" stroke-width="{stroke}" stroke-linecap="round" stroke-linejoin="round"/></svg>',
    'arrowRight': '<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M5 12h14" stroke="{color}" stroke-width="{stroke}" stroke-linecap="round"/><path d="M13 6l6 6-6 6" stroke="{color}" stroke-width="{stroke}" stroke-linecap="round" stroke-linejoin="round"/></svg>',
    'chevronRight': '<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><polyline points="9 18 15 12 9 6" stroke="{color}" stroke-width="{stroke}" stroke-linecap="round" stroke-linejoin="round"/></svg>',
    'heart': '<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M20.84 4.61a5.5 5.5 0 00-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 00-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 000-7.78Z" stroke="{color}" stroke-width="{stroke}" stroke-linecap="round" stroke-linejoin="round"/></svg>',
    'cup': '<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M18 8h1a4 4 0 010 8h-1" stroke="{color}" stroke-width="{stroke}" stroke-linecap="round" stroke-linejoin="round"/><path d="M2 8h16v9a4 4 0 01-4 4H6a4 4 0 01-4-4V8Z" stroke="{color}" stroke-width="{stroke}" stroke-linecap="round" stroke-linejoin="round"/><path d="M6 1v3M10 1v3M14 1v3" stroke="{color}" stroke-width="{stroke}" stroke-linecap="round"/></svg>',
    'drop': '<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M12 22a7 7 0 007-7c0-2-1-3.9-3-5.5S12.5 5.5 12 3c-.5 2.5-2 4.9-4 6.5C6 11.1 5 13 5 15a7 7 0 007 7Z" stroke="{color}" stroke-width="{stroke}" stroke-linecap="round" stroke-linejoin="round"/></svg>',
    'phone': '<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><rect x="4" y="2" width="16" height="20" rx="2" stroke="{color}" stroke-width="{stroke}"/><path d="M12 18h.01" stroke="{color}" stroke-width="{stroke}" stroke-linecap="round"/></svg>',
    'bag': '<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M6 2L3 6v14a2 2 0 002 2h14a2 2 0 002-2V6l-3-4H6Z" stroke="{color}" stroke-width="{stroke}" stroke-linecap="round" stroke-linejoin="round"/><path d="M3 6h18" stroke="{color}" stroke-width="{stroke}" stroke-linecap="round"/><path d="M16 10a4 4 0 01-8 0" stroke="{color}" stroke-width="{stroke}" stroke-linecap="round" stroke-linejoin="round"/></svg>',
    'dumbbell': '<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M6.5 6.5h11M6.5 17.5h11" stroke="{color}" stroke-width="{stroke}" stroke-linecap="round"/><rect x="2" y="4" width="4.5" height="16" rx="1" stroke="{color}" stroke-width="{stroke}"/><rect x="17.5" y="4" width="4.5" height="16" rx="1" stroke="{color}" stroke-width="{stroke}"/></svg>',
    'car': '<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><rect x="4" y="14" width="16" height="6" rx="2" stroke="{color}" stroke-width="{stroke}"/><circle cx="7" cy="20" r="2" stroke="{color}" stroke-width="{stroke}"/><circle cx="17" cy="20" r="2" stroke="{color}" stroke-width="{stroke}"/><path d="M4 14l2-5h12l2 5" stroke="{color}" stroke-width="{stroke}" stroke-linecap="round" stroke-linejoin="round"/></svg>',
    'priceUp': '<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M3 3h6l1.5 6-3 2a12 12 0 005.5 5.5l2-3 6 1.5V21a2 2 0 01-2 2A18 18 0 011 5a2 2 0 012-2Z" stroke="{color}" stroke-width="{stroke}" stroke-linecap="round" stroke-linejoin="round"/></svg>',
    'user': '<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2" stroke="{color}" stroke-width="{stroke}" stroke-linecap="round" stroke-linejoin="round"/><circle cx="9" cy="7" r="4" stroke="{color}" stroke-width="{stroke}"/></svg>',
    'bars': '<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><line x1="18" y1="20" x2="18" y2="10" stroke="{color}" stroke-width="{stroke}" stroke-linecap="round"/><line x1="12" y1="20" x2="12" y2="4" stroke="{color}" stroke-width="{stroke}" stroke-linecap="round"/><line x1="6" y1="20" x2="6" y2="14" stroke="{color}" stroke-width="{stroke}" stroke-linecap="round"/></svg>',
    'trendDown': '<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><polyline points="23 7 13.5 15.5 8.5 10.5 1 17" stroke="{color}" stroke-width="{stroke}" stroke-linecap="round" stroke-linejoin="round"/></svg>',
    'trendUp': '<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><polyline points="23 17 13.5 8.5 8.5 13.5 1 7" stroke="{color}" stroke-width="{stroke}" stroke-linecap="round" stroke-linejoin="round"/></svg>',
    'clock': '<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><circle cx="12" cy="12" r="10" stroke="{color}" stroke-width="{stroke}"/><path d="M12 6v6l4 2" stroke="{color}" stroke-width="{stroke}" stroke-linecap="round" stroke-linejoin="round"/></svg>',
    'close': '<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M18 6L6 18M6 6l12 12" stroke="{color}" stroke-width="{stroke}" stroke-linecap="round"/></svg>',
  };
  return map[name] ?? map['search']!;
}

String _glyphSvg(String name) {
  const map = {
    'bottle': '<svg viewBox="0 0 64 64" fill="none" xmlns="http://www.w3.org/2000/svg"><rect x="24" y="8" width="16" height="6" rx="3" fill="{fill}"/><rect x="20" y="14" width="24" height="38" rx="8" fill="{fill}"/></svg>',
    'detergent': '<svg viewBox="0 0 64 64" fill="none" xmlns="http://www.w3.org/2000/svg"><rect x="14" y="18" width="36" height="32" rx="8" fill="{fill}"/><rect x="16" y="20" width="32" height="28" rx="7" fill="{fill}"/></svg>',
    'tube': '<svg viewBox="0 0 64 64" fill="none" xmlns="http://www.w3.org/2000/svg"><rect x="22" y="14" width="20" height="36" rx="10" fill="{fill}"/></svg>',
    'jar': '<svg viewBox="0 0 64 64" fill="none" xmlns="http://www.w3.org/2000/svg"><rect x="18" y="18" width="28" height="32" rx="8" fill="{fill}"/></svg>',
  };
  return map[name] ?? map['jar']!;
}
