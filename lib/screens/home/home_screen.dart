import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/product_model.dart';
import '../../models/price_model.dart';
import '../../models/banner_model.dart';
import '../../models/category_model.dart'; // Kategori modeli eklendi
import '../../providers/product_provider.dart';
import '../../providers/banner_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
// Kategori provider'ının adını kendi projene göre güncelle (Örn: categoriesProvider veya allCategoriesProvider)
import '../../providers/category_provider.dart'; 
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

// ════════════ PORSCHE RENKLERİ ════════════
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
    // Tüm veriler Firebase/Riverpod üzerinden çekiliyor
    final userAsync = ref.watch(userModelStreamProvider);
    final bannersAsync = ref.watch(activeBannersProvider);
    final trendingAsync = ref.watch(trendingProductsProvider);
    final recommendedAsync = ref.watch(recommendedProductsProvider);
    final latestPricesAsync = ref.watch(latestPricesProvider);
    
    // Kategori Provider'ı (Eğer projenizdeki isim farklıysa burayı düzeltin)
    // Örn: ref.watch(allCategoriesStreamProvider)
    final categoriesAsync = ref.watch(categoriesProvider); 

    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: FRColors.bgApp,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          // 1. HEADER & ARAMA ÇUBUĞU (Aktif Yönlendirmeler Eklendi)
          SliverToBoxAdapter(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: EdgeInsets.fromLTRB(20, topPadding + 16, 20, 48), 
                  decoration: const BoxDecoration(
                    color: FRColors.darkMain,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
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

          const SliverToBoxAdapter(child: SizedBox(height: 48)),

          // 2. DİNAMİK KATEGORİLER
          SliverToBoxAdapter(
            child: categoriesAsync.when(
              data: (categories) => _buildDynamicCategories(categories),
              loading: () => const SizedBox(height: 80),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),

          // 3. DİNAMİK MEGA BANNER
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

          // 4. RADAR ANALİZ KARTI
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 32),
              child: recommendedAsync.when(
                data: (products) => products.isNotEmpty ? _buildAnalysisCard(products.first) : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
          ),

          // 5. SERT DÜŞÜŞLER (NEFES ALAN KARTLAR - BOĞULMA GİDERİLDİ)
          SliverToBoxAdapter(
            child: trendingAsync.when(
              data: (products) => _buildDarkSection('Sert Düşüşler', products),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),

          // 6. SON TARAMALAR (MAKSİMUM 5 ADET SINIRI)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 0),
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

  // ════════════ 1. HEADER BİLEŞENLERİ (Tıklamalar Aktif) ════════════
  Widget _buildHeaderContent(BuildContext context, dynamic user) {
    final displayName = user?.name ?? 'Kullanıcı';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'A';
    final points = user?.points ?? 0;
    final photoUrl = (user?.photoUrl ?? '').toString().trim().isEmpty ? null : user?.photoUrl;

    return Row(
      children: [
        // Profil Resmi
        GestureDetector(
          onTap: () => ref.read(currentTabProvider.notifier).state = 4, // Profil sekmesi
          child: Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: FRColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: FRColors.gold, width: 1.5),
            ),
            padding: const EdgeInsets.all(2),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: photoUrl != null 
                ? CachedNetworkImage(imageUrl: photoUrl, fit: BoxFit.cover) 
                : Center(child: Text(initial, style: const TextStyle(color: FRColors.darkMain, fontWeight: FontWeight.bold, fontSize: 18))),
            ),
          ),
        ),
        const SizedBox(width: 12),
        
        // Hoş geldin Metni
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
        
        // Puanlar (GERÇEK YÖNLENDİRME)
        PremiumPressable(
          borderRadius: BorderRadius.circular(100),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PointsScreen())),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                const Icon(Icons.stars_rounded, color: FRColors.gold, size: 16),
                const SizedBox(width: 6),
                Text('$points', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        
        // Bildirim Çanı (GERÇEK YÖNLENDİRME)
        PremiumPressable(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationCenterPage())),
          child: const _NotificationBellWidget(),
        ),
      ],
    );
  }

  // Arama Çubuğu (GERÇEK YÖNLENDİRME)
  Widget _buildSearchBar() {
    return PremiumPressable(
      borderRadius: BorderRadius.circular(24),
      onTap: () => ref.read(currentTabProvider.notifier).state = 1, // 1 = Arama/Keşfet Sekmesi
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
              decoration: BoxDecoration(color: FRColors.studio, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.qr_code_scanner_rounded, color: FRColors.darkMain, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════ 2. DİNAMİK KATEGORİLER ════════════
  Widget _buildDynamicCategories(List<CategoryModel> categories) {
    if (categories.isEmpty) return const SizedBox.shrink();
    
    // Tümü butonunu en başa eklemek için liste oluşturuyoruz
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const BouncingScrollPhysics(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sabit "Tümü" Butonu
          _buildCatSquare('Tümü', Icons.grid_view_rounded, isActive: true, onTap: () {}),
          const SizedBox(width: 16),
          
          // Firebase'den Gelen Kategoriler
          ...categories.map((cat) {
            // Kategori ismine göre dinamik ikon atama (Geliştirilebilir)
            IconData catIcon = Icons.category;
            final titleLower = cat.title.toLowerCase();
            if (titleLower.contains('market') || titleLower.contains('gıda')) catIcon = Icons.shopping_cart_outlined;
            else if (titleLower.contains('tekno')) catIcon = Icons.laptop_mac;
            else if (titleLower.contains('kozmetik') || titleLower.contains('bakım')) catIcon = Icons.face_retouching_natural;
            else if (titleLower.contains('spor') || titleLower.contains('hobi')) catIcon = Icons.sports_esports;
            else if (titleLower.contains('kitap')) catIcon = Icons.menu_book;

            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: _buildCatSquare(cat.title, catIcon, isActive: false, onTap: () {
                // Kategoriye tıklandığında yapılacak işlem
              }),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCatSquare(String title, IconData icon, {required bool isActive, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64, height: 64, 
            decoration: BoxDecoration(
              color: isActive ? FRColors.darkMain : Colors.white,
              borderRadius: BorderRadius.circular(18), 
              boxShadow: isActive ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: Icon(icon, color: isActive ? Colors.white : Colors.grey.shade600, size: 30),
          ),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(fontSize: 12, fontWeight: isActive ? FontWeight.bold : FontWeight.w600, color: FRColors.textMain)),
        ],
      ),
    );
  }

  // ════════════ 3. BANNER VE ANALİZ KARTI (Aynı Bırakıldı) ════════════
  Widget _buildBannerCarousel(List<BannerModel> banners) {
    if (banners.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 160,
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
                    Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [FRColors.darkMain.withOpacity(0.95), FRColors.darkMain.withOpacity(0.1)]))),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: FRColors.gold, borderRadius: BorderRadius.circular(6)), child: const Text('GÜNÜN FIRSATI', style: TextStyle(color: FRColors.darkMain, fontSize: 9, fontWeight: FontWeight.w900))),
                          const SizedBox(height: 8),
                          Text(banner.title, maxLines: 2, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, height: 1.2)),
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
    );
  }

  Widget _buildAnalysisCard(ProductModel product) {
    final price = product.price ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Radar Analizi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: FRColors.textMain)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(color: FRColors.dangerBg, borderRadius: BorderRadius.circular(6)),
                child: Row(
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: FRColors.danger, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    const Text('CANLI', style: TextStyle(color: FRColors.danger, fontSize: 9, fontWeight: FontWeight.w900)),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 16),
          PremiumPressable(
            onTap: () => Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: product.id))),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: FRColors.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFEBE5DF))),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 70, height: 70, padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: FRColors.studio, borderRadius: BorderRadius.circular(16)),
                        child: CachedNetworkImage(imageUrl: product.imageUrl ?? '', fit: BoxFit.contain),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text((product.brand ?? 'MARKA').toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: FRColors.gold)),
                            const SizedBox(height: 4),
                            Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: FRColors.textMain)),
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildChartRow(product.storeName ?? 'Market', price, 100, isBest: true),
                  const SizedBox(height: 8),
                  _buildChartRow('Ortalama', price * 1.15, 75, isBest: false),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartRow(String market, double price, int fillPercent, {bool isBest = false}) {
    return Row(
      children: [
        SizedBox(width: 55, child: Text(market, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isBest ? FRColors.darkMain : FRColors.textMuted))),
        Expanded(
          child: Container(
            height: 8, decoration: BoxDecoration(color: FRColors.studio, borderRadius: BorderRadius.circular(4)),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: fillPercent / 100,
              child: Container(decoration: BoxDecoration(color: isBest ? FRColors.gold : FRColors.textMuted.withOpacity(0.5), borderRadius: BorderRadius.circular(4))),
            ),
          ),
        ),
        SizedBox(width: 60, child: Text(formatTRY(price), textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isBest ? FRColors.gold : FRColors.textMain))),
      ],
    );
  }

  // ════════════ 4. SERT DÜŞÜŞLER (NEFES ALAN GENİŞ KARTLAR) ════════════
  Widget _buildDarkSection(String title, List<ProductModel> products) {
    if (products.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 36),
      padding: const EdgeInsets.symmetric(vertical: 32),
      color: FRColors.darkMain,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                GestureDetector(
                  onTap: () => ref.read(currentTabProvider.notifier).state = 1,
                  child: const Text('Tümünü Gör', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: FRColors.gold)),
                )
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250, // Boğulmaması için yükseklik artırıldı
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final product = products[index];
                return PremiumPressable(
                  onTap: () => Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: product.id))),
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: 175, // Genişlik artırıldı (Nefes alması için)
                    decoration: BoxDecoration(color: FRColors.darkSurface, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.05))),
                    padding: const EdgeInsets.all(14), // İç boşluk artırıldı
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            Container(
                              height: 120, // Resim alanı büyütüldü
                              width: double.infinity,
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.all(18), // Resim sınırları korundu
                              child: CachedNetworkImage(imageUrl: product.imageUrl ?? '', fit: BoxFit.contain, errorWidget: (_, __, ___) => const Icon(Icons.image_not_supported, color: Colors.grey)),
                            ),
                            Positioned(
                              top: 8, left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                decoration: BoxDecoration(color: FRColors.success.withOpacity(0.15), border: Border.all(color: FRColors.success.withOpacity(0.3)), borderRadius: BorderRadius.circular(6)),
                                child: const Row(
                                  children: [
                                    Icon(Icons.arrow_downward_rounded, color: Color(0xFF69F0AE), size: 12),
                                    SizedBox(width: 2),
                                    Text('İndirim', style: TextStyle(color: Color(0xFF69F0AE), fontSize: 9, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text((product.brand ?? 'MARKA').toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: FRColors.gold), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white, height: 1.3)),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(formatTRY((product.price ?? 0) * 1.15), style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.4), decoration: TextDecoration.lineThrough)),
                                Text(formatTRY(product.price ?? 0), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              decoration: BoxDecoration(color: FRColors.gold, borderRadius: BorderRadius.circular(6)),
                              child: Text(product.storeName ?? 'Market', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: FRColors.darkMain)),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ════════════ 5. SON TARAMALAR (MAKSİMUM 5 ADET) ════════════
  Widget _buildLatestPricesList(List<PriceModel> prices) {
    if (prices.isEmpty) return const SizedBox.shrink();
    
    // BURASI ÖNEMLİ: Sadece son 5 kaydı alıyoruz (.take(5))
    final limitedPrices = prices.take(5).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Son Taramalar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: FRColors.textMain)),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFEBE5DF)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: limitedPrices.asMap().entries.map((entry) {
                final index = entry.key;
                final price = entry.value;
                final isLast = index == (limitedPrices.length - 1);
                
                // Demo amaçlı index'e göre düşüş/yükseliş atıyoruz (Gerçekte veri tabanından fiyat karşılaştırması yapılır)
                final isDrop = index % 2 == 0; 
                
                return PremiumPressable(
                  onTap: () => Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: price.productId))),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(border: isLast ? null : Border.all(color: Colors.transparent), borderBottom: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFFEBE5DF)))),
                    child: Row(
                      children: [
                        Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(color: isDrop ? FRColors.successBg : FRColors.dangerBg, borderRadius: BorderRadius.circular(12)),
                          child: Icon(isDrop ? Icons.trending_down : Icons.trending_up, color: isDrop ? FRColors.success : FRColors.danger),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(price.storeName ?? 'Market', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: FRColors.textMain), maxLines: 1),
                              const SizedBox(height: 2),
                              Text('${price.reporterName ?? price.userName ?? 'Kullanıcı'} ekledi', style: const TextStyle(fontSize: 11, color: FRColors.textMuted)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(formatTRY(price.price), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: FRColors.darkMain)),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(isDrop ? Icons.arrow_downward : Icons.arrow_upward, color: isDrop ? FRColors.success : FRColors.danger, size: 10),
                                const SizedBox(width: 2),
                                Text(isDrop ? 'Düşüş Sinyali' : 'Yükseliş', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDrop ? FRColors.success : FRColors.danger)),
                              ],
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// BİLDİRİM ZİLİ KÜÇÜK WIDGET
class _NotificationBellWidget extends ConsumerWidget {
  const _NotificationBellWidget();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authStateProvider).valueOrNull?.uid;
    final unreadStream = uid == null ? Stream<int>.value(0) : NotificationCenterService().getUnreadCount(uid);

    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.1))),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 20),
          StreamBuilder<int>(
            stream: unreadStream,
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              if (count <= 0) return const SizedBox.shrink();
              return Positioned(top: 8, right: 8, child: Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle, border: Border.all(color: FRColors.darkMain, width: 1.5))));
            },
          ),
        ],
      ),
    );
  }
}
