import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

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
import '../../widgets/premium_pressable.dart';
import '../actual/actuals_screen.dart';
import '../add_price/add_price_screen.dart';
import '../notifications/notifications_screen.dart';
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

TextStyle _txt({
  double size = 14,
  FontWeight weight = FontWeight.w500,
  Color color = _t1,
  double? letterSpacing,
  double? height,
  FontStyle? fontStyle,
}) {
  return GoogleFonts.plusJakartaSans(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
    fontStyle: fontStyle,
  );
}

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _overlayController = TextEditingController();
  final FocusNode _overlayFocusNode = FocusNode();

  bool _overlayOpen = false;
  String _selectedMarket = 'Tümü';
  String _selectedCategory = 'Tumu';
  String _selectedCategoryGrid = 'Gıda';
  final Set<String> _favoriteProductIds = <String>{};
  final Set<String> _removedRecents = <String>{};

  @override
  void dispose() {
    _overlayController.dispose();
    _overlayFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exploreState = ref.watch(exploreControllerProvider);
    final categories = ref.watch(orderedCategoriesProvider);
    final notifications =
        ref.watch(notificationsProvider).valueOrNull ?? const <NotificationItem>[];
    final nearbyStores = ref.watch(nearbyStoresProvider).valueOrNull ?? const <StoreModel>[];
    final user = ref.watch(userModelStreamProvider).valueOrNull;
    final actual = ref.watch(latestActiveActualProvider).valueOrNull;
    ref.watch(authStateProvider);
    ref.watch(dailyDealProductProvider);

    final locationLabel = _resolveLocation(user, exploreState, nearbyStores);
    final visibleItems = _filterItems(exploreState.items);
    final marketFilters = _buildMarketFilters(exploreState.items);
    final dropItems = _buildDropItems(exploreState.items);
    final recentTerms = (ref.watch(searchHistoryProvider).valueOrNull ?? const <String>[])
        .where((e) => e.trim().isNotEmpty)
        .where((e) => !_removedRecents.contains(e.trim().toLowerCase()))
        .take(6)
        .toList();
    final trendTerms = _buildTrendTerms(exploreState.items, categories, recentTerms);
    final alarmItems = notifications.where((item) => item.type == 'alarm').toList();

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _buildHeader(locationLabel),
                ),
                SliverToBoxAdapter(
                  child: _buildCategoryChips(exploreState),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: _CampaignCountdownCard(
                      onTap: () {
                        if (actual != null) {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const ActualsScreen(),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _SectionHeader(
                    title: 'Ürünler',
                    actionLabel: 'Tümünü Gör',
                    onActionTap: visibleItems.isEmpty ? null : () {},
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildMarketFilterRow(marketFilters),
                ),
                if (exploreState.loading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: CircularProgressIndicator(color: _tc),
                    ),
                  )
                else if (exploreState.error != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _InfoCard(
                        title: 'Keşfet yüklenemedi',
                        subtitle: exploreState.error!,
                        actionLabel: 'Tekrar Dene',
                        onTap: () => ref.read(exploreControllerProvider.notifier).retry(),
                      ),
                    ),
                  )
                else if (visibleItems.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: _InfoCard(
                        title: 'Gösterilecek ürün bulunamadı',
                        subtitle: 'Farklı kategori veya market seçerek keşfetmeye devam et.',
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = visibleItems[index];
                          return _DiscoverProductCard(
                            item: item,
                            isFavorite: _favoriteProductIds.contains(item.product.id),
                            onTap: () => _openProduct(item),
                            onFavoriteTap: () {
                              setState(() {
                                if (!_favoriteProductIds.add(item.product.id)) {
                                  _favoriteProductIds.remove(item.product.id);
                                }
                              });
                            },
                          );
                        },
                        childCount: math.min(visibleItems.length, 6),
                      ),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 0.73,
                      ),
                    ),
                  ),
                if (dropItems.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _SectionHeader(
                      title: 'Fiyatı Düşenler',
                      subTitle: 'bu hafta',
                      actionLabel: 'Tümünü Gör',
                      onActionTap: () {},
                    ),
                  ),
                if (dropItems.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildDropRow(dropItems),
                  ),
                SliverToBoxAdapter(
                  child: _SectionHeader(title: 'Kategoriler'),
                ),
                SliverToBoxAdapter(
                  child: _CategoryGrid(
                    categories: _buildCategoryTiles(categories),
                    selected: _selectedCategoryGrid,
                    onTap: (label) {
                      setState(() {
                        _selectedCategoryGrid = label;
                        _selectedCategory = label == 'Tümü' ? 'Tumu' : label;
                      });
                      ref.read(exploreControllerProvider.notifier).updateCategory(
                            label == 'Tümü' ? 'Tumu' : label,
                          );
                    },
                  ),
                ),
                if (alarmItems.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 22),
                      child: _SectionHeader(title: 'Bildirimler', bottomPadding: 0),
                    ),
                  ),
                if (alarmItems.isNotEmpty)
                  SliverToBoxAdapter(
                    child: const SizedBox(height: 12),
                  ),
                if (alarmItems.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _AlarmBanner(
                      count: alarmItems.length,
                      subtitle: _alarmSubtitle(alarmItems),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const NotificationsScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                SliverToBoxAdapter(
                  child: _SectionHeader(title: 'Yakınındaki Marketler'),
                ),
                SliverToBoxAdapter(
                  child: _NearbyMarketsCard(
                    locationLabel: locationLabel,
                    stores: _buildNearbyMarketTiles(nearbyStores, visibleItems),
                    onTapMap: () {},
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20, bottom: 32),
                    child: _BarcodeFooterCard(
                      onTap: _scanBarcode,
                    ),
                  ),
                ),
              ],
            ),
            _SearchOverlay(
              open: _overlayOpen,
              controller: _overlayController,
              focusNode: _overlayFocusNode,
              trends: trendTerms,
              recents: recentTerms,
              onClose: _closeOverlay,
              onChanged: _applySearch,
              onSubmitted: (value) async {
                await _applySearch(value);
                _closeOverlay();
              },
              onPickTrend: (value) async {
                _overlayController.text = value;
                await _applySearch(value);
              },
              onRemoveRecent: (value) {
                setState(() {
                  _removedRecents.add(value.trim().toLowerCase());
                });
              },
            ),
          ],
        ),
      ),
      floatingActionButton: PremiumPressable(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const AddPriceScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _dk,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: _dk.withOpacity(0.18),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_rounded, color: _w, size: 18),
              const SizedBox(width: 8),
              Text('Fiyat Ekle', style: _txt(size: 13, weight: FontWeight.w800, color: _w)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String locationLabel) {
    return Container(
      color: _dk,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Keşfet',
                style: _txt(size: 26, weight: FontWeight.w900, color: _w, letterSpacing: -0.6),
              ),
              const Spacer(),
              PremiumPressable(
                onTap: () {},
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _w.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: _tc.withOpacity(0.28)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on_outlined, size: 12, color: _tc),
                      const SizedBox(width: 4),
                      Text(
                        locationLabel,
                        style: _txt(size: 11, weight: FontWeight.w700, color: _tc),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          PremiumPressable(
            onTap: _openOverlay,
            borderRadius: BorderRadius.circular(13),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
              decoration: BoxDecoration(
                color: _w,
                borderRadius: BorderRadius.circular(13),
                boxShadow: [
                  BoxShadow(
                    color: _dk.withOpacity(0.12),
                    blurRadius: 14,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, size: 15, color: _t3),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Ürün, marka veya mağaza ara...',
                      style: _txt(
                        size: 13,
                        color: _t3,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  PremiumPressable(
                    onTap: _scanBarcode,
                    borderRadius: BorderRadius.circular(9),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: _bg,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.qr_code_scanner_rounded, size: 16, color: _dk),
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

  Widget _buildCategoryChips(ExploreState state) {
    final chips = <String>['Tumu', ...state.categories.where((e) => e != 'Tumu')];
    return SizedBox(
      height: 52,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final label = chips[index];
          final isSelected = _selectedCategory == label;
          return PremiumPressable(
            onTap: () {
              setState(() => _selectedCategory = label);
              ref.read(exploreControllerProvider.notifier).updateCategory(label);
            },
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? _dk : _w,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: _dk.withOpacity(isSelected ? 0.20 : 0.07),
                    blurRadius: isSelected ? 10 : 6,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    _chipIcon(label),
                    size: 12,
                    color: isSelected ? _w : _t2,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    label == 'Tumu' ? 'Tümü' : label,
                    style: _txt(
                      size: 12,
                      weight: FontWeight.w800,
                      color: isSelected ? _w : _t1,
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

  Widget _buildMarketFilterRow(List<_MarketFilter> filters) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 2),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedMarket == filter.label;
          return PremiumPressable(
            onTap: () {
              setState(() => _selectedMarket = filter.label);
            },
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? _dk : _w,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: _dk.withOpacity(isSelected ? 0.20 : 0.07),
                    blurRadius: isSelected ? 10 : 6,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (filter.label != 'Tümü') ...[
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: filter.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    filter.label,
                    style: _txt(
                      size: 11,
                      weight: FontWeight.w800,
                      color: isSelected ? _w : _t2,
                    ),
                  ),
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

  Widget _buildDropRow(List<ExploreFeedItem> items) {
    return SizedBox(
      height: 191,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) => _DropCard(
          item: items[index],
          onTap: () => _openProduct(items[index]),
        ),
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemCount: math.min(items.length, 4),
      ),
    );
  }

  Future<void> _scanBarcode() async {
    final barcode = await BarcodeScannerSheet.scan(context, title: 'Barkod Tara');
    if (!mounted || barcode == null || barcode.trim().isEmpty) return;
    await _applySearch(barcode.trim());
  }

  void _openOverlay() {
    setState(() => _overlayOpen = true);
    _overlayController.selection = TextSelection.collapsed(offset: _overlayController.text.length);
    Future<void>.microtask(() => _overlayFocusNode.requestFocus());
  }

  void _closeOverlay() {
    _overlayFocusNode.unfocus();
    setState(() => _overlayOpen = false);
  }

  Future<void> _applySearch(String value) async {
    ref.read(exploreControllerProvider.notifier).updateSearchQuery(value);
    if (value.trim().isNotEmpty) {
      await ref.read(userNotifierProvider.notifier).saveSearch(value.trim());
    }
  }

  void _openProduct(ExploreFeedItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductDetailScreen(product: item.product),
      ),
    );
  }

  List<ExploreFeedItem> _filterItems(List<ExploreFeedItem> items) {
    return items.where((item) {
      final marketMatch = _selectedMarket == 'Tümü' || item.storeName == _selectedMarket;
      final categoryMatch =
          _selectedCategory == 'Tumu' || item.product.categories.any((e) => e == _selectedCategory);
      return marketMatch && categoryMatch;
    }).toList();
  }

  List<_MarketFilter> _buildMarketFilters(List<ExploreFeedItem> items) {
    final seen = <String>{};
    final filters = <_MarketFilter>[const _MarketFilter('Tümü', _tc)];
    for (final item in items) {
      final label = item.storeName.trim();
      if (label.isEmpty || !seen.add(label.toLowerCase())) continue;
      filters.add(_MarketFilter(label, _marketColor(label)));
    }
    return filters;
  }

  List<String> _buildTrendTerms(
    List<ExploreFeedItem> items,
    List<CategoryModel> categories,
    List<String> recents,
  ) {
    final values = <String>[];
    final seen = <String>{};

    void add(String value) {
      final trimmed = value.trim();
      if (trimmed.isEmpty || !seen.add(trimmed.toLowerCase())) return;
      values.add(trimmed);
    }

    add('Nutella');
    for (final recent in recents) {
      add(recent);
    }
    for (final item in items.take(4)) {
      add(item.product.name);
    }
    for (final category in categories.take(2)) {
      add(category.name);
    }
    return values.take(6).toList();
  }

  List<ExploreFeedItem> _buildDropItems(List<ExploreFeedItem> items) {
    final result = [...items]
      ..removeWhere((item) => item.dropPercent <= 0)
      ..sort((a, b) => b.dropPercent.compareTo(a.dropPercent));
    return result.take(4).toList();
  }

  String _resolveLocation(
    UserModel? user,
    ExploreState state,
    List<StoreModel> nearbyStores,
  ) {
    final address = state.userLocation?.address?.trim();
    if (address != null && address.isNotEmpty) {
      return address.split(',').take(2).join(', ').trim();
    }
    final userParts = [user?.neighborhood, user?.city]
        .whereType<String>()
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (userParts.isNotEmpty) return userParts.join(', ');
    final store = nearbyStores.isNotEmpty ? nearbyStores.first : null;
    final storeParts = [store?.district, store?.city]
        .whereType<String>()
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (storeParts.isNotEmpty) return storeParts.join(', ');
    return 'Çekmeköy, İstanbul';
  }

  String _alarmSubtitle(List<NotificationItem> items) {
    final names = items
        .map((e) => (e.productName ?? e.title).trim())
        .where((e) => e.isNotEmpty)
        .take(2)
        .toList();
    if (names.isEmpty) return 'Yeni alarm bildirimlerin seni bekliyor';
    return '${names.join(' ve ')} yeni fiyatlandı';
  }

  List<_NearbyMarketTileData> _buildNearbyMarketTiles(
    List<StoreModel> stores,
    List<ExploreFeedItem> items,
  ) {
    final data = <_NearbyMarketTileData>[];
    for (final store in stores.take(5)) {
      final related = items.cast<ExploreFeedItem?>().firstWhere(
            (item) => item?.store?.id == store.id || item?.storeName == store.displayName,
            orElse: () => null,
          );
      data.add(
        _NearbyMarketTileData(
          letter: store.displayName.isEmpty ? '?' : store.displayName.substring(0, 1),
          name: store.displayName,
          distance: related?.distanceLabel ?? 'Yakın',
          color: _marketColor(store.displayName),
        ),
      );
    }
    if (data.isNotEmpty) return data;
    return const [
      _NearbyMarketTileData(letter: 'A', name: 'A-101', distance: '176m', color: Color(0xFFD44020)),
      _NearbyMarketTileData(letter: 'B', name: 'BİM', distance: '200m', color: Color(0xFFC89018)),
      _NearbyMarketTileData(letter: 'Ş', name: 'ŞOK', distance: '202m', color: Color(0xFF6B2FA0)),
      _NearbyMarketTileData(letter: 'M', name: 'Migros', distance: '340m', color: Color(0xFFC07010)),
      _NearbyMarketTileData(letter: 'C', name: 'Carrefour', distance: '480m', color: Color(0xFF1840C0)),
    ];
  }

  List<_CategoryTileData> _buildCategoryTiles(List<CategoryModel> categories) {
    final defaults = <_CategoryTileData>[
      _CategoryTileData('Gıda', Icons.menu_rounded, _grn.withOpacity(0.10), _grn),
      _CategoryTileData('Bakım', Icons.favorite_outline_rounded, const Color(0x1A8264C8), const Color(0xFF8264C8)),
      _CategoryTileData('Ev', Icons.home_outlined, _tc.withOpacity(0.12), _tc),
      _CategoryTileData('Elektronik', Icons.devices_outlined, const Color(0x1A1E64DC), const Color(0xFF1E64DC)),
      _CategoryTileData('Giyim', Icons.checkroom_outlined, _red.withOpacity(0.10), _red),
      _CategoryTileData('Kitap', Icons.book_outlined, _tan.withOpacity(0.12), _tan),
      _CategoryTileData('Spor', Icons.sports_basketball_outlined, _grn.withOpacity(0.10), _grn),
      _CategoryTileData('Otomotiv', Icons.local_shipping_outlined, _dk.withOpacity(0.07), _t2),
    ];
    if (categories.isEmpty) return defaults;
    final mapped = <_CategoryTileData>[];
    for (var i = 0; i < math.min(8, categories.length); i++) {
      final base = defaults[i % defaults.length];
      mapped.add(_CategoryTileData(categories[i].name, base.icon, base.bg, base.fg));
    }
    return mapped;
  }
}

class _CampaignCountdownCard extends StatefulWidget {
  const _CampaignCountdownCard({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_CampaignCountdownCard> createState() => _CampaignCountdownCardState();
}

class _CampaignCountdownCardState extends State<_CampaignCountdownCard> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick() {
    final now = DateTime.now();
    var target = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final daysUntilSunday = ((DateTime.sunday - now.weekday) % 7 == 0)
        ? 7
        : (DateTime.sunday - now.weekday) % 7;
    target = target.add(Duration(days: daysUntilSunday));
    final diff = target.difference(now);
    if (!mounted) return;
    setState(() {
      _remaining = diff.isNegative ? Duration.zero : diff;
    });
  }

  @override
  Widget build(BuildContext context) {
    final days = _remaining.inDays;
    final hours = _remaining.inHours.remainder(24);
    final minutes = _remaining.inMinutes.remainder(60);
    final seconds = _remaining.inSeconds.remainder(60);

    return PremiumPressable(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          color: _dk,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: _dk.withOpacity(0.22),
              blurRadius: 26,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: RadialGradient(
                    center: const Alignment(0.9, -0.8),
                    radius: 1,
                    colors: [_tc.withOpacity(0.18), Colors.transparent],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
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
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: _tc.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(7),
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
                                    style: _txt(
                                      size: 9,
                                      weight: FontWeight.w800,
                                      color: _tcl,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Haftalık Fırsatlar\nBitiyor!',
                              style: _txt(size: 18, weight: FontWeight.w900, color: _w, height: 1.2),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Kampanyalar pazar gece yarısı sona eriyor',
                              style: _txt(size: 11, color: _w.withOpacity(0.35)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _tc,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Gör →',
                          style: _txt(size: 11, weight: FontWeight.w800, color: _dk),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Text(
                        'Kalan',
                        style: _txt(
                          size: 9,
                          weight: FontWeight.w700,
                          color: _w.withOpacity(0.28),
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _CountdownBlock(value: days),
                      _CountdownSeparator(),
                      _CountdownBlock(value: hours, unit: 'Saat'),
                      _CountdownSeparator(),
                      _CountdownBlock(value: minutes, unit: 'Dak'),
                      _CountdownSeparator(),
                      _CountdownBlock(value: seconds, unit: 'Sn'),
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

class _CountdownBlock extends StatelessWidget {
  const _CountdownBlock({required this.value, this.unit = 'Gün'});

  final int value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 42),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _w.withOpacity(0.08),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        children: [
          Text(
            value.toString().padLeft(2, '0'),
            style: _txt(size: 20, weight: FontWeight.w900, color: _w, letterSpacing: -0.6),
          ),
          Text(
            unit,
            style: _txt(size: 7, weight: FontWeight.w700, color: _t3, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }
}

class _CountdownSeparator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 6, right: 6),
      child: Text(':', style: _txt(size: 16, weight: FontWeight.w900, color: _w.withOpacity(0.16))),
    );
  }
}

class _DiscoverProductCard extends StatelessWidget {
  const _DiscoverProductCard({
    required this.item,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteTap,
  });

  final ExploreFeedItem item;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    final discount = item.dropPercent > 0 ? item.dropPercent : (item.priceChangePercent ?? 0);
    final isDrop = item.dropPercent > 0;

    return PremiumPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: _w,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _dk.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            SizedBox(
              height: 114,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: _imageBg(item.storeName),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: (item.product.effectiveImage ?? '').isNotEmpty
                            ? AppNetworkImage(
                                imageUrl: item.product.effectiveImage,
                                cacheKey: 'discover_${item.product.id}',
                                fit: BoxFit.contain,
                              )
                            : Icon(Icons.inventory_2_outlined, size: 44, color: _t3.withOpacity(0.5)),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 7,
                    left: 7,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _w.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isDrop ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_up_rounded,
                            size: 9,
                            color: isDrop ? _grn : _red,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '%${discount.abs().round()}',
                            style: _txt(
                              size: 9,
                              weight: FontWeight.w900,
                              color: isDrop ? _grn : _red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 7,
                    right: 7,
                    child: PremiumPressable(
                      onTap: onFavoriteTap,
                      borderRadius: BorderRadius.circular(99),
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: _w.withOpacity(0.92),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          size: 12,
                          color: isFavorite ? _red : _dk.withOpacity(0.28),
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
                      item.product.brand.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _txt(
                        size: 9,
                        weight: FontWeight.w700,
                        color: _tc,
                        letterSpacing: 0.45,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        item.product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: _txt(size: 12, weight: FontWeight.w800, color: _t1, height: 1.3),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      _formatPrice(item.displayPrice),
                      style: _txt(size: 17, weight: FontWeight.w900, color: _t1, letterSpacing: -0.5),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(11, 7, 11, 10),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: _dk.withOpacity(0.06))),
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
                            color: _marketColor(item.storeName),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            item.storeName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _txt(size: 10, weight: FontWeight.w700, color: _t2),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on_outlined, size: 8, color: _t3),
                      const SizedBox(width: 2),
                      Text(
                        item.distanceLabel ?? 'Online',
                        style: _txt(size: 9, weight: FontWeight.w700, color: _t3),
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
                    child: Icon(Icons.chevron_right_rounded, size: 10, color: _t3),
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

class _DropCard extends StatelessWidget {
  const _DropCard({required this.item, required this.onTap});

  final ExploreFeedItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PremiumPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          color: _w,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: _dk.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 86,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: _imageBg(item.storeName),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: (item.product.effectiveImage ?? '').isNotEmpty
                            ? AppNetworkImage(
                                imageUrl: item.product.effectiveImage,
                                cacheKey: 'drop_${item.product.id}',
                                fit: BoxFit.contain,
                              )
                            : Icon(Icons.shopping_bag_outlined, color: _t3.withOpacity(0.4), size: 34),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: _dk.withOpacity(0.72)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'EN DÜŞÜK',
                            style: _txt(size: 8, weight: FontWeight.w800, color: _tcl, letterSpacing: 0.4),
                          ),
                          Text(
                            '▼%${item.dropPercent.round()}',
                            style: _txt(size: 9, weight: FontWeight.w900, color: _grn),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 7, 10, 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.brand.toUpperCase(),
                    style: _txt(size: 8, weight: FontWeight.w700, color: _tc, letterSpacing: 0.4),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: _txt(size: 11, weight: FontWeight.w800, color: _t1, height: 1.3),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _formatPrice(item.displayPrice),
                    style: _txt(size: 13, weight: FontWeight.w900, color: _t1),
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

  final List<_CategoryTileData> categories;
  final String selected;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: categories.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.88,
        ),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selected == category.label;
          return PremiumPressable(
            onTap: () => onTap(category.label),
            borderRadius: BorderRadius.circular(15),
            child: Container(
              padding: const EdgeInsets.fromLTRB(6, 12, 6, 10),
              decoration: BoxDecoration(
                color: isSelected ? _dk : _w,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: _dk.withOpacity(isSelected ? 0.22 : 0.07),
                    blurRadius: isSelected ? 16 : 7,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isSelected ? _w.withOpacity(0.10) : category.bg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(category.icon, size: 17, color: isSelected ? _w : category.fg),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    category.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: _txt(
                      size: 9,
                      weight: FontWeight.w800,
                      color: isSelected ? _w.withOpacity(0.75) : _t2,
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

class _AlarmBanner extends StatelessWidget {
  const _AlarmBanner({
    required this.count,
    required this.subtitle,
    required this.onTap,
  });

  final int count;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: PremiumPressable(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          decoration: BoxDecoration(
            color: _dk,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(color: _dk.withOpacity(0.14), blurRadius: 16, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _tc.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(Icons.notifications_none_rounded, size: 17, color: _tc),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$count fiyat alarmın tetiklendi!',
                      style: _txt(size: 13, weight: FontWeight.w800, color: _w),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: _txt(size: 11, color: _w.withOpacity(0.35)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _tc,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('Gör →', style: _txt(size: 11, weight: FontWeight.w800, color: _dk)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NearbyMarketsCard extends StatelessWidget {
  const _NearbyMarketsCard({
    required this.locationLabel,
    required this.stores,
    required this.onTapMap,
  });

  final String locationLabel;
  final List<_NearbyMarketTileData> stores;
  final VoidCallback onTapMap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _dk,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: _dk.withOpacity(0.18), blurRadius: 20, offset: const Offset(0, 5)),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 11, color: _tc),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          locationLabel,
                          style: _txt(size: 13, weight: FontWeight.w900, color: _w),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                PremiumPressable(
                  onTap: onTapMap,
                  borderRadius: BorderRadius.circular(999),
                  child: Text('Haritada gör →', style: _txt(size: 10, weight: FontWeight.w700, color: _tc)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (var i = 0; i < stores.length; i++) ...[
                  Expanded(
                    child: _NearbyMarketItem(data: stores[i]),
                  ),
                  if (i != stores.length - 1) const SizedBox(width: 6),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NearbyMarketItem extends StatelessWidget {
  const _NearbyMarketItem({required this.data});

  final _NearbyMarketTileData data;

  @override
  Widget build(BuildContext context) {
    return PremiumPressable(
      onTap: () {},
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          color: _w.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _w.withOpacity(0.08)),
        ),
        child: Column(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(color: data.color, borderRadius: BorderRadius.circular(8)),
              alignment: Alignment.center,
              child: Text(data.letter, style: _txt(size: 10, weight: FontWeight.w900, color: _w)),
            ),
            const SizedBox(height: 4),
            Text(
              data.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _txt(size: 8, weight: FontWeight.w700, color: _w.withOpacity(0.35)),
            ),
            const SizedBox(height: 2),
            Text(data.distance, style: _txt(size: 9, weight: FontWeight.w900, color: _tc)),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: PremiumPressable(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
          decoration: BoxDecoration(
            color: _dk,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _tc.withOpacity(0.14)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Fırsatı Bulamadın mı?', style: _txt(size: 14, weight: FontWeight.w800, color: _w)),
                    const SizedBox(height: 2),
                    Text(
                      'Barkodu okut, anında keşfet.',
                      style: _txt(size: 11, color: _w.withOpacity(0.32)),
                    ),
                  ],
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _tc,
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(color: _tc.withOpacity(0.38), blurRadius: 12, offset: const Offset(0, 3)),
                  ],
                ),
                child: const Icon(Icons.qr_code_scanner_rounded, size: 19, color: _dk),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.subTitle,
    this.actionLabel,
    this.onActionTap,
    this.bottomPadding = 10,
  });

  final String title;
  final String? subTitle;
  final String? actionLabel;
  final VoidCallback? onActionTap;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 22, 16, bottomPadding),
      child: Row(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(title, style: _txt(size: 17, weight: FontWeight.w900, color: _t1, letterSpacing: -0.3)),
                if (subTitle != null) ...[
                  const SizedBox(width: 7),
                  Text(
                    subTitle!,
                    style: _txt(size: 10, weight: FontWeight.w600, color: _t3, fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),
          if (actionLabel != null)
            PremiumPressable(
              onTap: onActionTap,
              borderRadius: BorderRadius.circular(999),
              child: Text(actionLabel!, style: _txt(size: 12, weight: FontWeight.w700, color: _tc)),
            ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _w,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: _txt(size: 16, weight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(subtitle, style: _txt(size: 13, color: _t2, height: 1.5)),
          if (actionLabel != null && onTap != null) ...[
            const SizedBox(height: 14),
            PremiumPressable(
              onTap: onTap,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: _dk, borderRadius: BorderRadius.circular(999)),
                child: Text(actionLabel!, style: _txt(size: 12, weight: FontWeight.w800, color: _w)),
              ),
            ),
          ],
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
        opacity: open ? 1 : 0,
        duration: const Duration(milliseconds: 200),
        child: AnimatedSlide(
          offset: open ? Offset.zero : const Offset(0, 0.02),
          duration: const Duration(milliseconds: 200),
          child: Container(
            color: _bg,
            child: Column(
              children: [
                Container(
                  color: _dk,
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                  child: SafeArea(
                    bottom: false,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: _w,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search_rounded, size: 14, color: _t3),
                          const SizedBox(width: 9),
                          Expanded(
                            child: TextField(
                              controller: controller,
                              focusNode: focusNode,
                              onChanged: onChanged,
                              onSubmitted: onSubmitted,
                              style: _txt(size: 14, weight: FontWeight.w500, color: _t1),
                              decoration: InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                hintText: 'Ürün, mağaza veya kategori ara...',
                                hintStyle: _txt(size: 14, color: _t3, fontStyle: FontStyle.italic),
                              ),
                            ),
                          ),
                          PremiumPressable(
                            onTap: onClose,
                            borderRadius: BorderRadius.circular(999),
                            child: Text('İptal', style: _txt(size: 13, weight: FontWeight.w700, color: _t3)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _OverlaySection(
                        title: 'Trend Aramalar',
                        icon: Icons.trending_up_rounded,
                        child: Wrap(
                          spacing: 7,
                          runSpacing: 7,
                          children: trends.map((trend) {
                            final isHot = trend.toLowerCase() == 'nutella';
                            return PremiumPressable(
                              onTap: () => onPickTrend(trend),
                              borderRadius: BorderRadius.circular(999),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isHot ? _tc.withOpacity(0.10) : _w,
                                  borderRadius: BorderRadius.circular(999),
                                  border: isHot ? Border.all(color: _tc.withOpacity(0.25)) : null,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isHot ? Icons.local_fire_department_outlined : Icons.search_rounded,
                                      size: 12,
                                      color: isHot ? _tc : _t3,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(trend, style: _txt(size: 13, weight: FontWeight.w700, color: _t1)),
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
                          children: recents.map((recent) {
                            return Container(
                              padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 3),
                              decoration: BoxDecoration(
                                border: Border(bottom: BorderSide(color: _dk.withOpacity(0.07))),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.history_rounded, size: 13, color: _t3),
                                  const SizedBox(width: 9),
                                  Expanded(
                                    child: PremiumPressable(
                                      onTap: () => onSubmitted(recent),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(recent, style: _txt(size: 14, weight: FontWeight.w600)),
                                      ),
                                    ),
                                  ),
                                  PremiumPressable(
                                    onTap: () => onRemoveRecent(recent),
                                    borderRadius: BorderRadius.circular(999),
                                    child: Icon(Icons.close_rounded, size: 15, color: _t3.withOpacity(0.65)),
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
              Text(
                title,
                style: _txt(size: 11, weight: FontWeight.w800, color: _t3, letterSpacing: 0.8),
              ),
            ],
          ),
          const SizedBox(height: 11),
          child,
        ],
      ),
    );
  }
}

class _MarketFilter {
  const _MarketFilter(this.label, this.color);

  final String label;
  final Color color;
}

class _CategoryTileData {
  const _CategoryTileData(this.label, this.icon, this.bg, this.fg);

  final String label;
  final IconData icon;
  final Color bg;
  final Color fg;
}

class _NearbyMarketTileData {
  const _NearbyMarketTileData({
    required this.letter,
    required this.name,
    required this.distance,
    required this.color,
  });

  final String letter;
  final String name;
  final String distance;
  final Color color;
}

String _formatPrice(double price) {
  final text = price.toStringAsFixed(2).replaceAll('.', ',');
  return '$text₺';
}

Color _marketColor(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('a-101') || lower.contains('a101')) return const Color(0xFFD44020);
  if (lower.contains('bim')) return const Color(0xFFD4A000);
  if (lower.contains('şok') || lower.contains('sok')) return const Color(0xFF7B3FA0);
  if (lower.contains('migros')) return const Color(0xFFE07020);
  if (lower.contains('trendyol')) return const Color(0xFFF27A1A);
  if (lower.contains('carrefour')) return const Color(0xFF1840C0);
  return _tan;
}

Color _imageBg(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('a-101') || lower.contains('a101')) return const Color(0xFFFBF6EF);
  if (lower.contains('bim')) return const Color(0xFFF6F3EA);
  if (lower.contains('şok') || lower.contains('sok')) return const Color(0xFFF2F1FA);
  if (lower.contains('migros')) return const Color(0xFFEFF9F2);
  if (lower.contains('trendyol')) return const Color(0xFFFBF3EA);
  return const Color(0xFFFAF9EA);
}

IconData _chipIcon(String label) {
  switch (label.toLowerCase()) {
    case 'tumu':
      return Icons.home_filled;
    case 'gıda':
    case 'gida':
      return Icons.menu_rounded;
    case 'bakım':
    case 'bakim':
      return Icons.favorite_outline_rounded;
    case 'ev':
      return Icons.home_outlined;
    case 'teknoloji':
    case 'elektronik':
      return Icons.devices_outlined;
    case 'giyim':
      return Icons.checkroom_outlined;
    default:
      return Icons.widgets_outlined;
  }
}
