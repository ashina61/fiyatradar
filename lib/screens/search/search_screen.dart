import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/explore_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/formatters.dart';
import '../../utils/theme.dart';
import '../../widgets/price_change_badge.dart';
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
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 260,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.8,
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

    _showSnack(context, 'Online mağaza bilgisi ürün detayında gösterilir');
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

  const _ExplorePriceCard({
    required this.item,
    required this.mode,
    required this.onTap,
    required this.onStoreTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locationText = item.locationLabel.trim();
    final hasLocation = locationText.isNotEmpty;
    final distanceText = item.distanceLabel?.trim();
    final hasDistance = distanceText != null && distanceText.isNotEmpty;
    final primaryCategory = item.product.categories.isNotEmpty ? item.product.categories.first : null;
    final extraCategoryCount = item.product.categories.length > 1 ? item.product.categories.length - 1 : 0;

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
                    top: 10,
                    left: 10,
                    child: _Badge(
                      label: '⏱ ${_timeAgo(item.price.createdAt)}',
                      color: Colors.black.withOpacity(0.55),
                      textColor: Colors.white,
                    ),
                  ),
                  if (item.priceChangePercent != null)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: PriceChangeBadge(percent: item.priceChangePercent!),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  if (primaryCategory != null && primaryCategory.trim().isNotEmpty) ...[
                    Row(
                      children: [
                        _CategoryChip(label: primaryCategory.trim()),
                        if (extraCategoryCount > 0) ...[
                          const SizedBox(width: 6),
                          _CategoryChip(label: '+$extraCategoryCount'),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                  Text(
                    item.product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatTRY(item.displayPrice),
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
                  if (item.isLocalStore) ...[
                    const SizedBox(height: 6),
                    Divider(
                      height: 12,
                      thickness: 0.7,
                      color: Colors.black.withOpacity(0.08),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            hasLocation ? locationText : 'Konum izni gerekli',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 84),
                          child: Text(
                            hasDistance ? distanceText : '',
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (mode == ExploreMode.online) ...[
                    const SizedBox(height: 8),
                    _OnlineCheapestSummaryRow(stores: item.onlineCheapest3),
                  ],
                  ],
                ),
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


class _CategoryChip extends StatelessWidget {
  final String label;

  const _CategoryChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.outline),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}


class _OnlineCheapestSummaryRow extends StatelessWidget {
  final List<StorePrice> stores;

  const _OnlineCheapestSummaryRow({required this.stores});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = stores
        .take(3)
        .map((store) => '${store.storeName} ${formatTRY(store.price)}')
        .join(' • ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          Text(
            'En ucuz 3',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              summary.isEmpty ? 'Veri yok' : summary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
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
