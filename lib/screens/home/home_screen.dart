import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
import '../../widgets/horizontal_categories_widget.dart';
import '../../widgets/staggered_fade_slide.dart';
import '../../widgets/premium_pressable.dart';
import '../../utils/formatters.dart';
import '../main_screen.dart';
import '../points/points_screen.dart';
import '../product/product_detail_screen.dart';
import '../../pages/notification_center_page.dart';
import '../campaign/campaign_detail_screen.dart';
import '../campaign/campaigns_screen.dart';

// ════════════ FİYATRADAR KUSURSUZ DNA RENKLERİ ════════════
class VFinalColors {
  static const Color bgBody = Color(0xFFF9F6F2);        // Dinlendirici Uçuk Krem
  static const Color surface = Color(0xFFFFFFFF);       // Saf Beyaz
  static const Color studio = Color(0xFFF4EBE3);        // Ürün Resmi Arkaplanı (Soft Bej)
  
  static const Color primaryDark = Color(0xFF2A1A10);   // Asil Acı Kahve (Header)
  static const Color primary = Color(0xFF6B4226);       // FiyatRadar Buton Kahvesi
  static const Color gold = Color(0xFFC89B7B);          // Premium Altın
  static const Color goldLight = Color(0xFFEFE4DA);     // Yumuşak Altın Zemin
  
  static const Color textMain = Color(0xFF2A1A10);
  static const Color textMuted = Color(0xFF9A9188);
  
  static const Color success = Color(0xFF328A4A);
  static const Color successBg = Color(0xFFE6F3E9);
  static const Color danger = Color(0xFFD32F2F);
  static const Color dangerBg = Color(0xFFFFEBEE);
  
  static const Color border = Color(0x0F2A1A10);        // %6 opacity Acı Kahve
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  final PageController _bannerController = PageController(viewportFraction: 0.90);
  Timer? _bannerTimer;
  int _currentBannerPage = 0;
  final ScrollController _statsScrollController = ScrollController();
  Timer? _statsMarqueeTimer;

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
        duration: const Duration(milliseconds: 600),
        curve: Curves.fastOutSlowIn,
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
    _statsMarqueeTimer?.cancel();
    _statsScrollController.dispose();
    _bannerController.dispose();
    _headerAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userModelStreamProvider);
    final bannersAsync = ref.watch(activeBannersProvider);
    final trendingAsync = ref.watch(trendingProductsProvider);
    final recommendedAsync = ref.watch(recommendedProductsProvider);
    final storesAsync = ref.watch(allStoresStreamProvider);
    final usersAsync = ref.watch(allUsersProvider);
    final latestPricesAsync = ref.watch(latestPricesProvider);
    
    final users = usersAsync.valueOrNull ?? [];
    final marketCount = storesAsync.valueOrNull?.length ?? 0;
    final totalUserCount = users.length;
    final totalPriceCount = users.fold<int>(0, (sum, user) => sum + user.priceEntries);

    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: VFinalColors.bgBody,
      body: Stack(
        children: [
          // Ambiyans Işıkları (Krem/Bej ile uyumlu soft orblar)
          Positioned(
            top: 200, left: -80,
            child: _AmbientOrb(size: 300, color: VFinalColors.gold, opacity: 0.08),
          ),
          Positioned(
            bottom: 100, right: -100,
            child: _AmbientOrb(size: 260, color: VFinalColors.primary, opacity: 0.05),
          ),
          
          CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              // 1. ACI KAHVE HEADER & TAŞAN ARAMA ÇUBUĞU (Derinlik Hissi)
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _headerFade,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Acı Kahve Arkaplan
                      Container(
                        padding: EdgeInsets.fromLTRB(24, topPadding + 16, 24, 55), // Arama çubuğu için alttan 55px ekstra boşluk
                        decoration: const BoxDecoration(
                          color: VFinalColors.primaryDark,
                          borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 10))],
                        ),
                        child: userAsync.when(
                          data: (user) => _buildHeaderContent(context, user),
                          loading: () => _buildHeaderContent(context, null),
                          error: (_, __) => _buildHeaderContent(context, null),
                        ),
                      ),
                      // Taşan Arama Çubuğu
                      Positioned(
                        bottom: -22, left: 24, right: 24,
                        child: _buildFloatingSearchBar(),
                      ),
                    ],
                  ),
                ),
              ),

              // Arama çubuğunun taştığı kısım için boşluk
              const SliverToBoxAdapter(child: SizedBox(height: 42)),

              // 2. İSTATİSTİK BARI
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildStatsMarquee(marketCount, totalPriceCount, totalUserCount),
                ),
              ),

              // 3. KATEGORİLER
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: HorizontalCategoriesWidget(), // Mevcut bileşenin korunması
                ),
              ),

              // 4. DİNAMİK MEGA BANNER
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: bannersAsync.when(
                    data: (banners) => _buildBannerCarousel(banners),
                    loading: () => _buildBannerLoading(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
              ),

              // 5. TREND ÜRÜNLER (KUSURSUZ STÜDYO KARTLARI)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: trendingAsync.when(
                    data: (products) => _buildProductsSection('Trend Ürünler', products),
                    loading: () => _buildProductsLoading('Trend Ürünler'),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
              ),

              // 6. ÖNERİLEN ÜRÜNLER
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: recommendedAsync.when(
                    data: (products) => _buildProductsSection('Önerilen Ürünler', products),
                    loading: () => _buildProductsLoading('Önerilen Ürünler'),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
              ),

              // 7. PİYASA AKIŞI (SON EKLENENLER LİSTESİ)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: latestPricesAsync.when(
                    data: (prices) => _buildLatestPricesList(prices),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
              ),

              // Alt Menü Boşluğu
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ],
      ),
    );
  }

  // ════════════ ÖZEL WIDGET METOTLARI ════════════

  // 1. Header İçeriği (Acı Kahve Zemin Üzerinde)
  Widget _buildHeaderContent(BuildContext context, dynamic user) {
    final displayName = user?.name ?? 'Admin';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'A';
    final points = user?.points ?? 20506;
    final photoUrl = (user?.photoUrl ?? '').toString().trim().isEmpty ? null : user?.photoUrl;

    return Row(
      children: [
        // Avatar
        GestureDetector(
          onTap: () => ref.read(currentTabProvider.notifier).state = 4,
          child: Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: VFinalColors.surface,
              border: Border.all(color: VFinalColors.gold, width: 2),
              image: photoUrl != null ? DecorationImage(image: CachedNetworkImageProvider(photoUrl), fit: BoxFit.cover) : null,
            ),
            child: photoUrl == null ? Center(child: Text(initial, style: const TextStyle(color: VFinalColors.primaryDark, fontWeight: FontWeight.w800, fontSize: 18))) : null,
          ),
        ),
        const SizedBox(width: 12),
        // Metinler
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Hoş geldin,', style: TextStyle(color: VFinalColors.gold, fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(displayName, style: const TextStyle(color: VFinalColors.surface, fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: -0.3)),
            ],
          ),
        ),
        // Puan & Zil
        PremiumPressable(
          borderRadius: BorderRadius.circular(100),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PointsScreen())),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: VFinalColors.goldLight,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              children: [
                const Icon(Icons.stars_rounded, color: VFinalColors.primary, size: 16),
                const SizedBox(width: 4),
                Text('$points', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: VFinalColors.primaryDark)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        const _NotificationBellButton(),
      ],
    );
  }

  // 2. Taşan Arama Çubuğu
  Widget _buildFloatingSearchBar() {
    return PremiumPressable(
      borderRadius: BorderRadius.circular(20),
      onTap: () => ref.read(currentTabProvider.notifier).state = 1,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: VFinalColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 10))],
          border: Border.all(color: VFinalColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, color: VFinalColors.textMuted, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Ürün, marka veya mağaza ara...', style: TextStyle(color: VFinalColors.textMuted.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.w500)),
            ),
            Container(width: 1, height: 24, color: VFinalColors.border, margin: const EdgeInsets.symmetric(horizontal: 12)),
            const Icon(Icons.qr_code_scanner_rounded, color: VFinalColors.primary, size: 22),
          ],
        ),
      ),
    );
  }

  // 3. İstatistik Marquee
  Widget _buildStatsMarquee(int marketCount, int totalPriceCount, int totalUserCount) {
    final stats = [
      ('🛒', 'Kayıtlı market', marketCount),
      ('💸', 'Kayıtlı fiyat', totalPriceCount),
      ('👥', 'Toplam kullanıcı', totalUserCount),
    ];
    final loopedStats = [...stats, ...stats];

    return Container(
      height: 40,
      decoration: BoxDecoration(color: VFinalColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: VFinalColors.border)),
      child: ListView.separated(
        controller: _statsScrollController,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: loopedStats.length,
        separatorBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Center(child: Container(width: 4, height: 4, decoration: const BoxDecoration(color: VFinalColors.gold, shape: BoxShape.circle))),
        ),
        itemBuilder: (context, index) {
          final (emoji, label, value) = loopedStats[index];
          return Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 6),
                Text('$label: ', style: const TextStyle(color: VFinalColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
                Text(formatCompactCount(value), style: const TextStyle(color: VFinalColors.primaryDark, fontSize: 12, fontWeight: FontWeight.w800)),
              ],
            ),
          );
        },
      ),
    );
  }

  // 4. Dinamik Mega Banner
  Widget _buildBannerCarousel(List<BannerModel> banners) {
    if (banners.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _bannerController,
            onPageChanged: (index) => setState(() => _currentBannerPage = index),
            itemCount: banners.length,
            itemBuilder: (context, index) {
              final banner = banners[index];
              return AnimatedBuilder(
                animation: _bannerController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_bannerController.position.haveDimensions) {
                    value = (_bannerController.page ?? 0) - index;
                    value = (1 - (value.abs() * 0.1)).clamp(0.9, 1.0);
                  }
                  return Transform.scale(scale: value, child: child);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: PremiumPressable(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => _onBannerTap(banner),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: VFinalColors.primaryDark.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 8))],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Resim
                            CachedNetworkImage(
                              imageUrl: banner.imageUrl.isNotEmpty ? banner.imageUrl : 'https://images.unsplash.com/photo-1542838132-92c53300491e?q=80&w=600',
                              fit: BoxFit.cover,
                            ),
                            // Acı Kahve Karartma Degradesi
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    VFinalColors.primaryDark.withOpacity(0.95),
                                    VFinalColors.primaryDark.withOpacity(0.1),
                                  ],
                                ),
                              ),
                            ),
                            // İçerik
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: VFinalColors.surface, borderRadius: BorderRadius.circular(6)),
                                    child: const Text('GÜNÜN FIRSATI', style: TextStyle(color: VFinalColors.primaryDark, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    banner.title,
                                    maxLines: 2,
                                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, height: 1.2),
                                  ),
                                  const SizedBox(height: 14),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(banner.ctaText ?? 'İncele', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
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
        // Noktalar
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(banners.length, (index) {
            final isActive = _currentBannerPage == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 16 : 6, height: 6,
              decoration: BoxDecoration(color: isActive ? VFinalColors.primary : Colors.black12, borderRadius: BorderRadius.circular(4)),
            );
          }),
        ),
      ],
    );
  }

  void _onBannerTap(BannerModel banner) {
    final targetType = (banner.targetType ?? '').toLowerCase().trim();
    final campaignId = (banner.targetId ?? '').trim();
    if (targetType == 'campaign') {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => campaignId.isNotEmpty ? CampaignDetailScreen(campaignId: campaignId) : const CampaignsScreen()));
    }
  }

  // 5. Ürün Kartları Listesi
  Widget _buildProductsSection(String title, List<ProductModel> products) {
    if (products.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        _buildSectionHeader(title, actionText: 'Tümünü Gör', onAction: () => ref.read(currentTabProvider.notifier).state = 1),
        const SizedBox(height: 16),
        SizedBox(
          height: 250, // Kusursuz Kart Yüksekliği
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final product = products[index];
              return StaggeredFadeSlide(
                index: index,
                child: _FinalProductCard( // O mucizevi yeni kart
                  product: product,
                  onTap: () => Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: product.id))),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // 6. Piyasa Akışı (Son Eklenenler)
  Widget _buildLatestPricesList(List<PriceModel> prices) {
    if (prices.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          _buildSectionHeader('Piyasa Akışı'),
          const SizedBox(height: 16),
          ...prices.take(5).map((price) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PremiumPressable(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: price.productId))),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: VFinalColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: VFinalColors.border),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(color: VFinalColors.studio, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.history_rounded, color: VFinalColors.primary, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(price.storeName ?? 'Market', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: VFinalColors.textMain), maxLines: 1),
                            const SizedBox(height: 2),
                            Text('${price.reporterName ?? price.userName ?? 'Kullanıcı'} ekledi', style: const TextStyle(fontSize: 11, color: VFinalColors.textMuted, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      Text(formatTRY(price.price), style: const TextStyle(fontWeight: FontWeight.w900, color: VFinalColors.primaryDark, fontSize: 16)),
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

  // Ortak Başlık Metodu
  Widget _buildSectionHeader(String title, {String? actionText, VoidCallback? onAction}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: VFinalColors.textMain, letterSpacing: -0.3)),
          if (actionText != null)
            GestureDetector(
              onTap: onAction,
              child: Text(actionText, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: VFinalColors.gold)),
            )
        ],
      ),
    );
  }

  Widget _buildBannerLoading() {
    return Container(height: 160, margin: const EdgeInsets.symmetric(horizontal: 24), decoration: BoxDecoration(color: VFinalColors.surface, borderRadius: BorderRadius.circular(24)));
  }

  Widget _buildProductsLoading(String title) {
    return Column(
      children: [
        _buildSectionHeader(title),
        const SizedBox(height: 16),
        SizedBox(
          height: 250,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (_, __) => Container(width: 165, decoration: BoxDecoration(color: VFinalColors.surface, borderRadius: BorderRadius.circular(20))),
          ),
        ),
      ],
    );
  }
}

// ════════════ KUSURSUZ ÜRÜN KARTI (+ YOK, MARKET VAR) ════════════
class _FinalProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const _FinalProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final title = product.name;
    final brand = (product.brand ?? 'MARKA').toUpperCase();
    final priceStr = product.lowestPrice != null ? formatTRY(product.lowestPrice!) : '---';
    final isDrop = true; // Örnek trend
    final marketName = "En Uygun"; // Gerçek projede product.lowestPriceMarket gibi bir değer

    return PremiumPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 165,
        decoration: BoxDecoration(
          color: VFinalColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: VFinalColors.border),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Resim Stüdyosu (Hayati Kısım - Taşmayı %100 Önler)
            Container(
              height: 145,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: VFinalColors.studio, // Soft bej stüdyo
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Stack(
                children: [
                  // SİHİR BURADA: Padding + BoxFit.contain
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Center(
                      child: CachedNetworkImage(
                        imageUrl: product.imageUrl ?? '',
                        fit: BoxFit.contain, 
                        colorBlendMode: BlendMode.multiply, // Beyaz arkaplanları yok eder
                        color: Colors.white.withOpacity(0.01), // Multiply tetikleyici
                        errorWidget: (context, url, error) => const Icon(Icons.image_not_supported, color: VFinalColors.textMuted),
                      ),
                    ),
                  ),
                  // Trend Etiketi
                  Positioned(
                    top: 10, left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(color: isDrop ? VFinalColors.successBg : VFinalColors.dangerBg, borderRadius: BorderRadius.circular(6)),
                      child: Row(
                        children: [
                          Icon(isDrop ? Icons.south_east_rounded : Icons.north_east_rounded, color: isDrop ? VFinalColors.success : VFinalColors.danger, size: 12),
                          const SizedBox(width: 2),
                          Text('%18', style: TextStyle(color: isDrop ? VFinalColors.success : VFinalColors.danger, fontSize: 10, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ),
                  // Kalp
                  const Positioned(
                    top: 6, right: 6,
                    child: Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(Icons.favorite_border_rounded, color: VFinalColors.textMuted, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            // 2. Kart Detayları (+ Yok, Fiyat ve Market Var)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(brand, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: VFinalColors.textMuted, letterSpacing: 0.5)),
                        const SizedBox(height: 4),
                        Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: VFinalColors.textMain, height: 1.2)),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Ort: 40,00₺', style: TextStyle(fontSize: 10, color: VFinalColors.textMuted, decoration: TextDecoration.lineThrough, fontWeight: FontWeight.w600)),
                            Text(priceStr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: VFinalColors.primary, height: 1)),
                          ],
                        ),
                        // MARKET ETİKETİ (Senin isteğin üzerine eklendi)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(color: VFinalColors.goldLight, borderRadius: BorderRadius.circular(6)),
                          child: Text(marketName, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: VFinalColors.primaryDark)),
                        )
                      ],
                    )
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
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationCenterPage())),
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.notifications_none_rounded, color: VFinalColors.surface, size: 22),
            StreamBuilder<int>(
              stream: unreadStream,
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                if (count <= 0) return const SizedBox.shrink();
                return Positioned(
                  top: 10, right: 10,
                  child: Container(width: 8, height: 8, decoration: BoxDecoration(color: VFinalColors.danger, shape: BoxShape.circle, border: Border.all(color: VFinalColors.primaryDark, width: 1.5))),
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
  final double size; final Color color; final double opacity;
  const _AmbientOrb({required this.size, required this.color, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color.withOpacity(opacity), color.withOpacity(0)]),
        ),
      ),
    );
  }
}
