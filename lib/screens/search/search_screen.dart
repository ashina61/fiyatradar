import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/price_model.dart';
import '../../models/product_model.dart';
import '../../providers/price_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/location_service.dart';
import '../../utils/theme.dart';
import '../product/product_detail_screen.dart';

enum _SortOption {
  recommended('Onerilen'),
  priceLowToHigh('Fiyat: Dusukten Yuksege'),
  priceHighToLow('Fiyat: Yuksekten Dusuge'),
  newest('En Yeni'),
  mostPopular('En Populer');

  final String label;
  const _SortOption(this.label);
}

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  String _query = '';
  String _selectedCategory = 'Tumu';
  _SortOption _sortOption = _SortOption.recommended;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  List<ProductModel> _filterAndSortProducts(List<ProductModel> allProducts) {
    List<ProductModel> results;
    if (_query.isNotEmpty) {
      final lower = _query.toLowerCase();
      results = allProducts.where((p) {
        return p.name.toLowerCase().contains(lower) ||
            p.category.toLowerCase().contains(lower) ||
            p.brand.toLowerCase().contains(lower) ||
            (p.lastStore?.toLowerCase().contains(lower) ?? false);
      }).toList();
    } else {
      results = List.from(allProducts);
    }

    if (_selectedCategory != 'Tumu') {
      results = results.where((p) => p.category == _selectedCategory).toList();
    }

    switch (_sortOption) {
      case _SortOption.recommended:
        break;
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

  @override
  Widget build(BuildContext context) {
    ref.listen<String>(selectedCategoryFilterProvider, (prev, next) {
      if (next != 'Tumu') {
        setState(() => _selectedCategory = next);
        Future.microtask(
          () => ref.read(selectedCategoryFilterProvider.notifier).state = 'Tumu',
        );
      }
    });

    final theme = Theme.of(context);
    final allProductsAsync = ref.watch(allProductsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final latestPricesAsync = ref.watch(latestPricesProvider);
    final currentLocationAsync = ref.watch(currentLocationProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            children: [
              _buildSearchBar(theme),
              categoriesAsync.when(
                data: (categories) => _buildCategoryChips(theme, categories),
                loading: () => const SizedBox(height: 42),
                error: (_, __) => const SizedBox(height: 42),
              ),
              Expanded(
                child: allProductsAsync.when(
                  data: (allProducts) {
                    final filteredProducts = _filterAndSortProducts(allProducts);
                    return latestPricesAsync.when(
                      data: (latestPrices) => currentLocationAsync.when(
                        data: (locationData) => _buildExploreList(
                          theme,
                          allProducts: allProducts,
                          filteredProducts: filteredProducts,
                          latestPrices: latestPrices,
                          locationData: locationData,
                        ),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (_, __) => _buildExploreList(
                          theme,
                          allProducts: allProducts,
                          filteredProducts: filteredProducts,
                          latestPrices: latestPrices,
                          locationData: null,
                        ),
                      ),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (_, __) => _buildExploreList(
                        theme,
                        allProducts: allProducts,
                        filteredProducts: filteredProducts,
                        latestPrices: const [],
                        locationData: null,
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

  Widget _buildSearchBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Material(
        elevation: 1,
        shadowColor: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          onChanged: (v) {
            setState(() => _query = v);
            if (v.trim().isNotEmpty) {
              ref.read(userNotifierProvider.notifier).saveSearch(v.trim());
            }
          },
          style: theme.textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: 'Urun, magaza veya kategori ara...',
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded),
                    splashRadius: 18,
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  )
                : null,
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
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
              borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips(ThemeData theme, List<Map<String, dynamic>> categories) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: categories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final label = isAll ? 'Tumu' : categories[index - 1]['name'] ?? '';
          final selected = _selectedCategory == label;

          return FilterChip(
            label: Text(label),
            selected: selected,
            onSelected: (_) => setState(() => _selectedCategory = label),
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.surface,
            showCheckmark: false,
            labelStyle: TextStyle(
              color: selected ? AppColors.textOnPrimary : AppColors.textPrimary,
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
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          );
        },
      ),
    );
  }

  Widget _buildExploreList(
    ThemeData theme, {
    required List<ProductModel> allProducts,
    required List<ProductModel> filteredProducts,
    required List<PriceModel> latestPrices,
    required LocationData? locationData,
  }) {
    final productMap = {for (final p in allProducts) p.id: p};
    final hasQuery = _query.trim().isNotEmpty;

    final feedItems = hasQuery
        ? filteredProducts
            .map((p) => _ExploreFeedItem(product: p, price: null, distanceMeters: null))
            .toList()
        : latestPrices
            .map((price) {
              final product = productMap[price.productId];
              if (product == null) return null;

              if (_selectedCategory != 'Tumu' && product.category != _selectedCategory) {
                return null;
              }

              final distanceMeters = _distanceFromUser(locationData, price);
              return _ExploreFeedItem(
                product: product,
                price: price,
                distanceMeters: distanceMeters,
              );
            })
            .whereType<_ExploreFeedItem>()
            .toList();

    if (feedItems.isEmpty) {
      return Center(
        child: Text(
          'Gosterilecek fiyat kaydi bulunamadi',
          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 100),
      itemCount: feedItems.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          final title = hasQuery ? 'Arama Sonuclari' : 'Mahallenden Fiyatlar';
          final subtitle = hasQuery
              ? '${feedItems.length} urun listeleniyor'
              : 'Yazmadan kesfetmeye devam et';
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }

        final item = feedItems[index - 1];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: _ExplorePriceCard(
            item: item,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProductDetailScreen(productId: item.product.id),
              ),
            ),
          ),
        );
      },
    );
  }

  double? _distanceFromUser(LocationData? locationData, PriceModel price) {
    if (locationData == null || price.geoPoint == null) return null;
    return Geolocator.distanceBetween(
      locationData.geoPoint.latitude,
      locationData.geoPoint.longitude,
      price.geoPoint!.latitude,
      price.geoPoint!.longitude,
    );
  }
}

class _ExploreFeedItem {
  final ProductModel product;
  final PriceModel? price;
  final double? distanceMeters;

  const _ExploreFeedItem({
    required this.product,
    required this.price,
    required this.distanceMeters,
  });

  String get storeLabel => price?.storeName ?? product.lastStore ?? 'Magaza bilgisi yok';

  String get neighborhoodLabel {
    final raw = price?.storeLocation;
    if (raw == null || raw.trim().isEmpty) return 'Mahalle bilgisi yok';
    return raw.split(',').first.trim();
  }

  double? get displayPrice => price?.price ?? product.lastPrice;
}

class _ExplorePriceCard extends StatelessWidget {
  final _ExploreFeedItem item;
  final VoidCallback onTap;

  const _ExplorePriceCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.outline),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: item.product.mainImage != null
                      ? Image.network(
                          item.product.mainImage!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imageFallback(),
                        )
                      : _imageFallback(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.displayPrice != null
                          ? 'TL${_formatPrice(item.displayPrice!)}'
                          : 'Fiyat bilgisi yok',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.storefront_rounded,
                            size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item.storeLabel,
                            style: theme.textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item.neighborhoodLabel,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          item.distanceMeters != null
                              ? _formatDistance(item.distanceMeters!)
                              : '-',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
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
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      color: AppColors.primary.withOpacity(0.08),
      child: const Center(
        child: Icon(Icons.image_outlined, size: 40, color: AppColors.primary),
      ),
    );
  }
}

String _formatDistance(double meters) {
  if (meters < 1000) return '${meters.round()} m';
  return '${(meters / 1000).toStringAsFixed(1)} km';
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
