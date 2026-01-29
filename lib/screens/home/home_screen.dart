import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../providers/product_provider.dart';
import '../../providers/banner_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/product_model.dart';
import '../../widgets/product_card.dart';
import '../../widgets/banner_widget.dart';
import '../../utils/theme.dart';
import '../product/product_detail_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final banners = ref.watch(activeBannersProvider);
    final trendingProducts = ref.watch(trendingProductsProvider);
    final recommendedProducts = ref.watch(recommendedProductsProvider);
    final currentUser = ref.watch(userModelStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.radar,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            const Text('FiyatRadar'),
          ],
        ),
        actions: [
          currentUser.when(
            data: (user) => user != null
                ? Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.md),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.stars,
                          color: AppColors.accent,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${user.points}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(activeBannersProvider);
          ref.invalidate(trendingProductsProvider);
          ref.invalidate(recommendedProductsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),

              // Banners
              banners.when(
                data: (bannerList) => bannerList.isNotEmpty
                    ? BannerCarousel(
                        banners: bannerList,
                        onTap: (banner) {
                          if (banner.productId != null) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ProductDetailScreen(
                                  productId: banner.productId!,
                                ),
                              ),
                            );
                          }
                        },
                      )
                    : const SizedBox.shrink(),
                loading: () => const BannerShimmer(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Trend Products Section
              _buildSectionHeader(
                context,
                title: 'Trend Ürünler',
                icon: '🔥',
                onSeeAll: () {
                  // Navigate to all trending products
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              trendingProducts.when(
                data: (products) => _buildHorizontalProductList(
                  context,
                  products,
                ),
                loading: () => _buildHorizontalShimmer(),
                error: (_, __) => _buildErrorWidget(context),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Recommended Products Section
              _buildSectionHeader(
                context,
                title: 'Sizin İçin Önerilenler',
                icon: '⭐',
                onSeeAll: () {
                  // Navigate to all recommended products
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              recommendedProducts.when(
                data: (products) => _buildHorizontalProductList(
                  context,
                  products,
                ),
                loading: () => _buildHorizontalShimmer(),
                error: (_, __) => _buildErrorWidget(context),
              ),
              const SizedBox(height: AppSpacing.lg),

              // All Products Grid
              _buildSectionHeader(
                context,
                title: 'Tüm Ürünler',
                icon: '📦',
              ),
              const SizedBox(height: AppSpacing.sm),
              trendingProducts.when(
                data: (products) => _buildProductGrid(context, products),
                loading: () => _buildGridShimmer(),
                error: (_, __) => _buildErrorWidget(context),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required String icon,
    VoidCallback? onSeeAll,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: const Text('Tümünü Gör'),
            ),
        ],
      ),
    );
  }

  Widget _buildHorizontalProductList(
    BuildContext context,
    List<ProductModel> products,
  ) {
    if (products.isEmpty) {
      return Container(
        height: 200,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Center(
          child: Text(
            'Henüz ürün bulunmuyor',
            style: TextStyle(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          return SizedBox(
            width: 160,
            child: ProductCard(
              product: products[index],
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ProductDetailScreen(
                      productId: products[index].id,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductGrid(BuildContext context, List<ProductModel> products) {
    if (products.isEmpty) {
      return Container(
        height: 200,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Center(
          child: Text(
            'Henüz ürün bulunmuyor',
            style: TextStyle(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: MasonryGridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: products.length,
        itemBuilder: (context, index) {
          return SizedBox(
            height: 240,
            child: ProductCard(
              product: products[index],
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ProductDetailScreen(
                      productId: products[index].id,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildHorizontalShimmer() {
    return SizedBox(
      height: 220,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          return const SizedBox(
            width: 160,
            child: ProductCardShimmer(),
          );
        },
      ),
    );
  }

  Widget _buildGridShimmer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: MasonryGridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        itemBuilder: (context, index) {
          return const SizedBox(
            height: 240,
            child: ProductCardShimmer(),
          );
        },
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Bir hata oluştu',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
