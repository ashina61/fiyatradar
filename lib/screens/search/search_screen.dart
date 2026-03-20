import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/category_model.dart';
import '../../models/category_theme.dart';
import '../../models/notification_model.dart';
import '../../models/store_model.dart';
import '../../models/user_model.dart';
import '../../providers/actual_provider.dart';
import '../../providers/explore_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/fr_colors.dart';
import '../../utils/theme.dart';
import '../../widgets/barcode_scanner_sheet.dart';
import '../../widgets/premium_pressable.dart';
import '../actual/actuals_screen.dart';
import '../add_price/add_price_screen.dart';
import '../notifications/notifications_screen.dart';
import '../product/product_detail_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _overlayController = TextEditingController();
  final _overlayFocusNode = FocusNode();

  bool _searchOverlayOpen = false;
  String? _selectedMarket;
  final Set<String> _dismissedRecentTerms = <String>{};

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _overlayController.dispose();
    _overlayFocusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    final barcode = await BarcodeScannerSheet.scan(context, title: 'Barkod Tara');
    if (!mounted || barcode == null || barcode.trim().isEmpty) return;

    final value = barcode.trim();
    _searchController.text = value;
    _searchController.selection = TextSelection.collapsed(offset: value.length);
    _overlayController.text = value;
    _overlayController.selection = TextSelection.collapsed(offset: value.length);
    ref.read(exploreControllerProvider.notifier).updateSearchQuery(value);
    await ref.read(userNotifierProvider.notifier).saveSearch(value);
    if (mounted) {
      setState(() => _searchOverlayOpen = false);
    }
  }

  void _openSearchOverlay() {
    setState(() {
      _searchOverlayOpen = true;
      _overlayController.text = _searchController.text;
      _overlayController.selection = TextSelection.collapsed(
        offset: _overlayController.text.length,
      );
    });
    Future.microtask(() {
      if (mounted) {
        _overlayFocusNode.requestFocus();
      }
    });
  }

  void _closeSearchOverlay() {
    if (!mounted) return;
    _overlayFocusNode.unfocus();
    setState(() => _searchOverlayOpen = false);
  }

  Future<void> _applySearch(String value) async {
    final normalized = value.trim();
    _searchController.text = value;
    _searchController.selection = TextSelection.collapsed(offset: value.length);
    _overlayController.text = value;
    _overlayController.selection = TextSelection.collapsed(offset: value.length);
    ref.read(exploreControllerProvider.notifier).updateSearchQuery(value);
    if (normalized.isNotEmpty) {
      await ref.read(userNotifierProvider.notifier).saveSearch(normalized);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String>(selectedCategoryFilterProvider, (prev, next) {
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
    final notifications = ref.watch(notificationsProvider).valueOrNull ?? const <NotificationItem>[];
    final nearbyStores = ref.watch(nearbyStoresProvider).valueOrNull ?? const <StoreModel>[];
    final user = ref.watch(userModelStreamProvider).valueOrNull;

    if (_searchController.text != state.searchQuery) {
      _searchController.text = state.searchQuery;
      _searchController.selection = TextSelection.collapsed(
        offset: _searchController.text.length,
      );
    }
    if (!_searchOverlayOpen && _overlayController.text != state.searchQuery) {
      _overlayController.text = state.searchQuery;
      _overlayController.selection = TextSelection.collapsed(
        offset: _overlayController.text.length,
      );
    }

    final filteredItems = _filterItemsByMarket(state.items);
    final dropItems = [...filteredItems]
      ..removeWhere((item) => item.dropPercent <= 0)
      ..sort((a, b) => b.dropPercent.compareTo(a.dropPercent));
    final increaseItems = [...filteredItems]
      ..removeWhere((item) => (item.priceChangePercent ?? 0) <= 0)
      ..sort((a, b) => (b.priceChangePercent ?? 0).compareTo(a.priceChangePercent ?? 0));
    final alarmNotifications = notifications.where((item) => item.type == 'alarm').toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final trendTerms = _buildTrendTerms(history, filteredItems, categories);
    final visibleHistory = history
        .map((term) => term.trim())
        .where((term) => term.isNotEmpty)
        .where((term) => !_dismissedRecentTerms.contains(term.toLowerCase()))
        .toList();
    final locationLabel = _resolveLocationLabel(user, state, nearbyStores);
    final marketChips = _buildMarketChips(filteredItems);
    final nearestStores = _resolveNearestStores(state, nearbyStores);

    return Scaffold(
      backgroundColor: FRColors.backgroundWarm,
      body: SafeArea(
        bottom: false,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Stack(
            children: [
              Column(
                children: [
                  _buildPremiumHeader(locationLabel),
                  Expanded(
                    child: Transform.translate(
                      offset: const Offset(0, -16),
                      child: CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                              child: _buildSearchBar(state),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: _buildCategoryChips(state),
                          ),
                          if (alarmNotifications.isNotEmpty)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                                child: _AlarmBanner(
                                  count: alarmNotifications.length,
                                  title: alarmNotifications.first.title,
                                  subtitle: alarmNotifications
                                      .take(2)
                                      .map((item) => item.productName?.trim().isNotEmpty == true
                                          ? item.productName!.trim()
                                          : item.message.trim())
                                      .where((text) => text.isNotEmpty)
                                      .join(' • '),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const NotificationsScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          SliverToBoxAdapter(child: _buildActualCard()),
                          if (dropItems.isNotEmpty) ...[
                            SliverToBoxAdapter(
                              child: _SectionHeader(
                                title: 'Fiyatı Düşenler',
                                subtitle: 'bu hafta',
                                actionLabel: 'Tümü',
                                onAction: () {
                                  ref
                                      .read(exploreControllerProvider.notifier)
                                      .updateMode(ExploreMode.drops);
                                },
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: SizedBox(
                                height: 194,
                                child: ListView.separated(
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  scrollDirection: Axis.horizontal,
                                  itemCount: math.min(dropItems.length, 8),
                                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                                  itemBuilder: (context, index) => _MiniInsightCard(
                                    item: dropItems[index],
                                    positive: false,
                                    onTap: () => _openProduct(dropItems[index]),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          SliverToBoxAdapter(
                            child: _SectionHeader(
                              title: 'Ürünler',
                              subtitle: marketChips.length > 1
                                  ? '${marketChips.length - 1} market'
                                  : null,
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: _buildMarketFilters(marketChips),
                          ),
                          if (state.loading)
                            const SliverFillRemaining(
                              hasScrollBody: false,
                              child: _LoadingState(),
                            )
                          else if (state.error != null)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: _ErrorState(
                                onRetry: () => ref
                                    .read(exploreControllerProvider.notifier)
                                    .retry(),
                              ),
                            )
                          else if (filteredItems.isEmpty)
                            const SliverFillRemaining(
                              hasScrollBody: false,
                              child: _EmptyState(),
                            )
                          else
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                              sliver: SliverGrid(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final item = filteredItems[index];
                                    return _DiscoverProductCard(
                                      key: ValueKey('discover-${item.price.id}'),
                                      item: item,
                                      mode: state.selectedMode,
                                      accentColor: _storeColor(item.storeName),
                                      onTap: () => _openProduct(item),
                                    );
                                  },
                                  childCount: filteredItems.length,
                                ),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 8,
                                  crossAxisSpacing: 8,
                                  childAspectRatio: 0.61,
                                ),
                              ),
                            ),
                          if (categories.isNotEmpty) ...[
                            SliverToBoxAdapter(
                              child: const _SectionHeader(title: 'Kategoriler'),
                            ),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
                                child: _CategoryGrid(
                                  categories: categories.take(8).toList(),
                                  selected: state.selectedCategory,
                                  onTap: (category) => ref
                                      .read(exploreControllerProvider.notifier)
                                      .updateCategory(category.name),
                                ),
                              ),
                            ),
                          ],
                          if (increaseItems.isNotEmpty) ...[
                            SliverToBoxAdapter(
                              child: _SectionHeader(
                                title: 'Zam Yapanlar',
                                subtitle: 'bu hafta',
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: SizedBox(
                                height: 112,
                                child: ListView.separated(
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  scrollDirection: Axis.horizontal,
                                  itemCount: math.min(increaseItems.length, 8),
                                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                                  itemBuilder: (context, index) => _MiniInsightCard(
                                    item: increaseItems[index],
                                    positive: true,
                                    compact: true,
                                    onTap: () => _openProduct(increaseItems[index]),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          if (nearestStores.isNotEmpty) ...[
                            SliverToBoxAdapter(
                              child: const _SectionHeader(title: 'Yakınındaki Marketler'),
                            ),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
                                child: _NearbyMarketsCard(
                                  locationLabel: locationLabel,
                                  stores: nearestStores,
                                  onStoreTap: _openStoreMap,
                                ),
                              ),
                            ),
                          ],
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                              child: _CommunityCard(
                                user: user,
                                onTap: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const AddPriceScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(14, 10, 14, 120),
                              child: _BarcodeFooterCard(onTap: _scanBarcode),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              _SearchOverlay(
                open: _searchOverlayOpen,
                controller: _overlayController,
                focusNode: _overlayFocusNode,
                trends: trendTerms,
                recents: visibleHistory,
                onChanged: (value) {
                  _applySearch(value);
                },
                onSubmit: (value) {
                  _applySearch(value);
                },
                onClose: _closeSearchOverlay,
                onTrendTap: (term) async {
                  await _applySearch(term);
                  _closeSearchOverlay();
                },
                onRemoveRecent: (term) {
                  setState(() {
                    _dismissedRecentTerms.add(term.toLowerCase());
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openProduct(ExploreFeedItem item) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(productId: item.product.id),
      ),
    );
  }

  List<ExploreFeedItem> _filterItemsByMarket(List<ExploreFeedItem> items) {
    final selectedMarket = _selectedMarket;
    if (selectedMarket == null || selectedMarket == 'Tümü') return items;
    return items
        .where((item) => item.storeName.toLowerCase() == selectedMarket.toLowerCase())
        .toList();
  }

  List<_MarketChipData> _buildMarketChips(List<ExploreFeedItem> items) {
    final unique = <String>{};
    final chips = <_MarketChipData>[
      const _MarketChipData(label: 'Tümü', color: FRColors.camelStrong),
    ];

    for (final item in items) {
      final label = item.storeName.trim();
      if (label.isEmpty) continue;
      if (unique.add(label.toLowerCase())) {
        chips.add(_MarketChipData(label: label, color: _storeColor(label)));
      }
    }

    if (_selectedMarket != null &&
        !chips.any((chip) => chip.label.toLowerCase() == _selectedMarket!.toLowerCase())) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _selectedMarket = null);
        }
      });
    }

    return chips;
  }

  List<String> _buildTrendTerms(
    List<String> history,
    List<ExploreFeedItem> items,
    List<CategoryModel> categories,
  ) {
    final values = <String>[];
    final seen = <String>{};

    void add(String value) {
      final normalized = value.trim();
      if (normalized.isEmpty) return;
      if (seen.add(normalized.toLowerCase())) {
        values.add(normalized);
      }
    }

    for (final term in history) {
      add(term);
    }
    for (final item in items.take(6)) {
      add(item.product.brand);
      add(item.product.name);
    }
    for (final category in categories.take(4)) {
      add(category.name);
    }

    return values.take(8).toList();
  }

  String _resolveLocationLabel(
    UserModel? user,
    ExploreState state,
    List<StoreModel> nearbyStores,
  ) {
    final userNeighborhood = user?.neighborhood?.trim() ?? '';
    final userCity = user?.city?.trim() ?? user?.cityName?.trim() ?? '';
    if (userNeighborhood.isNotEmpty && userCity.isNotEmpty) {
      return '$userNeighborhood, $userCity';
    }
    if (userNeighborhood.isNotEmpty) return userNeighborhood;
    if (userCity.isNotEmpty) return userCity;

    final first = nearbyStores.isEmpty ? null : nearbyStores.first;
    if (first != null) {
      final district = first.district.trim();
      final city = first.city.trim();
      if (district.isNotEmpty && city.isNotEmpty) return '$district, $city';
      if (district.isNotEmpty) return district;
      if (city.isNotEmpty) return city;
    }

    final location = state.userLocation?.address?.trim() ?? '';
    if (location.isNotEmpty) {
      return location.split(',').take(2).join(', ').trim();
    }
    return 'Konum seç';
  }

  List<_NearbyStoreData> _resolveNearestStores(
    ExploreState state,
    List<StoreModel> stores,
  ) {
    final userLocation = state.userLocation;
    final mapped = stores
        .map((store) => _NearbyStoreData(
              store: store,
              distanceMeters: userLocation == null
                  ? null
                  : _distanceMeters(
                      userLocation.geoPoint.latitude,
                      userLocation.geoPoint.longitude,
                      store.lat,
                      store.lng,
                    ),
            ))
        .toList();
    mapped.sort((a, b) => (a.distanceMeters ?? double.infinity)
        .compareTo(b.distanceMeters ?? double.infinity));
    return mapped.take(5).toList();
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

  Future<void> _openStoreMap(StoreModel store) async {
    final address = store.address?.trim();
    if (address != null && address.startsWith('http')) {
      final uri = Uri.tryParse(address);
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }

    if (store.lat != 0 && store.lng != 0) {
      final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${store.lat},${store.lng}',
      );
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildPremiumHeader(String locationLabel) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
      decoration: const BoxDecoration(
        color: FRColors.espresso,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -36,
            top: -28,
            child: Container(
              width: 150,
              height: 150,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x38C09A60), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.03),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: const [
                        Text(
                          'Keşfet',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.6,
                          ),
                        ),
                        SizedBox(width: 8),
                        _HeaderDot(),
                      ],
                    ),
                  ),
                  _LocationPill(label: locationLabel),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ExploreState state) {
    return PremiumPressable(
      borderRadius: BorderRadius.circular(16),
      onTap: _openSearchOverlay,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: FRColors.espresso,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
          boxShadow: const [
            BoxShadow(
              color: FRColors.shadowMedium,
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.3), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                state.searchQuery.trim().isEmpty
                    ? 'Ürün, mağaza veya kategori ara…'
                    : state.searchQuery,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: state.searchQuery.trim().isEmpty
                      ? Colors.white.withOpacity(0.26)
                      : Colors.white,
                  fontSize: 13,
                  fontWeight: state.searchQuery.trim().isEmpty
                      ? FontWeight.w500
                      : FontWeight.w700,
                  fontStyle: state.searchQuery.trim().isEmpty
                      ? FontStyle.italic
                      : FontStyle.normal,
                ),
              ),
            ),
            PremiumPressable(
              borderRadius: BorderRadius.circular(10),
              onTap: _scanBarcode,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.qr_code_scanner_rounded,
                  color: Colors.white.withOpacity(0.6),
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips(ExploreState state) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        scrollDirection: Axis.horizontal,
        itemCount: state.categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final label = state.categories[index];
          final selected = state.selectedCategory == label;
          return PremiumPressable(
            borderRadius: BorderRadius.circular(999),
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(exploreControllerProvider.notifier).updateCategory(label);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? FRColors.espresso : FRColors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected ? FRColors.espresso : FRColors.border,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: FRColors.shadowSoft,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                label == 'Tumu' ? 'Tümü' : label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: selected ? FRColors.camelStrong : FRColors.textPrimary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActualCard() {
    final actualAsync = ref.watch(latestActiveActualProvider);
    return actualAsync.when(
      data: (actual) {
        if (actual == null) return const SizedBox.shrink();
        final dateText = '${_formatDate(actual.startDate)} - ${_formatDate(actual.endDate)}';
        return Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
          child: PremiumPressable(
            borderRadius: BorderRadius.circular(22),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ActualsScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [FRColors.camelStrong, FRColors.camelDeep],
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x42C29B78),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: FRColors.espresso,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Aktif • $dateText',
                            style: const TextStyle(
                              color: FRColors.camelStrong,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Aktüel Fırsatlar',
                          style: TextStyle(
                            color: FRColors.espresso,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          actual.marketName.trim().isNotEmpty
                              ? '${actual.marketName} katalogları seni bekliyor'
                              : (actual.title.trim().isNotEmpty
                                  ? actual.title
                                  : 'Haftanın en yeni katalogları'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xCC1C1108),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.menu_book_rounded, color: FRColors.espresso),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildMarketFilters(List<_MarketChipData> chips) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final chip = chips[index];
          final selected = (_selectedMarket ?? 'Tümü').toLowerCase() == chip.label.toLowerCase();
          return PremiumPressable(
            borderRadius: BorderRadius.circular(999),
            onTap: () {
              setState(() {
                _selectedMarket = chip.label == 'Tümü' ? null : chip.label;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: selected ? FRColors.espresso : FRColors.white,
                borderRadius: BorderRadius.circular(999),
                boxShadow: const [
                  BoxShadow(
                    color: FRColors.shadowSoft,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (chip.label != 'Tümü') ...[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: chip.color,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    chip.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: selected ? Colors.white : FRColors.textMuted,
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

  String _formatDate(DateTime date) {
    const months = [
      'Oca',
      'Şub',
      'Mar',
      'Nis',
      'May',
      'Haz',
      'Tem',
      'Ağu',
      'Eyl',
      'Eki',
      'Kas',
      'Ara',
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]}';
  }
}

class _HeaderDot extends StatelessWidget {
  const _HeaderDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: 5,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: FRColors.camelStrong,
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
      constraints: const BoxConstraints(maxWidth: 180),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x33C09A60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on_outlined, color: FRColors.camelStrong, size: 14),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white.withOpacity(0.72),
              ),
            ),
          ),
        ],
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
    required this.onChanged,
    required this.onSubmit,
    required this.onClose,
    required this.onTrendTap,
    required this.onRemoveRecent,
  });

  final bool open;
  final TextEditingController controller;
  final FocusNode focusNode;
  final List<String> trends;
  final List<String> recents;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmit;
  final VoidCallback onClose;
  final ValueChanged<String> onTrendTap;
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
          offset: open ? Offset.zero : const Offset(0, 0.02),
          child: Material(
            color: FRColors.backgroundWarm,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                    decoration: const BoxDecoration(
                      color: FRColors.espresso,
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.search_rounded,
                                  color: Colors.white.withOpacity(0.35),
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: controller,
                                    focusNode: focusNode,
                                    onChanged: onChanged,
                                    onSubmitted: (value) {
                                      onSubmit(value);
                                      onClose();
                                    },
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Ürün, mağaza veya kategori ara…',
                                      hintStyle: TextStyle(
                                        color: Colors.white.withOpacity(0.26),
                                        fontStyle: FontStyle.italic,
                                      ),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: onClose,
                          child: Text(
                            'İptal',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      children: [
                        if (trends.isNotEmpty) ...[
                          const _OverlayTitle(
                            icon: Icons.trending_up_rounded,
                            title: 'Trend Aramalar',
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (var i = 0; i < trends.length; i++)
                                _TrendChip(
                                  label: trends[i],
                                  hot: i == 0,
                                  onTap: () => onTrendTap(trends[i]),
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                        if (recents.isNotEmpty) ...[
                          const _OverlayTitle(
                            icon: Icons.history_rounded,
                            title: 'Son Aramalarım',
                          ),
                          const SizedBox(height: 8),
                          ...recents.map(
                            (term) => _RecentRow(
                              term: term,
                              onTap: () => onTrendTap(term),
                              onRemove: () => onRemoveRecent(term),
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

class _OverlayTitle extends StatelessWidget {
  const _OverlayTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: FRColors.textMuted),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.7,
            color: FRColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _TrendChip extends StatelessWidget {
  const _TrendChip({required this.label, required this.onTap, this.hot = false});

  final String label;
  final VoidCallback onTap;
  final bool hot;

  @override
  Widget build(BuildContext context) {
    return PremiumPressable(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: hot ? const Color(0xFFFFF4E8) : FRColors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: hot ? const Color(0x40C09A60) : FRColors.border,
          ),
          boxShadow: const [
            BoxShadow(
              color: FRColors.shadowSoft,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hot ? Icons.local_fire_department_rounded : Icons.search_rounded,
              size: 15,
              color: hot ? const Color(0xFFEF6C00) : FRColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: FRColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({
    required this.term,
    required this.onTap,
    required this.onRemove,
  });

  final String term;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return PremiumPressable(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: FRColors.border)),
        ),
        child: Row(
          children: [
            const Icon(Icons.history_rounded, size: 16, color: FRColors.textMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                term,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: FRColors.textPrimary,
                ),
              ),
            ),
            GestureDetector(
              onTap: onRemove,
              child: const Icon(Icons.close_rounded, size: 16, color: FRColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: FRColors.camelStrong,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: title,
                    style: const TextStyle(
                      color: FRColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (subtitle != null)
                    TextSpan(
                      text: '  $subtitle',
                      style: const TextStyle(
                        color: FRColors.textMuted,
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (actionLabel != null)
            PremiumPressable(
              borderRadius: BorderRadius.circular(8),
              onTap: onAction,
              child: Text(
                '$actionLabel →',
                style: const TextStyle(
                  color: FRColors.camelStrong,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AlarmBanner extends StatelessWidget {
  const _AlarmBanner({
    required this.count,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final int count;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PremiumPressable(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: FRColors.espresso,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: FRColors.shadowStrong,
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: FRColors.camelOverlay(0.16),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: FRColors.camelOverlay(0.22)),
              ),
              child: const Icon(Icons.notifications_active_outlined,
                  color: FRColors.camelStrong, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count fiyat alarmın tetiklendi!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle.isEmpty ? title : subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.44),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: FRColors.camelStrong,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Text(
                'Gör →',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniInsightCard extends StatelessWidget {
  const _MiniInsightCard({
    required this.item,
    required this.positive,
    required this.onTap,
    this.compact = false,
  });

  final ExploreFeedItem item;
  final bool positive;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final percent = (positive ? (item.priceChangePercent ?? 0) : item.dropPercent).abs();
    final badgeColor = positive ? FRColors.danger : FRColors.success;
    final badgeBg = positive ? FRColors.dangerSurface : FRColors.successSurface;

    return PremiumPressable(
      borderRadius: BorderRadius.circular(compact ? 16 : 18),
      onTap: onTap,
      child: Container(
        width: compact ? 152 : 154,
        padding: EdgeInsets.all(compact ? 10 : 0),
        decoration: BoxDecoration(
          color: FRColors.white,
          borderRadius: BorderRadius.circular(compact ? 16 : 18),
          boxShadow: const [
            BoxShadow(
              color: FRColors.shadowSoft,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
          border: compact && positive
              ? const Border(left: BorderSide(color: FRColors.danger, width: 3))
              : null,
        ),
        child: compact
            ? Row(
                children: [
                  _MiniProductThumb(item: item, compact: true),
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
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: FRColors.textPrimary,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              _formatTry(item.displayPrice),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: badgeColor,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: badgeBg,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                '+%${percent.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: badgeColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 86,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: FRColors.studio,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                    ),
                    child: Stack(
                      children: [
                        Center(child: _MiniProductThumb(item: item)),
                        Positioned(
                          left: 8,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: FRColors.espresso.withOpacity(0.78),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'EN DÜŞÜK',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                              ),
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
                        Text(
                          item.product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: FRColors.textPrimary,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatTry(item.displayPrice),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: FRColors.textPrimary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: badgeBg,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                '%${percent.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: badgeColor,
                                ),
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

class _MiniProductThumb extends StatelessWidget {
  const _MiniProductThumb({required this.item, this.compact = false});

  final ExploreFeedItem item;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final image = item.product.effectiveImage;
    return Padding(
      padding: EdgeInsets.all(compact ? 8 : 12),
      child: SizedBox(
        width: compact ? 42 : 62,
        height: compact ? 42 : 62,
        child: image != null && image.trim().isNotEmpty
            ? Image.network(
                image,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.image_not_supported_rounded,
                  color: FRColors.textHint,
                ),
              )
            : const Icon(Icons.inventory_2_outlined, color: FRColors.textHint),
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
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 7,
        mainAxisSpacing: 7,
        childAspectRatio: 0.95,
      ),
      itemBuilder: (context, index) {
        final category = categories[index];
        final theme = CategoryThemeCatalog.resolve(id: category.id, title: category.name);
        final isSelected = selected.toLowerCase() == category.name.toLowerCase();
        return PremiumPressable(
          borderRadius: BorderRadius.circular(15),
          onTap: () => onTap(category),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? FRColors.espresso : FRColors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isSelected ? FRColors.espresso : Colors.transparent,
                width: 1.5,
              ),
              boxShadow: const [
                BoxShadow(
                  color: FRColors.shadowSoft,
                  blurRadius: 10,
                  offset: Offset(0, 4),
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
                        ? Colors.white.withOpacity(0.08)
                        : (theme.bgTint ?? FRColors.camelOverlay(0.08)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      category.emoji?.trim().isNotEmpty == true
                          ? category.emoji!.trim()
                          : _emojiForCategory(theme.id),
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  category.name,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : FRColors.textMuted,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NearbyMarketsCard extends StatelessWidget {
  const _NearbyMarketsCard({
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FRColors.espresso,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: FRColors.shadowStrong,
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '📍 $locationLabel',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Text(
                'Haritada gör →',
                style: TextStyle(
                  color: FRColors.camelStrong,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final item in stores)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: PremiumPressable(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => onStoreTap(item.store),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.08)),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: _storeColor(item.store.displayName),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  item.store.displayName.characters.first.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              item.store.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.58),
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.distanceLabel,
                              style: const TextStyle(
                                color: FRColors.camelStrong,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CommunityCard extends StatelessWidget {
  const _CommunityCard({required this.user, required this.onTap});

  final UserModel? user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final points = user?.weeklyPoints ?? user?.points ?? 10;
    final contributionCount = user?.priceEntries ?? 0;
    return PremiumPressable(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: FRColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: FRColors.shadowSoft,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: FRColors.camelOverlay(0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.groups_rounded, color: FRColors.camelStrong, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sen de katkıda bulun',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: FRColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    contributionCount > 0
                        ? '$contributionCount fiyat girdin, yeni katkıyla puanını büyüt.'
                        : 'Yeni fiyat ekle, topluluğa katkı sağla.',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: FRColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
              decoration: BoxDecoration(
                color: FRColors.camelStrong,
                borderRadius: BorderRadius.circular(11),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x59C09A60),
                    blurRadius: 14,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                '+${math.max(points, 10)} puan',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarcodeFooterCard extends StatelessWidget {
  const _BarcodeFooterCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PremiumPressable(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: FRColors.espresso,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: FRColors.borderStrong),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fırsatı Bulamadın mı?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Barkodu okut, anında fiyatı keşfet.',
                    style: TextStyle(
                      color: FRColors.whiteMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: FRColors.camelStrong,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.qr_code_scanner_rounded, color: FRColors.espresso),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: FRColors.camelStrong,
            ),
          ),
          SizedBox(height: 14),
          Text(
            'Ürünler yükleniyor...',
            style: TextStyle(color: FRColors.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.wifi_off_rounded,
            size: 48,
            color: AppColors.textTertiary.withOpacity(0.5),
          ),
          const SizedBox(height: 14),
          const Text(
            'Bağlantı hatası',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Tekrar dene'),
            style: FilledButton.styleFrom(
              backgroundColor: FRColors.camelDeep,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 56,
            color: AppColors.textTertiary.withOpacity(0.4),
          ),
          const SizedBox(height: 14),
          const Text(
            'Henüz bu filtrede fiyat yok',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Farklı bir kategori veya market deneyin',
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscoverProductCard extends ConsumerWidget {
  const _DiscoverProductCard({
    super.key,
    required this.item,
    required this.mode,
    required this.accentColor,
    required this.onTap,
  });

  final ExploreFeedItem item;
  final ExploreMode mode;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final override = ref.watch(favoriteOverrideProvider(item.product.id));
    final favoriteAsync = ref.watch(isFavoriteProvider(item.product.id));
    final serverFavorite = favoriteAsync.valueOrNull ?? false;
    final isFavorite = override ?? serverFavorite;
    final image = item.product.effectiveImage;
    final priceChange = item.priceChangePercent;

    return PremiumPressable(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: FRColors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: FRColors.shadowSoft,
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              flex: 9,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F2EC),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: image != null && image.trim().isNotEmpty
                          ? Image.network(
                              image,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.image_not_supported_rounded,
                                color: FRColors.textHint,
                              ),
                            )
                          : const Icon(Icons.inventory_2_outlined, color: FRColors.textHint),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    top: 8,
                    child: _PriceBadge(
                      dropPercent: item.dropPercent,
                      priceChangePercent: priceChange,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () async {
                        final next = !isFavorite;
                        ref
                            .read(favoriteOverrideProvider(item.product.id).notifier)
                            .state = next;
                        await ref
                            .read(userNotifierProvider.notifier)
                            .toggleSavedProduct(item.product.id);
                      },
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x19000000),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 16,
                          color: isFavorite ? FRColors.danger : FRColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.product.brand.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: FRColors.camelStrong,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: FRColors.textPrimary,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatTry(item.displayPrice),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: FRColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: FRColors.border)),
                      color: Color(0x051C1108),
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: accentColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.storeName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: FRColors.textMuted,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          mode == ExploreMode.online
                              ? Icons.language_rounded
                              : Icons.location_on_outlined,
                          size: 10,
                          color: FRColors.textMuted,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          _metaLabel(item, mode),
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: FRColors.textMuted,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: FRColors.successSurface,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 10,
                            color: FRColors.success,
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
      ),
    );
  }

  String _metaLabel(ExploreFeedItem item, ExploreMode mode) {
    if (mode == ExploreMode.online) return 'Online';
    return item.distanceLabel ?? item.neighborhoodLabel;
  }
}

class _PriceBadge extends StatelessWidget {
  const _PriceBadge({
    required this.dropPercent,
    required this.priceChangePercent,
  });

  final double dropPercent;
  final double? priceChangePercent;

  @override
  Widget build(BuildContext context) {
    if (dropPercent > 0) {
      return _buildBadge(
        label: '%${dropPercent.toStringAsFixed(0)}',
        background: FRColors.successSurface,
        color: FRColors.success,
        icon: Icons.south_rounded,
      );
    }
    if ((priceChangePercent ?? 0) > 0) {
      return _buildBadge(
        label: '%${priceChangePercent!.toStringAsFixed(0)}',
        background: FRColors.dangerSurface,
        color: FRColors.danger,
        icon: Icons.north_rounded,
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildBadge({
    required String label,
    required Color background,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketChipData {
  const _MarketChipData({required this.label, required this.color});

  final String label;
  final Color color;
}

class _NearbyStoreData {
  const _NearbyStoreData({required this.store, required this.distanceMeters});

  final StoreModel store;
  final double? distanceMeters;

  String get distanceLabel {
    if (distanceMeters == null) return 'Yakında';
    if (distanceMeters! < 1000) return '${distanceMeters!.round()}m';
    return '${(distanceMeters! / 1000).toStringAsFixed(1)} km';
  }
}

Color _storeColor(String storeName) {
  const palette = <Color>[
    Color(0xFFD44020),
    Color(0xFFF5C518),
    Color(0xFF8B5CF6),
    Color(0xFFF0A030),
    Color(0xFF2E7D32),
    Color(0xFF1976D2),
  ];
  final index = storeName.trim().toLowerCase().hashCode.abs() % palette.length;
  return palette[index];
}

String _emojiForCategory(String normalizedId) {
  switch (normalizedId) {
    case 'gida':
      return '🥗';
    case 'kisisel_bakim':
      return '🧴';
    case 'ev_yasam':
      return '🏠';
    case 'elektronik':
      return '💻';
    case 'kitap':
      return '📚';
    case 'spor':
      return '⚽';
    case 'bebek':
      return '🍼';
    case 'icecek':
      return '🥤';
    default:
      return '🛒';
  }
}

String _formatTry(double value) {
  final fixed = value.toStringAsFixed(2).replaceAll('.', ',');
  return '$fixed₺';
}
