import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/notification_model.dart';
import '../../models/price_model.dart';
import '../../models/product_model.dart';
import '../../models/user_model.dart';
import '../../pages/notification_center_page.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/barcode_scanner_sheet.dart';
import '../main_screen.dart';
import '../product/product_detail_screen.dart';
import '../../theme/fr_colors.dart';

// ─── Design tokens (local) ────────────────────────────────────────────────
const _kHeaderRadius = 36.0;
const _kCardRadius = 20.0;
const _kPagePad = 20.0;
const _kSectionGap = 28.0;

const _kCardShadow = BoxShadow(
  color: Color(0x0F170D08),
  blurRadius: 14,
  offset: Offset(0, 4),
);

// ─────────────────────────────────────────────────────────────────────────

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
    final notifications =
        ref.watch(notificationsProvider).valueOrNull ?? const <NotificationItem>[];
    final watchlist =
        ref.watch(savedProductsProvider).valueOrNull ?? const <ProductModel>[];

    final prices = latestPricesAsync.valueOrNull ?? const <PriceModel>[];
    final trending = trendingAsync.valueOrNull ?? const <ProductModel>[];
    final changeMap = _priceChangeMap(prices);

    NotificationItem? alert;
    for (final n in notifications) {
      if (!n.isRead && (n.productId ?? '').trim().isNotEmpty) {
        alert = n;
        break;
      }
    }

    return Scaffold(
      backgroundColor: FRColors.backgroundWarm,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildHeader(context, userAsync.valueOrNull, unreadCount),
          _buildSearch(context),
          if (alert != null) _buildAlertStrip(context, alert),
          _buildLiveFeed(context, prices, changeMap),
          if (watchlist.isNotEmpty) _buildWatchlist(context, watchlist),
          if (trending.isNotEmpty) _buildTrending(context, trending),
          const SliverToBoxAdapter(child: SizedBox(height: 130)),
        ],
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, UserModel? user, int unread) {
    final name = user?.username.trim().isNotEmpty == true
        ? user!.username.trim()
        : (user?.preferredDisplayName ?? 'Kullanıcı');

    return SliverToBoxAdapter(
      child: Container(
        decoration: const BoxDecoration(
          color: FRColors.espresso,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(_kHeaderRadius),
            bottomRight: Radius.circular(_kHeaderRadius),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(_kPagePad, 16, _kPagePad, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: greeting + icons
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _greeting(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.4),
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            name,
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
                    _headerBtn(
                      Icons.notifications_outlined,
                      badge: unread > 0,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationCenterPage()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _headerBtn(
                      Icons.person_outline_rounded,
                      onTap: () => ref.read(currentTabProvider.notifier).state = 4,
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                // Wordmark
                RichText(
                  text: const TextSpan(
                    text: 'Fiyat',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.0,
                      letterSpacing: -1.0,
                    ),
                    children: [
                      TextSpan(
                        text: 'Radar',
                        style: TextStyle(color: FRColors.tan),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'CANLI FİYAT İSTİHBARATI',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withOpacity(0.28),
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerBtn(IconData icon, {bool badge = false, required VoidCallback onTap}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
            ),
            child: Icon(icon, size: 18, color: Colors.white.withOpacity(0.75)),
          ),
        ),
        if (badge)
          Positioned(
            right: 8,
            top: 8,
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

  // ─── Search ──────────────────────────────────────────────────────────────

  Widget _buildSearch(BuildContext context) {
    return SliverToBoxAdapter(
      child: Transform.translate(
        offset: const Offset(0, -20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: _kPagePad),
          child: Container(
            decoration: BoxDecoration(
              color: FRColors.surface,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(color: Color(0x18170D08), blurRadius: 20, offset: Offset(0, 6)),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => ref.read(currentTabProvider.notifier).state = 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, color: FRColors.tan, size: 21),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Ürün, marka veya kategori ara...',
                          style: TextStyle(
                            color: FRColors.textSubtle,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          final code = await BarcodeScannerSheet.scan(context);
                          if (!mounted || code == null || code.trim().isEmpty) return;
                          ref.read(searchQueryProvider.notifier).state = code.trim();
                          ref.read(currentTabProvider.notifier).state = 1;
                        },
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: FRColors.backgroundWarm,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.qr_code_scanner_rounded,
                            size: 16,
                            color: FRColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Alert strip ─────────────────────────────────────────────────────────

  Widget _buildAlertStrip(BuildContext context, NotificationItem alert) {
    return SliverToBoxAdapter(
      child: GestureDetector(
        onTap: (alert.productId ?? '').trim().isEmpty
            ? null
            : () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(productId: alert.productId!)),
                ),
        child: Container(
          margin: const EdgeInsets.fromLTRB(_kPagePad, 0, _kPagePad, _kSectionGap - 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: FRColors.espresso,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: FRColors.tan.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.notifications_active_rounded, size: 18, color: FRColors.tan),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'HEDEF FİYATA ULAŞILDI',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: FRColors.tan,
                        letterSpacing: 0.8,
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
              const Icon(Icons.chevron_right_rounded, color: FRColors.textMuted, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Live feed ───────────────────────────────────────────────────────────

  Widget _buildLiveFeed(
    BuildContext context,
    List<PriceModel> prices,
    Map<String, double> changeMap,
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: _kPagePad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionRow(
              'CANLI FİYATLAR',
              Icons.bolt_rounded,
              onMore: () => ref.read(currentTabProvider.notifier).state = 1,
            ),
            const SizedBox(height: 14),
            prices.isEmpty
                ? _emptyFeed()
                : Container(
                    decoration: BoxDecoration(
                      color: FRColors.surface,
                      borderRadius: BorderRadius.circular(_kCardRadius),
                      boxShadow: const [_kCardShadow],
                    ),
                    child: Column(
                      children: [
                        ...List.generate(prices.take(5).length, (i) {
                          final p = prices[i];
                          return Column(
                            children: [
                              if (i > 0)
                                const Divider(
                                  height: 1,
                                  indent: 76,
                                  color: Color(0x0C211510),
                                ),
                              _feedRow(context, p, changeMap[p.productId]),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _feedRow(BuildContext context, PriceModel p, double? change) {
    return InkWell(
      onTap: p.productId.trim().isNotEmpty
          ? () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: p.productId)),
              )
          : null,
      borderRadius: BorderRadius.circular(_kCardRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: FRColors.backgroundWarm,
                borderRadius: BorderRadius.circular(12),
              ),
              child: p.imageUrl?.isNotEmpty == true
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(imageUrl: p.imageUrl!, fit: BoxFit.cover),
                    )
                  : const Icon(Icons.category_outlined, size: 20, color: FRColors.tan),
            ),
            const SizedBox(width: 12),
            // Name + store
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.productName ?? 'Ürün',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: FRColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${p.storeName ?? 'Mağaza'} · ${_timeAgo(p.createdAt)}',
                    style: const TextStyle(fontSize: 11, color: FRColors.textSubtle),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Price + change
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatTRY(p.price),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: FRColors.tan,
                  ),
                ),
                if (change != null && change.abs() >= 1) ...[
                  const SizedBox(height: 3),
                  _changeBadge(change),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyFeed() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36),
      decoration: BoxDecoration(
        color: FRColors.surface,
        borderRadius: BorderRadius.circular(_kCardRadius),
        boxShadow: const [_kCardShadow],
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: FRColors.backgroundWarm,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.bolt_outlined, size: 26, color: FRColors.textSubtle),
          ),
          const SizedBox(height: 14),
          const Text(
            'Henüz canlı fiyat yok',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: FRColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'İlk fiyatı sen ekle!',
            style: TextStyle(fontSize: 12, color: FRColors.textSubtle),
          ),
        ],
      ),
    );
  }

  // ─── Watchlist ───────────────────────────────────────────────────────────

  Widget _buildWatchlist(BuildContext context, List<ProductModel> list) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(_kPagePad, _kSectionGap, _kPagePad, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionRow(
              'TAKİP LİSTEM',
              Icons.bookmark_rounded,
              count: list.length,
              onMore: () => ref.read(currentTabProvider.notifier).state = 4,
            ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: FRColors.surface,
                borderRadius: BorderRadius.circular(_kCardRadius),
                boxShadow: const [_kCardShadow],
              ),
              child: Column(
                children: List.generate(list.take(3).length, (i) {
                  final item = list[i];
                  return Column(
                    children: [
                      if (i > 0) const Divider(height: 1, indent: 68, color: Color(0x0C211510)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: FRColors.backgroundWarm,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.bookmark_rounded, size: 18, color: FRColors.tan),
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
                            const SizedBox(width: 10),
                            Text(
                              (item.lastPrice ?? 0) > 0 ? formatTRY(item.lastPrice ?? 0) : '—',
                              style: const TextStyle(
                                fontSize: 14,
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Trending ────────────────────────────────────────────────────────────

  Widget _buildTrending(BuildContext context, List<ProductModel> products) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, _kSectionGap, 0, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: _kPagePad),
              child: _sectionRow(
                'SEÇKİLER',
                Icons.explore_rounded,
                onMore: () => ref.read(currentTabProvider.notifier).state = 1,
                moreLabel: 'Keşfet',
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 196,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(left: _kPagePad, right: 8),
                itemCount: products.length > 6 ? 6 : products.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (ctx, i) => _trendCard(ctx, products[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _trendCard(BuildContext context, ProductModel p) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: p.id)),
      ),
      child: Container(
        width: 152,
        decoration: BoxDecoration(
          color: FRColors.surface,
          borderRadius: BorderRadius.circular(_kCardRadius),
          boxShadow: const [_kCardShadow],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                Container(
                  height: 116,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: FRColors.backgroundWarm,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(_kCardRadius)),
                  ),
                  child: p.effectiveImage?.isNotEmpty == true
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(_kCardRadius)),
                          child: CachedNetworkImage(
                            imageUrl: p.effectiveImage!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        )
                      : const Center(child: Icon(Icons.category_outlined, size: 38, color: FRColors.tan)),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: FRColors.espresso.withOpacity(0.88),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _badge(p),
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        color: FRColors.tan,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: FRColors.textPrimary,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    (p.lastPrice ?? 0) > 0 ? formatTRY(p.lastPrice ?? 0) : '—',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
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

  // ─── Shared UI pieces ────────────────────────────────────────────────────

  Widget _sectionRow(
    String label,
    IconData icon, {
    int? count,
    VoidCallback? onMore,
    String moreLabel = 'Tümü',
  }) {
    return Row(
      children: [
        Icon(icon, size: 13, color: FRColors.tan),
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
        if (count != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: FRColors.tan.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: FRColors.tan,
              ),
            ),
          ),
        ],
        const Spacer(),
        if (onMore != null)
          GestureDetector(
            onTap: onMore,
            child: Text(
              moreLabel,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: FRColors.tan,
              ),
            ),
          ),
      ],
    );
  }

  Widget _changeBadge(double pct) {
    final down = pct <= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: down ? FRColors.successSurface : FRColors.dangerSurface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${down ? '↓' : '↑'} ${pct.abs().toStringAsFixed(0)}%',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: down ? FRColors.success : FRColors.danger,
        ),
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  String _greeting() {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 11) return 'Günaydın';
    if (h >= 11 && h < 18) return 'İyi günler';
    if (h >= 18 && h < 23) return 'İyi akşamlar';
    return 'İyi geceler';
  }

  String _timeAgo(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inSeconds < 60) return '${d.inSeconds}s';
    if (d.inMinutes < 60) return '${d.inMinutes}d';
    if (d.inHours < 24) return '${d.inHours}s';
    return '${d.inDays}g';
  }

  Map<String, double> _priceChangeMap(List<PriceModel> prices) {
    final grouped = <String, List<PriceModel>>{};
    for (final p in prices) {
      grouped.putIfAbsent(p.productId, () => []).add(p);
    }
    final result = <String, double>{};
    for (final e in grouped.entries) {
      if (e.value.length < 2) continue;
      final sorted = [...e.value]..sort((a, b) => b.reportedAt.compareTo(a.reportedAt));
      final latest = sorted.first.price;
      final prev = sorted[1].price;
      if (prev > 0) result[e.key] = ((latest - prev) / prev) * 100;
    }
    return result;
  }

  String _badge(ProductModel p) {
    if (p.priceEntryCount <= 2) return 'YENİ';
    if (p.isEditorPick) return 'FIRSAT';
    return 'TREND';
  }
}
