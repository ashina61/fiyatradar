import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/theme.dart';
import '../../models/product_model.dart';
import '../../models/price_model.dart';
import '../../models/banner_model.dart';
import '../../providers/product_provider.dart';
import '../../providers/banner_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/home_product_card.dart';
import '../../utils/formatters.dart';
import '../main_screen.dart';
import '../points/points_screen.dart';
import '../product/product_detail_screen.dart';
import '../campaign/campaign_basket_screen.dart';

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
    final trendingAsync = ref.watch(trendingProductsProvider);
    final recommendedAsync = ref.watch(recommendedProductsProvider);
    final unreadCountAsync = ref.watch(unreadNotificationCountProvider);
    final latestPricesAsync = ref.watch(latestPricesProvider);

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
                          'Urun, magaza veya kategori ara...',
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
                  error: (_, __) => _buildBannerEmpty(),
                ),
              ),
            ),

            // ---------- Categories Section ----------
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.lg),
                child: categoriesAsync.when(
                  data: (categories) => _buildCategoriesSection(theme, categories),
                  loading: () => _buildCategoriesLoading(theme),
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
                    'Trend Urunler',
                    products,
                    icon: Icons.local_fire_department,
                    iconColor: AppColors.error,
                  ),
                  loading: () => _buildProductsLoading(theme, 'Trend Urunler', icon: Icons.local_fire_department, iconColor: AppColors.error),
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
                    'Onerilen Urunler',
                    products,
                    icon: Icons.thumb_up,
                    iconColor: AppColors.primary,
                  ),
                  loading: () => _buildProductsLoading(theme, 'Onerilen Urunler', icon: Icons.thumb_up, iconColor: AppColors.primary),
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
    final displayName = user?.name ?? 'Kullanici';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
    final points = user?.points ?? 0;
    final unreadCount = unreadCountAsync.valueOrNull ?? 0;
    final String? photoUrl = user?.photoUrl;

    return Row(
      children: [
        // Avatar + Greeting
        GestureDetector(
          onTap: () {
            ref.read(currentTabProvider.notifier).state = 3;
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
                image: NetworkImage(photoUrl),
                fit: BoxFit.cover,
                onError: (_, __) {},
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
              Text(
                'Merhaba',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                displayName,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
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
            ref.read(currentTabProvider.notifier).state = 3;
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
                if (unreadCount > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
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
    final actionType = banner.actionType?.toLowerCase();
    if (actionType == 'campaign' && (banner.targetId?.isNotEmpty ?? false)) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CampaignBasketScreen(
            campaignId: banner.targetId!,
            banner: banner,
          ),
        ),
      );
      return;
    }

    if (actionType == 'product') {
      final productId = banner.targetId ?? banner.productId;
      if (productId != null && productId.isNotEmpty) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: productId)),
        );
      }
    }
  }

  Widget _buildBannerCarousel(List<BannerModel> banners) {
    if (banners.isEmpty) return _buildBannerEmpty();

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _bannerController,
            onPageChanged: (index) {
              setState(() => _currentBannerPage = index);
            },
            itemCount: banners.length,
            itemBuilder: (context, index) {
              final banner = banners[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: GestureDetector(
                  onTap: () => _onBannerTap(banner),
                  child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.75),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    image: banner.imageUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(banner.imageUrl),
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(
                              AppColors.primary.withOpacity(0.35),
                              BlendMode.darken,
                            ),
                            onError: (_, __) {},
                          )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        banner.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(blurRadius: 6, color: Colors.black45)],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      if (banner.description != null)
                        Text(
                          banner.description!,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            shadows: const [Shadow(blurRadius: 6, color: Colors.black45)],
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
        // Page indicator dots
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
                color: _currentBannerPage == index
                    ? AppColors.primary
                    : AppColors.outlineVariant,
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
            'FiyatRadar\'a Hosgeldiniz!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            'En iyi fiyatlari kesfetmeye baslayin',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection(ThemeData theme, List<Map<String, dynamic>> categories) {
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
          height: 100,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm + 4),
            itemBuilder: (context, index) {
              final cat = categories[index];
              final catName = cat['name'] ?? '';
              return _CategoryChip(
                name: catName,
                iconData: _categoryIcon(cat['iconName'] ?? 'category'),
                color: _categoryColor(index),
                onTap: () {
                  ref.read(currentTabProvider.notifier).state = 1;
                  // Set category filter via a brief delay to let the tab switch first
                  Future.delayed(const Duration(milliseconds: 100), () {
                    ref.read(selectedCategoryFilterProvider.notifier).state = catName;
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
        const SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
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
          actionText: 'Tumunu Gor',
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

  IconData _categoryIcon(String iconName) {
    switch (iconName) {
      case 'devices':
        return Icons.devices;
      case 'restaurant':
        return Icons.restaurant;
      case 'cleaning_services':
        return Icons.cleaning_services;
      case 'face':
        return Icons.face;
      case 'home':
        return Icons.home;
      case 'checkroom':
        return Icons.checkroom;
      case 'sports':
        return Icons.sports;
      case 'toys':
        return Icons.toys;
      case 'book':
        return Icons.book;
      case 'directions_car':
        return Icons.directions_car;
      default:
        return Icons.category;
    }
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

  Color _categoryColor(int index) {
    const colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.info,
      AppColors.accent,
      AppColors.error,
      AppColors.primaryDark,
      AppColors.secondaryDark,
      AppColors.accentDark,
      AppColors.primaryLight,
      AppColors.secondaryLight,
    ];
    return colors[index % colors.length];
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
// Category Chip
// ============================================================

class _CategoryChip extends StatelessWidget {
  final String name;
  final IconData iconData;
  final Color color;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.name,
    required this.iconData,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 74,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Icon(iconData, color: color, size: 26),
            ),
            const SizedBox(height: AppSpacing.xs + 2),
            Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Product Card (horizontal scroll card)
// ============================================================
