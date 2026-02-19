import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/actual_provider.dart';
import '../../providers/explore_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/home_product_card.dart';
import '../../widgets/staggered_fade_slide.dart';
import '../../widgets/premium_pressable.dart';
import '../product/product_detail_screen.dart';
import '../actual/actuals_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isSearchFocused = false;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);
    _animController.forward();

    _focusNode.addListener(() {
      if (mounted) {
        setState(() => _isSearchFocused = _focusNode.hasFocus);
      }
    });
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
            () => ref.read(selectedCategoryFilterProvider.notifier).state = 'Tumu');
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
              // Header area
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: _buildHeader(theme),
              ),
              const SizedBox(height: 14),
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildSearchBar(theme, state),
              ),
              const SizedBox(height: 14),
              // Aktuel card
              _buildConditionalAktuelCard(theme),
              // Mode tabs
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                child: _buildModeTabs(theme, state),
              ),
              // Category chips
              _buildCategoryChips(theme, state),
              const SizedBox(height: 8),
              // Content
              Expanded(child: _buildBody(theme, state)),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────
  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Kesfet',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.12),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.radar_rounded,
                  size: 15, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                'FiyatRadar',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Search Bar ────────────────────────────────────────────────
  Widget _buildSearchBar(ThemeData theme, ExploreState state) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (_isSearchFocused)
            BoxShadow(
              color: AppColors.primary.withOpacity(0.10),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: TextField(
            controller: _searchController,
            focusNode: _focusNode,
            onChanged: (value) {
              ref
                  .read(exploreControllerProvider.notifier)
                  .updateSearchQuery(value);
              if (value.trim().isNotEmpty) {
                ref.read(userNotifierProvider.notifier).saveSearch(value.trim());
              }
            },
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'Urun, magaza veya kategori ara...',
              hintStyle: TextStyle(
                color: AppColors.textHint,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.all(12),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.search_rounded,
                      color: AppColors.primary, size: 20),
                ),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 52,
                minHeight: 52,
              ),
              suffixIcon: state.searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.textTertiary.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded,
                            size: 16, color: AppColors.textSecondary),
                      ),
                      splashRadius: 18,
                      onPressed: () {
                        _searchController.clear();
                        ref
                            .read(exploreControllerProvider.notifier)
                            .updateSearchQuery('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.surface.withOpacity(0.9),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                    color: AppColors.outline.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                    color: AppColors.outline.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Aktuel Card ───────────────────────────────────────────────
  Widget _buildConditionalAktuelCard(ThemeData theme) {
    final actualAsync = ref.watch(latestActiveActualProvider);
    return actualAsync.when(
      data: (actual) {
        if (actual == null) return const SizedBox.shrink();
        return _buildAktuelCard(theme);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildAktuelCard(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: PremiumPressable(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ActualsScreen()),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.local_offer_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Aktuel Firsatlar',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Haftanin en iyi kampanyalari',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chevron_right_rounded,
                    color: Colors.white, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Mode Tabs (Segmented Control) ─────────────────────────────
  Widget _buildModeTabs(ThemeData theme, ExploreState state) {
    const modes = <MapEntry<ExploreMode, _ModeTabInfo>>[
      MapEntry(ExploreMode.nearby,
          _ModeTabInfo('Yakinimda', Icons.location_on_rounded)),
      MapEntry(
          ExploreMode.online, _ModeTabInfo('Online', Icons.language_rounded)),
      MapEntry(ExploreMode.drops,
          _ModeTabInfo('Dusenler', Icons.trending_down_rounded)),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withOpacity(0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.outline.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: modes.map((entry) {
          final isSelected = state.selectedMode == entry.key;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                ref
                    .read(exploreControllerProvider.notifier)
                    .updateMode(entry.key);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      entry.value.icon,
                      size: 16,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textTertiary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        entry.value.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Category Chips ────────────────────────────────────────────
  Widget _buildCategoryChips(ThemeData theme, ExploreState state) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: state.categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final label = state.categories[index];
          final selected = state.selectedCategory == label;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              ref
                  .read(exploreControllerProvider.notifier)
                  .updateCategory(label);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected
                      ? AppColors.primary
                      : AppColors.outline.withOpacity(0.5),
                  width: selected ? 1.5 : 1,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? Colors.white
                      : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Body ──────────────────────────────────────────────────────
  Widget _buildBody(ThemeData theme, ExploreState state) {
    if (state.loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primary.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Urunler yukleniyor...',
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: AppColors.textTertiary.withOpacity(0.5),
            ),
            const SizedBox(height: 14),
            Text(
              'Baglanti hatasi',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () =>
                  ref.read(exploreControllerProvider.notifier).retry(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Tekrar dene'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return _buildExploreGrid(theme, state);
  }

  Widget _buildExploreGrid(ThemeData theme, ExploreState state) {
    if (state.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 56,
              color: AppColors.textTertiary.withOpacity(0.4),
            ),
            const SizedBox(height: 14),
            Text(
              'Henuz bu filtrede fiyat yok',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Farkli bir kategori veya mod deneyin',
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final cardWidth =
            (constraints.maxWidth - (20 * 2) - spacing) / 2;

        return GridView.builder(
          padding:
              const EdgeInsets.fromLTRB(20, 12, 20, 96),
          itemCount: state.items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 12,
            childAspectRatio: 0.72,
          ),
          itemBuilder: (context, index) {
            final item = state.items[index];
            return StaggeredFadeSlide(
              index: index,
              baseDelayMs: 20,
              stepDelayMs: 30,
              child: HomeProductCard(
                product: item.product,
                width: cardWidth,
                showStore: false,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        ProductDetailScreen(productId: item.product.id),
                  ),
                ),
                bottomSection:
                    _ExploreMetaRow(item: item, mode: state.selectedMode),
              ),
            );
          },
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════
// Supporting Widgets
// ════════════════════════════════════════════════════════════════

class _ModeTabInfo {
  final String label;
  final IconData icon;
  const _ModeTabInfo(this.label, this.icon);
}

class _ExploreMetaRow extends StatelessWidget {
  final ExploreFeedItem item;
  final ExploreMode mode;

  const _ExploreMetaRow({required this.item, required this.mode});

  @override
  Widget build(BuildContext context) {
    final neighborhoodText = item.neighborhoodLabel;
    final distanceText = mode == ExploreMode.online
        ? 'Online'
        : (item.distanceLabel?.trim().isNotEmpty ?? false)
            ? item.distanceLabel!.trim()
            : '';

    return Column(
      children: [
        Divider(
          height: 10,
          thickness: 0.5,
          color: AppColors.outline.withOpacity(0.4),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            if (mode == ExploreMode.online)
              Icon(Icons.language_rounded,
                  size: 12, color: AppColors.textTertiary)
            else
              Icon(Icons.location_on_outlined,
                  size: 12, color: AppColors.textTertiary),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                neighborhoodText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                    ),
              ),
            ),
            if (distanceText.isNotEmpty) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  distanceText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
