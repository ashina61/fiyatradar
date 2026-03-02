import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/theme.dart';
import '../../models/product_model.dart';
import '../../models/price_model.dart';
import '../../models/banner_model.dart';
import '../../models/category_model.dart';
import '../../providers/product_provider.dart';
import '../../providers/banner_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/notification_center_service.dart';
import '../../widgets/home_product_card.dart';
import '../../widgets/category_tile_v3.dart';
import '../../widgets/horizontal_categories_widget.dart';
import '../../widgets/staggered_fade_slide.dart';
import '../../widgets/premium_pressable.dart';
import '../../utils/formatters.dart';
import '../main_screen.dart';
import '../points/points_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../product/product_detail_screen.dart';
import '../../pages/notification_center_page.dart';
import '../campaign/campaign_detail_screen.dart';
import '../campaign/campaigns_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  final PageController _bannerController = PageController(viewportFraction: 0.88);
  Timer? _bannerTimer;
  int _currentBannerPage = 0;
  final ScrollController _categoryScrollController = ScrollController();
  final ScrollController _statsScrollController = ScrollController();
  bool _isSnappingCategories = false;
  Timer? _statsMarqueeTimer;

  static const double _categoryTileWidth = 110;
  static const double _categoryTileSpacing = 12;
  static const double _categoryListHorizontalPadding = 20;
  late final AnimationController _headerAnimController;
  late final Animation<double> _headerFade;

  @override
  void initState() {
    super.initState();
    _startBannerAutoScroll();
    _startStatsMarquee();
    _headerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _headerFade = CurvedAnimation(
      parent: _headerAnimController,
      curve: Curves.easeOutCubic,
    );
    _headerAnimController.forward();
  }


  void _startBannerAutoScroll() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) return;
      final banners = ref.read(activeBannersProvider).valueOrNull ?? [];
      if (banners.isEmpty) return;
      if (!_bannerController.hasClients) return;
      final nextPage = (_currentBannerPage + 1) % banners.length;
      _bannerController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    });
  }


  void _startStatsMarquee() {
    _statsMarqueeTimer = Timer.periodic(const Duration(milliseconds: 45), (_) {
      if (!mounted || !_statsScrollController.hasClients) return;
      final position = _statsScrollController.position;
      final maxScroll = position.maxScrollExtent;
      if (maxScroll <= 0) return;

      final nextOffset = position.pixels + 1;
      if (nextOffset >= maxScroll) {
        _statsScrollController.jumpTo(0);
      } else {
        _statsScrollController.jumpTo(nextOffset);
      }
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _categoryScrollController.dispose();
    _statsMarqueeTimer?.cancel();
    _statsScrollController.dispose();
    _bannerController.dispose();
    _headerAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userAsync = ref.watch(userModelStreamProvider);
    final bannersAsync = ref.watch(activeBannersProvider);
    final trendingAsync = ref.watch(trendingProductsProvider);
    final recommendedAsync = ref.watch(recommendedProductsProvider);
    final storesAsync = ref.watch(allStoresStreamProvider);
    final usersAsync = ref.watch(allUsersProvider);
    final latestPricesAsync = ref.watch(latestPricesProvider);
    final recentlyViewedAsync = ref.watch(recentlyViewedProvider);
    final users = usersAsync.valueOrNull ?? [];
    final marketCount = storesAsync.valueOrNull?.length ?? 0;
    final totalUserCount = users.length;
    final totalPriceCount = users.fold<int>(
      0,
      (sum, user) => sum + user.priceEntries,
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Ambient gradient background
          Positioned(
            top: -120,
            left: -80,
            child: _AmbientOrb(
                size: 300,
                color: AppColors.primary,
                opacity: 0.10),
          ),
          Positioned(
            top: 200,
            right: -100,
            child: _AmbientOrb(
                size: 260,
                color: AppColors.accent,
                opacity: 0.08),
          ),
          Positioned(
            bottom: 100,
            left: -60,
            child: _AmbientOrb(
                size: 200,
                color: AppColors.secondary,
                opacity: 0.06),
          ),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                // ---------- App Bar ----------
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _headerFade,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: userAsync.when(
                        data: (user) =>
                            _buildAppBar(context, theme, user),
                        loading: () =>
                            _buildAppBar(context, theme, null),
                        error: (_, __) =>
                            _buildAppBar(context, theme, null),
                      ),
                    ),
                  ),
                ),

                // ---------- Search Bar ----------
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: _buildSearchBar(theme),
                  ),
                ),

                // ---------- System Stats Marquee ----------
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                    child: _buildSystemStatsMarquee(
                      theme,
                      marketCount: marketCount,
                      totalPriceCount: totalPriceCount,
                      totalUserCount: totalUserCount,
                    ),
                  ),
                ),

                // ---------- Banner Carousel ----------
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: bannersAsync.when(
                      data: (banners) => _buildBannerCarousel(banners, theme),
                      loading: () => _buildBannerLoading(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ),
                ),

                // ---------- Categories Section ----------
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: const HorizontalCategoriesWidget(),
                  ),
                ),

                // ---------- Recently Viewed ----------
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: recentlyViewedAsync.when(
                      data: (items) =>
                          _buildRecentlyViewedSection(theme, items),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ),
                ),

                // ---------- Trending Products ----------
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 26),
                    child: trendingAsync.when(
                      data: (products) => _buildProductsSection(
                        theme,
                        'Trend Ürünler',
                        products,
                        icon: Icons.local_fire_department_rounded,
                        iconColor: AppColors.error,
                      ),
                      loading: () => _buildProductsLoading(theme,
                          'Trend Ürünler',
                          icon: Icons.local_fire_department_rounded,
                          iconColor: AppColors.error),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ),
                ),

                // ---------- Recommended Products ----------
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 26),
                    child: recommendedAsync.when(
                      data: (products) => _buildProductsSection(
                        theme,
                        'Önerilen Ürünler',
                        products,
                        icon: Icons.auto_awesome_rounded,
                        iconColor: AppColors.accent,
                      ),
                      loading: () => _buildProductsLoading(theme,
                          'Önerilen Ürünler',
                          icon: Icons.auto_awesome_rounded,
                          iconColor: AppColors.accent),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ),
                ),

                // ---------- Latest Prices ----------
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 26),
                    child: latestPricesAsync.when(
                      data: (prices) =>
                          _buildLatestPricesSection(theme, prices),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ),
                ),

                // Bottom spacing
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── App Bar ───────────────────────────────────────────────────
  Widget _buildAppBar(BuildContext context, ThemeData theme, dynamic user) {
    final displayName = user?.name ?? 'Kullanıcı';
    final initial =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
    final points = user?.points ?? 0;
    final rawPhotoUrl = (user?.photoUrl ?? '').toString().trim();
    final photoUrl = rawPhotoUrl.isEmpty ? null : rawPhotoUrl;

    return Row(
      children: [
        // Avatar
        GestureDetector(
          onTap: () {
            ref.read(currentTabProvider.notifier).state = 4;
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: photoUrl == null
                  ? const LinearGradient(
                      colors: [AppColors.primary, AppColors.accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              image: photoUrl != null
                  ? DecorationImage(
                      image: CachedNetworkImageProvider(photoUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: photoUrl == null
                ? Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 19,
                      ),
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Merhaba, $displayName',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _getGreetingSubtitle(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        // Points badge
        PremiumPressable(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PointsScreen()),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.accent.withOpacity(0.12),
                  AppColors.secondary.withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.accent.withOpacity(0.15),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.stars_rounded,
                    color: AppColors.accent, size: 17),
                const SizedBox(width: 5),
                Text(
                  '$points',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.accentDark,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        const _NotificationBellButton(),
      ],
    );
  }


  String _getGreetingSubtitle() {
    final hour = DateTime.now().hour;
    if (hour < 6) return 'Gece kusu musun?';
    if (hour < 12) return 'Gunaydin! Bugunun firsatlari hazir.';
    if (hour < 18) return 'Iyi gunler! Firsatlari kacirma.';
    return 'Iyi aksamlar! Son firsatlara goz at.';
  }

  // ─── Search Bar ────────────────────────────────────────────────
  Widget _buildSearchBar(ThemeData theme) {
    return PremiumPressable(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        ref.read(currentTabProvider.notifier).state = 1;
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.85),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.outline.withOpacity(0.4),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.search_rounded,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ürün, mağaza veya kategori ara...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textHint,
                    ),
                  ),
                ),
                Icon(Icons.tune_rounded,
                    color: AppColors.textTertiary, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── System Stats Marquee ───────────────────────────────
  Widget _buildSystemStatsMarquee(
    ThemeData theme, {
    required int marketCount,
    required int totalPriceCount,
    required int totalUserCount,
  }) {
    final stats = [
      'Sistemde kayıtlı market sayısı: $marketCount',
      'Sistemde kayıtlı fiyat sayısı: $totalPriceCount',
      'Toplam kullanıcı sayısı: $totalUserCount',
    ];

    final loopedStats = [...stats, ...stats];

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.14)),
      ),
      child: ListView.separated(
        controller: _statsScrollController,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: loopedStats.length,
        separatorBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Icon(Icons.circle, size: 6, color: AppColors.primary.withOpacity(0.55)),
        ),
        itemBuilder: (context, index) {
          return Center(
            child: Text(
              loopedStats[index],
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        },
      ),
    );
  }


  // ─── Banner Carousel ───────────────────────────────────────────
  Widget _buildBannerCarousel(List<BannerModel> banners, ThemeData theme) {
    if (banners.isEmpty) return const SizedBox.shrink();

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
              final subtitle =
                  (banner.subtitle ?? banner.description ?? '').trim();
              return AnimatedBuilder(
                animation: _bannerController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_bannerController.position.haveDimensions) {
                    value = (_bannerController.page ?? 0) - index;
                    value = (1 - (value.abs() * 0.15)).clamp(0.85, 1.0);
                  }
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: PremiumPressable(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _onBannerTap(banner),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.12),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (banner.imageUrl.isNotEmpty)
                              CachedNetworkImage(
                                imageUrl: banner.imageUrl,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primary,
                                        AppColors.accent
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                ),
                              )
                            else
                              Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      AppColors.accent
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                              ),
                            // Gradient overlay
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.65),
                                  ],
                                  stops: const [0.3, 1.0],
                                ),
                              ),
                            ),
                            // Content
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    banner.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 19,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.3,
                                      height: 1.2,
                                    ),
                                  ),
                                  if (subtitle.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      subtitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.85),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(
                                          color: Colors.white30, width: 0.5),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          banner.ctaText ?? 'Kesfet',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.arrow_forward_rounded,
                                          color: Colors.white,
                                          size: 14,
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
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        // Page indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            banners.length,
            (index) {
              final isActive = _currentBannerPage == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primary
                      : AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBannerLoading() {
    return Container(
      height: 180,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.primary.withOpacity(0.5),
          ),
        ),
      ),
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

  // ─── Categories ────────────────────────────────────────────────
  Widget _buildCategoriesSection(ThemeData theme,
      List<CategoryModel> categories, String? selectedCategoryId) {
    if (categories.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Kategoriler',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 142,
          child: NotificationListener<ScrollEndNotification>(
            onNotification: (notification) {
              if (_isSnappingCategories ||
                  !_categoryScrollController.hasClients ||
                  categories.length <= 1) {
                return false;
              }

              final rawIndex = (_categoryScrollController.offset /
                      (_categoryTileWidth + _categoryTileSpacing))
                  .round();
              final targetIndex =
                  rawIndex.clamp(0, categories.length - 1);
              final targetOffset =
                  targetIndex * (_categoryTileWidth + _categoryTileSpacing);

              if ((_categoryScrollController.offset - targetOffset).abs() <
                  2) {
                return false;
              }

              _isSnappingCategories = true;
              _categoryScrollController
                  .animateTo(
                    targetOffset,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                  )
                  .whenComplete(() => _isSnappingCategories = false);

              return false;
            },
            child: ListView.separated(
              controller: _categoryScrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: _categoryListHorizontalPadding,
              ),
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: _categoryTileSpacing),
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected =
                    selectedCategoryId == category.canonicalId;

                return StaggeredFadeSlide(
                  index: index,
                  child: CategoryTileV3(
                    category: category,
                    isSelected: isSelected,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      ref.read(currentTabProvider.notifier).state = 1;
                      Future.delayed(const Duration(milliseconds: 100), () {
                        ref.read(selectedCategoryIdProvider.notifier).state =
                            category.canonicalId;
                        ref
                            .read(selectedCategoryFilterProvider.notifier)
                            .state = category.title;
                      });
                    },
                  ),
                );
              },
            ),
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
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Kategoriler',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 142,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(
                horizontal: _categoryListHorizontalPadding),
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            separatorBuilder: (_, __) =>
                const SizedBox(width: _categoryTileSpacing),
            itemBuilder: (_, __) => Container(
              width: _categoryTileWidth,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(22),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Recently Viewed ───────────────────────────────────────────
  Widget _buildRecentlyViewedSection(
      ThemeData theme, List<Map<String, dynamic>> items) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        _SectionHeader(
          title: 'Son Incelediklerin',
          icon: Icons.history_rounded,
          iconColor: AppColors.secondary,
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 92,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final item = items[index];
              final productId =
                  (item['productId'] ?? item['id'] ?? '').toString();
              final productName =
                  (item['productName'] ?? 'Ürün').toString();
              final imageUrl = (item['imageUrl'] ?? '').toString();

              return PremiumPressable(
                borderRadius: BorderRadius.circular(16),
                onTap: productId.isEmpty
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                ProductDetailScreen(productId: productId),
                          ),
                        );
                      },
                child: SizedBox(
                  width: 72,
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.surfaceContainerHighest,
                          border: Border.all(
                            color: AppColors.outline.withOpacity(0.4),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          image: imageUrl.isNotEmpty
                              ? DecorationImage(
                                  image:
                                      CachedNetworkImageProvider(imageUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: imageUrl.isEmpty
                            ? Icon(
                                Icons.inventory_2_outlined,
                                color: AppColors.textTertiary,
                                size: 22,
                              )
                            : null,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        productName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          color: AppColors.textSecondary,
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

  // ─── Product Sections ──────────────────────────────────────────
  Widget _buildProductsSection(ThemeData theme, String title,
      List<ProductModel> products,
      {IconData? icon, Color? iconColor}) {
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
        const SizedBox(height: 14),
        SizedBox(
          height: 235,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final product = products[index];
              return StaggeredFadeSlide(
                index: index,
                child: HomeProductCard(
                  product: product,
                  width: 165,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            ProductDetailScreen(productId: product.id),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductsLoading(ThemeData theme, String title,
      {IconData? icon, Color? iconColor}) {
    return Column(
      children: [
        _SectionHeader(title: title, icon: icon, iconColor: iconColor),
        const SizedBox(height: 14),
        SizedBox(
          height: 235,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (_, __) => Container(
              width: 165,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Latest Prices ─────────────────────────────────────────────
  Widget _buildLatestPricesSection(ThemeData theme, List<PriceModel> prices) {
    if (prices.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        const _SectionHeader(
          title: 'Son Eklenen Fiyatlar',
          icon: Icons.schedule_rounded,
          iconColor: AppColors.info,
        ),
        const SizedBox(height: 14),
        ...prices.take(5).toList().asMap().entries.map((entry) {
          final index = entry.key;
          final price = entry.value;
          return StaggeredFadeSlide(
            index: index,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: PremiumPressable(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        ProductDetailScreen(productId: price.productId),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.outline.withOpacity(0.4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withOpacity(0.10),
                              AppColors.accent.withOpacity(0.06),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.price_change_outlined,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              price.storeName ?? '',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              ((price.reporterName ?? price.userName ?? 'Kullanıcı').trim().isEmpty
                                  ? 'Kullanıcı'
                                  : (price.reporterName ?? price.userName ?? 'Kullanıcı')),
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.success.withOpacity(0.15),
                          ),
                        ),
                        child: Text(
                          formatTRY(price.price),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════
// Supporting Widgets
// ════════════════════════════════════════════════════════════════

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
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.primary).withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  size: 18,
                  color: iconColor ?? theme.colorScheme.primary),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
          ),
          if (actionText != null && onAction != null)
            GestureDetector(
              onTap: onAction,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionText!,
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: theme.colorScheme.primary,
                    size: 18,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _NotificationBellButton extends ConsumerWidget {
  const _NotificationBellButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authStateProvider).valueOrNull?.uid;
    final unreadStream = uid == null
        ? Stream<int>.value(0)
        : NotificationCenterService().getUnreadCount(uid);

    return PremiumPressable(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NotificationCenterPage()),
        );
      },
      child: SizedBox(
        width: 44,
        height: 44,
        child: Stack(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant.withOpacity(0.7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.outline.withOpacity(0.5),
                ),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: AppColors.textSecondary,
                size: 22,
              ),
            ),
            StreamBuilder<int>(
              stream: unreadStream,
              builder: (context, snapshot) {
                final unreadCount = snapshot.data ?? 0;
                if (unreadCount <= 0) return const SizedBox.shrink();
                return Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AmbientOrb extends StatelessWidget {
  const _AmbientOrb({
    required this.size,
    required this.color,
    required this.opacity,
  });

  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withOpacity(opacity),
              color.withOpacity(0),
            ],
          ),
        ),
      ),
    );
  }
}
