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
      backgroundColor: FRColors.backgroundWarm,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildPageHeader(context),
          _buildSearchInput(context),
          _buildFilterChips(context, categories),
          _buildResultsHeader(context, results.length, searchResultsAsync.isLoading),
          if (searchResultsAsync.isLoading)
            _buildLoadingState()
          else if (results.isEmpty)
            _buildEmptyState(context, query)
          else
            _buildResultsList(context, results, latestByProduct),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _buildPageHeader(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        decoration: const BoxDecoration(
          color: FRColors.espresso,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Keşfet',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'RADARDAKİ TÜM ÜRÜNLER',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: FRColors.textMuted,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchInput(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Container(
          decoration: BoxDecoration(
            color: FRColors.surface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x10170D08),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
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
              prefixIcon: const Icon(Icons.search_rounded, color: FRColors.tan, size: 22),
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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

  Widget _buildFilterChips(BuildContext context, List<dynamic> categories) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // Category chips
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildCategoryChip(
                  label: 'Tümü',
                  icon: Icons.grid_view_rounded,
                  isActive: _selectedCategory == null,
                  onTap: () => setState(() => _selectedCategory = null),
                ),
                ...categories.take(8).map(
                  (cat) {
                    final name = (cat.title ?? cat.name ?? 'Kategori').toString();
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _buildCategoryChip(
                        label: name,
                        icon: _getCategoryIcon(name),
                        isActive: _selectedCategory == name,
                        onTap: () => setState(() => _selectedCategory = name),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Utility filter chips
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip(
                  label: 'En İyi Fiyat',
                  icon: Icons.sell_rounded,
                  isActive: _sortBy == 0,
                  onTap: () => setState(() => _sortBy = 0),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'En Yeni',
                  icon: Icons.access_time_rounded,
                  isActive: _sortBy == 1,
                  onTap: () => setState(() => _sortBy = 1),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Yüksek Güven',
                  icon: Icons.verified_user_rounded,
                  isActive: _showOnlyHighTrust,
                  onTap: () => setState(() => _showOnlyHighTrust = !_showOnlyHighTrust),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'İndirimli',
                  icon: Icons.trending_down_rounded,
                  isActive: _showOnlyDiscounted,
                  onTap: () => setState(() => _showOnlyDiscounted = !_showOnlyDiscounted),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Alarm Kur',
                  icon: Icons.notifications_none_rounded,
                  isActive: false,
                  isAccent: true,
                  onTap: () => _showAlertSetup(context),
                ),
              ],
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? FRColors.espresso : FRColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isActive ? FRColors.espresso : FRColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isActive ? FRColors.tan : FRColors.textMuted),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isActive ? Colors.white : FRColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    bool isAccent = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? FRColors.tan.withOpacity(0.12) : FRColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? FRColors.tan
                : isAccent
                    ? FRColors.tan.withOpacity(0.4)
                    : FRColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: isActive || isAccent ? FRColors.tan : FRColors.textMuted),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isActive || isAccent ? FRColors.tan : FRColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsHeader(BuildContext context, int count, bool isLoading) {
    if (isLoading) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  'SONUÇLAR',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: FRColors.textMuted,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: FRColors.tan.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: FRColors.tan,
                    ),
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () => _showSortOptions(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: FRColors.surface,
                  borderRadius: BorderRadius.circular(10),
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

  Widget _buildResultsList(
    BuildContext context,
    List<ProductModel> results,
    Map<String, PriceModel> latestByProduct,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildResultCard(
            context,
            results[index],
            latestByProduct: latestByProduct,
          ),
          childCount: results.length,
        ),
      ),
    );
  }

  Widget _buildResultCard(
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
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: FRColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Color(0x08170D08), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: productId)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: FRColors.backgroundWarm,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: FRColors.border),
                  ),
                  child: productImage != null && productImage.toString().isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: CachedNetworkImage(
                            imageUrl: productImage.toString(),
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) =>
                                const Icon(Icons.category_outlined, size: 28, color: FRColors.tan),
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
                          const Icon(Icons.store_outlined, size: 10, color: FRColors.textSubtle),
                          const SizedBox(width: 3),
                          Text(storeName, style: const TextStyle(fontSize: 10, color: FRColors.textSubtle)),
                          const SizedBox(width: 4),
                          Text('• $timeAgo', style: const TextStyle(fontSize: 10, color: FRColors.textSubtle)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            formatTRY(price),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: FRColors.tan,
                            ),
                          ),
                          if (priceChangePercent != null && priceChangePercent.abs() >= 1)
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: priceChangePercent <= 0 ? FRColors.successSurface : FRColors.dangerSurface,
                                borderRadius: BorderRadius.circular(6),
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
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                      decoration: BoxDecoration(
                        color: trustScore >= 90
                            ? FRColors.successSurface
                            : trustScore >= 75
                                ? FRColors.backgroundWarm
                                : FRColors.dangerSurface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: trustScore >= 90
                              ? FRColors.success.withOpacity(0.3)
                              : FRColors.border,
                        ),
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
                    const SizedBox(height: 10),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildActionBtn(
                          icon: Icons.bookmark_outline_rounded,
                          onTap: () => _addToWatchlist(context, productId),
                        ),
                        const SizedBox(width: 6),
                        _buildActionBtn(
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

  Widget _buildActionBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: FRColors.backgroundWarm,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: FRColors.border),
        ),
        child: Icon(icon, size: 14, color: FRColors.textMuted),
      ),
    );
  }

  Widget _buildLoadingState() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 64),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: FRColors.tan,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Aranıyor...',
                style: TextStyle(fontSize: 13, color: FRColors.textSubtle),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String query) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 32),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: FRColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Color(0x0A170D08), blurRadius: 10, offset: Offset(0, 3)),
                  ],
                ),
                child: const Icon(Icons.search_off_rounded, size: 32, color: FRColors.textMuted),
              ),
              const SizedBox(height: 20),
              Text(
                query.isEmpty ? 'Aramaya Başlayın' : '"$query" bulunamadı',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: FRColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                query.isEmpty ? 'Ürün, marka veya kategori arayın' : 'Farklı bir arama deneyin',
                style: const TextStyle(fontSize: 13, color: FRColors.textSubtle),
                textAlign: TextAlign.center,
              ),
              if (query.isNotEmpty) ...[
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    _searchController.clear();
                    ref.read(searchQueryProvider.notifier).state = '';
                    _focusNode.requestFocus();
                    setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FRColors.tan,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: const Text('Aramayı Temizle', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _getSortLabel() {
    switch (_sortBy) {
      case 0: return 'En İyi Fiyat';
      case 1: return 'En Yeni';
      case 2: return 'Yüksek Güven';
      default: return 'Sırala';
    }
  }

  IconData _getCategoryIcon(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('market') || lower.contains('gıda')) return Icons.shopping_cart_rounded;
    if (lower.contains('tekno') || lower.contains('elektronik')) return Icons.laptop_mac_rounded;
    if (lower.contains('kozmetik') || lower.contains('bakım')) return Icons.face_retouching_natural_rounded;
    if (lower.contains('hobi') || lower.contains('spor')) return Icons.sports_esports_rounded;
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
      backgroundColor: FRColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: FRColors.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Text(
                'Sırala',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: FRColors.textPrimary),
              ),
            ),
            _buildSortTile(ctx, 'En İyi Fiyat', Icons.sell_rounded, 0),
            _buildSortTile(ctx, 'En Yeni', Icons.access_time_rounded, 1),
            _buildSortTile(ctx, 'Yüksek Güven', Icons.shield_rounded, 2),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildSortTile(BuildContext ctx, String label, IconData icon, int sortValue) {
    final isActive = _sortBy == sortValue;
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isActive ? FRColors.tan.withOpacity(0.1) : FRColors.backgroundWarm,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: isActive ? FRColors.tan : FRColors.textMuted),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isActive ? FRColors.tan : FRColors.textPrimary,
        ),
      ),
      trailing: isActive ? const Icon(Icons.check_rounded, color: FRColors.tan, size: 18) : null,
      onTap: () {
        setState(() => _sortBy = sortValue);
        Navigator.pop(ctx);
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
