import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/category_model.dart';
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
import '../../widgets/editor_choice_widgets.dart';
import '../../widgets/home_product_card.dart';
import '../../widgets/market_badge.dart';
import '../../widgets/premium_pressable.dart';
import '../add_price/add_price_screen.dart';
import '../main_screen.dart';
import '../points/points_screen.dart';
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
  Future<void> _launchAffiliateLink(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userModelStreamProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final trendingAsync = ref.watch(trendingProductsProvider);
    final latestPricesAsync = ref.watch(latestPricesProvider);
    final unreadCount = ref.watch(unreadCountProvider);

    final trendingProducts = trendingAsync.valueOrNull ?? const <ProductModel>[];
    final latestPrices = latestPricesAsync.valueOrNull ?? const <PriceModel>[];
    final editorPickAsync = ref.watch(editorPickProductsProvider);
    final editorPickProduct = editorPickAsync.valueOrNull?.isNotEmpty == true
        ? editorPickAsync.valueOrNull!.first
        : null;

    return Scaffold(
      backgroundColor: FRColors.background,
      body: Stack(
        children: [
          Positioned(
            top: 220,
            right: -90,
            child: _ambientBlob(
              size: 200,
              color: FRColors.borderStrong,
            ),
          ),
          Positioned(
            bottom: 160,
            left: -72,
            child: _ambientBlob(
              size: 180,
              color: FRColors.espressoOverlay(0.10),
            ),
          ),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _buildHeader(
                  context,
                  userAsync.valueOrNull,
                  unreadCount,
                ),
              ),
              SliverToBoxAdapter(
                child: _buildTrendProducts(
                  context,
                  trendingProducts,
                  latestPrices,
                  userAsync.valueOrNull?.savedProducts.toSet() ??
                      const <String>{},
                ),
              ),
              SliverToBoxAdapter(
                child: _buildLatestPrices(latestPrices),
              ),
              SliverToBoxAdapter(child: _buildFooter(context)),
              SliverToBoxAdapter(
                child: _buildCategories(
                  context,
                  categoriesAsync.valueOrNull ?? const [],
                ),
              ),
              SliverToBoxAdapter(
                child: _buildEditorChoice(
                  context,
                  editorPickProduct,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ambientBlob({required double size, required Color color}) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserModel? user, int unreadCount) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final displayName = user?.username.trim().isNotEmpty == true ? user!.username.trim() : (user?.preferredDisplayName ?? 'Radar Kullanıcısı');
    final points = user?.points ?? 0;

    return Padding(
      padding: FRSpaceInsets.bottomXl,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: FRSpaceInsets.headerWithTop(topPadding, bottom: FRSpacing.heroHeaderBottom),
            decoration: BoxDecoration(
              color: FRColors.espressoSoft,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(FRRadius.hero),
                bottomRight: Radius.circular(FRRadius.hero),
              ),
              boxShadow: [
                BoxShadow(
                  color: FRColors.espressoOverlay(0.20),
                  blurRadius: 30,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                PremiumPressable(
                  borderRadius: FRRadius.lgRadius,
                  onTap: () => ref.read(currentTabProvider.notifier).state = 4,
                  child: Container(
                    width: 50,
                    height: 50,
                    padding: FRSpaceInsets.allXxs,
                    decoration: BoxDecoration(
                      border: Border.all(color: FRColors.camelStrong, width: 1.5),
                      borderRadius: FRRadius.lgRadius,
                    ),
                    child: ClipRRect(
                      borderRadius: FRRadius.mdRadius,
                      child: user?.photoUrl != null
                          ? CachedNetworkImage(imageUrl: user!.photoUrl!, fit: BoxFit.cover)
                          : Container(
                              color: FRColors.studio,
                              alignment: Alignment.center,
                              child: Text(
                                displayName.characters.first.toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: FRColors.espressoSoft,
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: FRSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _greetingByHour(),
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w600,
                          color: FRColors.camelStrong,
                        ),
                      ),
                      const SizedBox(height: FRSpacing.xxs),
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
                  borderRadius: FRRadius.pillRadius,
                  onTap: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => const PointsScreen())),
                  child: Container(
                    padding:
                        FRSpaceInsets.pointsChip,
                    decoration: BoxDecoration(
                      color: FRColors.white.withOpacity(0.08),
                      border: Border.all(color: FRColors.white.withOpacity(0.1)),
                      borderRadius: FRRadius.pillRadius,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.stars_rounded,
                            color: FRColors.camelStrong, size: 16),
                        const SizedBox(width: FRSpacing.xsPlus),
                        Text(
                          formatCompactCount(points),
                          style: const TextStyle(
                            color: FRColors.camelStrong,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: FRSpacing.sm),
                PremiumPressable(
                  borderRadius: FRRadius.mdPlusRadius,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NotificationCenterPage()),
                  ),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: FRColors.white.withOpacity(0.05),
                      borderRadius: FRRadius.mdPlusRadius,
                      border: Border.all(color: FRColors.white.withOpacity(0.1)),
                    ),
                    child: Stack(
                      children: [
                        const Center(
                          child: Icon(
                            Icons.notifications_rounded,
                            color: FRColors.surface,
                            size: 20,
                          ),
                        ),
                        if (unreadCount > 0)
                          const Positioned(
                            right: 11,
                            top: 11,
                            child: CircleAvatar(
                              radius: 3,
                              backgroundColor: FRColors.danger,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: FRSpacing.xxl,
            right: FRSpacing.xxl,
            bottom: -FRSpacing.xxl,
            child: PremiumPressable(
              borderRadius: FRRadius.xlRadius,
              onTap: () => ref.read(currentTabProvider.notifier).state = 1,
              child: Container(
                padding: FRSpaceInsets.searchBar,
                decoration: BoxDecoration(
                  color: FRColors.surface,
                  borderRadius: FRRadius.xlRadius,
                  boxShadow: const [
                    BoxShadow(
                      color: FRColors.shadowMedium,
                      blurRadius: 35,
                      offset: Offset(0, 15),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded,
                        color: FRColors.textMuted, size: 22),
                    const SizedBox(width: FRSpacing.md),
                    const Expanded(
                      child: Text(
                        'Ürün, marka veya mağaza ara...',
                        style: TextStyle(
                          color: FRColors.textSubtle,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    PremiumPressable(
                      borderRadius: FRRadius.mdPlusRadius,
                      onTap: () async {
                        final barcode = await BarcodeScannerSheet.scan(context);
                        if (!mounted || barcode == null || barcode.trim().isEmpty) {
                          return;
                        }
                        ref.read(searchQueryProvider.notifier).state = barcode.trim();
                        ref.read(currentTabProvider.notifier).state = 1;
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: FRColors.studio,
                          borderRadius: FRRadius.mdPlusRadius,
                        ),
                        child: const Icon(
                          Icons.qr_code_scanner_rounded,
                          color: FRColors.espressoSoft,
                          size: 20,
                        ),
                      ),
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

  Widget _buildCategories(BuildContext context, List<CategoryModel> categories) {
    final selectedCategory = ref.watch(selectedCategoryFilterProvider);

    return Padding(
      padding: FRSpaceInsets.sectionTop,
      child: SizedBox(
        height: 46,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _categoryPill(
                title: 'Tümü',
                icon: Icons.grid_view_rounded,
                isActive: selectedCategory == 'Tumu',
                onTap: () {
                  ref.read(selectedCategoryFilterProvider.notifier).state = 'Tumu';
                  ref.read(selectedCategoryIdProvider.notifier).state = null;
                  ref.read(currentTabProvider.notifier).state = 1;
                },
              ),
              ...categories.map(
                (item) => Padding(
                  padding: FRSpaceInsets.leftSmPlus,
                  child: _categoryPill(
                    title: item.title,
                    icon: _categoryIcon(item.title),
                    isActive: selectedCategory == item.title,
                    onTap: () {
                      ref.read(selectedCategoryFilterProvider.notifier).state = item.title;
                      ref.read(selectedCategoryIdProvider.notifier).state = item.id;
                      ref.read(currentTabProvider.notifier).state = 1;
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryPill({
    required String title,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return PremiumPressable(
      borderRadius: FRRadius.pillRadius,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: FRSpaceInsets.categoryPill,
        decoration: BoxDecoration(
          color: isActive ? FRColors.espressoSoft : FRColors.surface,
          borderRadius: FRRadius.pillRadius,
          border: Border.all(
            color: isActive ? FRColors.espressoSoft : FRColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: isActive ? FRColors.espressoOverlay(0.17) : FRColors.shadowSoft,
              blurRadius: isActive ? 16 : 12,
              offset: Offset(0, FRSpacing.xs),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? FRColors.surface : FRColors.textMuted,
            ),
            const SizedBox(width: FRSpacing.xsPlus),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isActive ? FRColors.surface : FRColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildTrendProducts(
    BuildContext context,
    List<ProductModel> products,
    List<PriceModel> latestPrices,
    Set<String> savedProducts,
  ) {
    if (products.isEmpty) return const SizedBox.shrink();
    final trendByProduct = _resolveTrendByProduct(latestPrices);

    return Padding(
      padding: FRSpaceInsets.topXxxlPlus,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: FRSpaceInsets.horizontalXxl,
            child: _sectionTitle(
              title: 'Trend Ürünler',
              action: 'Tümünü Gör',
              badge: const _PopularBadge(),
            ),
          ),
          const SizedBox(height: FRSpacing.lg),
          SizedBox(
            height: 258,
            child: ListView.separated(
              padding: FRSpaceInsets.horizontalXxl,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final product = products[index];
                final hasPrice = (product.lastPrice ?? 0) > 0;
                final trend = trendByProduct[product.id];
                final hasReliableTrend = trend != null && trend.isFinite && trend.abs() >= 0.1;

                return HomeProductCard(
                  product: product,
                  width: 174,
                  trendPercent: hasReliableTrend ? trend : null,
                  isPriceRising: (trend ?? 0) > 0,
                  isSaved: savedProducts.contains(product.id),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(productId: product.id),
                    ),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: FRSpacing.md),
              itemCount: products.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorChoice(BuildContext context, ProductModel? product) {
    if (product == null) return const SizedBox.shrink();
    final hasPrice = (product.lastPrice ?? 0) > 0;
    final affiliateUrl = product.preferredAffiliateUrl;
    final hasAffiliate = affiliateUrl != null && affiliateUrl.isNotEmpty;

    return Padding(
      padding: FRSpaceInsets.sectionXxlTop,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            title: 'Editörün Seçimi',
            badge: const ApprovedBadge(),
          ),
          const SizedBox(height: FRSpacing.lg),
          PremiumPressable(
            borderRadius: FRRadius.xxlRadius,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProductDetailScreen(productId: product.id),
              ),
            ),
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                color: FRColors.espressoSoft,
                borderRadius: FRRadius.xxlRadius,
                border: Border.all(color: FRColors.borderStrong),
                boxShadow: const [
                  BoxShadow(
                    color: FRColors.shadowMedium,
                    blurRadius: 28,
                    offset: Offset(0, 14),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: Padding(
                      padding: FRSpaceInsets.allXl,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            product.brand.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              color: FRColors.camelStrong,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: FRSpacing.xsPlus),
                          Text(
                            product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              color: FRColors.surface,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: FRSpacing.md),
                          Text(
                            hasPrice
                                ? formatTRY(product.lastPrice ?? 0)
                                : 'Fiyat bilgisi bekleniyor',
                            style: TextStyle(
                              color: hasPrice
                                  ? FRColors.surface
                                  : FRColors.white.withOpacity(0.7),
                              fontSize: hasPrice ? 22 : 13,
                              fontWeight:
                                  hasPrice ? FontWeight.w900 : FontWeight.w600,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: FRSpacing.sm),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                MarketActionButton(
                                  label: (product.lastStore ?? '').trim().isNotEmpty
                                      ? product.lastStore!.trim()
                                      : 'Trendyol Market',
                                  onTap: hasAffiliate ? () => _launchAffiliateLink(affiliateUrl) : null,
                                ),
                                if (hasAffiliate) ...[
                                  const SizedBox(height: FRSpacing.smPlus),
                                  PremiumPressable(
                                    borderRadius: FRRadius.lgPlusRadius,
                                    onTap: () => _launchAffiliateLink(affiliateUrl),
                                    child: Container(
                                      padding: FRSpaceInsets.ctaChip,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            FRColors.ivory,
                                            FRColors.camel,
                                          ],
                                        ),
                                        borderRadius: FRRadius.lgPlusRadius,
                                        border: Border.all(color: FRColors.goldGlowSoft.withOpacity(0.85)),
                                        boxShadow: [
                                          BoxShadow(
                                            color: FRColors.espressoOverlay(0.20),
                                            blurRadius: 16,
                                            offset: Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Satın Al',
                                            style: TextStyle(
                                              color: FRColors.espressoSoft,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(width: FRSpacing.xsPlus),
                                          const Icon(
                                            Icons.open_in_new_rounded,
                                            size: 15,
                                            color: FRColors.espressoSoft,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: FRColors.white.withOpacity(0.03),
                        border: Border(
                          left:
                              BorderSide(color: FRColors.white.withOpacity(0.05)),
                        ),
                        borderRadius: BorderRadius.horizontal(
                          right: Radius.circular(FRRadius.xxl),
                        ),
                      ),
                      child: Padding(
                        padding: FRSpaceInsets.allXxl,
                        child: Center(
                          child: CachedNetworkImage(
                            imageUrl: product.effectiveImage ?? '',
                            fit: BoxFit.contain,
                            errorWidget: (_, __, ___) => const Icon(
                              Icons.image_not_supported_rounded,
                              color: FRColors.textMuted,
                            ),
                          ),
                        ),
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
      padding: FRSpaceInsets.sectionXxlTop,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(title: 'Son Eklenen Fiyatlar', action: 'Tümünü Gör'),
          const SizedBox(height: FRSpacing.lg),
          Container(
            padding: FRSpaceInsets.latestListContainer,
            decoration: _cardDecoration(radius: 24),
            child: Column(
              children: [
                for (int i = 0; i < rows.length; i++)
                  Container(
                    padding: FRSpaceInsets.verticalLg,
                    decoration: BoxDecoration(
                      border: i == rows.length - 1
                          ? null
                          : const Border(
                              bottom: BorderSide(color: FRColors.border),
                            ),
                    ),
                    child: _latestPriceRow(context, rows[i]),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _latestPriceRow(BuildContext context, PriceModel item) {
    final verificationDelta = item.upVotes - item.downVotes;
    final iconBg = verificationDelta == 0
        ? FRColors.studio
        : verificationDelta > 0
            ? FRColors.successSurface
            : FRColors.dangerSurface;
    final iconFg = verificationDelta == 0
        ? FRColors.textMuted
        : verificationDelta > 0
            ? FRColors.success
            : FRColors.danger;

    final verificationText = verificationDelta == 0
        ? 'Yeni'
        : verificationDelta > 0
            ? 'Doğrulama +$verificationDelta'
            : 'İtiraz ${verificationDelta.abs()}';

    final productId = item.productId.trim().isNotEmpty ? item.productId.trim() : null;

    final row = Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration:
              BoxDecoration(color: iconBg, borderRadius: FRRadius.mdRadius),
          child: Icon(
            verificationDelta == 0
                ? Icons.drag_handle_rounded
                : verificationDelta > 0
                    ? Icons.thumb_up_alt_rounded
                    : Icons.thumb_down_alt_rounded,
            color: iconFg,
            size: 18,
          ),
        ),
        const SizedBox(width: FRSpacing.mdPlus),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.productName ?? 'Ürün',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: FRSpacing.xxs),
              Text(
                '${item.storeName ?? 'Mağaza'} • ${item.userName ?? item.reporterName ?? 'Sistem'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: FRColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
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
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: FRColors.espressoSoft,
              ),
            ),
            const SizedBox(height: FRSpacing.xxs),
            Text(
              verificationText,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: iconFg,
              ),
            ),
          ],
        ),
      ],
    );

    if (productId == null) return row;
    return PremiumPressable(
      borderRadius: FRRadius.mdPlusRadius,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(productId: productId),
        ),
      ),
      child: row,
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: FRSpaceInsets.footer,
      child: Column(
        children: [
          PremiumPressable(
            borderRadius: FRRadius.xlRadius,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AddPriceScreen()),
            ),
            child: Container(
              padding: FRSpaceInsets.allXl,
              decoration: BoxDecoration(
                color: FRColors.espressoSoft,
                borderRadius: FRRadius.xlRadius,
                border: Border.all(color: FRColors.borderStrong),
                boxShadow: const [
                  BoxShadow(
                    color: FRColors.shadowMedium,
                    blurRadius: 30,
                    offset: Offset(0, 14),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fiyat Ekle, Puan Kazan!',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: FRColors.surface,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Topluluğa katıl ve radarın gücünü artır.',
                          style: TextStyle(
                            fontSize: 11,
                            color: FRColors.whiteMuted,
                          ),
                        ),
                      ],
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

  Widget _sectionTitle({
    required String title,
    String? action,
    Widget? badge,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: FRColors.textPrimary,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 10),
              badge,
            ],
          ],
        ),
        if (action != null)
          Text(
            action,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: FRColors.camelStrong,
            ),
          ),
      ],
    );
  }

  BoxDecoration _cardDecoration({double radius = 20}) {
    return BoxDecoration(
      color: FRColors.surface,
      borderRadius: FRRadius.all(radius),
      border: Border.all(color: FRColors.border),
      boxShadow: const [
        BoxShadow(
          color: FRColors.shadowSoft,
          blurRadius: 15,
          offset: Offset(0, 5),
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

  Map<String, double> _resolveTrendByProduct(List<PriceModel> latestPrices) {
    final grouped = <String, List<PriceModel>>{};
    for (final price in latestPrices) {
      final id = price.productId.trim();
      if (id.isEmpty) continue;
      grouped.putIfAbsent(id, () => <PriceModel>[]).add(price);
    }

    final trendMap = <String, double>{};
    grouped.forEach((productId, prices) {
      if (prices.length < 2) return;
      prices.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final current = prices[0].price;
      final previous = prices[1].price;
      if (previous <= 0) return;
      trendMap[productId] = ((current - previous) / previous) * 100;
    });

    return trendMap;
  }

  IconData _categoryIcon(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('market') || lower.contains('gıda')) {
      return Icons.shopping_cart_rounded;
    }
    if (lower.contains('tekno') || lower.contains('elektronik')) {
      return Icons.laptop_mac_rounded;
    }
    if (lower.contains('kozmetik') || lower.contains('bakım')) {
      return Icons.face_retouching_natural_rounded;
    }
    if (lower.contains('hobi') || lower.contains('spor')) {
      return Icons.sports_esports_rounded;
    }
    return Icons.category_rounded;
  }

}

class _PopularBadge extends StatelessWidget {
  const _PopularBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: FRSpaceInsets.popularBadge,
      decoration: BoxDecoration(
        color: FRColors.camelOverlay(0.15),
        borderRadius: FRRadius.xsRadius,
      ),
      child: const Row(
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            size: 12,
            color: FRColors.camelStrong,
          ),
          SizedBox(width: 4),
          Text(
            'POPÜLER',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: FRColors.camelStrong,
            ),
          ),
        ],
      ),
    );
  }
}
