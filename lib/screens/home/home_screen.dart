import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/banner_model.dart';
import '../../models/price_model.dart';
import '../../models/product_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/banner_provider.dart';
import '../../providers/product_provider.dart';

class FRColors {
  static const Color bgApp = Color(0xFFF5F3F0); // Uçuk Krem Arkaplan
  static const Color surface = Color(0xFFFFFFFF); // Bembeyaz Kartlar
  static const Color studio = Color(0xFFEBE5DF); // Resim arkası bej kutu

  static const Color darkMain = Color(0xFF211510); // Porsche Kahvesi (Header ve Dark Section)
  static const Color darkSurface = Color(0xFF2D1E17); // Karanlık alan kartları
  static const Color gold = Color(0xFFC29B78); // Mat, zengin altın

  static const Color textMain = Color(0xFF211510);
  static const Color textMuted = Color(0xFF948A82);

  static const Color success = Color(0xFF4CAF50); // Neon Yeşil
  static const Color successBg = Color(0xFFE8F5E9);
  static const Color danger = Color(0xFFF44336); // Canlı Kırmızı
  static const Color dangerBg = Color(0xFFFFEBEE);
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _selectedCategory = 'Tümü';

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userModelStreamProvider);
    final bannersAsync = ref.watch(activeBannersProvider);
    final trendingAsync = ref.watch(trendingProductsProvider);
    final recommendedAsync = ref.watch(recommendedProductsProvider);
    final latestAsync = ref.watch(latestPricesProvider);
    final topPadding = MediaQuery.of(context).padding.top;

    final dynamicCategories = _buildDynamicCategories(
      trendingAsync.valueOrNull ?? const <ProductModel>[],
      recommendedAsync.valueOrNull ?? const <ProductModel>[],
    );

    return Scaffold(
      backgroundColor: FRColors.bgApp,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _EliteHeader(topPadding: topPadding, userAsync: userAsync),
                const Positioned(
                  left: 24,
                  right: 24,
                  bottom: -24,
                  child: _FloatingSearchBar(),
                ),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 44)),
          SliverToBoxAdapter(
            child: _CategoriesSection(
              categories: dynamicCategories,
              selected: _selectedCategory,
              onTap: (category) => setState(() => _selectedCategory = category),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: _MegaBannerSection(bannersAsync: bannersAsync),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: _RadarAnalysisCard(
                recommendedAsync: recommendedAsync,
                latestAsync: latestAsync,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 28),
              child: _HardDropsSection(
                trendingAsync: trendingAsync,
                categoryFilter: _selectedCategory,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 42),
              child: _LatestScansSection(latestAsync: latestAsync),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _buildDynamicCategories(List<ProductModel> trending, List<ProductModel> recommended) {
    final set = <String>{'Tümü'};
    for (final product in [...trending, ...recommended]) {
      for (final category in product.categories) {
        if (category.trim().isNotEmpty) set.add(category.trim());
      }
    }
    return set.toList();
  }
}

class _EliteHeader extends StatelessWidget {
  const _EliteHeader({required this.topPadding, required this.userAsync});

  final double topPadding;
  final AsyncValue<UserModel?> userAsync;

  @override
  Widget build(BuildContext context) {
    final user = userAsync.valueOrNull;
    final userName = user?.name.trim();
    final avatarUrl = user?.photoUrl?.trim();
    final points = user?.points ?? 0;

    return Container(
      padding: EdgeInsets.fromLTRB(24, topPadding + 14, 24, 50),
      decoration: const BoxDecoration(
        color: FRColors.darkMain,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: FRColors.gold, width: 1.5),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: (avatarUrl ?? '').isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: avatarUrl!,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: FRColors.studio,
                            child: const Icon(Icons.person, color: FRColors.darkMain),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hoş geldin,',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: FRColors.gold,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        (userName ?? '').isEmpty ? 'FiyatRadar Kullanıcısı' : userName!,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: FRColors.surface,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              color: FRColors.surface.withOpacity(0.08),
              border: Border.all(color: FRColors.surface.withOpacity(0.10)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.stars_rounded, color: FRColors.gold, size: 16),
                const SizedBox(width: 5),
                Text(
                  points.toString(),
                  style: const TextStyle(
                    color: FRColors.gold,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: FRColors.surface.withOpacity(0.05),
              border: Border.all(color: FRColors.surface.withOpacity(0.10)),
            ),
            child: const Center(
              child: Icon(Icons.notifications_rounded, color: FRColors.surface, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingSearchBar extends StatelessWidget {
  const _FloatingSearchBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: FRColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: FRColors.textMuted),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Ürün, marka veya market ara',
              style: TextStyle(
                color: FRColors.textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: FRColors.studio,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.qr_code_2_rounded, color: FRColors.textMain, size: 20),
          ),
        ],
      ),
    );
  }
}

class _CategoriesSection extends StatelessWidget {
  const _CategoriesSection({
    required this.categories,
    required this.selected,
    required this.onTap,
  });

  final List<String> categories;
  final String selected;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, i) {
          final category = categories[i];
          final selectedCategory = category == selected;
          return GestureDetector(
            onTap: () => onTap(category),
            child: SizedBox(
              width: 72,
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: selectedCategory ? FRColors.darkMain : FRColors.surface,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      _iconForCategory(category),
                      color: selectedCategory ? FRColors.surface : FRColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    category,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: FRColors.textMain,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
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

  IconData _iconForCategory(String value) {
    final key = value.toLowerCase();
    if (key.contains('temiz') || key.contains('hijyen')) return Icons.cleaning_services_rounded;
    if (key.contains('atıştır') || key.contains('gıda')) return Icons.fastfood_rounded;
    if (key.contains('içecek')) return Icons.local_drink_rounded;
    if (key.contains('kozmetik') || key.contains('bakım')) return Icons.spa_rounded;
    if (key.contains('ev')) return Icons.chair_alt_rounded;
    if (key.contains('tekno') || key.contains('elektronik')) return Icons.devices_rounded;
    return Icons.grid_view_rounded;
  }
}

class _MegaBannerSection extends StatefulWidget {
  const _MegaBannerSection({required this.bannersAsync});

  final AsyncValue<List<BannerModel>> bannersAsync;

  @override
  State<_MegaBannerSection> createState() => _MegaBannerSectionState();
}

class _MegaBannerSectionState extends State<_MegaBannerSection> {
  final _controller = PageController(viewportFraction: 1);
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: widget.bannersAsync.when(
        data: (rawBanners) {
          final banners = rawBanners;
          if (banners.isEmpty) return const _EmptyTile(message: 'Aktif banner bulunamadı.');
          return ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                PageView.builder(
                  controller: _controller,
                  itemCount: banners.length,
                  onPageChanged: (value) => setState(() => _index = value),
                  itemBuilder: (_, i) {
                    final banner = banners[i];
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: banner.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: FRColors.studio),
                          errorWidget: (_, __, ___) => Container(color: FRColors.studio),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                FRColors.darkMain.withOpacity(0.78),
                                FRColors.darkMain.withOpacity(0.22),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 18,
                          right: 18,
                          bottom: 18,
                          child: Text(
                            banner.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: FRColors.surface,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                Positioned(
                  right: 14,
                  bottom: 14,
                  child: Row(
                    children: List.generate(
                      banners.length,
                      (dot) => Container(
                        width: dot == _index ? 18 : 6,
                        height: 6,
                        margin: const EdgeInsets.only(left: 5),
                        decoration: BoxDecoration(
                          color: dot == _index ? FRColors.gold : FRColors.surface.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const _LoadingTile(height: 160),
        error: (_, __) => const _EmptyTile(message: 'Banner verisi alınamadı.'),
      ),
    );
  }
}

class _RadarAnalysisCard extends StatelessWidget {
  const _RadarAnalysisCard({required this.recommendedAsync, required this.latestAsync});

  final AsyncValue<List<ProductModel>> recommendedAsync;
  final AsyncValue<List<PriceModel>> latestAsync;

  @override
  Widget build(BuildContext context) {
    return recommendedAsync.when(
      data: (recommended) {
        if (recommended.isEmpty) {
          return const _EmptyTile(message: 'Önerilen ürün bulunamadı.');
        }
        final featured = recommended.first;
        final priceRows = _buildPriceRows(featured, latestAsync.valueOrNull ?? const []);
        final maxPrice = priceRows.fold<double>(0, (prev, e) => math.max(prev, e.price));

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: FRColors.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Radar Analiz',
                style: TextStyle(
                  color: FRColors.textMain,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: FRColors.studio,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: featured.mainImage ?? featured.imageUrl ?? '',
                        fit: BoxFit.contain,
                        placeholder: (_, __) => Container(color: FRColors.studio),
                        errorWidget: (_, __, ___) => const Icon(Icons.image_not_supported_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          featured.brand,
                          style: const TextStyle(color: FRColors.textMuted, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          featured.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: FRColors.textMain,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ...priceRows.map((row) {
                final ratio = maxPrice <= 0 ? 1.0 : (row.price / maxPrice).clamp(0.08, 1.0);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 62,
                        child: Text(
                          row.store,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: FRColors.textMain, fontWeight: FontWeight.w700),
                        ),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            minHeight: 10,
                            value: ratio,
                            backgroundColor: FRColors.studio,
                            valueColor: AlwaysStoppedAnimation<Color>(row.isBest ? FRColors.gold : FRColors.darkMain),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _tl(row.price),
                        style: const TextStyle(color: FRColors.textMain, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
      loading: () => const _LoadingTile(height: 240),
      error: (_, __) => const _EmptyTile(message: 'Radar analizi yüklenemedi.'),
    );
  }

  List<_StoreBarRow> _buildPriceRows(ProductModel product, List<PriceModel> latest) {
    final rows = latest
        .where((p) => p.productId == product.id && (p.storeName ?? '').trim().isNotEmpty)
        .map((p) => _StoreBarRow(store: p.storeName!, price: p.price))
        .toList();

    if (rows.isEmpty && product.lastPrice != null) {
      rows.add(_StoreBarRow(store: product.lastStore ?? 'Market', price: product.lastPrice!));
    }

    final deduped = <String, _StoreBarRow>{};
    for (final row in rows) {
      final existing = deduped[row.store];
      if (existing == null || row.price < existing.price) deduped[row.store] = row;
    }
    final sorted = deduped.values.toList()..sort((a, b) => a.price.compareTo(b.price));
    if (sorted.isNotEmpty) {
      final best = sorted.first.store;
      return sorted.take(4).map((e) => e.copyWith(isBest: e.store == best)).toList();
    }
    return const [
      _StoreBarRow(store: 'Veri yok', price: 0, isBest: false),
    ];
  }
}

class _HardDropsSection extends StatelessWidget {
  const _HardDropsSection({required this.trendingAsync, required this.categoryFilter});

  final AsyncValue<List<ProductModel>> trendingAsync;
  final String categoryFilter;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: FRColors.darkMain,
      padding: const EdgeInsets.fromLTRB(24, 24, 0, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(right: 24),
            child: Text(
              'Sert Düşüşler',
              style: TextStyle(
                color: FRColors.surface,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 230,
            child: trendingAsync.when(
              data: (products) {
                final filtered = categoryFilter == 'Tümü'
                    ? products
                    : products
                        .where((p) => p.categories.map((e) => e.toLowerCase()).contains(categoryFilter.toLowerCase()))
                        .toList();
                if (filtered.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(right: 24),
                    child: _EmptyTile(message: 'Bu kategori için ürün bulunamadı.', dark: true),
                  );
                }
                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) {
                    final product = filtered[i];
                    final price = product.lastPrice ?? 0;
                    final oldPrice = price == 0 ? 0 : price * 1.14;
                    final dropPercent = oldPrice == 0 ? 0 : (((oldPrice - price) / oldPrice) * 100).round();
                    return Container(
                      width: 180,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: FRColors.darkSurface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              Container(
                                height: 86,
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: FRColors.studio,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: CachedNetworkImage(
                                  imageUrl: product.mainImage ?? product.imageUrl ?? '',
                                  fit: BoxFit.contain,
                                  placeholder: (_, __) => Container(color: FRColors.studio),
                                  errorWidget: (_, __, ___) => const Icon(Icons.image_not_supported_outlined),
                                ),
                              ),
                              Positioned(
                                left: 8,
                                top: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: FRColors.success.withOpacity(0.16),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.arrow_downward_rounded, size: 13, color: Color(0xFF69F0AE)),
                                      const SizedBox(width: 3),
                                      Text(
                                        'İndirim %$dropPercent',
                                        style: const TextStyle(
                                          color: Color(0xFF69F0AE),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: FRColors.surface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _tl(price),
                            style: const TextStyle(
                              color: FRColors.surface,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            oldPrice == 0 ? '-' : _tl(oldPrice),
                            style: TextStyle(
                              color: FRColors.surface.withOpacity(0.6),
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: FRColors.gold,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              (product.lastStore ?? 'Market').trim().isEmpty ? 'Market' : product.lastStore!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: FRColors.textMain,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const _LoadingTile(height: 220, dark: true),
              error: (_, __) => const _EmptyTile(message: 'Trend ürünler alınamadı.', dark: true),
            ),
          ),
        ],
      ),
    );
  }
}

class _LatestScansSection extends StatelessWidget {
  const _LatestScansSection({required this.latestAsync});

  final AsyncValue<List<PriceModel>> latestAsync;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Son Taramalar',
          style: TextStyle(
            color: FRColors.textMain,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: FRColors.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: latestAsync.when(
            data: (items) {
              if (items.isEmpty) return const _EmptyTile(message: 'Son tarama verisi bulunamadı.');
              return Column(
                children: [
                  for (int i = 0; i < items.length; i++) ...[
                    _LatestPriceRow(item: items[i]),
                    if (i != items.length - 1)
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: FRColors.bgApp,
                        indent: 18,
                        endIndent: 18,
                      ),
                  ],
                ],
              );
            },
            loading: () => const _LoadingTile(height: 180),
            error: (_, __) => const _EmptyTile(message: 'Son fiyatlar yüklenemedi.'),
          ),
        ),
      ],
    );
  }
}

class _LatestPriceRow extends StatelessWidget {
  const _LatestPriceRow({required this.item});

  final PriceModel item;

  @override
  Widget build(BuildContext context) {
    final isPositive = item.score >= 0;
    final iconBg = isPositive ? FRColors.successBg : FRColors.dangerBg;
    final indicatorColor = isPositive ? FRColors.success : FRColors.danger;
    final indicatorIcon = isPositive ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(14)),
            child: Icon(indicatorIcon, color: indicatorColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName ?? 'Ürün',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FRColors.textMain,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.storeName ?? 'Market'} • ${item.reporterName ?? item.userName ?? 'Sistem'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: FRColors.textMuted, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _tl(item.price),
                style: const TextStyle(
                  color: FRColors.textMain,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(indicatorIcon, color: indicatorColor, size: 14),
                  const SizedBox(width: 2),
                  Text(
                    isPositive ? 'Düşüş sinyali' : 'Yükseliş sinyali',
                    style: TextStyle(
                      color: indicatorColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoadingTile extends StatelessWidget {
  const _LoadingTile({required this.height, this.dark = false});

  final double height;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: dark ? FRColors.darkSurface : FRColors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: CircularProgressIndicator(
          color: dark ? FRColors.gold : FRColors.darkMain,
        ),
      ),
    );
  }
}

class _EmptyTile extends StatelessWidget {
  const _EmptyTile({required this.message, this.dark = false});

  final String message;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? FRColors.darkSurface : FRColors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: dark ? FRColors.surface : FRColors.textMuted,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StoreBarRow {
  const _StoreBarRow({required this.store, required this.price, this.isBest = false});

  final String store;
  final double price;
  final bool isBest;

  _StoreBarRow copyWith({String? store, double? price, bool? isBest}) {
    return _StoreBarRow(
      store: store ?? this.store,
      price: price ?? this.price,
      isBest: isBest ?? this.isBest,
    );
  }
}

String _tl(double value) => '${value.toStringAsFixed(2)}₺';
