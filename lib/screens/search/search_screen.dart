import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/price_model.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/barcode_scanner_sheet.dart';
import '../product/product_detail_screen.dart';
import '../main_screen.dart';
import '../../theme/fr_colors.dart';
import '../../theme/fr_radius.dart';
import '../../theme/fr_spacing.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({
    super.key,
    this.initialQuery,
  });

  final String? initialQuery;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  String? _selectedCategory;
  int _sortBy = 0; // 0: Best Price, 1: Newest, 2: Highest Trust
  bool _showOnlyDiscounted = false;
  bool _showOnlyHighTrust = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialQuery?.trim() ?? '';
    if (initial.isNotEmpty) {
      _searchController.text = initial;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(searchQueryProvider.notifier).state = initial;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim();
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const [];
    final searchResultsAsync = ref.watch(searchResultsProvider);
    final latestPrices = ref.watch(latestPricesProvider).valueOrNull ?? const <PriceModel>[];

    final latestByProduct = _latestPriceByProduct(latestPrices);
    final rawResults = searchResultsAsync.valueOrNull ?? const <ProductModel>[];
    final filtered = _applyFilters(
      rawResults,
      categoryName: _selectedCategory,
      showOnlyDiscounted: _showOnlyDiscounted,
      showOnlyHighTrust: _showOnlyHighTrust,
    );
    final results = _sortResults(filtered, _sortBy, latestByProduct);

    return Scaffold(
      backgroundColor: FRColors.surfaceSoft,
      appBar: _buildAppBar(context),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            _buildSearchInput(context),
            _buildFilterSystem(context, categories),
            _buildResultsHeader(context, results.length),
            if (searchResultsAsync.isLoading)
              _buildLoadingState()
            else if (results.isEmpty)
              _buildEmptyState(context, query)
            else
              _buildResultsList(context, results, latestByProduct),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: FRColors.surfaceSoft,
      elevation: 0,
      toolbarHeight: 56,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        color: FRColors.textPrimary,
        onPressed: () => Navigator.maybePop(context),
      ),
      title: const Text(
        'Ara',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: FRColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildSearchInput(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: FRSpaceInsets.fromLTRB(16, 12, 16, 12),
        child: Container(
          decoration: BoxDecoration(
            color: FRColors.surface,
            borderRadius: FRRadius.all(FRRadius.xl),
            border: Border.all(color: FRColors.border),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _focusNode,
            decoration: InputDecoration(
              hintText: 'Ürün, marka veya kategori ara...',
              hintStyle: const TextStyle(
                color: FRColors.textSubtle,
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: FRColors.tan,
                size: 22,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 20),
                      color: FRColors.textMuted,
                      onPressed: () {
                        _searchController.clear();
                        ref.read(searchQueryProvider.notifier).state = '';
                        setState(() {});
                        _focusNode.requestFocus();
                      },
                    )
                  : IconButton(
                      icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
                      color: FRColors.textMuted,
                      onPressed: () async {
                        final barcode = await BarcodeScannerSheet.scan(context);
                        if (!mounted || barcode == null || barcode.trim().isEmpty) return;
                        _searchController.text = barcode.trim();
                        ref.read(searchQueryProvider.notifier).state = barcode.trim();
                        setState(() {});
                      },
                    ),
              border: InputBorder.none,
              contentPadding: FRSpaceInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            textInputAction: TextInputAction.search,
            onSubmitted: (value) {
              ref.read(searchQueryProvider.notifier).state = value.trim();
              _focusNode.unfocus();
              setState(() {});
            },
            onChanged: (value) {
              ref.read(searchQueryProvider.notifier).state = value.trim();
              setState(() {});
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSystem(BuildContext context, List<dynamic> categories) {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          Padding(
            padding: FRSpaceInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildCategoryChip(
                    label: 'Tümü',
                    icon: Icons.grid_view_rounded,
                    isActive: _selectedCategory == null,
                    onTap: () => setState(() => _selectedCategory = null),
                  ),
                  const SizedBox(width: 6),
                  ...categories.take(8).map(
                    (cat) => Padding(
                      padding: FRSpaceInsets.only(left: 6),
                      child: _buildCategoryChip(
                        label: (cat.title ?? cat.name ?? 'Kategori').toString(),
                        icon: _getCategoryIcon((cat.title ?? cat.name ?? '').toString()),
                        isActive: _selectedCategory == (cat.title ?? cat.name ?? '').toString(),
                        onTap: () => setState(() => _selectedCategory = (cat.title ?? cat.name ?? '').toString()),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: FRSpaceInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildUtilityChip(
                    label: 'En İyi Fiyat',
                    icon: Icons.sort_rounded,
                    isActive: _sortBy == 0,
                    onTap: () => setState(() => _sortBy = 0),
                  ),
                  const SizedBox(width: 6),
                  _buildUtilityChip(
                    label: 'En Yeni',
                    icon: Icons.access_time_rounded,
                    isActive: _sortBy == 1,
                    onTap: () => setState(() => _sortBy = 1),
                  ),
                  const SizedBox(width: 6),
                  _buildUtilityChip(
                    label: 'Yüksek Güven',
                    icon: Icons.verified_user_rounded,
                    isActive: _showOnlyHighTrust,
                    onTap: () => setState(() => _showOnlyHighTrust = !_showOnlyHighTrust),
                  ),
                  const SizedBox(width: 6),
                  _buildUtilityChip(
                    label: 'İndirimli',
                    icon: Icons.trending_down_rounded,
                    isActive: _showOnlyDiscounted,
                    onTap: () => setState(() => _showOnlyDiscounted = !_showOnlyDiscounted),
                  ),
                  const SizedBox(width: 6),
                  _buildAlertChip(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: FRRadius.all(FRRadius.pill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: FRSpaceInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? FRColors.tan : FRColors.surface,
          borderRadius: FRRadius.all(FRRadius.pill),
          border: Border.all(
            color: isActive ? FRColors.tan : FRColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? FRColors.surface : FRColors.textMuted,
            ),
            const SizedBox(width: FRSpacing.xsPlus),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isActive ? FRColors.surface : FRColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUtilityChip({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: FRRadius.all(FRRadius.md),
      child: Container(
        padding: FRSpaceInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? FRColors.surfaceAlt : FRColors.surface,
          borderRadius: FRRadius.all(FRRadius.md),
          border: Border.all(
            color: isActive ? FRColors.tan : FRColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? FRColors.tan : FRColors.textMuted,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isActive ? FRColors.tan : FRColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertChip(BuildContext context) {
    return InkWell(
      onTap: () => _showAlertSetup(context),
      borderRadius: FRRadius.all(FRRadius.md),
      child: Container(
        padding: FRSpaceInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: FRColors.surface,
          borderRadius: FRRadius.all(FRRadius.md),
          border: Border.all(color: FRColors.tan),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              size: 14,
              color: FRColors.tan,
            ),
            SizedBox(width: 5),
            Text(
              'Alarm Kur',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: FRColors.tan,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsHeader(BuildContext context, int count) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: FRSpaceInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            RichText(
              text: TextSpan(
                text: '$count ',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: FRColors.tan,
                ),
                children: const [
                  TextSpan(
                    text: 'sonuç bulundu',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: FRColors.textSubtle,
                    ),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: () => _showSortOptions(context),
              borderRadius: FRRadius.all(FRRadius.md),
              child: Container(
                padding: FRSpaceInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: FRColors.surface,
                  borderRadius: FRRadius.all(FRRadius.md),
                  border: Border.all(color: FRColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.sort_rounded, size: 14, color: FRColors.textMuted),
                    const SizedBox(width: 5),
                    Text(
                      _getSortLabel(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: FRColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSortLabel() {
    switch (_sortBy) {
      case 0:
        return 'En İyi Fiyat';
      case 1:
        return 'En Yeni';
      case 2:
        return 'Yüksek Güven';
      default:
        return 'Sırala';
    }
  }

  Widget _buildResultsList(
    BuildContext context,
    List<ProductModel> results,
    Map<String, PriceModel> latestByProduct,
  ) {
    return SliverPadding(
      padding: FRSpaceInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildResultRow(
            context,
            results[index],
            latestByProduct: latestByProduct,
          ),
          childCount: results.length,
        ),
      ),
    );
  }

  Widget _buildResultRow(
    BuildContext context,
    ProductModel item, {
    required Map<String, PriceModel> latestByProduct,
  }) {
    final productId = item.id;
    final productName = item.name;
    final productImage = item.effectiveImage;
    final latestPrice = latestByProduct[productId];
    final price = latestPrice?.price ?? item.lastPrice ?? 0;
    final storeName = latestPrice?.storeName ?? item.lastStore ?? 'Mağaza';
    final timeAgo = _formatTimeAgo(latestPrice?.createdAt ?? item.updatedAt ?? item.createdAt);
    final trustScore = latestPrice?.trustPercent ?? ((item.priceEntryCount >= 10 ? 92 : item.priceEntryCount >= 5 ? 82 : 72));
    final priceChangePercent = _computePriceChangeForProduct(item.id);

    return Container(
      margin: FRSpaceInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: FRColors.surface,
        borderRadius: FRRadius.all(FRRadius.lg),
        border: Border.all(color: FRColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: FRRadius.all(FRRadius.lg),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: productId)),
          ),
          child: Padding(
            padding: FRSpaceInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: FRColors.surfaceAlt,
                    borderRadius: FRRadius.all(FRRadius.md),
                    border: Border.all(color: FRColors.border),
                  ),
                  child: productImage != null && productImage.toString().isNotEmpty
                      ? ClipRRect(
                          borderRadius: FRRadius.all(FRRadius.md),
                          child: CachedNetworkImage(
                            imageUrl: productImage.toString(),
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => const Icon(
                              Icons.category_outlined,
                              size: 28,
                              color: FRColors.tan,
                            ),
                          ),
                        )
                      : const Icon(Icons.category_outlined, size: 28, color: FRColors.tan),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: FRColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.store_outlined, size: 11, color: FRColors.textSubtle),
                          const SizedBox(width: 4),
                          Text(
                            storeName,
                            style: const TextStyle(fontSize: 10, color: FRColors.textSubtle),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '• $timeAgo',
                            style: const TextStyle(fontSize: 10, color: FRColors.textSubtle),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            formatTRY(price),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: FRColors.tan,
                            ),
                          ),
                          if (priceChangePercent != null && priceChangePercent.abs() >= 1)
                            Container(
                              margin: FRSpaceInsets.only(left: 6),
                              padding: FRSpaceInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: priceChangePercent <= 0 ? FRColors.successSurface : FRColors.dangerSurface,
                                borderRadius: FRRadius.all(FRRadius.sm),
                              ),
                              child: Text(
                                '${priceChangePercent <= 0 ? '↓' : '↑'} ${priceChangePercent.abs().toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: priceChangePercent <= 0 ? FRColors.success : FRColors.danger,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: FRSpaceInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: trustScore >= 90
                            ? FRColors.successSurface
                            : trustScore >= 75
                                ? FRColors.surfaceAlt
                                : FRColors.dangerSurface,
                        borderRadius: FRRadius.all(FRRadius.sm),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.shield_rounded,
                            size: 10,
                            color: trustScore >= 90
                                ? FRColors.success
                                : trustScore >= 75
                                    ? FRColors.textMuted
                                    : FRColors.danger,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '$trustScore%',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: trustScore >= 90
                                  ? FRColors.success
                                  : trustScore >= 75
                                      ? FRColors.textMuted
                                      : FRColors.danger,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildQuickActionButton(
                          icon: Icons.bookmark_outline_rounded,
                          onTap: () => _addToWatchlist(context, productId),
                        ),
                        const SizedBox(width: 6),
                        _buildQuickActionButton(
                          icon: Icons.notifications_none_rounded,
                          onTap: () => _setPriceAlert(context, productId),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: FRRadius.all(FRRadius.sm),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: FRColors.surfaceAlt,
          borderRadius: FRRadius.all(FRRadius.sm),
          border: Border.all(color: FRColors.border),
        ),
        child: Icon(icon, size: 14, color: FRColors.textMuted),
      ),
    );
  }

  Widget _buildLoadingState() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: FRSpaceInsets.symmetric(vertical: 48),
        child: const Center(
          child: CircularProgressIndicator(color: FRColors.tan),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String query) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: FRSpaceInsets.symmetric(vertical: 64),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: FRColors.surfaceAlt,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.search_off_rounded,
                  size: 32,
                  color: FRColors.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                query.isEmpty ? 'Arama yapın' : '"$query" için sonuç bulunamadı',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: FRColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                query.isEmpty ? 'Ürün, marka veya kategori arayın' : 'Farklı bir arama deneyin',
                style: const TextStyle(
                  fontSize: 12,
                  color: FRColors.textSubtle,
                ),
              ),
              if (query.isNotEmpty) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    _searchController.clear();
                    ref.read(searchQueryProvider.notifier).state = '';
                    _focusNode.requestFocus();
                    setState(() {});
                  },
                  icon: const Icon(Icons.clear_rounded, size: 16),
                  label: const Text('Aramayı Temizle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FRColors.tan,
                    foregroundColor: FRColors.surface,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final currentIndex = ref.watch(currentTabProvider).clamp(0, 3);

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) => ref.read(currentTabProvider.notifier).state = index,
      type: BottomNavigationBarType.fixed,
      backgroundColor: FRColors.surface.withOpacity(0.97),
      selectedItemColor: FRColors.tan,
      unselectedItemColor: FRColors.textSubtle,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Ana Sayfa'),
        BottomNavigationBarItem(icon: Icon(Icons.search_rounded), label: 'Ara'),
        BottomNavigationBarItem(icon: Icon(Icons.add_circle_rounded), label: 'Ekle'),
        BottomNavigationBarItem(icon: Icon(Icons.list_rounded), label: 'Liste'),
      ],
    );
  }

  IconData _getCategoryIcon(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('market') || lower.contains('gıda')) {
      return Icons.shopping_cart_rounded;
    }
    if (lower.contains('tekno') || lower.contains('elektronik')) {
      return Icons.laptop_mac_rounded;
    }
    if (lower.contains('kozmetik') || lower.contains('bakım')) {
      return Icons.face_retouching_natural_rounded;
    }
    if (lower.contains('hobi') || lower.contains('spor')) {
      return Icons.sports_esports_rounded;
    }
    return Icons.category_rounded;
  }

  String _formatTimeAgo(DateTime createdAt) {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}d';
    if (diff.inHours < 24) return '${diff.inHours}s';
    return '${diff.inDays}g';
  }

  void _showAlertSetup(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Alarm ayarları yakında eklenecek.')),
    );
  }

  void _showSortOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.sell_outlined),
                title: const Text('En İyi Fiyat'),
                onTap: () {
                  setState(() => _sortBy = 0);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.access_time_rounded),
                title: const Text('En Yeni'),
                onTap: () {
                  setState(() => _sortBy = 1);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.shield_outlined),
                title: const Text('Yüksek Güven'),
                onTap: () {
                  setState(() => _sortBy = 2);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _addToWatchlist(BuildContext context, String productId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Takip listesine eklendi.')),
    );
  }

  void _setPriceAlert(BuildContext context, String productId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fiyat alarmı kurma ekranı yakında eklenecek.')),
    );
  }

  Map<String, PriceModel> _latestPriceByProduct(List<PriceModel> prices) {
    final map = <String, PriceModel>{};
    for (final price in prices) {
      final existing = map[price.productId];
      if (existing == null || price.reportedAt.isAfter(existing.reportedAt)) {
        map[price.productId] = price;
      }
    }
    return map;
  }

  List<ProductModel> _applyFilters(
    List<ProductModel> results, {
    required String? categoryName,
    required bool showOnlyDiscounted,
    required bool showOnlyHighTrust,
  }) {
    return results.where((product) {
      if (categoryName != null && categoryName.isNotEmpty) {
        final byCategory = product.categories.any((c) => c.toLowerCase() == categoryName.toLowerCase());
        if (!byCategory) return false;
      }

      final delta = _computePriceChangeForProduct(product.id);
      if (showOnlyDiscounted && !(delta != null && delta < 0)) return false;
      if (showOnlyHighTrust && product.priceEntryCount < 5) return false;

      return true;
    }).toList(growable: false);
  }

  List<ProductModel> _sortResults(
    List<ProductModel> results,
    int sortBy,
    Map<String, PriceModel> latestByProduct,
  ) {
    final sorted = [...results];
    switch (sortBy) {
      case 0:
        sorted.sort((a, b) {
          final aPrice = latestByProduct[a.id]?.price ?? a.lastPrice ?? double.infinity;
          final bPrice = latestByProduct[b.id]?.price ?? b.lastPrice ?? double.infinity;
          return aPrice.compareTo(bPrice);
        });
        break;
      case 1:
        sorted.sort((a, b) {
          final aDate = latestByProduct[a.id]?.reportedAt ?? a.updatedAt ?? a.createdAt;
          final bDate = latestByProduct[b.id]?.reportedAt ?? b.updatedAt ?? b.createdAt;
          return bDate.compareTo(aDate);
        });
        break;
      case 2:
        sorted.sort((a, b) => b.priceEntryCount.compareTo(a.priceEntryCount));
        break;
      default:
        break;
    }
    return sorted;
  }

  double? _computePriceChangeForProduct(String productId) {
    final latestPrices = ref.read(latestPricesProvider).valueOrNull ?? const <PriceModel>[];
    final productPrices = latestPrices.where((p) => p.productId == productId).toList()
      ..sort((a, b) => b.reportedAt.compareTo(a.reportedAt));
    if (productPrices.length < 2) return null;
    final latest = productPrices[0].price;
    final prev = productPrices[1].price;
    if (prev <= 0) return null;
    return ((latest - prev) / prev) * 100;
  }
}
