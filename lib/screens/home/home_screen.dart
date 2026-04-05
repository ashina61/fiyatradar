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
import '../../utils/formatters.dart';
import '../../widgets/barcode_scanner_sheet.dart';
import '../main_screen.dart';
import '../product/product_detail_screen.dart';
import '../../theme/fr_colors.dart';

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
      backgroundColor: FRColors.backgroundWarm,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverHeader(context, userAsync.valueOrNull, unreadCount),
          _buildSearchBar(context),
          if (triggeredAlert != null) _buildAlertBanner(context, triggeredAlert),
          if (watchlistProducts.isNotEmpty) _buildWatchlistSection(context, watchlistProducts),
          _buildLiveFeedSection(context, latestPrices, priceChangeByProduct),
          if (trendingProducts.isNotEmpty) _buildTrendSection(context, trendingProducts),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _buildSliverHeader(BuildContext context, UserModel? user, int unreadCount) {
    final displayName = user?.username.trim().isNotEmpty == true
        ? user!.username.trim()
        : (user?.preferredDisplayName ?? 'Kullanıcı');

    return SliverToBoxAdapter(
      child: Container(
        decoration: const BoxDecoration(
          color: FRColors.espresso,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _greetingByHour(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: FRColors.textMuted,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: FRColors.tanLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildHeaderIconBtn(
                      icon: Icons.notifications_outlined,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationCenterPage()),
                      ),
                      badge: unreadCount > 0,
                    ),
                    const SizedBox(width: 8),
                    _buildHeaderIconBtn(
                      icon: Icons.person_outline_rounded,
                      onTap: () => ref.read(currentTabProvider.notifier).state = 4,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                RichText(
                  text: const TextSpan(
                    text: 'Fiyat',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.1,
                    ),
                    children: [
                      TextSpan(
                        text: 'Radar',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: FRColors.tan,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'RADARDA SON GELİŞMELER',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: FRColors.textMuted,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderIconBtn({
    required IconData icon,
    required VoidCallback onTap,
    bool badge = false,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Icon(icon, size: 18, color: Colors.white.withOpacity(0.85)),
          ),
        ),
        if (badge)
          Positioned(
            right: 7,
            top: 7,
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: FRColors.danger,
                shape: BoxShape.circle,
                border: Border.all(color: FRColors.espresso, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return SliverToBoxAdapter(
      child: Transform.translate(
        offset: const Offset(0, -1),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Container(
            decoration: BoxDecoration(
              color: FRColors.surface,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14170D08),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => ref.read(currentTabProvider.notifier).state = 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, color: FRColors.tan, size: 22),
                    const SizedBox(width: 12),
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
                    GestureDetector(
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
                          color: FRColors.backgroundWarm,
                          borderRadius: BorderRadius.circular(10),
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
      ),
    );
  }

  Widget _buildAlertBanner(BuildContext context, NotificationItem alert) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        decoration: BoxDecoration(
          color: FRColors.espresso,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: (alert.productId ?? '').toString().trim().isEmpty
                ? null
                : () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: alert.productId!)),
                    ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: FRColors.tan.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.notifications_active_rounded, size: 20, color: FRColors.tan),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert.type == 'price_alert' ? 'Hedef Fiyata Ulaşıldı' : 'Yeni Bildirim',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: FRColors.tan,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          (alert.productName ?? alert.title ?? 'Ürün').toString(),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: FRColors.textMuted, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWatchlistSection(BuildContext context, List<ProductModel> watchlist) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionLabel('TAKİP LİSTEM', Icons.star_rounded),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: FRColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x08170D08),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ...watchlist.take(2).toList().asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    return Column(
                      children: [
                        if (idx > 0)
                          const Divider(height: 1, indent: 16, endIndent: 16, color: FRColors.border),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: FRColors.backgroundWarm,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: FRColors.border),
                                ),
                                child: const Icon(Icons.bookmark_rounded, size: 20, color: FRColors.tan),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: FRColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                (item.lastPrice ?? 0) > 0 ? formatTRY(item.lastPrice ?? 0) : '-',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: FRColors.tan,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                  if (watchlist.length > 2)
                    InkWell(
                      onTap: () => ref.read(currentTabProvider.notifier).state = 4,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: FRColors.backgroundWarm.withOpacity(0.5),
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                          border: const Border(top: BorderSide(color: FRColors.border)),
                        ),
                        child: Text(
                          '${watchlist.length - 2} ürün daha',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: FRColors.tan,
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
    );
  }

  Widget _buildLiveFeedSection(
    BuildContext context,
    List<PriceModel> prices,
    Map<String, double> priceChangeByProduct,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionLabel('CANLI FİYATLAR', Icons.bolt_rounded),
              TextButton(
                onPressed: () => ref.read(currentTabProvider.notifier).state = 1,
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                child: const Text(
                  'Tümünü Gör',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: FRColors.tan),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (prices.isEmpty)
            _buildEmptyFeed()
          else
            Container(
              decoration: BoxDecoration(
                color: FRColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Color(0x08170D08), blurRadius: 12, offset: Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  ...prices.take(5).toList().asMap().entries.map((entry) {
                    final idx = entry.key;
                    final price = entry.value;
                    return Column(
                      children: [
                        if (idx > 0)
                          const Divider(height: 1, indent: 76, endIndent: 0, color: FRColors.border),
                        _buildLiveFeedItem(context, price,
                            priceChangePercent: priceChangeByProduct[price.productId]),
                      ],
                    );
                  }),
                ],
              ),
            ),
        ]),
      ),
    );
  }

  Widget _buildEmptyFeed() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: FRColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bolt_outlined, size: 32, color: FRColors.textSubtle),
            SizedBox(height: 10),
            Text(
              'Henüz canlı fiyat yok.',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: FRColors.textPrimary),
            ),
            SizedBox(height: 4),
            Text(
              'İlk fiyatı sen ekle!',
              style: TextStyle(fontSize: 12, color: FRColors.textSubtle),
            ),
          ],
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: productId != null
            ? () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: productId)),
                )
            : null,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: FRColors.backgroundWarm,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: FRColors.border),
                ),
                child: item.imageUrl?.isNotEmpty == true
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(imageUrl: item.imageUrl!, fit: BoxFit.cover),
                      )
                    : const Icon(Icons.category_outlined, size: 22, color: FRColors.tan),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName ?? 'Ürün',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: FRColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.store_outlined, size: 10, color: FRColors.textSubtle),
                        const SizedBox(width: 3),
                        Text(
                          item.storeName ?? 'Mağaza',
                          style: const TextStyle(fontSize: 10, color: FRColors.textSubtle),
                        ),
                        const SizedBox(width: 5),
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
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: FRColors.tan,
                    ),
                  ),
                  if (priceChangePercent != null && priceChangePercent.abs() >= 1)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: priceChangePercent <= 0 ? FRColors.successSurface : FRColors.dangerSurface,
                        borderRadius: BorderRadius.circular(6),
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
    );
  }

  Widget _buildTrendSection(BuildContext context, List<ProductModel> products) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionLabel('SEÇKİLER', Icons.explore_rounded),
              TextButton(
                onPressed: () => ref.read(currentTabProvider.notifier).state = 1,
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                child: const Text(
                  'Keşfet',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: FRColors.tan),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 190,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: products.length > 6 ? 6 : products.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) => _buildTrendCard(context, products[index]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildTrendCard(BuildContext context, ProductModel product) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: product.id)),
      ),
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          color: FRColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Color(0x08170D08), blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 112,
                  decoration: BoxDecoration(
                    color: FRColors.backgroundWarm,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: product.effectiveImage != null && product.effectiveImage!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          child: CachedNetworkImage(
                            imageUrl: product.effectiveImage!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        )
                      : const Center(
                          child: Icon(Icons.category_outlined, size: 40, color: FRColors.tan),
                        ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: FRColors.espresso.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _getTrendBadge(product),
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: FRColors.tan,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: FRColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    (product.lastPrice ?? 0) > 0 ? formatTRY(product.lastPrice ?? 0) : 'Fiyat yok',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: FRColors.tan,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: FRColors.tan),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: FRColors.textMuted,
            letterSpacing: 1.0,
          ),
        ),
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

  String _formatTimeAgo(DateTime createdAt) {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}d';
    if (diff.inHours < 24) return '${diff.inHours}s';
    return '${diff.inDays}g';
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
    if (product.isEditorPick) return 'FIRSAT';
    return 'TREND';
  }
}
