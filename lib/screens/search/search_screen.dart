import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/theme.dart';
import '../../models/product_model.dart';
import '../../models/price_model.dart';
import '../../providers/product_provider.dart';
import '../../providers/user_provider.dart';
import '../product/product_detail_screen.dart';

// ---------------------------------------------------------------------------
// Sort options
// ---------------------------------------------------------------------------
enum _SortOption {
  recommended('Onerilen'),
  priceLowToHigh('Fiyat: Dusukten Yuksege'),
  priceHighToLow('Fiyat: Yuksekten Dusuge'),
  newest('En Yeni'),
  mostPopular('En Populer');

  final String label;
  const _SortOption(this.label);
}

// ---------------------------------------------------------------------------
// Search Screen
// ---------------------------------------------------------------------------
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin {
  // Controllers & focus
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  // State
  String _query = '';
  String _selectedCategory = 'Tumu';
  _SortOption _sortOption = _SortOption.recommended;
  bool _isGridView = true;

  // Popular search data
  final List<String> _popularSearches = [
    'Telefon',
    'Laptop',
    'Deterjan',
    'Kahve',
    'Kulaklik',
    'Ayakkabi',
    'Supurge',
    'Bebek bezi',
  ];

  // Animation
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();

    // Auto-focus the search field after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  // ---- Helpers ----

  IconData _iconForCategory(String name) {
    switch (name) {
      case 'Elektronik':
        return Icons.devices_rounded;
      case 'Gida':
        return Icons.restaurant_rounded;
      case 'Temizlik':
        return Icons.cleaning_services_rounded;
      case 'Kisisel Bakim':
        return Icons.face_rounded;
      case 'Ev & Yasam':
        return Icons.home_rounded;
      case 'Giyim':
        return Icons.checkroom_rounded;
      case 'Spor':
        return Icons.sports_soccer_rounded;
      case 'Oyuncak':
        return Icons.toys_rounded;
      case 'Kitap':
        return Icons.menu_book_rounded;
      case 'Otomotiv':
        return Icons.directions_car_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  Color _colorForCategory(String name) {
    switch (name) {
      case 'Elektronik':
        return const Color(0xFF6366F1);
      case 'Gida':
        return const Color(0xFFEF4444);
      case 'Temizlik':
        return const Color(0xFF3B82F6);
      case 'Kisisel Bakim':
        return const Color(0xFFEC4899);
      case 'Ev & Yasam':
        return const Color(0xFFF59E0B);
      case 'Giyim':
        return const Color(0xFF8B5CF6);
      case 'Spor':
        return const Color(0xFF10B981);
      case 'Oyuncak':
        return const Color(0xFFF97316);
      case 'Kitap':
        return const Color(0xFF14B8A6);
      case 'Otomotiv':
        return const Color(0xFF64748B);
      default:
        return AppColors.primary;
    }
  }

  List<ProductModel> _filterAndSortProducts(List<ProductModel> allProducts) {
    List<ProductModel> results;

    if (_query.isNotEmpty) {
      final lower = _query.toLowerCase();
      results = allProducts.where((p) {
        return p.name.toLowerCase().contains(lower) ||
            p.category.toLowerCase().contains(lower) ||
            (p.brand.toLowerCase().contains(lower)) ||
            (p.lastStore?.toLowerCase().contains(lower) ?? false);
      }).toList();
    } else {
      results = List.from(allProducts);
    }

    // Category filter
    if (_selectedCategory != 'Tumu') {
      results =
          results.where((p) => p.category == _selectedCategory).toList();
    }

    // Sort
    switch (_sortOption) {
      case _SortOption.recommended:
        break; // default order
      case _SortOption.priceLowToHigh:
        results.sort((a, b) => (a.lastPrice ?? 0).compareTo(b.lastPrice ?? 0));
        break;
      case _SortOption.priceHighToLow:
        results.sort((a, b) => (b.lastPrice ?? 0).compareTo(a.lastPrice ?? 0));
        break;
      case _SortOption.newest:
        results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case _SortOption.mostPopular:
        results.sort((a, b) => b.viewCount.compareTo(a.viewCount));
        break;
    }

    return results;
  }

  bool get _hasActiveSearch => _query.isNotEmpty || _selectedCategory != 'Tumu';

  void _applySearch(String text) {
    setState(() {
      _query = text;
      _searchController.text = text;
      _searchController.selection =
          TextSelection.collapsed(offset: text.length);
    });
    // Save search to Firebase
    ref.read(userNotifierProvider.notifier).saveSearch(text);
  }

  // ---- Build ----

  @override
  Widget build(BuildContext context) {
    // Listen for category filter changes from home screen
    ref.listen<String>(selectedCategoryFilterProvider, (prev, next) {
      if (next != 'Tumu') {
        setState(() => _selectedCategory = next);
        // Reset so it doesn't stick on next navigation
        Future.microtask(() => ref.read(selectedCategoryFilterProvider.notifier).state = 'Tumu');
      }
    });

    final theme = Theme.of(context);
    final allProductsAsync = ref.watch(allProductsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final searchHistoryAsync = ref.watch(searchHistoryProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            children: [
              // ── Search Bar ──
              _buildSearchBar(theme),

              // ── Category Chips ──
              categoriesAsync.when(
                data: (categories) => _buildCategoryChips(theme, categories),
                loading: () => const SizedBox(height: 48),
                error: (_, __) => const SizedBox(height: 48),
              ),

              // ── Body ──
              Expanded(
                child: allProductsAsync.when(
                  data: (allProducts) {
                    final products = _filterAndSortProducts(allProducts);
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: _hasActiveSearch
                          ? _buildResultsBody(theme, products)
                          : _buildEmptyState(
                              theme,
                              categoriesAsync.valueOrNull ?? [],
                              searchHistoryAsync.valueOrNull ?? [],
                            ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Center(child: Text('Urunler yuklenemedi')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // SEARCH BAR
  // ─────────────────────────────────────────────
  Widget _buildSearchBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
      child: Material(
        elevation: 2,
        shadowColor: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          onChanged: (v) => setState(() => _query = v),
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: 'Urun, magaza veya kategori ara...',
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textTertiary,
            ),
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.textSecondary),
                    splashRadius: 20,
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                      _focusNode.requestFocus();
                    },
                  )
                : null,
            filled: true,
            fillColor: AppColors.surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // CATEGORY CHIPS
  // ─────────────────────────────────────────────
  Widget _buildCategoryChips(ThemeData theme, List<Map<String, dynamic>> categories) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: categories.length + 1, // +1 for "Tumu"
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final label = isAll ? 'Tumu' : categories[index - 1]['name'] ?? '';
          final selected = _selectedCategory == label;

          return FilterChip(
            label: Text(label),
            selected: selected,
            onSelected: (_) {
              setState(() => _selectedCategory = label);
            },
            avatar: isAll
                ? null
                : Icon(
                    _iconForCategory(categories[index - 1]['name'] ?? ''),
                    size: 16,
                    color: selected
                        ? AppColors.textOnPrimary
                        : AppColors.textSecondary,
                  ),
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.surface,
            checkmarkColor: AppColors.textOnPrimary,
            labelStyle: TextStyle(
              color: selected
                  ? AppColors.textOnPrimary
                  : AppColors.textPrimary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 13,
            ),
            side: BorderSide(
              color: selected ? AppColors.primary : AppColors.outline,
              width: 1,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────
  // RESULTS BODY (sort row + grid/list)
  // ─────────────────────────────────────────────
  Widget _buildResultsBody(ThemeData theme, List<ProductModel> products) {
    if (products.isEmpty) return _buildNoResults(theme);

    return Column(
      key: const ValueKey('results'),
      children: [
        // Sort row
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs),
          child: Row(
            children: [
              // Result count
              Text(
                '${products.length} urun bulundu',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              // Sort dropdown
              Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.outline),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<_SortOption>(
                    value: _sortOption,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        size: 18, color: AppColors.textSecondary),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    isDense: true,
                    items: _SortOption.values
                        .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(e.label),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _sortOption = v);
                    },
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Grid / list toggle
              Container(
                height: 34,
                width: 34,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.outline),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  iconSize: 18,
                  icon: Icon(
                    _isGridView
                        ? Icons.view_list_rounded
                        : Icons.grid_view_rounded,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () =>
                      setState(() => _isGridView = !_isGridView),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.xs),

        // Products
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _isGridView
                ? _buildGridView(products)
                : _buildListView(products),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // GRID VIEW
  // ─────────────────────────────────────────────
  Widget _buildGridView(List<ProductModel> products) {
    return GridView.builder(
      key: const ValueKey('grid'),
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.lg),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.68,
      ),
      itemCount: products.length,
      itemBuilder: (context, i) => _ProductGridCard(
        product: products[i],
        icon: _iconForCategory(products[i].category),
        color: _colorForCategory(products[i].category),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                ProductDetailScreen(productId: products[i].id),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // LIST VIEW
  // ─────────────────────────────────────────────
  Widget _buildListView(List<ProductModel> products) {
    return ListView.separated(
      key: const ValueKey('list'),
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.lg),
      itemCount: products.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _ProductListCard(
        product: products[i],
        icon: _iconForCategory(products[i].category),
        color: _colorForCategory(products[i].category),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                ProductDetailScreen(productId: products[i].id),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // EMPTY STATE  (no search active)
  // ─────────────────────────────────────────────
  Widget _buildEmptyState(
      ThemeData theme, List<Map<String, dynamic>> categories, List<String> recentSearches) {
    return SingleChildScrollView(
      key: const ValueKey('empty'),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Son Aramalar ──
          if (recentSearches.isNotEmpty) ...[
            _sectionTitle(theme, 'Son Aramalar', icon: Icons.history_rounded),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: recentSearches.map((s) {
                return ActionChip(
                  label: Text(s),
                  avatar: const Icon(Icons.history_rounded,
                      size: 16, color: AppColors.textTertiary),
                  onPressed: () => _applySearch(s),
                  backgroundColor: AppColors.surface,
                  side: const BorderSide(color: AppColors.outline),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                  labelStyle: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          // ── Populer Aramalar ──
          _sectionTitle(theme, 'Populer Aramalar',
              icon: Icons.trending_up_rounded),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _popularSearches.map((s) {
              return ActionChip(
                label: Text(s),
                avatar: const Icon(Icons.local_fire_department_rounded,
                    size: 16, color: AppColors.accent),
                onPressed: () => _applySearch(s),
                backgroundColor: AppColors.accent.withOpacity(0.08),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                labelStyle: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Populer Kategoriler ──
          if (categories.isNotEmpty) ...[
            _sectionTitle(theme, 'Populer Kategoriler',
                icon: Icons.category_rounded),
            const SizedBox(height: AppSpacing.sm),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.4,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final catName = cat['name'] ?? '';
                final color = _colorForCategory(catName);
                return Material(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    onTap: () {
                      setState(() {
                        _selectedCategory = catName;
                      });
                    },
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Icon(_iconForCategory(catName),
                                size: 18, color: color),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              catName,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // NO RESULTS STATE
  // ─────────────────────────────────────────────
  Widget _buildNoResults(ThemeData theme) {
    return Center(
      key: const ValueKey('no-results'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_off_rounded,
                  size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Sonuc bulunamadi',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Farkli anahtar kelimeler deneyin',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // SECTION TITLE HELPER
  // ─────────────────────────────────────────────
  Widget _sectionTitle(ThemeData theme, String title,
      {required IconData icon}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// PRODUCT GRID CARD
// ===========================================================================
class _ProductGridCard extends ConsumerWidget {
  final ProductModel product;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ProductGridCard({
    required this.product,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final priceHistoryAsync =
        ref.watch(productPriceHistoryProvider(product.id));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.outline, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Expanded(
              flex: 5,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.lg)),
                  image: product.mainImage != null
                      ? DecorationImage(
                          image: NetworkImage(product.mainImage!),
                          fit: BoxFit.cover,
                          onError: (_, __) {},
                        )
                      : null,
                ),
                child: product.mainImage == null
                    ? Center(
                        child: Icon(icon, size: 40, color: color.withOpacity(0.5)),
                      )
                    : null,
              ),
            ),

            // Info
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category tag
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(AppRadius.xs),
                      ),
                      child: Text(
                        product.category,
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Name
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                    const Spacer(),
                    // Price
                    if (product.lastPrice != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TL${_formatPrice(product.lastPrice!)}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          priceHistoryAsync.when(
                            data: (prices) =>
                                _buildPriceChangeIndicator(prices),
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                          priceHistoryAsync.when(
                            data: (prices) => _buildRelativeTimeText(prices),
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    const SizedBox(height: 2),
                    // Store
                    if (product.lastStore != null)
                      Row(
                        children: [
                          const Icon(Icons.storefront_rounded,
                              size: 12, color: AppColors.textTertiary),
                          const SizedBox(width: 3),
                          Text(
                            product.lastStore!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
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
}

// ===========================================================================
// PRODUCT LIST CARD
// ===========================================================================
class _ProductListCard extends ConsumerWidget {
  final ProductModel product;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ProductListCard({
    required this.product,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final priceHistoryAsync =
        ref.watch(productPriceHistoryProvider(product.id));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.outline, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image placeholder
            Container(
              width: 100,
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(AppRadius.lg)),
                image: product.mainImage != null
                    ? DecorationImage(
                        image: NetworkImage(product.mainImage!),
                        fit: BoxFit.cover,
                        onError: (_, __) {},
                      )
                    : null,
              ),
              child: product.mainImage == null
                  ? Center(
                      child:
                          Icon(icon, size: 36, color: color.withOpacity(0.5)),
                    )
                  : null,
            ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category tag
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(AppRadius.xs),
                      ),
                      child: Text(
                        product.category,
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Name
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                    const Spacer(),
                    // Price + store row
                    Row(
                      children: [
                        if (product.lastPrice != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TL${_formatPrice(product.lastPrice!)}',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                              priceHistoryAsync.when(
                                data: (prices) =>
                                    _buildPriceChangeIndicator(prices),
                                loading: () => const SizedBox.shrink(),
                                error: (_, __) => const SizedBox.shrink(),
                              ),
                              priceHistoryAsync.when(
                                data: (prices) =>
                                    _buildRelativeTimeText(prices),
                                loading: () => const SizedBox.shrink(),
                                error: (_, __) => const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        const Spacer(),
                        if (product.lastStore != null) ...[
                          const Icon(Icons.storefront_rounded,
                              size: 12, color: AppColors.textTertiary),
                          const SizedBox(width: 3),
                          Text(
                            product.lastStore!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ],
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
}

// ===========================================================================
// PRICE FORMATTER
// ===========================================================================
Widget _buildPriceChangeIndicator(List<PriceModel> prices) {
  if (prices.length < 2) return const SizedBox.shrink();
  final approved = prices.where((price) => price.isApproved).toList();
  final source = approved.length >= 2 ? approved : prices;
  if (source.length < 2) return const SizedBox.shrink();

  final latest = source[0];
  final previous = source[1];
  final diff = latest.price - previous.price;
  if (diff == 0) return const SizedBox.shrink();

  final percent = (diff / previous.price) * 100;
  final isUp = diff > 0;
  final color = isUp ? AppColors.error : AppColors.success;

  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        isUp ? Icons.trending_up : Icons.trending_down,
        size: 12,
        color: color,
      ),
      const SizedBox(width: 2),
      Text(
        '${percent.abs().toStringAsFixed(1)}%',
        style: TextStyle(fontSize: 11, color: color),
      ),
    ],
  );
}

Widget _buildRelativeTimeText(List<PriceModel> prices) {
  if (prices.isEmpty) return const SizedBox.shrink();
  final text = _formatTimeAgo(prices.first.createdAt);
  if (text.isEmpty) return const SizedBox.shrink();
  return Text(
    text,
    style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
  );
}

String _formatTimeAgo(DateTime dateTime) {
  final now = DateTime.now();
  final difference = now.difference(dateTime);

  if (difference.inMinutes < 1) {
    return 'az once';
  } else if (difference.inMinutes < 60) {
    return '${difference.inMinutes} dk once';
  } else if (difference.inHours < 24) {
    return '${difference.inHours} sa once';
  } else if (difference.inDays < 7) {
    return '${difference.inDays} gun once';
  } else {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}

String _formatPrice(double price) {
  if (price >= 1000) {
    final parts = price.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final decPart = parts[1];
    final buffer = StringBuffer();
    for (var i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buffer.write('.');
      buffer.write(intPart[i]);
    }
    return '$buffer,$decPart';
  }
  return price.toStringAsFixed(2).replaceAll('.', ',');
}
