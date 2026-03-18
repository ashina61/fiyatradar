import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
import '../../widgets/banner_card.dart';
import '../../widgets/premium_pressable.dart';
import '../add_price/add_price_screen.dart';
import '../main_screen.dart';
import '../points/points_screen.dart';
import '../product/product_detail_screen.dart';
import '../../theme/fr_colors.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
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
    final usersAsync = ref.watch(allUsersProvider);
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
              color: Color(0x1A211510),
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
                child: _buildCategories(context, categoriesAsync.valueOrNull ?? const []),
              ),
              const SliverToBoxAdapter(
                child: PremiumBannerSection(),
              ),
              SliverToBoxAdapter(
                child: _buildInsightGrid(
                  latestPrices,
                  usersAsync.valueOrNull ?? const <UserModel>[],
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
                child: _buildEditorChoice(
                  context,
                  editorPickProduct,
                ),
              ),
              SliverToBoxAdapter(
                child: _buildLatestPrices(latestPrices),
              ),
              SliverToBoxAdapter(
                child: _buildLeaders(usersAsync.valueOrNull ?? const []),
              ),
              SliverToBoxAdapter(child: _buildFooter(context)),
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
    final displayName = user?.preferredDisplayName ?? 'Radar Kullanıcısı';
    final points = user?.points ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(24, topPadding + 16, 24, 50),
            decoration: const BoxDecoration(
              color: FRColors.espressoSoft,
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
                    border: Border.all(color: FRColors.camelStrong, width: 1.5),
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
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: FRColors.espressoSoft,
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
                      Text(
                        _greetingByHour(),
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w600,
                          color: FRColors.camelStrong,
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
                  onTap: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => const PointsScreen())),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.stars_rounded,
                            color: FRColors.camelStrong, size: 16),
                        const SizedBox(width: 6),
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
                const SizedBox(width: 8),
                PremiumPressable(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NotificationCenterPage()),
                  ),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
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
                    const SizedBox(width: 12),
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
                      borderRadius: BorderRadius.circular(14),
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
                          borderRadius: BorderRadius.circular(14),
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
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
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
                  padding: const EdgeInsets.only(left: 10),
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
      borderRadius: BorderRadius.circular(100),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? FRColors.espressoSoft : FRColors.surface,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isActive ? FRColors.espressoSoft : FRColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: isActive ? const Color(0x2B211510) : FRColors.shadowSoft,
              blurRadius: isActive ? 16 : 12,
              offset: const Offset(0, 4),
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
            const SizedBox(width: 6),
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


  Widget _buildInsightGrid(
    List<PriceModel> latestPrices,
    List<UserModel> users,
  ) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));

    final todaysPriceEntries = latestPrices.where((price) {
      final dt = price.reportedAt;
      return !dt.isBefore(todayStart) && dt.isBefore(tomorrowStart);
    }).length;

    final todaysNewUsers = users.where((user) {
      final dt = user.createdAt;
      return !dt.isBefore(todayStart) && dt.isBefore(tomorrowStart);
    }).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(title: 'Bugünün Özeti', action: 'Tüm Analizler'),
          const SizedBox(height: 6),
          GridView.count(
            primary: false,
            padding: EdgeInsets.zero,
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 10,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            childAspectRatio: 1.0,
            children: [
              _insightCard(
                icon: Icons.price_change_rounded,
                iconBg: FRColors.sapphireSurface,
                iconColor: FRColors.sapphire,
                label: 'BUGÜN GİRİLEN FİYAT',
                value: '$todaysPriceEntries',
                meta: 'Bugün sisteme eklenen toplam fiyat bildirimi sayısı.',
              ),
              _insightCard(
                icon: Icons.person_add_alt_1_rounded,
                iconBg: FRColors.successSurface,
                iconColor: FRColors.success,
                label: 'BUGÜN KAYDOLAN',
                value: '$todaysNewUsers',
                meta: 'Bugün uygulamaya yeni kayıt olan kullanıcı sayısı.',
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: _cardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: FRColors.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w900,
              color: FRColors.espressoSoft,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            meta,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.5,
              color: FRColors.textMuted,
              height: 1.32,
            ),
          ),
        ],
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
      padding: const EdgeInsets.only(top: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _sectionTitle(
              title: 'Trend Ürünler',
              action: 'Tümünü Gör',
              badge: const _PopularBadge(),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 258,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final product = products[index];
                final hasPrice = (product.lastPrice ?? 0) > 0;
                final trend = trendByProduct[product.id];
                final hasReliableTrend = trend != null && trend.isFinite && trend.abs() >= 0.1;

                return PremiumPressable(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(productId: product.id),
                    ),
                  ),
                  child: Container(
                    width: 174,
                    decoration: _cardDecoration(radius: 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 136,
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                          decoration: const BoxDecoration(
                            color: FRColors.studio,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 6),
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
                              if (hasReliableTrend)
                                Positioned(
                                  left: 0,
                                  top: 0,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: FRColors.shadowStrong,
                                          blurRadius: 12,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: _TrendBadge(changePercent: trend),
                                  ),
                                ),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: FRColors.surface.withOpacity(0.9),
                                    shape: BoxShape.circle,
                                    boxShadow: const [
                                      BoxShadow(
                                        color: FRColors.shadowStrong,
                                        blurRadius: 10,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    savedProducts.contains(product.id)
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    color: savedProducts.contains(product.id)
                                        ? FRColors.danger
                                        : FRColors.textMuted,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.brand.isNotEmpty ? product.brand : 'Marka yok',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: FRColors.textMuted,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  product.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    height: 1.25,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  product.lastStore ?? 'Mağaza bilgisi yok',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: FRColors.textMuted,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  hasPrice
                                      ? formatTRY(product.lastPrice ?? 0)
                                      : 'Fiyat bekleniyor',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: hasPrice ? 17 : 11,
                                    fontWeight: hasPrice ? FontWeight.w900 : FontWeight.w600,
                                    color: hasPrice ? FRColors.espressoSoft : FRColors.textMuted,
                                  ),
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
              separatorBuilder: (_, __) => const SizedBox(width: 12),
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            title: 'Editörün Seçimi',
            badge: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: FRColors.camelStrong,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_rounded,
                      size: 12, color: FRColors.espressoSoft),
                  SizedBox(width: 4),
                  Text(
                    'ONAYLI',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: FRColors.espressoSoft,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          PremiumPressable(
            borderRadius: BorderRadius.circular(24),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProductDetailScreen(productId: product.id),
              ),
            ),
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                color: FRColors.espressoSoft,
                borderRadius: BorderRadius.circular(24),
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
                      padding: const EdgeInsets.all(20),
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
                          const SizedBox(height: 6),
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
                          const SizedBox(height: 12),
                          Text(
                            hasPrice
                                ? formatTRY(product.lastPrice ?? 0)
                                : 'Fiyat bilgisi bekleniyor',
                            style: TextStyle(
                              color: hasPrice
                                  ? FRColors.surface
                                  : Colors.white.withOpacity(0.7),
                              fontSize: hasPrice ? 22 : 13,
                              fontWeight:
                                  hasPrice ? FontWeight.w900 : FontWeight.w600,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: FRColors.camelStrong,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  product.lastStore ?? 'Mağaza',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: FRColors.espressoSoft,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.open_in_new_rounded,
                                  size: 13,
                                  color: FRColors.espressoSoft,
                                ),
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
                        color: Colors.white.withOpacity(0.03),
                        border: Border(
                          left:
                              BorderSide(color: Colors.white.withOpacity(0.05)),
                        ),
                        borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(24),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
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
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(title: 'Son Eklenen Fiyatlar', action: 'Tümünü Gör'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: _cardDecoration(radius: 24),
            child: Column(
              children: [
                for (int i = 0; i < rows.length; i++)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
              BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
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
        const SizedBox(width: 14),
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
              const SizedBox(height: 2),
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
            const SizedBox(height: 2),
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
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(productId: productId),
        ),
      ),
      child: row,
    );
  }

  Widget _buildLeaders(List<UserModel> users) {
    if (users.isEmpty) return const SizedBox.shrink();

    final leaders = [...users]
      ..sort((a, b) {
        final byPoints = b.points.compareTo(a.points);
        if (byPoints != 0) return byPoints;
        final byTrust = b.trustScorePercent.compareTo(a.trustScorePercent);
        if (byTrust != 0) return byTrust;
        return b.priceEntries.compareTo(a.priceEntries);
      });

    final topLeaders = leaders.take(2).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(title: 'Öne Çıkan Avcılar', action: 'Liderlik'),
          const SizedBox(height: 16),
          ...topLeaders.asMap().entries.map((entry) {
            final rank = entry.key + 1;
            final user = entry.value;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: _cardDecoration(radius: 20),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: rank == 1
                          ? const LinearGradient(
                              colors: [FRColors.camelStrong, FRColors.camelDeep],
                            )
                          : const LinearGradient(
                              colors: [FRColors.silver, FRColors.silverDeep],
                            ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _initials(user.displayName ?? user.username),
                      style: const TextStyle(
                        color: FRColors.surface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName ?? user.username,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Bu hafta ${user.priceEntries} doğrulanmış fiyat',
                          style: const TextStyle(
                            fontSize: 11,
                            color: FRColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: FRColors.studio,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '%${user.trustScorePercent}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: FRColors.espressoSoft,
                          ),
                        ),
                        const Text(
                          'GÜVEN',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: FRColors.textMuted,
                          ),
                        ),
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

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 160),
      child: Column(
        children: [
          PremiumPressable(
            borderRadius: BorderRadius.circular(20),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AddPriceScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: FRColors.espressoSoft,
                borderRadius: BorderRadius.circular(20),
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
                  PremiumPressable(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () async {
                      final barcode = await BarcodeScannerSheet.scan(context);
                      if (!mounted || barcode == null || barcode.trim().isEmpty) {
                        return;
                      }
                      ref.read(searchQueryProvider.notifier).state = barcode.trim();
                      ref.read(currentTabProvider.notifier).state = 1;
                    },
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: FRColors.camelStrong,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner_rounded,
                        color: FRColors.espressoSoft,
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
      borderRadius: BorderRadius.circular(radius),
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

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'FR';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }
}

class _TrendBadge extends StatelessWidget {
  const _TrendBadge({required this.changePercent});

  final double changePercent;

  @override
  Widget build(BuildContext context) {
    final isUp = changePercent > 0;
    final color = isUp ? FRColors.danger : FRColors.success;
    final bgColor = isUp ? FRColors.dangerSurface : FRColors.successSurface;
    final arrow = isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(arrow, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            '%${changePercent.abs().toStringAsFixed(1)}',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _PopularBadge extends StatelessWidget {
  const _PopularBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: FRColors.camelOverlay(0.15),
        borderRadius: BorderRadius.circular(6),
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
