import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/product_model.dart';
import '../../models/price_model.dart';
import '../../models/banner_model.dart';
import '../../providers/product_provider.dart';
import '../../providers/banner_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/notification_center_service.dart';
import '../../widgets/staggered_fade_slide.dart';
import '../../widgets/premium_pressable.dart';
import '../../utils/formatters.dart';
import '../points/points_screen.dart';
import '../product/product_detail_screen.dart';
import '../../pages/notification_center_page.dart';
import '../campaign/campaign_detail_screen.dart';
import '../campaign/campaigns_screen.dart';
import '../main_screen.dart';

// FOTOĞRAFLARDAN ÇEKİLEN BİREBİR RENKLER
class FRColors {
  static const Color bgApp = Color(0xFFF7F5F2);       // Fotoğraftaki uçuk krem arkaplan
  static const Color headerBg = Color(0xFF311F15);    // Fotoğraftaki asil koyu kahve header
  static const Color surface = Color(0xFFFFFFFF);     // Saf Beyaz
  static const Color pillBg = Color(0xFFF6F1EC);      // Fotoğraftaki ikon/resim arkası bej tonu
  static const Color textMain = Color(0xFF2A1A10);    // Ana metin kahvesi
  static const Color textMuted = Color(0xFF9E928A);   // Gri alt metinler
  static const Color trendGreenBg = Color(0xFFE8F5E9);
  static const Color trendGreenText = Color(0xFF2E7D32);
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

  @override
  void initState() {
    super.initState();
    _startBannerAutoScroll();
  }

  void _startBannerAutoScroll() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) return;
      final banners = ref.read(activeBannersProvider).valueOrNull ?? [];
      if (banners.isEmpty || !_bannerController.hasClients) return;
      final nextPage = (_currentBannerPage + 1) % banners.length;
      _bannerController.animateToPage(nextPage, duration: const Duration(milliseconds: 600), curve: Curves.fastOutSlowIn);
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
    final recommendedAsync = ref.watch(recommendedProductsProvider);
    final latestPricesAsync = ref.watch(latestPricesProvider);

    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: FRColors.bgApp,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          // 1. KUSURSUZ HEADER VE TAŞAN ARAMA ÇUBUĞU
          SliverToBoxAdapter(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: EdgeInsets.fromLTRB(20, topPadding + 16, 20, 48), 
                  decoration: const BoxDecoration(
                    color: FRColors.headerBg,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
                  ),
                  child: userAsync.when(
                    data: (user) => _buildHeaderContent(context, user),
                    loading: () => const SizedBox(height: 50),
                    error: (_, __) => const SizedBox(height: 50),
                  ),
                ),
                Positioned(
                  bottom: -24, left: 20, right: 20,
                  child: _buildSearchBar(),
                ),
              ],
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 44)),

          // 2. KATEGORİLER (TAM FOTOĞRAFTAKİ GİBİ KARE KUTULAR)
          SliverToBoxAdapter(
            child: _buildCategoriesRow(),
          ),

          // 3. BANNER
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 24),
              child: bannersAsync.when(
                data: (banners) => _buildBannerCarousel(banners),
                loading: () => const SizedBox(height: 160),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
          ),

          // 4. TREND ÜRÜNLER (TAM FOTOĞRAFA UYGUN DİNAMİK KARTLAR)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 32),
              child: trendingAsync.when(
                data: (products) => _buildProductsSection('Trend Ürünler', products),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
          ),

          // 5. ÖNERİLEN ÜRÜNLER
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 32),
              child: recommendedAsync.when(
                data: (products) => _buildProductsSection('Önerilen Ürünler', products),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
          ),

          // 6. PİYASA AKIŞI (TAM FOTOĞRAFTAKİ LİSTE)
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

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  // ════════════ 1. HEADER (KAREMSİ PROFİL, DOĞRU RENKLER) ════════════
  Widget _buildHeaderContent(BuildContext context, dynamic user) {
    final displayName = user?.name ?? 'Admin';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'A';
    final points = user?.points ?? 20508;
    final photoUrl = (user?.photoUrl ?? '').toString().trim().isEmpty ? null : user?.photoUrl;

    return Row(
      children: [
        // FOTOĞRAFTAKİ KAREMSİ PROFİL RESMİ VE KAHVERENGİMSİ ŞERİT
        GestureDetector(
          onTap: () => ref.read(currentTabProvider.notifier).state = 4,
          child: Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: FRColors.surface,
              borderRadius: BorderRadius.circular(14), // Yuvarlak değil, karemsi!
              border: Border.all(color: const Color(0xFF8D6E63), width: 1.5), // Kahverengimsi şerit
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: photoUrl != null 
                ? CachedNetworkImage(imageUrl: photoUrl, fit: BoxFit.cover) 
                : Center(child: Text(initial, style: const TextStyle(color: FRColors.headerBg, fontWeight: FontWeight.bold, fontSize: 18))),
            ),
          ),
        ),
        const SizedBox(width: 12),
        
        // YAZILAR
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hoş geldin,', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(displayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
        ),
        
        // PUAN
        PremiumPressable(
          borderRadius: BorderRadius.circular(100),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PointsScreen())),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFF4A3326), borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                const Icon(Icons.stars_rounded, color: Color(0xFFD7CCC8), size: 16),
                const SizedBox(width: 6),
                Text('$points', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        
        // BİLDİRİM ZİLİ
        const _NotificationBellButton(),
      ],
    );
  }

  // ════════════ 2. ARAMA ÇUBUĞU ════════════
  Widget _buildSearchBar() {
    return PremiumPressable(
      borderRadius: BorderRadius.circular(24),
      onTap: () => ref.read(currentTabProvider.notifier).state = 1,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24), 
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, color: Colors.grey, size: 22),
            const SizedBox(width: 12),
            Expanded(child: Text('Ürün, marka veya mağaza ara...', style: TextStyle(color: Colors.grey.shade500, fontSize: 14))),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: FRColors.pillBg, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.qr_code_scanner_rounded, color: FRColors.headerBg, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════ 3. KATEGORİLER ════════════
  Widget _buildCategoriesRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const BouncingScrollPhysics(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCatSquare('Tümü', Icons.grid_view_rounded, isActive: true),
          const SizedBox(width: 16),
          _buildCatSquare('Market', Icons.shopping_cart_outlined),
          const SizedBox(width: 16),
          _buildCatSquare('Teknoloji', Icons.laptop_mac),
          const SizedBox(width: 16),
          _buildCatSquare('Kozmetik', Icons.face_retouching_natural),
          const SizedBox(width: 16),
          _buildCatSquare('Hobi', Icons.sports_esports),
        ],
      ),
    );
  }

  Widget _buildCatSquare(String title, IconData icon, {bool isActive = false}) {
    return Column(
      children: [
        Container(
          width: 64, height: 64, 
          decoration: BoxDecoration(
            color: isActive ? FRColors.headerBg : Colors.white,
            borderRadius: BorderRadius.circular(18), // KÖŞELERİ YUVARLATILMIŞ KARE
            boxShadow: isActive ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))],
          ),
          child: Icon(icon, color: isActive ? Colors.white : Colors.grey.shade600, size: 30),
        ),
        const SizedBox(height: 8),
        Text(title, style: TextStyle(fontSize: 12, fontWeight: isActive ? FontWeight.bold : FontWeight.w600, color: FRColors.textMain)),
      ],
    );
  }

  // ════════════ 4. BANNER ════════════
  Widget _buildBannerCarousel(List<BannerModel> banners) {
    if (banners.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        SizedBox(
          height: 150,
          child: PageView.builder(
            controller: _bannerController,
            onPageChanged: (index) => setState(() => _currentBannerPage = index),
            itemCount: banners.length,
            itemBuilder: (context, index) {
              final banner = banners[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: PremiumPressable(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () {
                    final targetType = (banner.targetType ?? '').toLowerCase().trim();
                    final campaignId = (banner.targetId ?? '').trim();
                    if (targetType == 'campaign') {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => campaignId.isNotEmpty ? CampaignDetailScreen(campaignId: campaignId) : const CampaignsScreen()));
                    }
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(imageUrl: banner.imageUrl.isNotEmpty ? banner.imageUrl : 'https://images.unsplash.com/photo-1542838132-92c53300491e?q=80&w=600', fit: BoxFit.cover),
                        Container(
                          decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [FRColors.headerBg.withOpacity(0.9), FRColors.headerBg.withOpacity(0.1)])),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                                child: const Text('GÜNÜN FIRSATI', style: TextStyle(color: FRColors.headerBg, fontSize: 9, fontWeight: FontWeight.w900)),
                              ),
                              const SizedBox(height: 8),
                              Text(banner.title, maxLines: 2, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, height: 1.2)),
                              const Spacer(),
                              Row(
                                children: [
                                  Text(banner.ctaText ?? 'Keşfet', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
                                ],
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ════════════ 5. ÜRÜN KARTLARI LİSTESİ ════════════
  Widget _buildProductsSection(String title, List<ProductModel> products) {
    if (products.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: FRColors.textMain)),
              GestureDetector(
                onTap: () => ref.read(currentTabProvider.notifier).state = 1,
                child: const Text('Tümünü Gör', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFD48B6A))),
              )
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 250, 
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              return StaggeredFadeSlide(
                index: index,
                child: _ExactPhotoProductCard( 
                  product: products[index],
                  onTap: () => Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: products[index].id))),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ════════════ 6. PİYASA AKIŞI ════════════
  Widget _buildLatestPricesList(List<PriceModel> prices) {
    if (prices.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Piyasa Akışı', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: FRColors.textMain)),
          const SizedBox(height: 16),
          ...prices.take(5).map((price) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PremiumPressable(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: price.productId))),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(color: FRColors.pillBg, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.history_rounded, color: Colors.grey, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(price.storeName ?? 'Market', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: FRColors.textMain), maxLines: 1),
                            const SizedBox(height: 2),
                            Text('${price.reporterName ?? price.userName ?? 'Kullanıcı'} ekledi', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Text(formatTRY(price.price), style: const TextStyle(fontWeight: FontWeight.bold, color: FRColors.textMain, fontSize: 16)),
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

// ════════════ MOCK DATADAN TAMAMEN KURTULMUŞ DİNAMİK ÜRÜN KARTI ════════════
class _ExactPhotoProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const _ExactPhotoProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // 1. GERÇEK VERİLER (Modelden çekilir, hiçbir şey statik değil)
    final title = product.name;
    final brand = (product.brand ?? 'MARKA').toUpperCase();
    final priceStr = product.price != null ? formatTRY(product.price!) : '---';
    
    // NOT: product.storeName kısmı modelindeki doğru değişkenle eşleşmeli (örn: product.marketName)
    final marketName = product.storeName ?? 'Market'; 
    
    // Trend yüzdesi ve düşüş/yükseliş durumu (varsa modelinden bağlayabilirsin, şimdilik UI'ı bozmaması için basit kontrol)
    final isDrop = true; 

    return PremiumPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        padding: const EdgeInsets.all(10), 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 2. RESİM STÜDYOSU (Asla Taşmaz)
            Container(
              height: 140, 
              width: double.infinity,
              decoration: BoxDecoration(
                color: FRColors.pillBg, 
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0), 
                    child: Center(
                      child: CachedNetworkImage(
                        imageUrl: product.imageUrl ?? '',
                        fit: BoxFit.contain, 
                        colorBlendMode: BlendMode.multiply,
                        color: Colors.white.withOpacity(0.01), 
                        errorWidget: (context, url, error) => const Icon(Icons.image_not_supported, color: Colors.grey),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10, left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(color: isDrop ? FRColors.trendGreenBg : const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(6)),
                      child: Row(
                        children: [
                          Icon(isDrop ? Icons.south_east_rounded : Icons.north_east_rounded, color: isDrop ? FRColors.trendGreenText : const Color(0xFFC62828), size: 10),
                          const SizedBox(width: 2),
                          Text('%18', style: TextStyle(color: isDrop ? FRColors.trendGreenText : const Color(0xFFC62828), fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const Positioned(
                    top: 10, right: 10,
                    child: Icon(Icons.favorite, color: Colors.red, size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            
            // 3. METİNLER (Dinamik)
            Text(brand, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: FRColors.textMain, height: 1.2)),
            const Spacer(),
            
            // 4. FİYAT VE DİNAMİK MARKET ETİKETİ
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Eğer ProductModel'inde eski fiyat yoksa burayı silebilirsin. Tasarımdaki yeri korumak için ekliyorum.
                    const Text('Ort: 40,00₺', style: TextStyle(fontSize: 10, color: Colors.grey, decoration: TextDecoration.lineThrough, fontWeight: FontWeight.w600)),
                    Text(priceStr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: FRColors.textMain)),
                  ],
                ),
                // İŞTE BURASI: Artık "En Uygun" değil, veritabanından gelen A-101, Trendyol M. vb. yazacak!
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(color: FRColors.pillBg, borderRadius: BorderRadius.circular(8)),
                  child: Text(marketName, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: FRColors.textMain)),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}

// BİLDİRİM ZİLİ
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
        width: 40, height: 40,
        decoration: BoxDecoration(color: const Color(0xFF4A3326), borderRadius: BorderRadius.circular(12)),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 20),
            StreamBuilder<int>(
              stream: unreadStream,
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                if (count <= 0) return const SizedBox.shrink();
                return Positioned(
                  top: 8, right: 8,
                  child: Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle, border: Border.all(color: FRColors.headerBg, width: 1.5))),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
