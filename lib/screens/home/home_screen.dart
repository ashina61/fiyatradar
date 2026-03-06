import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

// Orijinal Tasarımından Çekilen Birebir Renkler
class OriginalColors {
  static const Color bg = Color(0xFFF7F4F0); // Resimdeki uçuk krem arkaplan
  static const Color headerBg = Color(0xFF331E12); // Koyu acı kahve header
  static const Color textMain = Color(0xFF2D1A11); // Ana metin
  static const Color textMuted = Color(0xFF9E928A); // Alt metinler
  static const Color primary = Color(0xFF6B4226); // FiyatRadar kahvesi
  static const Color cardBg = Colors.white; // Kart beyazı
  static const Color pillBg = Color(0xFFF3EBE4); // İkon/Kategori arka plan beji
  static const Color trendGreen = Color(0xFFE8F5E9);
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
    final storesAsync = ref.watch(allStoresStreamProvider);
    final usersAsync = ref.watch(allUsersProvider);
    final latestPricesAsync = ref.watch(latestPricesProvider);
    
    final users = usersAsync.valueOrNull ?? [];
    final marketCount = storesAsync.valueOrNull?.length ?? 0;
    final totalUserCount = users.length;
    final totalPriceCount = users.fold<int>(0, (sum, user) => sum + user.priceEntries);

    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: OriginalColors.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          // 1. KUSURSUZ HEADER VE TAŞAN ARAMA ÇUBUĞU
          SliverToBoxAdapter(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Koyu Kahve Arkaplan
                Container(
                  height: 180 + topPadding,
                  decoration: const BoxDecoration(
                    color: OriginalColors.headerBg,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
                  ),
                  padding: EdgeInsets.fromLTRB(20, topPadding + 16, 20, 0),
                  child: userAsync.when(
                    data: (user) => _buildHeaderContent(context, user),
                    loading: () => _buildHeaderContent(context, null),
                    error: (_, __) => _buildHeaderContent(context, null),
                  ),
                ),
                // Taşan Arama Çubuğu
                Positioned(
                  bottom: -24,
                  left: 20,
                  right: 20,
                  child: _buildSearchBar(),
                ),
              ],
            ),
          ),

          // Arama çubuğunun altındaki boşluk ve İstatistikler
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 44),
                _buildQuickStats(totalPriceCount, totalUserCount, marketCount),
                const SizedBox(height: 24),
              ],
            ),
          ),

          // 2. KATEGORİLER (Birebir Fotoğraftaki Gibi)
          SliverToBoxAdapter(
            child: _buildCategories(),
          ),

          // 3. BANNER (Günün Fırsatı)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 24),
              child: bannersAsync.when(
                data: (banners) => _buildBannerCarousel(banners),
                loading: () => const SizedBox(height: 150),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
          ),

          // 4. TREND ÜRÜNLER (Fotoğraftaki Orijinal Kartlar)
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

          // 6. PİYASA AKIŞI (Temiz Liste)
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

          // Alt Menü boşluğu (Alt menüye dokunmadım)
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  // ════════════ PARÇALAR ════════════

  Widget _buildHeaderContent(BuildContext context, dynamic user) {
    final displayName = user?.name ?? 'Admin';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'A';
    final points = user?.points ?? 20508;
    final photoUrl = (user?.photoUrl ?? '').toString().trim().isEmpty ? null : user?.photoUrl;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            image: photoUrl != null ? DecorationImage(image: CachedNetworkImageProvider(photoUrl), fit: BoxFit.cover) : null,
          ),
          child: photoUrl == null ? Center(child: Text(initial, style: const TextStyle(color: OriginalColors.headerBg, fontWeight: FontWeight.bold))) : null,
        ),
        const SizedBox(width: 12),
        // Yazı
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Hoş geldin,', style: TextStyle(color: Color(0xFFBCAAA4), fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(displayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
        ),
        // Puan
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF4E342E), // Kahve tonu
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const Icon(Icons.stars, color: Color(0xFFD7CCC8), size: 16),
              const SizedBox(width: 4),
              Text('$points', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Bildirim Zili
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF4E342E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.notifications_none, color: Colors.white, size: 20),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.grey, size: 22),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Ürün, marka veya mağaza ara...', style: TextStyle(color: Colors.grey, fontSize: 14)),
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: OriginalColors.pillBg, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.qr_code_scanner, color: OriginalColors.primary, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(int prices, int users, int markets) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _statItem(Icons.payments, 'Kayıtlı fiyat', prices, Colors.green),
        _statDot(),
        _statItem(Icons.people, 'Toplam kullanıcı', users, Colors.blue),
        _statDot(),
        _statItem(Icons.storefront, 'Kayıtlı', markets, Colors.grey),
      ],
    );
  }

  Widget _statItem(IconData icon, String text, int val, Color iconColor) {
    return Row(
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 4),
        Text('$text: ', style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Text('$val', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: OriginalColors.textMain)),
      ],
    );
  }

  Widget _statDot() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(width: 4, height: 4, decoration: const BoxDecoration(color: OriginalColors.primary, shape: BoxShape.circle)),
    );
  }

  Widget _buildCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(width: 3, height: 16, color: OriginalColors.primary),
              const SizedBox(width: 8),
              const Text('Kategoriler', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: OriginalColors.primary)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          physics: const BouncingScrollPhysics(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCatItem('Tümü', Icons.grid_view_rounded, isActive: true),
              const SizedBox(width: 16),
              _buildCatItem('Kişisel Bakım', Icons.face_retouching_natural),
              const SizedBox(width: 16),
              _buildCatItem('Kitap', Icons.menu_book),
              const SizedBox(width: 16),
              _buildCatItem('Spor', Icons.category), // İkonlar resmine göre uyarlandı
              const SizedBox(width: 16),
              _buildCatItem('Gıda', Icons.restaurant),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCatItem(String title, IconData icon, {bool isActive = false}) {
    return Column(
      children: [
        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(
            color: isActive ? OriginalColors.primary : OriginalColors.pillBg,
            borderRadius: isActive ? BorderRadius.circular(16) : BorderRadius.circular(30), // Tümü kare, diğerleri yuvarlak (resimdeki gibi)
          ),
          child: Icon(icon, color: isActive ? Colors.white : OriginalColors.primary, size: 28),
        ),
        const SizedBox(height: 8),
        Text(title, style: TextStyle(fontSize: 11, fontWeight: isActive ? FontWeight.bold : FontWeight.w500, color: OriginalColors.textMain)),
      ],
    );
  }

  Widget _buildBannerCarousel(List<BannerModel> banners) {
    if (banners.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        SizedBox(
          height: 140,
          child: PageView.builder(
            controller: _bannerController,
            onPageChanged: (index) => setState(() => _currentBannerPage = index),
            itemCount: banners.length,
            itemBuilder: (context, index) {
              final banner = banners[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(imageUrl: banner.imageUrl.isNotEmpty ? banner.imageUrl : 'https://images.unsplash.com/photo-1542838132-92c53300491e?q=80&w=600', fit: BoxFit.cover),
                      Container(color: Colors.black.withOpacity(0.4)), // Karartma
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                              child: const Text('GÜNÜN FIRSATI', style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 8),
                            Text(banner.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.5))),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Keşfet', style: TextStyle(color: Colors.white, fontSize: 12)),
                                  SizedBox(width: 4),
                                  Icon(Icons.arrow_forward, color: Colors.white, size: 14),
                                ],
                              ),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(banners.length, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _currentBannerPage == index ? 16 : 6, height: 6,
              decoration: BoxDecoration(color: _currentBannerPage == index ? OriginalColors.primary : Colors.grey.shade400, borderRadius: BorderRadius.circular(4)),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildProductsSection(String title, List<ProductModel> products) {
    if (products.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: OriginalColors.textMain)),
              const Text('Tümünü Gör', style: TextStyle(fontSize: 12, color: OriginalColors.textMuted)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 230,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              return _OriginalProductCard(product: products[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLatestPricesList(List<PriceModel> prices) {
    if (prices.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Piyasa Akışı', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: OriginalColors.textMain)),
          const SizedBox(height: 16),
          ...prices.take(5).map((price) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: OriginalColors.pillBg, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.history, color: OriginalColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(price.storeName ?? 'Market', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('${price.reporterName ?? price.userName ?? 'Kullanıcı'} ekledi', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                  ),
                  Text(formatTRY(price.price), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ════════════ BİREBİR FOTOĞRAFTAKİ ÜRÜN KARTI ════════════
class _OriginalProductCard extends StatelessWidget {
  final ProductModel product;
  const _OriginalProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final title = product.name;
    final brand = (product.brand ?? 'MARKA').toUpperCase();
    final priceStr = product.price != null ? formatTRY(product.price!) : '---';
    final marketName = "En Uygun"; // Veya Trendyol M.

    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: OriginalColors.cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Üst Kısım: Etiket, Resim, Kalp
          Stack(
            children: [
              Container(
                height: 110,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: OriginalColors.pillBg, // Senin o "Nutella" arkaplanındaki krem renk
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: CachedNetworkImage(
                    imageUrl: product.imageUrl ?? '',
                    fit: BoxFit.contain, // ASLA TAŞMAZ
                    errorWidget: (_, __, ___) => const Icon(Icons.image_not_supported, color: Colors.grey),
                  ),
                ),
              ),
              Positioned(
                top: 8, left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(color: OriginalColors.trendGreen, borderRadius: BorderRadius.circular(6)),
                  child: const Row(
                    children: [
                      Icon(Icons.south_east, color: OriginalColors.trendGreenText, size: 10),
                      SizedBox(width: 2),
                      Text('%18', style: TextStyle(color: OriginalColors.trendGreenText, fontSize: 9, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const Positioned(
                top: 8, right: 8,
                child: Icon(Icons.favorite_border, color: Colors.grey, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Metinler
          Text(brand, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, height: 1.2)),
          const Spacer(),
          // Alt Fiyat ve Market (RESİMDEKİ GİBİ)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ort: 40,00₺', style: TextStyle(fontSize: 10, color: Colors.grey, decoration: TextDecoration.lineThrough)),
                  Text(priceStr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: OriginalColors.textMain)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: OriginalColors.pillBg, borderRadius: BorderRadius.circular(6)),
                child: Text(marketName, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: OriginalColors.textMain)),
              )
            ],
          )
        ],
      ),
    );
  }
}
