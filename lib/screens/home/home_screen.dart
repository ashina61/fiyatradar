import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/banner_model.dart';
import '../../models/price_model.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/banner_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/notification_center_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/premium_pressable.dart';
import '../../widgets/staggered_fade_slide.dart';
import '../../pages/notification_center_page.dart';
import '../campaign/campaign_detail_screen.dart';
import '../campaign/campaigns_screen.dart';
import '../main_screen.dart';
import '../points/points_screen.dart';
import '../product/product_detail_screen.dart';

class FRColors {
  static const bgBody = Color(0xFFF9F6F2);
  static const surface = Colors.white;
  static const studio = Color(0xFFF3EBE4);
  static const primaryDark = Color(0xFF2A1A10);
  static const primary = Color(0xFF6B4226);
  static const gold = Color(0xFFC89B7B);
  static const goldLight = Color(0xFFEFE4DA);
  static const textMain = Color(0xFF2A1A10);
  static const textMuted = Color(0xFF9A9188);
  static const success = Color(0xFF328A4A);
  static const successBg = Color(0xFFE6F3E9);
  static const danger = Color(0xFFD32F2F);
  static const dangerBg = Color(0xFFFFEBEE);
  static const border = Color(0x0F2A1A10);
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final PageController _bannerController = PageController(viewportFraction: 0.94);
  Timer? _bannerTimer;
  int _currentBannerPage = 0;

  @override
  void initState() {
    super.initState();
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_bannerController.hasClients) return;
      final banners = ref.read(activeBannersProvider).valueOrNull ?? const <BannerModel>[];
      if (banners.isEmpty) return;
      final next = (_currentBannerPage + 1) % banners.length;
      _bannerController.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
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
    final userAsync = ref.watch(userModelStreamProvider);
    final bannersAsync = ref.watch(activeBannersProvider);
    final trendingAsync = ref.watch(trendingProductsProvider);
    final latestPricesAsync = ref.watch(latestPricesProvider);
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: FRColors.bgBody,
      body: DefaultTextStyle(
        style: GoogleFonts.outfit(color: FRColors.textMain),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverToBoxAdapter(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: EdgeInsets.fromLTRB(24, top + 14, 24, 44),
                    decoration: const BoxDecoration(
                      color: FRColors.primaryDark,
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                      boxShadow: [
                        BoxShadow(color: Color(0x262A1A10), blurRadius: 30, offset: Offset(0, 10)),
                      ],
                    ),
                    child: userAsync.when(
                      data: (user) => _Header(user: user),
                      loading: () => const SizedBox(height: 56),
                      error: (_, __) => const SizedBox(height: 56),
                    ),
                  ),
                  Positioned(left: 24, right: 24, bottom: -26, child: _buildSearchBox()),
                ],
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 46)),
            SliverToBoxAdapter(child: _buildCategorySection()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 28),
                child: bannersAsync.when(
                  data: _buildBannerSection,
                  loading: () => const SizedBox(height: 160),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 32),
                child: trendingAsync.when(
                  data: (items) => _buildTrendingSection(items.take(10).toList()),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 30),
                child: latestPricesAsync.when(
                  data: (prices) => _buildLatestPrices(prices.take(10).toList()),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBox() {
    return PremiumPressable(
      onTap: () => ref.read(currentTabProvider.notifier).state = 1,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        decoration: BoxDecoration(
          color: FRColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: FRColors.border),
          boxShadow: const [BoxShadow(color: Color(0x1A2A1A10), blurRadius: 30, offset: Offset(0, 15))],
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, color: FRColors.textMuted, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Ürün, marka veya market ara...',
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFFBDB6B0)),
              ),
            ),
            Container(width: 1, height: 24, color: FRColors.border),
            const SizedBox(width: 12),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: FRColors.studio, borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.qr_code_scanner_rounded, color: FRColors.primary, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    const items = [
      ('Tümü', Icons.grid_view_rounded, true),
      ('Market', Icons.local_grocery_store_rounded, false),
      ('Teknoloji', Icons.devices_rounded, false),
      ('Kozmetik', Icons.face_retouching_natural_rounded, false),
      ('Hobi', Icons.sports_esports_rounded, false),
    ];

    return SizedBox(
      height: 94,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final item = items[index];
          final isActive = item.$3;
          return Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isActive ? FRColors.primaryDark : FRColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: isActive ? FRColors.primaryDark : FRColors.border),
                  boxShadow: isActive
                      ? const [BoxShadow(color: Color(0x332A1A10), blurRadius: 20, offset: Offset(0, 8))]
                      : const [BoxShadow(color: Color(0x0A2A1A10), blurRadius: 15, offset: Offset(0, 4))],
                ),
                child: Icon(item.$2 as IconData, color: isActive ? FRColors.gold : FRColors.textMuted, size: 26),
              ),
              const SizedBox(height: 8),
              Text(
                item.$1,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: isActive ? FRColors.primaryDark : FRColors.textMain,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBannerSection(List<BannerModel> banners) {
    if (banners.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 170,
      child: PageView.builder(
        controller: _bannerController,
        itemCount: banners.length,
        onPageChanged: (value) => _currentBannerPage = value,
        itemBuilder: (context, index) {
          final banner = banners[index];
          final imageUrl = banner.imageUrl.isNotEmpty
              ? banner.imageUrl
              : 'https://images.unsplash.com/photo-1542838132-92c53300491e?q=80&w=600&auto=format&fit=crop';
          return Padding(
            padding: const EdgeInsets.only(left: 24, right: 8),
            child: PremiumPressable(
              onTap: () {
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
                }
              },
              borderRadius: BorderRadius.circular(24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover),
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [Color(0xF22A1A10), Color(0x1A2A1A10)],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: index.isEven ? Colors.white : FRColors.gold,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              index.isEven ? 'GÜNÜN FIRSATI' : 'HAFTANIN YILDIZI',
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: FRColors.primaryDark,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            banner.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              height: 1.2,
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  banner.ctaText ?? 'İncele',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
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
          );
        },
      ),
    );
  }

  Widget _buildTrendingSection(List<ProductModel> products) {
    if (products.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Trend Ürünler',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: FRColors.textMain),
              ),
              GestureDetector(
                onTap: () => ref.read(currentTabProvider.notifier).state = 1,
                child: Text(
                  'Tümünü Gör',
                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: FRColors.gold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 266,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) => StaggeredFadeSlide(
              index: index,
              child: _ProductCard(
                product: products[index],
                onTap: () => Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: products[index].id)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLatestPrices(List<PriceModel> prices) {
    if (prices.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Piyasa Akışı', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: FRColors.textMain)),
          const SizedBox(height: 16),
          ...prices.take(5).map((price) {
            final subtitleLeft = (price.storeName ?? 'Market').trim();
            final subtitleRight = (price.reporterName ?? price.userName ?? 'Sistem').trim();
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PremiumPressable(
                onTap: () => Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: price.productId)),
                ),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: FRColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: FRColors.border),
                    boxShadow: const [BoxShadow(color: Color(0x0A2A1A10), blurRadius: 15, offset: Offset(0, 4))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(color: FRColors.studio, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.history_rounded, color: FRColors.primary, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (price.productName ?? 'Ürün').trim(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, color: FRColors.textMain),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$subtitleLeft • $subtitleRight',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500, color: FRColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        formatTRY(price.price),
                        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: FRColors.primaryDark),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.user});

  final dynamic user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayName = (user?.name ?? 'Kullanıcı').toString();
    final points = user?.points ?? 0;
    final imageUrl = (user?.photoUrl ?? '').toString().trim();
    final initial = displayName.isNotEmpty ? displayName.characters.first.toUpperCase() : 'U';

    return Row(
      children: [
        GestureDetector(
          onTap: () => ref.read(currentTabProvider.notifier).state = 4,
          child: Container(
            width: 46,
            height: 46,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: FRColors.gold, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: imageUrl.isNotEmpty
                  ? CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover)
                  : ColoredBox(
                      color: Colors.white,
                      child: Center(
                        child: Text(
                          initial,
                          style: GoogleFonts.outfit(color: FRColors.primaryDark, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hoş geldin,', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500, color: FRColors.gold)),
              const SizedBox(height: 2),
              Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ],
          ),
        ),
        PremiumPressable(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PointsScreen())),
          borderRadius: BorderRadius.circular(100),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: const Color(0x4DC89B7B)),
              color: const Color(0x26C89B7B),
            ),
            child: Row(
              children: [
                const Icon(Icons.stars_rounded, color: FRColors.gold, size: 16),
                const SizedBox(width: 4),
                Text(
                  points.toString(),
                  style: GoogleFonts.outfit(fontSize: 13, color: FRColors.gold, fontWeight: FontWeight.w800),
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
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.onTap});

  final ProductModel product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = product.name.trim().isEmpty ? 'Ürün' : product.name.trim();
    final brand = product.brand.trim().isEmpty ? 'MARKA' : product.brand.trim().toUpperCase();
    final oldPrice = product.lastPrice != null ? product.lastPrice! * 1.08 : null;
    final trendPercent = product.priceEntryCount > 0 ? product.priceEntryCount.clamp(1, 99) : 1;
    final trendIsDrop = (product.viewCount + product.priceEntryCount).isEven;

    return PremiumPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 165,
        decoration: BoxDecoration(
          color: FRColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: FRColors.border),
          boxShadow: const [BoxShadow(color: Color(0x0A2A1A10), blurRadius: 15, offset: Offset(0, 4))],
        ),
        child: Column(
          children: [
            Container(
              height: 145,
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: FRColors.studio,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(bottom: BorderSide(color: FRColors.border)),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CachedNetworkImage(
                      imageUrl: product.effectiveImage ?? '',
                      fit: BoxFit.contain,
                      errorWidget: (_, __, ___) => const Icon(Icons.image_not_supported, color: FRColors.textMuted),
                    ),
                  ),
                  Positioned(
                    top: -12,
                    left: -12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: trendIsDrop ? FRColors.successBg : FRColors.dangerBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            trendIsDrop ? Icons.south_east_rounded : Icons.north_east_rounded,
                            size: 14,
                            color: trendIsDrop ? FRColors.success : FRColors.danger,
                          ),
                          Text(
                            '%$trendPercent',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: trendIsDrop ? FRColors.success : FRColors.danger,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: -12,
                    right: -12,
                    child: Icon(
                      product.isTrending ? Icons.favorite : Icons.favorite_border,
                      color: product.isTrending ? FRColors.danger : const Color(0xFFC2BBB5),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      brand,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800, color: FRColors.textMuted, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(fontSize: 13, height: 1.3, fontWeight: FontWeight.w700, color: FRColors.textMain),
                    ),
                    const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                oldPrice != null ? formatTRY(oldPrice) : '—',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: FRColors.textMuted,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              Text(
                                product.lastPrice != null ? formatTRY(product.lastPrice!) : '—',
                                style: GoogleFonts.outfit(fontSize: 18, height: 1, fontWeight: FontWeight.w900, color: FRColors.primary),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: FRColors.goldLight, borderRadius: BorderRadius.circular(6)),
                          child: Text(
                            (product.lastStore ?? 'Market').trim(),
                            style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800, color: FRColors.primaryDark),
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

class _NotificationBellButton extends ConsumerWidget {
  const _NotificationBellButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authStateProvider).valueOrNull?.uid;
    final unreadStream = uid == null ? Stream<int>.value(0) : NotificationCenterService().getUnreadCount(uid);

    return PremiumPressable(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationCenterPage())),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x1AFFFFFF)),
          color: const Color(0x0DFFFFFF),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.notifications_rounded, color: Colors.white, size: 20),
            StreamBuilder<int>(
              stream: unreadStream,
              builder: (context, snapshot) {
                if ((snapshot.data ?? 0) <= 0) return const SizedBox.shrink();
                return Positioned(
                  top: 9,
                  right: 9,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: FRColors.danger,
                      shape: BoxShape.circle,
                      border: Border.all(color: FRColors.primaryDark, width: 2),
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
