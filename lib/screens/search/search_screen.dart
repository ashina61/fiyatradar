import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/banner_model.dart';
import '../../providers/banner_provider.dart';
import '../../providers/explore_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/banner_widget.dart';
import '../../widgets/home_product_card.dart';
import '../campaign/campaign_basket_screen.dart';
import '../product/product_detail_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
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
        Future.microtask(() => ref.read(selectedCategoryFilterProvider.notifier).state = 'Tumu');
      }
    });

    final theme = Theme.of(context);
    final state = ref.watch(exploreControllerProvider);
    final bannersAsync = ref.watch(activeBannersProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            children: [
              _buildSearchBar(theme, state),
              bannersAsync.when(
                data: (banners) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: BannerCarousel(
                    banners: banners,
                    onTap: _onBannerTap,
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              _buildModeTabs(theme, state),
              _buildCategoryChips(theme, state),
              Expanded(child: _buildBody(theme, state)),
            ],
          ),
        ),
      ),
    );
  }

  void _onBannerTap(BannerModel banner) {
    final type = banner.actionType?.toLowerCase();
    if (type == 'campaign' && (banner.targetId?.isNotEmpty ?? false)) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CampaignBasketScreen(campaignId: banner.targetId!, banner: banner),
        ),
      );
      return;
    }

    if (type == 'product') {
      final productId = banner.targetId ?? banner.productId;
      if (productId != null && productId.isNotEmpty) {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: productId)));
      }
    }
  }

  Widget _buildBody(ThemeData theme, ExploreState state) {
    if (state.loading) return const Center(child: CircularProgressIndicator());
    if (state.error != null) {
      return Center(
        child: FilledButton(
          onPressed: () => ref.read(exploreControllerProvider.notifier).retry(),
          child: const Text('Tekrar dene'),
        ),
      );
    }
    return _buildExploreGrid(theme, state);
  }

  Widget _buildSearchBar(ThemeData theme, ExploreState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg), borderSide: BorderSide.none),
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
          );
        },
      ),
    );
  }

  Widget _buildExploreGrid(ThemeData theme, ExploreState state) {
    if (state.items.isEmpty) return const Center(child: Text('Henüz bu filtrede fiyat yok'));

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final cardWidth = (constraints.maxWidth - (AppSpacing.md * 2) - spacing) / 2;

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 96),
          itemCount: state.items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.72,
          ),
          itemBuilder: (context, index) {
            final item = state.items[index];
            return HomeProductCard(
              product: item.product,
              width: cardWidth,
              showStore: false,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: item.product.id)),
              ),
              bottomSection: _ExploreMetaRow(item: item, mode: state.selectedMode),
            );
          },
        );
      },
    );
  }
}

class _ExploreMetaRow extends StatelessWidget {
  final ExploreFeedItem item;
  final ExploreMode mode;

  const _ExploreMetaRow({required this.item, required this.mode});

  @override
  Widget build(BuildContext context) {
    final neighborhoodText = item.neighborhoodLabel;
    final distanceText = mode == ExploreMode.online ? 'Online' : (item.distanceLabel?.trim() ?? '—');
    final highlightNearby = item.isVeryNearby && mode == ExploreMode.nearby;

    return Column(
      children: [
        Divider(height: 10, thickness: 0.7, color: Colors.black.withOpacity(0.08)),
        const SizedBox(height: 2),
        Row(
          children: [
            Expanded(
              child: Text(
                neighborhoodText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(width: 8),
            if (highlightNearby)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.outline),
                ),
                child: const Text('🔥', style: TextStyle(fontSize: 10)),
              ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                distanceText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: highlightNearby ? FontWeight.w900 : FontWeight.w800,
                    ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
