import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/notification_model.dart';
import '../../models/price_model.dart';
import '../../models/product_model.dart';
import '../../models/user_model.dart';
import '../../pages/notification_center_page.dart';
import '../../providers/notification_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/barcode_scanner_sheet.dart';
import '../add_price/add_price_screen.dart';
import '../main_screen.dart';
import '../product/product_detail_screen.dart';
import '../../theme/fr_colors.dart';
import '../../theme/fr_radius.dart';
import '../../theme/fr_spacing.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userModelStreamProvider);
    final latestPricesAsync = ref.watch(latestPricesProvider);
    final trendingAsync = ref.watch(trendingProductsProvider);
    final unreadCount = ref.watch(unreadCountProvider);
    final notifications = ref.watch(notificationsProvider).valueOrNull ?? const <NotificationItem>[];
    final watchlistProducts = ref.watch(savedProductsProvider).valueOrNull ?? const <ProductModel>[];

    final latestPrices = latestPricesAsync.valueOrNull ?? const <PriceModel>[];
    final trendingProducts = trendingAsync.valueOrNull ?? const <ProductModel>[];
    final priceChangeByProduct = _computePriceChangeByProduct(latestPrices);
    NotificationItem? triggeredAlert;
    for (final item in notifications) {
      if (!item.isRead && (item.productId ?? '').trim().isNotEmpty) {
        triggeredAlert = item;
        break;
      }
    }

    return Scaffold(
      backgroundColor: FRColors.surfaceSoft,
      appBar: _buildAppBar(context, userAsync.valueOrNull, unreadCount),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSearchHero(context),
            if (triggeredAlert != null) _buildPriorityAlert(context, triggeredAlert),
            if (watchlistProducts.isNotEmpty) _buildPersonalSummary(context, watchlistProducts),
            _buildLiveFeedSection(context, latestPrices, priceChangeByProduct),
            if (trendingProducts.isNotEmpty) _buildTrendSection(context, trendingProducts),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
      floatingActionButton: _buildFab(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, UserModel? user, int unreadCount) {
    final displayName = user?.username.trim().isNotEmpty == true
        ? user!.username.trim()
        : (user?.preferredDisplayName ?? 'Kullanıcı');

    return AppBar(
      backgroundColor: FRColors.surfaceSoft,
      elevation: 0,
      toolbarHeight: 72,
      titleSpacing: 16,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _greetingByHour(),
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w500,
              color: FRColors.textSubtle,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: FRColors.textMuted),
          ),
          const SizedBox(height: 2),
          RichText(
            text: const TextSpan(
              text: 'Fiyat',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: FRColors.textPrimary,
              ),
              children: [
                TextSpan(
                  text: 'Radar',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: FRColors.tan,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        _buildIconButton(
          icon: Icons.notifications_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationCenterPage()),
          ),
          badge: unreadCount > 0,
        ),
        const SizedBox(width: 4),
        _buildIconButton(
          icon: Icons.person_outline,
          onTap: () => ref.read(currentTabProvider.notifier).state = 4,
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
    bool badge = false,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: FRRadius.all(FRRadius.md),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: FRColors.surface,
              borderRadius: FRRadius.all(FRRadius.md),
              border: Border.all(color: FRColors.border),
            ),
            child: Icon(icon, size: 18, color: FRColors.textMuted),
          ),
        ),
        if (badge)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: FRColors.danger,
                shape: BoxShape.circle,
                border: Border.all(color: FRColors.surfaceSoft, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchHero(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: FRSpaceInsets.fromLTRB(16, 8, 16, 12),
        child: Container(
          decoration: BoxDecoration(
            color: FRColors.surface,
            borderRadius: FRRadius.all(FRRadius.xl),
            border: Border.all(color: FRColors.border),
          ),
          child: InkWell(
            borderRadius: FRRadius.all(FRRadius.xl),
            onTap: () => ref.read(currentTabProvider.notifier).state = 1,
            child: Padding(
              padding: FRSpaceInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: FRColors.tan, size: 22),
                  const SizedBox(width: FRSpacing.md),
                  const Expanded(
                    child: Text(
                      'Ürün, marka veya kategori ara...',
                      style: TextStyle(
                        color: FRColors.textSubtle,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () async {
                      final barcode = await BarcodeScannerSheet.scan(context);
                      if (!mounted || barcode == null || barcode.trim().isEmpty) return;
                      ref.read(searchQueryProvider.notifier).state = barcode.trim();
                      ref.read(currentTabProvider.notifier).state = 1;
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: FRColors.surfaceAlt,
                        borderRadius: FRRadius.all(FRRadius.md),
                        border: Border.all(color: FRColors.border),
                      ),
                      child: const Icon(Icons.qr_code_scanner_rounded, size: 18, color: FRColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityAlert(BuildContext context, NotificationItem alert) {
    return SliverToBoxAdapter(
      child: Container(
        margin: FRSpaceInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [FRColors.gold.withOpacity(0.08), FRColors.gold.withOpacity(0.02)],
          ),
          borderRadius: FRRadius.all(FRRadius.xl),
          border: Border.all(color: FRColors.gold.withOpacity(0.3)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: FRRadius.all(FRRadius.xl),
            onTap: (alert.productId ?? '').toString().trim().isEmpty
                ? null
                : () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: alert.productId!)),
                    ),
            child: Padding(
              padding: FRSpaceInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: FRSpaceInsets.all(6),
                        decoration: BoxDecoration(
                          color: FRColors.gold,
                          borderRadius: FRRadius.all(FRRadius.pill),
                        ),
                        child: const Icon(Icons.notifications_active_rounded, size: 14, color: FRColors.white),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        alert.type == 'price_alert' ? 'Hedef Fiyata Ulaşıldı' : 'Bildirim',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: FRColors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    (alert.productName ?? alert.title ?? 'Ürün').toString(),
                    style: const TextStyle(fontSize: 13, color: FRColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (alert.message ?? 'Fiyat bildirimi mevcut').toString(),
                    style: const TextStyle(fontSize: 11, color: FRColors.textMuted),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalSummary(BuildContext context, List<ProductModel> watchlist) {
    return SliverToBoxAdapter(
      child: Container(
        margin: FRSpaceInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [FRColors.surface, FRColors.surfaceSoft],
          ),
          borderRadius: FRRadius.all(FRRadius.xl),
          border: Border.all(color: FRColors.border),
        ),
        child: Padding(
          padding: FRSpaceInsets.all(17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.star_rounded, size: 14, color: FRColors.tan),
                      SizedBox(width: 5),
                      Text(
                        'Takip Listem',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: FRColors.textMuted,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${watchlist.length} ürün',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: FRColors.tan),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...watchlist.take(2).map(
                    (item) => Padding(
                      padding: FRSpaceInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: FRColors.surfaceAlt,
                              borderRadius: FRRadius.all(FRRadius.md),
                              border: Border.all(color: FRColors.border),
                            ),
                            child: const Icon(Icons.bookmark_outline_rounded, size: 20, color: FRColors.tan),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.name,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: FRColors.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            (item.lastPrice ?? 0) > 0 ? formatTRY(item.lastPrice ?? 0) : '-',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: FRColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveFeedSection(
    BuildContext context,
    List<PriceModel> prices,
    Map<String, double> priceChangeByProduct,
  ) {
    return SliverPadding(
      padding: FRSpaceInsets.fromLTRB(16, 20, 16, 16),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.bolt_rounded, size: 16, color: FRColors.tan),
                  SizedBox(width: 7),
                  Text('Canlı Fiyatlar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: FRColors.textPrimary)),
                ],
              ),
              TextButton(
                onPressed: () => ref.read(currentTabProvider.notifier).state = 1,
                child: const Text('Tümü', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: FRColors.tan)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (prices.isEmpty)
            _buildEmptyFeed()
          else
            ...prices.take(5).map(
                  (price) => _buildLiveFeedItem(
                    context,
                    price,
                    priceChangePercent: priceChangeByProduct[price.productId],
                  ),
                ),
        ]),
      ),
    );
  }

  Widget _buildEmptyFeed() {
    return Container(
      padding: FRSpaceInsets.symmetric(vertical: 24),
      child: const Center(
        child: Text(
          'Henüz canlı fiyat yok.\nİlk fiyatı sen ekle!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: FRColors.textSubtle, height: 1.4),
        ),
      ),
    );
  }

  Widget _buildLiveFeedItem(
    BuildContext context,
    PriceModel item, {
    double? priceChangePercent,
  }) {
    final productId = item.productId.trim().isNotEmpty ? item.productId.trim() : null;

    return Container(
      margin: FRSpaceInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: FRColors.surface,
        borderRadius: FRRadius.all(FRRadius.lg),
        border: Border.all(color: FRColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: FRRadius.all(FRRadius.lg),
          onTap: productId != null
              ? () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: productId)),
                  )
              : null,
          child: Padding(
            padding: FRSpaceInsets.all(13),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: FRColors.surfaceAlt,
                    borderRadius: FRRadius.all(FRRadius.md),
                    border: Border.all(color: FRColors.border),
                  ),
                  child: item.imageUrl?.isNotEmpty == true
                      ? ClipRRect(
                          borderRadius: FRRadius.all(FRRadius.md),
                          child: CachedNetworkImage(imageUrl: item.imageUrl!, fit: BoxFit.cover),
                        )
                      : const Icon(Icons.category_outlined, size: 22, color: FRColors.tan),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName ?? 'Ürün',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: FRColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.store_outlined, size: 11, color: FRColors.textSubtle),
                          const SizedBox(width: 4),
                          Text(
                            item.storeName ?? 'Mağaza',
                            style: const TextStyle(fontSize: 10, color: FRColors.textSubtle),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '• ${_formatTimeAgo(item.createdAt)}',
                            style: const TextStyle(fontSize: 10, color: FRColors.textSubtle),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatTRY(item.price),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: FRColors.tan),
                    ),
                    if (priceChangePercent != null && priceChangePercent.abs() >= 1)
                      Container(
                        margin: FRSpaceInsets.only(top: 4),
                        padding: FRSpaceInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: priceChangePercent <= 0 ? FRColors.successSurface : FRColors.dangerSurface,
                          borderRadius: FRRadius.all(FRRadius.sm),
                        ),
                        child: Text(
                          '${priceChangePercent <= 0 ? '↓' : '↑'} ${priceChangePercent.abs().toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: priceChangePercent <= 0 ? FRColors.success : FRColors.danger,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime createdAt) {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}d';
    if (diff.inHours < 24) return '${diff.inHours}s';
    return '${diff.inDays}g';
  }

  Widget _buildTrendSection(BuildContext context, List<ProductModel> products) {
    return SliverPadding(
      padding: FRSpaceInsets.fromLTRB(16, 8, 16, 24),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.explore_rounded, size: 16, color: FRColors.tan),
                  SizedBox(width: 7),
                  Text('Seçkiler', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: FRColors.textPrimary)),
                ],
              ),
              TextButton(
                onPressed: () => ref.read(currentTabProvider.notifier).state = 1,
                child: const Text('Keşfet', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: FRColors.tan)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: products.length > 5 ? 5 : products.length,
              separatorBuilder: (_, __) => const SizedBox(width: 13),
              itemBuilder: (context, index) => _buildTrendCard(context, products[index]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildTrendCard(BuildContext context, ProductModel product) {
    return Container(
      width: 155,
      decoration: BoxDecoration(
        color: FRColors.surface,
        borderRadius: FRRadius.all(FRRadius.xl),
        border: Border.all(color: FRColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: FRRadius.all(FRRadius.xl),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: product.id)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    height: 105,
                    decoration: BoxDecoration(
                      color: FRColors.surfaceAlt,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                    ),
                    child: product.effectiveImage != null && product.effectiveImage!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                            child: CachedNetworkImage(imageUrl: product.effectiveImage!, fit: BoxFit.cover),
                          )
                        : const Center(
                            child: Icon(Icons.category_outlined, size: 42, color: FRColors.tan),
                          ),
                  ),
                  Positioned(
                    top: 7,
                    left: 7,
                    child: Container(
                      padding: FRSpaceInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: FRRadius.all(FRRadius.pill),
                      ),
                      child: Text(
                        _getTrendBadge(product),
                        style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: FRSpaceInsets.all(11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: FRColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      (product.lastPrice ?? 0) > 0 ? formatTRY(product.lastPrice ?? 0) : 'Fiyat bilgisi yok',
                      style: const TextStyle(fontSize: 10, color: FRColors.textSubtle, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFab(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AddPriceScreen()),
      ),
      backgroundColor: FRColors.tan,
      foregroundColor: FRColors.espresso,
      elevation: 4,
      shape: const CircleBorder(),
      child: const Icon(Icons.add_rounded, size: 24),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final currentIndex = ref.watch(currentTabProvider);
    final clamped = currentIndex.clamp(0, 3);

    return BottomNavigationBar(
      currentIndex: clamped,
      onTap: (index) => ref.read(currentTabProvider.notifier).state = index,
      type: BottomNavigationBarType.fixed,
      backgroundColor: FRColors.surface.withOpacity(0.97),
      selectedItemColor: FRColors.tan,
      unselectedItemColor: FRColors.textSubtle,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Ana Sayfa'),
        BottomNavigationBarItem(icon: Icon(Icons.search_rounded), label: 'Ara'),
        BottomNavigationBarItem(icon: Icon(Icons.add_circle_rounded), label: 'Ekle'),
        BottomNavigationBarItem(icon: Icon(Icons.list_rounded), label: 'Liste'),
      ],
    );
  }

  String _greetingByHour() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) return 'Günaydın';
    if (hour >= 11 && hour < 18) return 'İyi günler';
    if (hour >= 18 && hour < 23) return 'İyi akşamlar';
    return 'İyi geceler';
  }

  Map<String, double> _computePriceChangeByProduct(List<PriceModel> prices) {
    final grouped = <String, List<PriceModel>>{};
    for (final price in prices) {
      grouped.putIfAbsent(price.productId, () => <PriceModel>[]).add(price);
    }

    final result = <String, double>{};
    for (final entry in grouped.entries) {
      if (entry.value.length < 2) continue;
      final sorted = [...entry.value]..sort((a, b) => b.reportedAt.compareTo(a.reportedAt));
      final latest = sorted.first.price;
      final previous = sorted[1].price;
      if (previous <= 0) continue;
      result[entry.key] = ((latest - previous) / previous) * 100;
    }
    return result;
  }

  String _getTrendBadge(ProductModel product) {
    if (product.priceEntryCount <= 2) return 'YENİ';
    if (product.isEditorPick) {
      return 'FIRSAT';
    }
    return 'TREND';
  }
}
