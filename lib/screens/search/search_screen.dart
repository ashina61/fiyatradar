import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/explore_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/theme.dart';
import '../product/product_detail_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String>(selectedCategoryFilterProvider, (prev, next) {
      if (next != 'Tumu') {
        ref.read(exploreControllerProvider.notifier).updateCategory(next);
        Future.microtask(
          () => ref.read(selectedCategoryFilterProvider.notifier).state = 'Tumu',
        );
      }
    });

    final theme = Theme.of(context);
    final state = ref.watch(exploreControllerProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            children: [
              _buildSearchBar(theme, state),
              _buildModeTabs(theme, state),
              _buildCategoryChips(theme, state),
              Expanded(child: _buildBody(theme, state)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, ExploreState state) {
    if (state.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Keşfet akışı yüklenemedi',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                state.error!,
                style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () => ref.read(exploreControllerProvider.notifier).retry(),
                child: const Text('Tekrar dene'),
              ),
            ],
          ),
        ),
      );
    }

    return _buildExploreList(theme, state);
  }

  Widget _buildSearchBar(ThemeData theme, ExploreState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Material(
        elevation: 1,
        shadowColor: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          onChanged: (value) {
            ref.read(exploreControllerProvider.notifier).updateSearchQuery(value);
            if (value.trim().isNotEmpty) {
              ref.read(userNotifierProvider.notifier).saveSearch(value.trim());
            }
          },
          style: theme.textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: 'Mahallende ürün, mağaza veya kategori ara…',
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
            suffixIcon: state.searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded),
                    splashRadius: 18,
                    onPressed: () {
                      _searchController.clear();
                      ref.read(exploreControllerProvider.notifier).updateSearchQuery('');
                    },
                  )
                : null,
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeTabs(ThemeData theme, ExploreState state) {
    const modes = <MapEntry<ExploreMode, String>>[
      MapEntry(ExploreMode.nearby, 'Yakınımda'),
      MapEntry(ExploreMode.online, 'Online'),
      MapEntry(ExploreMode.drops, 'Düşenler'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
      child: Row(
        children: [
          for (final mode in modes)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Center(child: Text(mode.value)),
                  selected: state.selectedMode == mode.key,
                  onSelected: (_) => ref.read(exploreControllerProvider.notifier).updateMode(mode.key),
                  showCheckmark: false,
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  side: BorderSide(
                    color: state.selectedMode == mode.key ? AppColors.primary : AppColors.outline,
                  ),
                  labelStyle: theme.textTheme.bodySmall?.copyWith(
                    color: state.selectedMode == mode.key ? AppColors.textOnPrimary : AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips(ThemeData theme, ExploreState state) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: state.categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final label = state.categories[index];
          final selected = state.selectedCategory == label;

          return FilterChip(
            label: Text(label),
            selected: selected,
            onSelected: (_) => ref.read(exploreControllerProvider.notifier).updateCategory(label),
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.surface,
            showCheckmark: false,
            labelStyle: TextStyle(
              color: selected ? AppColors.textOnPrimary : AppColors.textPrimary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 13,
            ),
            side: BorderSide(
              color: selected ? AppColors.primary : AppColors.outline,
              width: 1,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          );
        },
      ),
    );
  }

  Widget _buildExploreList(ThemeData theme, ExploreState state) {
    if (state.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Henüz bu filtrede fiyat yok',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: () => ref.read(exploreControllerProvider.notifier).retry(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Yenile'),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 96),
      itemCount: state.items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 310,
      ),
      itemBuilder: (context, index) {
        final item = state.items[index];
        return _ExplorePriceCard(
          item: item,
          mode: state.selectedMode,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(productId: item.product.id),
            ),
          ),
          onStoreTap: () => _handleStoreTap(context, item),
          onOnlineStoreTap: (storePrice) => _openUrl(context, storePrice.url),
        );
      },
    );
  }

  Future<void> _handleStoreTap(BuildContext context, ExploreFeedItem item) async {
    if (item.isLocalStore) {
      final lat = item.store?.lat ?? item.price.geoPoint?.latitude;
      final lng = item.store?.lng ?? item.price.geoPoint?.longitude;
      if (lat == null || lng == null || lat == 0 || lng == 0) {
        _showSnack(context, 'Konum bilgisi bulunamadı');
        return;
      }
      final mapsUri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
      );
      final launched = await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        _showSnack(context, 'Google Maps açılamadı');
      }
      return;
    }

    await _openUrl(context, item.storeUrl);
  }

  Future<void> _openUrl(BuildContext context, String? rawUrl) async {
    if (rawUrl == null || rawUrl.trim().isEmpty) {
      _showSnack(context, 'Bağlantı bulunamadı');
      return;
    }
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null) {
      _showSnack(context, 'Bağlantı geçersiz');
      return;
    }
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      _showSnack(context, 'Bağlantı açılamadı');
    }
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ExplorePriceCard extends StatelessWidget {
  final ExploreFeedItem item;
  final ExploreMode mode;
  final VoidCallback onTap;
  final VoidCallback onStoreTap;
  final ValueChanged<StorePrice> onOnlineStoreTap;

  const _ExplorePriceCard({
    required this.item,
    required this.mode,
    required this.onTap,
    required this.onStoreTap,
    required this.onOnlineStoreTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locationText = item.locationLabel.trim();
    final hasLocation = locationText.isNotEmpty;
    final distanceText = item.distanceLabel?.trim();
    final hasDistance = distanceText != null && distanceText.isNotEmpty;

    return Card(
      color: AppColors.surface,
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.outline),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildImage(),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _Badge(
                      label: '⏱ ${_timeAgo(item.price.createdAt)}',
                      color: Colors.black.withOpacity(0.55),
                      textColor: Colors.white,
                    ),
                  ),
                  if (item.dropPercent > 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _Badge(
                        label: '▼ %${item.dropPercent.round()}',
                        color: AppColors.primary.withOpacity(0.9),
                        textColor: AppColors.textOnPrimary,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '₺${_formatPrice(item.displayPrice)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: onStoreTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.outline),
                        boxShadow: mode == ExploreMode.nearby && item.isNearby
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.35),
                                  blurRadius: 18,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.storefront_rounded, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              item.storeName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (hasLocation) ...[
                    Divider(
                      height: 14,
                      thickness: 0.6,
                      color: Colors.black.withOpacity(0.08),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            locationText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                        if (hasDistance) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: AppColors.outline),
                            ),
                            child: Text(
                              distanceText,
                              maxLines: 1,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                  if (mode == ExploreMode.online) ...[
                    const SizedBox(height: 6),
                    Text(
                      'En ucuz 3',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: item.onlineCheapest3
                            .map(
                              (storePrice) => Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: _OnlineStoreChip(
                                  storePrice: storePrice,
                                  isBest: item.onlineCheapest3.isNotEmpty && item.onlineCheapest3.first == storePrice,
                                  onTap: storePrice.url == null ? null : () => onOnlineStoreTap(storePrice),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    final imageUrl =
        item.product.mainImage ?? (item.product.imageUrls.isNotEmpty ? item.product.imageUrls.first : null);
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        color: Colors.grey.shade200,
        child: const Center(
          child: Icon(Icons.shopping_bag_outlined, size: 42, color: AppColors.textSecondary),
        ),
      );
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey.shade200,
        child: const Center(
          child: Icon(Icons.shopping_bag_outlined, size: 42, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _OnlineStoreChip extends StatelessWidget {
  final StorePrice storePrice;
  final bool isBest;
  final VoidCallback? onTap;

  const _OnlineStoreChip({required this.storePrice, required this.isBest, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: onTap == null
              ? AppColors.surfaceVariant.withOpacity(0.5)
              : isBest
                  ? AppColors.primary.withOpacity(0.08)
                  : AppColors.surfaceVariant,
          border: Border.all(
            color: isBest ? AppColors.primary.withOpacity(0.2) : AppColors.outline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.store_mall_directory_rounded, size: 13),
            const SizedBox(width: 4),
            Text(
              '${storePrice.storeName} ₺${_formatPrice(storePrice.price)}',
              style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 4),
            Icon(Icons.north_east_rounded, size: 12, color: onTap == null ? AppColors.textSecondary : AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const _Badge({required this.label, required this.color, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

String _timeAgo(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'şimdi';
  if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
  if (diff.inHours < 24) return '${diff.inHours} sa önce';
  return '${diff.inDays} gün önce';
}

String _formatPrice(double price) {
  if (price >= 1000) {
    final parts = price.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final decPart = parts[1];
    final buffer = StringBuffer();
    for (var i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buffer.write('.');
      buffer.write(intPart[i]);
    }
    return '$buffer,$decPart';
  }
  return price.toStringAsFixed(2).replaceAll('.', ',');
}
