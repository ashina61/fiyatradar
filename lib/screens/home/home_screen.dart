import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/theme.dart';
import '../../models/product_model.dart';
import '../../models/price_model.dart';
import '../../models/banner_model.dart';
import '../../models/category_model.dart';
import '../../providers/product_provider.dart';
import '../../providers/banner_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/home_product_card.dart';
import '../../widgets/ultra_category_card.dart';
import '../../utils/formatters.dart';
import '../main_screen.dart';
import '../points/points_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../product/product_detail_screen.dart';
import '../notifications/notifications_screen.dart';
import '../campaign/campaign_detail_screen.dart';
import '../campaign/campaigns_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final PageController _bannerController = PageController();
  Timer? _bannerTimer;
  int _currentBannerPage = 0;

  @override
  void initState() {
    super.initState();
    _startBannerAutoScroll();
  }

  void _startBannerAutoScroll() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) return;
      final banners = ref.read(activeBannersProvider).valueOrNull ?? [];
      if (banners.isEmpty) return;
      final nextPage = (_currentBannerPage + 1) % banners.length;
      _bannerController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userAsync = ref.watch(userModelStreamProvider);
    final bannersAsync = ref.watch(activeBannersProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCategory = ref.watch(selectedCategoryFilterProvider);
    final trendingAsync = ref.watch(trendingProductsProvider);
    final recommendedAsync = ref.watch(recommendedProductsProvider);
    final unreadCountAsync = ref.watch(unreadNotificationCountProvider);
    final latestPricesAsync = ref.watch(latestPricesProvider);
    final recentlyViewedAsync = ref.watch(recentlyViewedProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ---------- Custom App Bar ----------
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
                child: userAsync.when(
                  data: (user) => _buildAppBar(context, theme, user, unreadCountAsync),
                  loading: () => _buildAppBar(context, theme, null, unreadCountAsync),
                  error: (_, __) => _buildAppBar(context, theme, null, unreadCountAsync),
                ),
              ),
            ),

            // ---------- Search Bar ----------
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
                child: GestureDetector(
                  onTap: () {
                    ref.read(currentTabProvider.notifier).state = 1;
                  },
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Row(
                      children: [
                        const Icon(Icons.search,
                            color: AppColors.textTertiary, size: 22),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Ürün, mağaza veya kategori ara...',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),


            // ---------- Banner Carousel ----------
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: bannersAsync.when(
                  data: (banners) => _buildBannerCarousel(banners),
                  loading: () => _buildBannerLoading(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
            ),

            // ---------- Categories Section ----------
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.lg),
                child: categoriesAsync.when(
                  data: (categories) => _buildCategoriesSection(theme, categories, selectedCategory),
                  loading: () => _buildCategoriesLoading(theme),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
            ),


            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: recentlyViewedAsync.when(
                  data: (items) => _buildRecentlyViewedSection(theme, items),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
            ),

            // ---------- Trending Products ----------
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.lg),
                child: trendingAsync.when(
                  data: (products) => _buildProductsSection(
                    theme,
                    'Trend Ürünler',
                    products,
                    icon: Icons.local_fire_department,
                    iconColor: AppColors.error,
                  ),
                  loading: () => _buildProductsLoading(theme, 'Trend Ürünler', icon: Icons.local_fire_department, iconColor: AppColors.error),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
            ),

            // ---------- Recommended Products ----------
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.lg),
                child: recommendedAsync.when(
                  data: (products) => _buildProductsSection(
                    theme,
                    'Önerilen Ürünler',
                    products,
                    icon: Icons.thumb_up,
                    iconColor: AppColors.primary,
                  ),
                  loading: () => _buildProductsLoading(theme, 'Önerilen Ürünler', icon: Icons.thumb_up, iconColor: AppColors.primary),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
            ),

            // ---------- Latest Prices ----------
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.lg),
                child: latestPricesAsync.when(
                  data: (prices) => _buildLatestPricesSection(theme, prices),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
            ),

            // Bottom spacing
            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.xl),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, ThemeData theme, dynamic user, AsyncValue<int> unreadCountAsync) {
    final displayName = user?.name ?? 'Kullanıcı';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
    final points = user?.points ?? 0;
    final unreadCount = unreadCountAsync.valueOrNull ?? 0;
    final rawPhotoUrl = (user?.photoUrl ?? '').toString().trim();
    final photoUrl = rawPhotoUrl.isEmpty ? null : rawPhotoUrl;

    return Row(
      children: [
        // Avatar + Greeting
        GestureDetector(
          onTap: () {
            ref.read(currentTabProvider.notifier).state = 4;
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: photoUrl == null ? const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ) : null,
              image: photoUrl != null ? DecorationImage(
                image: CachedNetworkImageProvider(photoUrl),
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
              ) : null,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: photoUrl == null ? Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ) : null,
          ),
        ),
        const SizedBox(width: AppSpacing.sm + 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'Fiyat',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    TextSpan(
                      text: 'Radar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Merhaba, $displayName',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        // Points badge
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PointsScreen()),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: AppColors.accent, size: 16),
                const SizedBox(width: 4),
                Text(
                  '$points',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.accentDark,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        // Notification bell
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            );
          },
          child: SizedBox(
            width: 42,
            height: 42,
            child: Stack(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: AppColors.textPrimary,
                    size: 22,
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Badge(
                    isLabelVisible: unreadCount > 0,
                    backgroundColor: AppColors.error,
                    label: Text(unreadCount > 99 ? '99+' : '$unreadCount'),
                    child: const SizedBox(width: 1, height: 1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _onBannerTap(BannerModel banner) {
    final targetType = (banner.targetType ?? '').toLowerCase().trim();
    final campaignId = (banner.targetId ?? '').trim();

    if (targetType == 'campaign') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => campaignId.isNotEmpty
              ? CampaignDetailScreen(campaignId: campaignId)
              : const CampaignsScreen(),
        ),
      );
      return;
    }
  }

  Widget _buildBannerCarousel(List<BannerModel> banners) {
    if (banners.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 188,
          child: PageView.builder(
            controller: _bannerController,
            onPageChanged: (index) {
              setState(() => _currentBannerPage = index);
            },
            itemCount: banners.length,
            itemBuilder: (context, index) {
              final banner = banners[index];
              final subtitle = (banner.subtitle ?? banner.description ?? '').trim();
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Material(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _onBannerTap(banner),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (banner.imageUrl.isNotEmpty)
                          CachedNetworkImage(
                            imageUrl: banner.imageUrl,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(color: AppColors.surfaceVariant),
                          )
                        else
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF8C5A2B), Color(0xFFB98542)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.black.withOpacity(0.08), Colors.black.withOpacity(0.58)],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                banner.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                              ),
                              if (subtitle.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  subtitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Colors.white.withOpacity(0.95), fontWeight: FontWeight.w500),
                                ),
                              ],
                              const SizedBox(height: AppSpacing.sm),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(AppRadius.full),
                                    border: Border.all(color: Colors.white24),
                                  ),
                                  child: Text(
                                    banner.ctaText ?? 'Keşfet',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            banners.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _currentBannerPage == index ? 20 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: _currentBannerPage == index ? AppColors.primary : AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBannerLoading() {
    return Container(
      height: 180,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildBannerEmpty() {
    return Container(
      height: 180,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        gradient: AppColors.gradient,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Haftanın Kampanya Sepeti',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            'Admin tarafından seçilen premium sepetleri kaçırmayın',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection(ThemeData theme, List<CategoryModel> categories, String selectedCategory) {
    if (categories.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            'Kategoriler',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 102,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final cat = categories[index];
              final isSelected = selectedCategory == cat.title;
              return UltraCategoryCard(
                categoryName: cat.title,
                isSelected: isSelected,
                onTap: () {
                  ref.read(currentTabProvider.notifier).state = 1;
                  Future.delayed(const Duration(milliseconds: 100), () {
                    ref.read(selectedCategoryFilterProvider.notifier).state = cat.title;
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesLoading(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            'Kategoriler',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 102,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            scrollDirection: Axis.horizontal,
            itemCount: 6,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (_, __) => Container(
              width: 98,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.outline),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductsSection(ThemeData theme, String title, List<ProductModel> products, {IconData? icon, Color? iconColor}) {
    if (products.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        _SectionHeader(
          title: title,
          icon: icon,
          iconColor: iconColor,
          actionText: 'Tümünü Gör',
          onAction: () {
            ref.read(currentTabProvider.notifier).state = 1;
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 230,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm + 4),
            itemBuilder: (context, index) {
              final product = products[index];
              return HomeProductCard(
                product: product,
                width: 165,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(productId: product.id),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductsLoading(ThemeData theme, String title, {IconData? icon, Color? iconColor}) {
    return Column(
      children: [
        _SectionHeader(title: title, icon: icon, iconColor: iconColor),
        const SizedBox(height: AppSpacing.sm),
        const SizedBox(
          height: 230,
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
    );
  }

  Widget _buildRecentlyViewedSection(ThemeData theme, List<Map<String, dynamic>> items) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        const _SectionHeader(
          title: 'Son İncelediklerin',
          icon: Icons.history,
          iconColor: AppColors.secondary,
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 108,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final item = items[index];
              final productId = (item['productId'] ?? item['id'] ?? '').toString();
              final productName = (item['productName'] ?? 'Ürün').toString();
              final imageUrl = (item['imageUrl'] ?? '').toString();

              return InkWell(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                onTap: productId.isEmpty
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ProductDetailScreen(productId: productId),
                          ),
                        );
                      },
                child: SizedBox(
                  width: 90,
                  child: Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          child: imageUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => Container(
                                    color: AppColors.surfaceVariant,
                                    child: const Icon(
                                      Icons.inventory_2_outlined,
                                      color: AppColors.textTertiary,
                                    ),
                                  ),
                                )
                              : Container(
                                  color: AppColors.surfaceVariant,
                                  child: const Icon(
                                    Icons.inventory_2_outlined,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        productName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLatestPricesSection(ThemeData theme, List<PriceModel> prices) {
    if (prices.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        const _SectionHeader(
          title: 'Son Eklenen Fiyatlar',
          icon: Icons.access_time,
          iconColor: AppColors.info,
        ),
        const SizedBox(height: AppSpacing.sm),
        ...prices.take(5).map((price) => Card(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
          child: ListTile(
            leading: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(Icons.price_change, color: AppColors.primary, size: 20),
            ),
            title: Text(price.storeName ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(price.userName ?? 'Anonim', style: const TextStyle(fontSize: 12)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                formatTRY(price.price),
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success, fontSize: 14),
              ),
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: price.productId)),
            ),
          ),
        )),
      ],
    );
  }

}

// ============================================================
// Section Header
// ============================================================

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onAction;
  final IconData? icon;
  final Color? iconColor;

  const _SectionHeader({
    required this.title,
    this.actionText,
    this.onAction,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 22, color: iconColor ?? AppColors.primary),
                const SizedBox(width: 6),
              ],
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (actionText != null && onAction != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionText!,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// Product Card (horizontal scroll card)
// ============================================================
