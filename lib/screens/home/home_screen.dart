import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/banner_model.dart';
import '../../models/category_model.dart';
import '../../models/price_model.dart';
import '../../models/product_model.dart';
import '../../models/user_model.dart';
import '../../pages/notification_center_page.dart';
import '../../providers/auth_provider.dart';
import '../../providers/banner_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/premium_pressable.dart';
import '../main_screen.dart';
import '../points/points_screen.dart';
import '../product/product_detail_screen.dart';

class FRColors {
  static const Color bgApp = Color(0xFFF5F3F0);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color studio = Color(0xFFEBE5DF);

  static const Color darkMain = Color(0xFF211510);
  static const Color darkSurface = Color(0xFF2D1E17);
  static const Color gold = Color(0xFFC29B78);

  static const Color textMain = Color(0xFF211510);
  static const Color textMuted = Color(0xFF948A82);

  static const Color success = Color(0xFF4CAF50);
  static const Color successBg = Color(0xFFE8F5E9);
  static const Color danger = Color(0xFFF44336);
  static const Color dangerBg = Color(0xFFFFEBEE);
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final PageController _bannerController = PageController();
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      final banners = ref.read(activeBannersProvider).valueOrNull ?? const [];
      if (banners.length < 2 || !_bannerController.hasClients) return;
      final page = _bannerController.page?.round() ?? 0;
      final next = (page + 1) % banners.length;
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
    final categoriesAsync = ref.watch(categoriesProvider);
    final bannersAsync = ref.watch(activeBannersProvider);
    final trendingAsync = ref.watch(trendingProductsProvider);
    final recommendedAsync = ref.watch(recommendedProductsProvider);
    final latestPricesAsync = ref.watch(latestPricesProvider);
    final usersAsync = ref.watch(allUsersProvider);

    return Scaffold(
      backgroundColor: FRColors.bgApp,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context, userAsync.valueOrNull)),
          SliverToBoxAdapter(child: _buildCategories(categoriesAsync.valueOrNull ?? const [])),
          SliverToBoxAdapter(child: _buildBannerSection(context, bannersAsync.valueOrNull ?? const [])),
          SliverToBoxAdapter(child: _buildInsightGrid(trendingAsync.valueOrNull ?? const [])),
          SliverToBoxAdapter(child: _buildTrendProducts(context, trendingAsync.valueOrNull ?? const [])),
          SliverToBoxAdapter(
            child: _buildEditorChoice(context, recommendedAsync.valueOrNull?.isNotEmpty == true ? recommendedAsync.valueOrNull!.first : null),
          ),
          SliverToBoxAdapter(child: _buildLatestPrices(latestPricesAsync.valueOrNull ?? const [])),
          SliverToBoxAdapter(child: _buildLeaders(usersAsync.valueOrNull ?? const [])),
          SliverToBoxAdapter(child: _buildFooter()),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserModel? user) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final displayName = (user?.displayName?.isNotEmpty == true ? user!.displayName! : 'Radar Kullanıcısı');
    final points = user?.points ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(24, topPadding + 16, 24, 50),
            decoration: const BoxDecoration(
              color: FRColors.darkMain,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x33211510),
                  blurRadius: 30,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    border: Border.all(color: FRColors.gold, width: 1.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: user?.photoUrl != null
                        ? CachedNetworkImage(imageUrl: user!.photoUrl!, fit: BoxFit.cover)
                        : Container(
                            color: FRColors.studio,
                            alignment: Alignment.center,
                            child: Text(
                              displayName.characters.first.toUpperCase(),
                              style: const TextStyle(fontWeight: FontWeight.w800, color: FRColors.darkMain),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'RADAR AKTİF',
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w600,
                          color: FRColors.gold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: FRColors.surface,
                        ),
                      ),
                    ],
                  ),
                ),
                PremiumPressable(
                  borderRadius: BorderRadius.circular(100),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PointsScreen())),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.stars_rounded, color: FRColors.gold, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          formatCompactCount(points),
                          style: const TextStyle(color: FRColors.gold, fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PremiumPressable(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationCenterPage())),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Stack(
                      children: const [
                        Center(child: Icon(Icons.notifications_rounded, color: FRColors.surface, size: 20)),
                        Positioned(
                          right: 11,
                          top: 11,
                          child: CircleAvatar(radius: 3, backgroundColor: FRColors.danger),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: -24,
            child: PremiumPressable(
              borderRadius: BorderRadius.circular(20),
              onTap: () => ref.read(currentTabProvider.notifier).state = 1,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
                decoration: BoxDecoration(
                  color: FRColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14211510),
                      blurRadius: 35,
                      offset: Offset(0, 15),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: FRColors.textMuted, size: 22),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Ürün, marka veya mağaza ara...',
                        style: TextStyle(color: Color(0xFFAFA59D), fontWeight: FontWeight.w500, fontSize: 14),
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: FRColors.studio, borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.qr_code_scanner_rounded, color: FRColors.darkMain, size: 20),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories(List<CategoryModel> categories) {
    return SizedBox(
      height: 58,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _categoryPill(title: 'Tümü', icon: Icons.grid_view_rounded, active: true);
          }
          final item = categories[index - 1];
          return _categoryPill(title: item.title, icon: _categoryIcon(item.title));
        },
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemCount: categories.length + 1,
      ),
    );
  }

  Widget _categoryPill({required String title, required IconData icon, bool active = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: active ? FRColors.darkMain : FRColors.surface,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: active ? FRColors.darkMain : const Color(0x0D211510)),
        boxShadow: [
          BoxShadow(
            color: active ? const Color(0x33211510) : const Color(0x0A211510),
            blurRadius: active ? 20 : 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: active ? FRColors.gold : FRColors.textMuted),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: active ? FRColors.gold : FRColors.textMain,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerSection(BuildContext context, List<BannerModel> banners) {
    if (banners.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: SizedBox(
        height: 160,
        child: PageView.builder(
          controller: _bannerController,
          itemCount: banners.length,
          itemBuilder: (context, index) {
            final banner = banners[index];
            return Padding(
              padding: EdgeInsets.only(right: index == banners.length - 1 ? 0 : 10),
              child: PremiumPressable(
                borderRadius: BorderRadius.circular(24),
                onTap: () {},
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(imageUrl: banner.imageUrl, fit: BoxFit.cover),
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [Color(0xF2211510), Color(0x1A211510)],
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
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: FRColors.gold, borderRadius: BorderRadius.circular(6)),
                              child: const Text('GÜNÜN FIRSATI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              banner.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: FRColors.surface, fontSize: 20, fontWeight: FontWeight.w800, height: 1.2),
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
    );
  }

  Widget _buildInsightGrid(List<ProductModel> trendingProducts) {
    if (trendingProducts.isEmpty) return const SizedBox.shrink();

    final prices = trendingProducts.map((e) => e.lastPrice ?? 0).where((e) => e > 0).toList()..sort();
    final min = prices.isNotEmpty ? prices.first : 0.0;
    final max = prices.length > 1 ? prices.last : min * 1.18;
    final basketAdv = max <= 0 ? 0 : ((max - min) / max * 100).round();
    final biggestDropValue = (max - min).clamp(0, double.infinity);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Bugünün Özeti', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: FRColors.textMain)),
              Text('Tüm Analizler', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: FRColors.gold)),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            // 💥 KUTULAR NEFES ALSIN DİYE ORAN DÜŞÜRÜLDÜ 💥
            childAspectRatio: 1.20, 
            children: [
              _insightCard(
                icon: Icons.savings,
                iconBg: FRColors.successBg,
                iconColor: FRColors.success,
                label: 'SEPET AVANTAJI',
                value: '%$basketAdv',
                meta: 'En uygun kombin trend ürünlerde dinamik hesaplandı.',
              ),
              _insightCard(
                icon: Icons.trending_down,
                iconBg: const Color(0x26C29B78),
                iconColor: FRColors.gold,
                label: 'SERT DÜŞÜŞ',
                value: formatTRY(biggestDropValue <= 0 ? min * 0.15 : biggestDropValue, withDecimals: false),
                meta: 'Trend listesindeki en yüksek fiyat farkı yakalandı.',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _insightCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String value,
    required String meta,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FRColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x0D211510)),
        boxShadow: const [BoxShadow(color: Color(0x0A211510), blurRadius: 15, offset: Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: FRColors.textMuted)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: FRColors.darkMain)),
          const Spacer(),
          Text(meta, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: FRColors.textMuted, height: 1.2)),
        ],
      ),
    );
  }

  Widget _buildTrendProducts(BuildContext context, List<ProductModel> products) {
    if (products.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text('Trend Ürünler', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: FRColors.textMain)),
                    SizedBox(width: 10),
                    _PopularBadge(),
                  ],
                ),
                Text('Tümünü Gör', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: FRColors.gold)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final product = products[index];
                final oldPrice = (product.lastPrice ?? 0) * 1.15;
                final newPrice = product.lastPrice ?? 0;
                final dropPercent = oldPrice <= 0 ? 0 : (((oldPrice - newPrice) / oldPrice) * 100).round();
                
                return PremiumPressable(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: product.id))),
                  child: Container(
                    width: 165,
                    decoration: BoxDecoration(
                      color: FRColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0x0D211510)),
                      boxShadow: const [BoxShadow(color: Color(0x0A211510), blurRadius: 15, offset: Offset(0, 5))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 140,
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(color: FRColors.studio, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // 💥 YAZI KAYMASINI ENGELLEYEN ROZET YAPISI 💥
                              Positioned(
                                left: -10,
                                top: -10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                  decoration: BoxDecoration(color: const Color(0x264CAF50), borderRadius: BorderRadius.circular(6)),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.arrow_downward_rounded, color: FRColors.success, size: 10),
                                      const SizedBox(width: 2),
                                      Text('%$dropPercent', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: FRColors.success)),
                                    ],
                                  ),
                                ),
                              ),
                              Center(
                                child: CachedNetworkImage(
                                  imageUrl: product.effectiveImage ?? '',
                                  fit: BoxFit.contain,
                                  errorWidget: (_, __, ___) => const Icon(Icons.image_not_supported_rounded, color: FRColors.textMuted),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(product.brand.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: FRColors.gold)),
                                const SizedBox(height: 4),
                                Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                                const Spacer(),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(formatTRY(oldPrice), style: const TextStyle(fontSize: 11, decoration: TextDecoration.lineThrough, color: FRColors.textMuted)),
                                          Text(formatTRY(newPrice), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: FRColors.darkMain)),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: FRColors.studio, borderRadius: BorderRadius.circular(6)),
                                      child: Text(product.lastStore ?? 'Market', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
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
              },
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemCount: products.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorChoice(BuildContext context, ProductModel? product) {
    if (product == null) return const SizedBox.shrink();
    final oldPrice = (product.lastPrice ?? 0) * 1.15;
    final newPrice = product.lastPrice ?? 0;
    final discount = (oldPrice - newPrice).abs();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Editörün Seçimi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: FRColors.textMain)),
          const SizedBox(height: 16),
          PremiumPressable(
            borderRadius: BorderRadius.circular(24),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: product.id))),
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                color: FRColors.darkMain,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0x33C29B78)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 6, // 💥 YAZI ALANI BÜYÜTÜLDÜ 💥
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(product.brand.toUpperCase(), style: const TextStyle(fontSize: 10, color: FRColors.gold, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, color: FRColors.surface, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(formatTRY(oldPrice), style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12, decoration: TextDecoration.lineThrough)),
                              const SizedBox(width: 8),
                              Text(formatTRY(newPrice), style: const TextStyle(color: FRColors.surface, fontSize: 22, fontWeight: FontWeight.w900, height: 1)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4, // 💥 RESİM ALANI KÜÇÜLTÜLDÜ 💥
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        border: Border(left: BorderSide(color: Colors.white.withOpacity(0.05))),
                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(24)),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // 💥 ROZET KESİLMESİN DİYE İÇERİ ALINDI 💥
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: FRColors.danger, borderRadius: BorderRadius.circular(8)),
                              child: Text('-${formatTRY(discount, withDecimals: false)}', style: const TextStyle(color: FRColors.surface, fontSize: 11, fontWeight: FontWeight.w900)),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Center(
                              child: CachedNetworkImage(
                                imageUrl: product.effectiveImage ?? '',
                                fit: BoxFit.contain,
                                errorWidget: (_, __, ___) => const Icon(Icons.image_not_supported_rounded, color: FRColors.textMuted),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLatestPrices(List<PriceModel> prices) {
    if (prices.isEmpty) return const SizedBox.shrink();
    final rows = prices.take(5).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Son Eklenen Fiyatlar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: FRColors.textMain)),
              Text('Tümünü Gör', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: FRColors.gold)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: FRColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0x0D211510)),
              boxShadow: const [BoxShadow(color: Color(0x0A211510), blurRadius: 15, offset: Offset(0, 5))],
            ),
            child: Column(
              children: [
                for (int i = 0; i < rows.length; i++)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      border: i == rows.length - 1 ? null : const Border(bottom: BorderSide(color: Color(0x0D211510))),
                    ),
                    child: _latestPriceRow(rows[i]),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _latestPriceRow(PriceModel item) {
    final delta = item.upVotes - item.downVotes;
    final isDrop = delta >= 0;
    final bgColor = delta == 0 ? FRColors.studio : (isDrop ? FRColors.successBg : FRColors.dangerBg);
    final fgColor = delta == 0 ? FRColors.textMuted : (isDrop ? FRColors.success : FRColors.danger);

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
          child: Icon(
            delta == 0 ? Icons.drag_handle_rounded : (isDrop ? Icons.trending_down_rounded : Icons.trending_up_rounded),
            color: fgColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.productName ?? 'Ürün', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text('${item.storeName ?? 'Mağaza'} • ${item.userName ?? item.reporterName ?? 'Sistem'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: FRColors.textMuted, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(formatTRY(item.price), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: FRColors.darkMain)),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (delta != 0)
                  Icon(isDrop ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, size: 12, color: fgColor),
                Text(
                  delta == 0 ? 'Sabit' : (isDrop ? 'Düştü' : 'Zamlandı'),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: fgColor),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLeaders(List<UserModel> users) {
    if (users.isEmpty) return const SizedBox.shrink();
    final top2 = [...users]..sort((a, b) => b.points.compareTo(a.points));
    final leaders = top2.take(2).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Öne Çıkan Avcılar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: FRColors.textMain)),
              Text('Liderlik', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: FRColors.gold)),
            ],
          ),
          const SizedBox(height: 16),
          ...leaders.asMap().entries.map((entry) {
            final rank = entry.key + 1;
            final u = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: FRColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0x0D211510)),
                boxShadow: const [BoxShadow(color: Color(0x0A211510), blurRadius: 15, offset: Offset(0, 5))],
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: rank == 1
                          ? const LinearGradient(colors: [FRColors.gold, Color(0xFFA67C52)])
                          : const LinearGradient(colors: [Color(0xFFB0BEC5), Color(0xFF78909C)]),
                    ),
                    alignment: Alignment.center,
                    child: Text(_initials(u.name), style: const TextStyle(color: FRColors.surface, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(u.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text('Bu hafta ${u.priceEntries} doğrulanmış fiyat', style: const TextStyle(fontSize: 11, color: FRColors.textMuted)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: FRColors.studio, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('%${u.trustScorePercent}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: FRColors.darkMain)),
                        const Text('GÜVEN', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: FRColors.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    // 💥 FAB BUTONU ALTINDA EZİLMESİN DİYE PADDING 160 YAPILDI 💥
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 160),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: FRColors.darkMain,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0x33C29B78)),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Fiyat Ekle Puan Kazan!', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: FRColors.surface)),
                      SizedBox(height: 4),
                      Text('Topluluğa katıl ve radarın gücünü artır.', style: TextStyle(fontSize: 11, color: Color(0x99FFFFFF))),
                    ],
                  ),
                ),
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(color: FRColors.gold, borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.qr_code_scanner_rounded, color: FRColors.darkMain),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Opacity(
            opacity: 0.6,
            child: Column(
              children: const [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Color(0x14211510),
                  child: Icon(Icons.radar_rounded, color: FRColors.textMain, size: 18),
                ),
                SizedBox(height: 8),
                Text('FiyatRadar', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: FRColors.textMain)),
                SizedBox(height: 4),
                Text('V3.0 Porsche Edition', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: FRColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _categoryIcon(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('market') || lower.contains('gıda')) return Icons.shopping_cart_rounded;
    if (lower.contains('tekno') || lower.contains('elektronik')) return Icons.laptop_mac_rounded;
    if (lower.contains('kozmetik') || lower.contains('bakım')) return Icons.face_retouching_natural_rounded;
    if (lower.contains('hobi') || lower.contains('spor')) return Icons.sports_esports_rounded;
    return Icons.category_rounded;
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'FR';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }
}

class _PopularBadge extends StatelessWidget {
  const _PopularBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: const Color(0x26C29B78), borderRadius: BorderRadius.circular(6)),
      child: const Row(
        children: [
          Icon(Icons.local_fire_department_rounded, size: 12, color: FRColors.gold),
          SizedBox(width: 4),
          Text('POPÜLER', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: FRColors.gold)),
        ],
      ),
    );
  }
}
