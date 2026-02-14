import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/theme.dart';
import '../../models/product_model.dart';
import '../../models/price_model.dart';
import '../../models/banner_model.dart';
import '../../models/category_model.dart';
import '../../models/user_model.dart';
import '../../providers/product_provider.dart';
import '../../providers/banner_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/home_product_card.dart';
import '../../utils/formatters.dart';
import '../main_screen.dart';
import '../points/points_screen.dart';
import '../add_price/add_price_screen.dart';
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

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  final PageController _bannerController = PageController();
  Timer? _bannerTimer;
  int _currentBannerPage = 0;

  // Section entrance animations
  late final List<AnimationController> _sectionControllers;
  late final List<Animation<double>> _sectionFades;
  late final List<Animation<Offset>> _sectionSlides;

  static const int _sectionCount = 8;

  @override
  void initState() {
    super.initState();
    _startBannerAutoScroll();
    _initSectionAnimations();
  }

  void _initSectionAnimations() {
    _sectionControllers = List.generate(
      _sectionCount,
      (i) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 180 + (i * 40)),
      ),
    );

    _sectionFades = _sectionControllers
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeOut))
        .map((a) => Tween<double>(begin: 0.0, end: 1.0).animate(a))
        .toList();

    _sectionSlides = _sectionControllers
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeOutCubic))
        .map((a) =>
            Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
                .animate(a))
        .toList();

    // Stagger the animations
    Future.delayed(const Duration(milliseconds: 80), () {
      if (!mounted) return;
      for (var i = 0; i < _sectionCount; i++) {
        Future.delayed(Duration(milliseconds: i * 60), () {
          if (mounted) _sectionControllers[i].forward();
        });
      }
    });
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
    for (final c in _sectionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _animatedSection(int index, Widget child) {
    if (index >= _sectionCount) return child;
    return SlideTransition(
      position: _sectionSlides[index],
      child: FadeTransition(
        opacity: _sectionFades[index],
        child: child,
      ),
    );
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
            // ---------- App Bar ----------
            SliverToBoxAdapter(
              child: _animatedSection(
                0,
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: userAsync.when(
                    data: (user) =>
                        _buildAppBar(context, theme, user, unreadCountAsync),
                    loading: () =>
                        _buildAppBar(context, theme, null, unreadCountAsync),
                    error: (_, __) =>
                        _buildAppBar(context, theme, null, unreadCountAsync),
                  ),
                ),
              ),
            ),

            // ---------- Search Bar ----------
            SliverToBoxAdapter(
              child: _animatedSection(
                0,
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _buildSearchBar(theme),
                ),
              ),
            ),

            // ---------- Hero Card ----------
            SliverToBoxAdapter(
              child: _animatedSection(
                1,
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: userAsync.when(
                    data: (user) => _buildHeroCard(context, theme, user),
                    loading: () => _buildHeroCardLoading(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),

            // ---------- Quick Actions ----------
            SliverToBoxAdapter(
              child: _animatedSection(
                2,
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: _buildQuickActions(context, theme),
                ),
              ),
            ),

            // ---------- Impact Mini Cards ----------
            SliverToBoxAdapter(
              child: _animatedSection(
                3,
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: userAsync.when(
                    data: (user) => _buildImpactCards(theme, user),
                    loading: () => _buildImpactCardsLoading(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),

            // ---------- Banner Carousel ----------
            SliverToBoxAdapter(
              child: _animatedSection(
                4,
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: bannersAsync.when(
                    data: (banners) => _buildBannerCarousel(banners),
                    loading: () => _buildBannerLoading(),
                    error: (_, __) => _buildBannerEmpty(),
                  ),
                ),
              ),
            ),

            // ---------- Categories ----------
            SliverToBoxAdapter(
              child: _animatedSection(
                5,
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: categoriesAsync.when(
                    data: (categories) =>
                        _buildCategoriesSection(theme, categories),
                    loading: () => _buildCategoriesLoading(theme),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),

            // ---------- Badges / Rozetler ----------
            SliverToBoxAdapter(
              child: _animatedSection(
                5,
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: userAsync.when(
                    data: (user) => _buildBadgeSection(theme, user),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),

            // ---------- Trending Products ----------
            SliverToBoxAdapter(
              child: _animatedSection(
                6,
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: trendingAsync.when(
                    data: (products) => _buildProductsSection(
                      theme,
                      'Trend Urunler',
                      products,
                      icon: Icons.local_fire_department_rounded,
                      iconColor: AppColors.error,
                    ),
                    loading: () => _buildProductsLoading(theme, 'Trend Urunler',
                        icon: Icons.local_fire_department_rounded,
                        iconColor: AppColors.error),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),

            // ---------- Recommended Products ----------
            SliverToBoxAdapter(
              child: _animatedSection(
                6,
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: recommendedAsync.when(
                    data: (products) => _buildProductsSection(
                      theme,
                      'Onerilen Urunler',
                      products,
                      icon: Icons.thumb_up_rounded,
                      iconColor: AppColors.primary,
                    ),
                    loading: () => _buildProductsLoading(
                        theme, 'Onerilen Urunler',
                        icon: Icons.thumb_up_rounded,
                        iconColor: AppColors.primary),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),

            // ---------- Activity Feed ----------
            SliverToBoxAdapter(
              child: _animatedSection(
                7,
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: latestPricesAsync.when(
                    data: (prices) => _buildActivityFeed(theme, prices),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),

            // Bottom spacing
            const SliverToBoxAdapter(
              child: SizedBox(height: 32),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // APP BAR
  // ================================================================

  Widget _buildAppBar(BuildContext context, ThemeData theme, dynamic user,
      AsyncValue<int> unreadCountAsync) {
    final displayName = user?.name ?? 'Kullanici';
    final initial =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
    final points = user?.points ?? 0;
    final unreadCount = unreadCountAsync.valueOrNull ?? 0;
    final String? photoUrl = user?.photoUrl;

    return Row(
      children: [
        // Avatar
        GestureDetector(
          onTap: () => ref.read(currentTabProvider.notifier).state = 4,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: photoUrl == null
                  ? const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              image: photoUrl != null
                  ? DecorationImage(
                      image: NetworkImage(photoUrl),
                      fit: BoxFit.cover,
                      onError: (_, __) {},
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
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
                        fontSize: 18,
                      ),
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Merhaba',
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                displayName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
        // Points badge
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PointsScreen()),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.accent.withOpacity(0.15),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded,
                    color: AppColors.accent, size: 16),
                const SizedBox(width: 4),
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
        const SizedBox(width: 8),
        // Notification bell
        GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          ),
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: AppColors.textPrimary,
                    size: 22,
                  ),
                ),
                if (unreadCount > 0)
                  Positioned(
                    top: 0,
                    right: 0,
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
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
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

  // ================================================================
  // SEARCH BAR
  // ================================================================

  Widget _buildSearchBar(ThemeData theme) {
    return GestureDetector(
      onTap: () => ref.read(currentTabProvider.notifier).state = 1,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(Icons.search_rounded,
                color: AppColors.textHint, size: 22),
            const SizedBox(width: 8),
            Text(
              'Urun, magaza veya kategori ara...',
              style: TextStyle(
                color: AppColors.textHint,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // HERO CARD - Premium gradient + glass feel
  // ================================================================

  Widget _buildHeroCard(BuildContext context, ThemeData theme, UserModel? user) {
    if (user == null) return const SizedBox.shrink();

    final points = user.points;
    final levelName = _levelName(points);
    final nextLevel = _nextLevel(points);
    final progress = _levelProgress(points);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFB5651D),
            Color(0xFFCD853F),
            Color(0xFFD4874A),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Subtle decorative circle (glass effect)
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          // Content - left aligned
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            levelName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '$points',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Toplam Puan',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Edit icon button
                  GestureDetector(
                    onTap: () =>
                        ref.read(currentTabProvider.notifier).state = 4,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
              if (nextLevel != null) ...[
                const SizedBox(height: 16),
                // Progress bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sonraki: ${nextLevel['name']}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCardLoading() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: AppColors.surfaceVariant,
      ),
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }

  String _levelName(int points) {
    if (points >= 5000) return 'Efsane';
    if (points >= 2500) return 'Uzman';
    if (points >= 1000) return 'Guvenilir';
    if (points >= 500) return 'Fiyat Avcisi';
    if (points >= 100) return 'Aktif';
    return 'Yeni Baslayan';
  }

  Map<String, dynamic>? _nextLevel(int points) {
    final levels = [
      {'name': 'Aktif', 'threshold': 100},
      {'name': 'Fiyat Avcisi', 'threshold': 500},
      {'name': 'Guvenilir', 'threshold': 1000},
      {'name': 'Uzman', 'threshold': 2500},
      {'name': 'Efsane', 'threshold': 5000},
    ];
    for (final level in levels) {
      if (points < (level['threshold'] as int)) return level;
    }
    return null;
  }

  double _levelProgress(int points) {
    final levels = [0, 100, 500, 1000, 2500, 5000];
    for (var i = 1; i < levels.length; i++) {
      if (points < levels[i]) {
        return (points - levels[i - 1]) / (levels[i] - levels[i - 1]);
      }
    }
    return 1.0;
  }

  // ================================================================
  // QUICK ACTIONS - 2x2 grid
  // ================================================================

  Widget _buildQuickActions(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PremiumSectionTitle(title: 'Hizli Islemler'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.add_circle_outline_rounded,
                title: 'Fiyat Ekle',
                color: AppColors.primary,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AddPriceScreen(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.local_fire_department_rounded,
                title: 'Trendler',
                color: AppColors.error,
                onTap: () =>
                    ref.read(currentTabProvider.notifier).state = 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.campaign_rounded,
                title: 'Kampanyalar',
                color: AppColors.accent,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const CampaignsScreen()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.bookmark_outline_rounded,
                title: 'Favoriler',
                color: AppColors.secondary,
                onTap: () =>
                    ref.read(currentTabProvider.notifier).state = 3,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ================================================================
  // IMPACT MINI CARDS - 3 column
  // ================================================================

  Widget _buildImpactCards(ThemeData theme, UserModel? user) {
    if (user == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PremiumSectionTitle(title: 'Etki Ozeti'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ImpactMiniCard(
                label: 'Fiyat Girisi',
                value: '${user.priceEntries}',
                icon: Icons.receipt_long_rounded,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ImpactMiniCard(
                label: 'Dogrulama',
                value: '${user.validations}',
                icon: Icons.verified_rounded,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ImpactMiniCard(
                label: 'Guvenilirlik',
                value: '${user.reliabilityScore.toInt()}',
                icon: Icons.shield_rounded,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImpactCardsLoading() {
    return Row(
      children: List.generate(
        3,
        (i) => Expanded(
          child: Container(
            margin: EdgeInsets.only(left: i > 0 ? 12 : 0),
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    );
  }

  // ================================================================
  // BANNER CAROUSEL
  // ================================================================

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
    if (banners.isEmpty) return _buildBannerEmpty();

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _bannerController,
            onPageChanged: (index) =>
                setState(() => _currentBannerPage = index),
            itemCount: banners.length,
            itemBuilder: (context, index) {
              final banner = banners[index];
              final subtitle =
                  (banner.subtitle ?? banner.description ?? '').trim();
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Material(
                  borderRadius: BorderRadius.circular(22),
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
                            errorWidget: (_, __, ___) =>
                                Container(color: AppColors.surfaceVariant),
                          )
                        else
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFF8C5A2B),
                                  Color(0xFFB98542)
                                ],
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
                              colors: [
                                Colors.black.withOpacity(0.05),
                                Colors.black.withOpacity(0.55),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
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
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              if (subtitle.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  subtitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(24),
                                    border:
                                        Border.all(color: Colors.white24),
                                  ),
                                  child: Text(
                                    banner.ctaText ?? 'Kesfet',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
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
        const SizedBox(height: 12),
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
                borderRadius: BorderRadius.circular(100),
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
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }

  Widget _buildBannerEmpty() {
    return Container(
      height: 180,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: AppColors.gradient,
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Text(
            'Haftanin Kampanya Sepeti',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Admin tarafindan secilen premium sepetleri kacirmayin',
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // CATEGORIES
  // ================================================================

  Widget _buildCategoriesSection(
      ThemeData theme, List<CategoryModel> categories) {
    if (categories.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: _PremiumSectionTitle(title: 'Kategoriler'),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 96,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final cat = categories[index];
              return _CategoryChip(
                name: cat.name,
                iconData: _categoryIcon(cat.iconName),
                color: _categoryColor(index),
                imageUrl: cat.versionedImageUrl,
                onTap: () {
                  ref.read(currentTabProvider.notifier).state = 1;
                  Future.delayed(const Duration(milliseconds: 100), () {
                    ref.read(selectedCategoryFilterProvider.notifier).state =
                        cat.name;
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
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: _PremiumSectionTitle(title: 'Kategoriler'),
        ),
        const SizedBox(height: 12),
        const SizedBox(
          height: 96,
          child: Center(
              child: CircularProgressIndicator(color: AppColors.primary)),
        ),
      ],
    );
  }

  // ================================================================
  // BADGES / ROZETLER
  // ================================================================

  Widget _buildBadgeSection(ThemeData theme, UserModel? user) {
    if (user == null) return const SizedBox.shrink();
    final points = user.points;

    final allBadges = [
      _BadgeData('Yeni Baslayan', Icons.emoji_events_rounded, 0,
          AppColors.textTertiary),
      _BadgeData(
          'Aktif', Icons.bolt_rounded, 100, AppColors.primary),
      _BadgeData('Fiyat Avcisi', Icons.search_rounded, 500,
          AppColors.accent),
      _BadgeData('Guvenilir', Icons.verified_user_rounded, 1000,
          AppColors.success),
      _BadgeData(
          'Uzman', Icons.workspace_premium_rounded, 2500, AppColors.warning),
      _BadgeData('Efsane', Icons.diamond_rounded, 5000, AppColors.error),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PremiumSectionTitle(title: 'Rozetler'),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: allBadges.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final badge = allBadges[index];
              final earned = points >= badge.threshold;
              return _BadgeCard(
                badge: badge,
                earned: earned,
              );
            },
          ),
        ),
      ],
    );
  }

  // ================================================================
  // PRODUCTS SECTION
  // ================================================================

  Widget _buildProductsSection(
      ThemeData theme, String title, List<ProductModel> products,
      {IconData? icon, Color? iconColor}) {
    if (products.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        _PremiumSectionHeader(
          title: title,
          icon: icon,
          iconColor: iconColor,
          actionText: 'Tumunu Gor',
          onAction: () => ref.read(currentTabProvider.notifier).state = 1,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 230,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final product = products[index];
              return HomeProductCard(
                product: product,
                width: 165,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        ProductDetailScreen(productId: product.id),
                  ),
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
        _PremiumSectionHeader(title: title, icon: icon, iconColor: iconColor),
        const SizedBox(height: 12),
        const SizedBox(
          height: 230,
          child: Center(
              child: CircularProgressIndicator(color: AppColors.primary)),
        ),
      ],
    );
  }

  // ================================================================
  // ACTIVITY FEED
  // ================================================================

  Widget _buildActivityFeed(ThemeData theme, List<PriceModel> prices) {
    if (prices.isEmpty) {
      return _buildEmptyState(
        icon: Icons.receipt_long_rounded,
        title: 'Henuz aktivite yok',
        subtitle: 'Fiyat ekleyerek toplulugun ise katkin!',
        ctaText: 'Fiyat Ekle',
        onCta: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddPriceScreen()),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PremiumSectionTitle(title: 'Son Aktiviteler'),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.outline.withOpacity(0.4),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.cardShadow.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              ...prices.take(5).toList().asMap().entries.map((entry) {
                final index = entry.key;
                final price = entry.value;
                final isLast = index == math.min(4, prices.length - 1);

                return Column(
                  children: [
                    _ActivityRow(
                      price: price,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ProductDetailScreen(
                              productId: price.productId),
                        ),
                      ),
                    ),
                    if (!isLast)
                      Divider(
                        height: 1,
                        thickness: 0.5,
                        color: AppColors.outline.withOpacity(0.3),
                        indent: 56,
                        endIndent: 16,
                      ),
                  ],
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  // ================================================================
  // EMPTY STATE
  // ================================================================

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? ctaText,
    VoidCallback? onCta,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.outline.withOpacity(0.4),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textTertiary,
            ),
          ),
          if (ctaText != null && onCta != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 40,
              child: ElevatedButton(
                onPressed: onCta,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                ),
                child: Text(
                  ctaText,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ================================================================
  // HELPERS
  // ================================================================

  IconData _categoryIcon(String iconName) {
    switch (iconName) {
      case 'devices':
        return Icons.devices_rounded;
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'cleaning_services':
        return Icons.cleaning_services_rounded;
      case 'face':
        return Icons.face_rounded;
      case 'home':
        return Icons.home_rounded;
      case 'checkroom':
        return Icons.checkroom_rounded;
      case 'sports':
        return Icons.sports_rounded;
      case 'toys':
        return Icons.toys_rounded;
      case 'book':
        return Icons.book_rounded;
      case 'directions_car':
        return Icons.directions_car_rounded;
      default:
        return Icons.category_rounded;
    }
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
// PREMIUM SECTION TITLE (no icon, no action)
// ============================================================

class _PremiumSectionTitle extends StatelessWidget {
  final String title;

  const _PremiumSectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.3,
      ),
    );
  }
}

// ============================================================
// PREMIUM SECTION HEADER (with icon + action)
// ============================================================

class _PremiumSectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onAction;
  final IconData? icon;
  final Color? iconColor;

  const _PremiumSectionHeader({
    required this.title,
    this.actionText,
    this.onAction,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
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
// QUICK ACTION CARD with ripple + scale(0.97)
// ============================================================

class _QuickActionCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) {
        _scaleController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _scaleController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {}, // handled by GestureDetector for scale
            splashColor: widget.color.withOpacity(0.08),
            highlightColor: widget.color.withOpacity(0.04),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.outline.withOpacity(0.4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.cardShadow.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: widget.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(widget.icon,
                          color: widget.color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// IMPACT MINI CARD
// ============================================================

class _ImpactMiniCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _ImpactMiniCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.outline.withOpacity(0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// BADGE DATA + BADGE CARD with shine + scale-in
// ============================================================

class _BadgeData {
  final String name;
  final IconData icon;
  final int threshold;
  final Color color;

  _BadgeData(this.name, this.icon, this.threshold, this.color);
}

class _BadgeCard extends StatefulWidget {
  final _BadgeData badge;
  final bool earned;

  const _BadgeCard({required this.badge, required this.earned});

  @override
  State<_BadgeCard> createState() => _BadgeCardState();
}

class _BadgeCardState extends State<_BadgeCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _shineAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
          parent: _controller, curve: Curves.elasticOut),
    );
    _shineAnim = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.earned) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final badge = widget.badge;
    final earned = widget.earned;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = earned ? _scaleAnim.value : 1.0;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 88,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: earned
                  ? AppColors.surface
                  : AppColors.surfaceVariant.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: earned
                    ? badge.color.withOpacity(0.3)
                    : AppColors.outline.withOpacity(0.3),
              ),
              boxShadow: earned
                  ? [
                      BoxShadow(
                        color: badge.color.withOpacity(0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              children: [
                // Shine effect overlay
                if (earned)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: ShaderMask(
                        shaderCallback: (bounds) {
                          return LinearGradient(
                            begin: Alignment(-1.0 + _shineAnim.value, -0.3),
                            end: Alignment(
                                -0.5 + _shineAnim.value, 0.3),
                            colors: [
                              Colors.transparent,
                              Colors.white.withOpacity(0.15),
                              Colors.transparent,
                            ],
                          ).createShader(bounds);
                        },
                        blendMode: BlendMode.srcATop,
                        child: Container(color: Colors.white),
                      ),
                    ),
                  ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      badge.icon,
                      color: earned
                          ? badge.color
                          : AppColors.textHint,
                      size: 28,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      badge.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            earned ? FontWeight.w600 : FontWeight.w500,
                        color: earned
                            ? AppColors.textPrimary
                            : AppColors.textHint,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================
// ACTIVITY ROW
// ============================================================

class _ActivityRow extends StatelessWidget {
  final PriceModel price;
  final VoidCallback onTap;

  const _ActivityRow({required this.price, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    price.storeName ?? 'Magaza',
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
                    price.userName ?? 'Anonim',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
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
    );
  }
}

// ============================================================
// CATEGORY CHIP
// ============================================================

class _CategoryChip extends StatelessWidget {
  final String name;
  final IconData iconData;
  final Color color;
  final String? imageUrl;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.name,
    required this.iconData,
    required this.color,
    this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              key: ValueKey(imageUrl ?? name),
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: imageUrl != null && imageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) =>
                          Icon(iconData, color: color, size: 26),
                    )
                  : Icon(iconData, color: color, size: 26),
            ),
            const SizedBox(height: 6),
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

