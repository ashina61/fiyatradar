import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/banner_model.dart';
import '../../providers/actual_provider.dart';
import '../../providers/banner_provider.dart';
import '../../providers/explore_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/barcode_scanner_sheet.dart';
import '../../widgets/premium_pressable.dart';
import '../actual/actuals_screen.dart';
import '../main_screen.dart';
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
  bool _isSearchFocused = false;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
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

  Future<void> _scanBarcode() async {
    final barcode = await BarcodeScannerSheet.scan(context, title: 'Barkod Tara');
    if (!mounted || barcode == null || barcode.trim().isEmpty) return;

    final value = barcode.trim();
    _searchController.text = value;
    _searchController.selection = TextSelection.collapsed(offset: value.length);
    ref.read(exploreControllerProvider.notifier).updateSearchQuery(value);
    ref.read(userNotifierProvider.notifier).saveSearch(value);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String>(selectedCategoryFilterProvider, (prev, next) {
      if (next != 'Tumu') {
        ref.read(exploreControllerProvider.notifier).updateCategory(next);
        Future.microtask(() {
          ref.read(selectedCategoryFilterProvider.notifier).state = 'Tumu';
        });
      }
    });

    final theme = Theme.of(context);
    final state = ref.watch(exploreControllerProvider);

    if (_searchController.text != state.searchQuery) {
      final oldSelection = _searchController.selection;
      _searchController.text = state.searchQuery;
      final offset = oldSelection.baseOffset.clamp(0, _searchController.text.length) as int;
      _searchController.selection = TextSelection.collapsed(offset: offset);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F0),
      body: SafeArea(
        bottom: false,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            children: [
              _buildPremiumHeader(),
              Transform.translate(
                offset: const Offset(0, -24),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildSearchBar(theme, state),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildModeTabs(state),
              ),
              const SizedBox(height: 12),
              _buildCategoryChips(state),
              const SizedBox(height: 8),
              Expanded(child: _buildBody(state)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 42),
      decoration: BoxDecoration(
        color: const Color(0xFF211510),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF211510).withOpacity(0.22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFFF5F3F0),
              size: 20,
            ),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
                return;
              }
              ref.read(currentTabProvider.notifier).state = 0;
            },
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Text(
              'Keşfet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ),
          _buildBrandPill(),
        ],
      ),
    );
  }

  Widget _buildBrandPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.radar_rounded, size: 15, color: Color(0xFFC29B78)),
          SizedBox(width: 4),
          Text(
            'FiyatRadar',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFFC29B78),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme, ExploreState state) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF211510).withOpacity(_isSearchFocused ? 0.1 : 0.05),
            blurRadius: _isSearchFocused ? 26 : 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: TextField(
            controller: _searchController,
            focusNode: _focusNode,
            onChanged: (value) {
              ref.read(exploreControllerProvider.notifier).updateSearchQuery(value);
              if (value.trim().isNotEmpty) {
                ref.read(userNotifierProvider.notifier).saveSearch(value.trim());
              }
            },
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: 'Ürün, mağaza veya kategori ara...',
              hintStyle: const TextStyle(
                color: Color(0xFFAFA59D),
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 14, right: 8),
                child: Icon(Icons.search_rounded, color: Color(0xFF948A82), size: 22),
              ),
              suffixIconConstraints: const BoxConstraints(minWidth: 88),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (state.searchQuery.isNotEmpty)
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: Color(0xFF948A82),
                      ),
                      splashRadius: 18,
                      onPressed: () {
                        _searchController.clear();
                        ref.read(exploreControllerProvider.notifier).updateSearchQuery('');
                      },
                    ),
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: PremiumPressable(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _scanBarcode,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEBE5DF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.qr_code_scanner_rounded,
                          color: Color(0xFF2D1E17),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: const Color(0xFF211510).withOpacity(0.08)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: const Color(0xFF211510).withOpacity(0.08)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: Color(0xFFC29B78), width: 1.3),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeTabs(ExploreState state) {
    const modes = <MapEntry<ExploreMode, _ModeTabInfo>>[
      MapEntry(ExploreMode.nearby, _ModeTabInfo('Yakınımda', Icons.my_location_rounded)),
      MapEntry(ExploreMode.online, _ModeTabInfo('Online', Icons.language_rounded)),
      MapEntry(ExploreMode.drops, _ModeTabInfo('Düşenler', Icons.south_east_rounded)),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEBE5DF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: modes.map((entry) {
          final isSelected = state.selectedMode == entry.key;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                ref.read(exploreControllerProvider.notifier).updateMode(entry.key);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF211510) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF211510).withOpacity(0.24),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
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
                      color: isSelected ? const Color(0xFFC29B78) : const Color(0xFF948A82),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        entry.value.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? const Color(0xFFC29B78) : const Color(0xFF948A82),
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

  Widget _buildCategoryChips(ExploreState state) {
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
          return PremiumPressable(
            borderRadius: BorderRadius.circular(100),
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(exploreControllerProvider.notifier).updateCategory(label);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF211510) : Colors.white,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF211510)
                      : const Color(0xFF211510).withOpacity(0.08),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF211510).withOpacity(selected ? 0.2 : 0.04),
                    blurRadius: selected ? 16 : 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: selected ? const Color(0xFFC29B78) : const Color(0xFF211510),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(ExploreState state) {
    if (state.loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFFC29B78),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Ürünler yükleniyor...',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
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
              'Bağlantı hatası',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => ref.read(exploreControllerProvider.notifier).retry(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Tekrar dene'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF8A5B3E),
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

    final hasItems = state.items.isNotEmpty;
    final activeBanners = ref.watch(activeBannersProvider).valueOrNull ?? const <BannerModel>[];
    BannerModel? weeklyEventBanner;
    for (final banner in activeBanners) {
      if ((banner.linkUrl ?? '').trim().isNotEmpty) {
        weeklyEventBanner = banner;
        break;
      }
    }
    final huntItem = state.items
        .where((item) => item.dropPercent > 0)
        .fold<ExploreFeedItem?>(null, (best, current) {
      if (best == null || current.dropPercent > best.dropPercent) return current;
      return best;
    });

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _buildConditionalAktuelCard()),
        if (weeklyEventBanner != null)
          SliverToBoxAdapter(child: _buildWeeklyEventCard(weeklyEventBanner))
        else if (huntItem != null)
          SliverToBoxAdapter(child: _buildHuntCard(huntItem)),
        if (!hasItems)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyState(),
          )
        else ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Row(
                children: const [
                  Text(
                    'Senin İçin Seçildi',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF211510),
                      letterSpacing: -0.4,
                    ),
                  ),
                  SizedBox(width: 10),
                  _AiBadge(),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = state.items[index];
                  return _DiscoverProductCard(
                    key: ValueKey('discover-${item.price.id}'),
                    item: item,
                    mode: state.selectedMode,
                    onTap: () {
                      Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(
                          builder: (_) => ProductDetailScreen(productId: item.product.id),
                        ),
                      );
                    },
                  );
                },
                childCount: state.items.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 14,
                childAspectRatio: 0.61,
              ),
            ),
          ),
        ],
        SliverToBoxAdapter(child: _buildTrendSearches()),
        SliverToBoxAdapter(child: _buildFooterCta()),
      ],
    );
  }

  Widget _buildConditionalAktuelCard() {
    final actualAsync = ref.watch(latestActiveActualProvider);
    return actualAsync.when(
      data: (actual) {
        if (actual == null) return const SizedBox.shrink();
        final today = DateTime.now();
        final dateText =
            '${_formatDate(actual.startDate)} - ${_formatDate(actual.endDate)}';
        final status = actual.endDate.isBefore(today)
            ? 'Arşiv'
            : actual.startDate.isAfter(today)
                ? 'Yakında'
                : 'Aktif';

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
          child: PremiumPressable(
            borderRadius: BorderRadius.circular(24),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ActualsScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFC29B78), Color(0xFFA67C52)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFC29B78).withOpacity(0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF211510),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$status • $dateText',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFC29B78),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Aktüel Fırsatlar',
                          style: TextStyle(
                            color: Color(0xFF211510),
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          actual.title.trim().isNotEmpty
                              ? actual.title
                              : 'Haftanın en yeni pazar katalogları',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xCC211510),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.auto_stories_rounded, color: Color(0xFF211510)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }



  Widget _buildWeeklyEventCard(BannerModel banner) {
    final imageUrl = (banner.imageUrl ?? '').trim();
    final badgeText = (banner.badgeText ?? '').trim().isNotEmpty
        ? banner.badgeText!.trim()
        : 'ETİKET';
    final actionText = banner.buttonText.trim().isNotEmpty
        ? banner.buttonText.trim()
        : 'KEŞFET';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: PremiumPressable(
        borderRadius: BorderRadius.circular(28),
        onTap: () async {
          final linkUrl = (banner.linkUrl ?? '').trim();
          if (linkUrl.isEmpty) return;
          final uri = Uri.tryParse(linkUrl);
          if (uri == null) return;
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        },
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFF1C1108),
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x261C1108),
                blurRadius: 32,
                offset: Offset(0, 16),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      )
                    : const DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(0xFF1C1108),
                          gradient: RadialGradient(
                            center: Alignment(1, -1),
                            radius: 1.15,
                            colors: [Color(0x66C09A60), Color(0x001C1108)],
                            stops: [0.0, 1.0],
                          ),
                        ),
                      ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: imageUrl.isNotEmpty
                        ? const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [Color(0xDE000000), Color(0x00000000)],
                            stops: [0.0, 0.9],
                          )
                        : null,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: banner.isSponsor ? const Color(0x40C09A60) : const Color(0x26C09A60),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: banner.isSponsor ? const Color(0xFFC09A60) : const Color(0x4DC09A60),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            banner.isSponsor ? Icons.star : Icons.circle,
                            size: banner.isSponsor ? 12 : 6,
                            color: const Color(0xFFC09A60),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            badgeText.toUpperCase(),
                            style: TextStyle(
                              color: banner.isSponsor ? const Color(0xFFFFE6C9) : const Color(0xFFC09A60),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      banner.title,
                      style: const TextStyle(
                        fontSize: 20,
                        height: 1.2,
                        letterSpacing: -0.5,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    if ((banner.description ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        banner.description!.trim(),
                        style: const TextStyle(
                          color: Color(0x99FFFFFF),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          actionText.toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFFC09A60),
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: Color(0xFFC09A60),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x4DC09A60),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.arrow_forward_rounded, size: 18, color: Color(0xFF1C1108)),
                        ),
                      ],
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
  Widget _buildHuntCard(ExploreFeedItem item) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: PremiumPressable(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          ref.read(exploreControllerProvider.notifier).updateMode(ExploreMode.drops);
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF211510),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0x33C29B78)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F3F0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.whatshot_rounded, size: 12, color: Color(0xFF211510)),
                          SizedBox(width: 4),
                          Text(
                            'HAFTANIN OLAYI',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF211510),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${item.product.brand}\n${item.product.name}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '%${item.dropPercent.toStringAsFixed(0)} düşüş yakalandı',
                      style: const TextStyle(
                        color: Color(0x99FFFFFF),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Avı Başlat',
                          style: TextStyle(
                            color: Color(0xFFC29B78),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFFC29B78)),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.shopping_basket_rounded,
                  size: 32,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendSearches() {
    final historyAsync = ref.watch(searchHistoryProvider);

    return historyAsync.when(
      data: (terms) {
        final cleaned = <String>{};
        final unique = terms
            .where((term) => term.trim().isNotEmpty)
            .map((term) => term.trim())
            .where((term) => cleaned.add(term.toLowerCase()))
            .take(8)
            .toList();

        if (unique.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Text(
                    'Trend Aramalar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF211510),
                      letterSpacing: -0.4,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.trending_up_rounded, color: Color(0xFF948A82), size: 20),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: unique.map((term) {
                  final isHot = term == unique.first;
                  return PremiumPressable(
                    borderRadius: BorderRadius.circular(100),
                    onTap: () {
                      _searchController.text = term;
                      _searchController.selection =
                          TextSelection.collapsed(offset: term.length);
                      ref.read(exploreControllerProvider.notifier).updateSearchQuery(term);
                    },
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 42),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                      decoration: BoxDecoration(
                        color: isHot ? const Color(0xFFFFF4E8) : Colors.white,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: isHot
                              ? const Color(0xFFC29B78).withOpacity(0.4)
                              : const Color(0xFF211510).withOpacity(0.08),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isHot ? Icons.local_fire_department_rounded : Icons.search_rounded,
                            size: isHot ? 18 : 17,
                            color:
                                isHot ? const Color(0xFFEF6C00) : const Color(0xFF948A82),
                          ),
                          const SizedBox(width: 8),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 210, minWidth: 44),
                            child: Text(
                              term,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isHot ? FontWeight.w800 : FontWeight.w700,
                                color: const Color(0xFF211510),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildFooterCta() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
      child: PremiumPressable(
        borderRadius: BorderRadius.circular(20),
        onTap: _scanBarcode,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            color: const Color(0xFF211510),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0x33C29B78)),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fırsatı Bulamadın mı?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Barkodu okut, anında fiyatı keşfet.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0x99FFFFFF),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFC29B78),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: Color(0xFF211510),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Oca',
      'Şub',
      'Mar',
      'Nis',
      'May',
      'Haz',
      'Tem',
      'Ağu',
      'Eyl',
      'Eki',
      'Kas',
      'Ara',
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]}';
  }
}

class _ModeTabInfo {
  final String label;
  final IconData icon;

  const _ModeTabInfo(this.label, this.icon);
}

class _AiBadge extends StatelessWidget {
  const _AiBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFC29B78).withOpacity(0.18),
        borderRadius: BorderRadius.circular(7),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded, size: 12, color: Color(0xFFC29B78)),
          SizedBox(width: 3),
          Text(
            'AI',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: Color(0xFFC29B78),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
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
            'Henüz bu filtrede fiyat yok',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Farklı bir kategori veya mod deneyin',
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscoverProductCard extends ConsumerWidget {
  const _DiscoverProductCard({
    super.key,
    required this.item,
    required this.mode,
    required this.onTap,
  });

  final ExploreFeedItem item;
  final ExploreMode mode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final override = ref.watch(favoriteOverrideProvider(item.product.id));
    final favoriteAsync = ref.watch(isFavoriteProvider(item.product.id));
    final serverFavorite = favoriteAsync.valueOrNull ?? false;
    final isFavorite = override ?? serverFavorite;

    final image = item.product.effectiveImage;
    final oldPrice = _oldPriceFromPriceChange(item);

    return PremiumPressable(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF211510).withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF211510).withOpacity(0.05),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 8,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFEBE5DF),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: image != null && image.trim().isNotEmpty
                            ? Image.network(
                                image,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.image_not_supported_rounded,
                                  color: Color(0xFFB0A69D),
                                ),
                              )
                            : const Icon(
                                Icons.image_outlined,
                                color: Color(0xFFB0A69D),
                              ),
                      ),
                    ),
                    if (item.dropPercent > 0)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            '↓ %${item.dropPercent.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Color(0xFF2E7D32),
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: GestureDetector(
                        onTap: () async {
                          final next = !isFavorite;
                          ref.read(favoriteOverrideProvider(item.product.id).notifier).state = next;
                          await ref
                              .read(userNotifierProvider.notifier)
                              .toggleSavedProduct(item.product.id);
                        },
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 17,
                            color: isFavorite ? const Color(0xFFF44336) : const Color(0xFF948A82),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 9,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.brand.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                        color: Color(0xFFC29B78),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF211510),
                        height: 1.2,
                      ),
                    ),
                    const Spacer(),
                    if (oldPrice != null)
                      Text(
                        _formatTry(oldPrice),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF948A82),
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    Text(
                      _formatTry(item.displayPrice),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF211510),
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEBE5DF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                item.storeName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF2D1E17),
                                  height: 1.1,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (_resolveMetaLabel(item, mode) case final metaLabel?) ...[
                          const SizedBox(width: 10),
                          ConstrainedBox(
                            constraints: const BoxConstraints(minWidth: 72, maxWidth: 116),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    _resolveMetaIcon(mode),
                                    size: 13,
                                    color: const Color(0xFF948A82),
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      metaLabel,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.end,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF948A82),
                                        height: 1.1,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double? _oldPriceFromPriceChange(ExploreFeedItem item) {
    final change = item.priceChangePercent;
    if (change == null || change >= -0.5) return null;
    final ratio = 1 + (change / 100);
    if (ratio <= 0) return null;
    return item.displayPrice / ratio;
  }

  String? _resolveMetaLabel(ExploreFeedItem item, ExploreMode mode) {
    if (mode == ExploreMode.online) return 'Online';

    final distance = item.distanceLabel?.trim();
    if (distance != null && distance.isNotEmpty && distance != '—') {
      return distance;
    }

    final neighborhood = item.neighborhoodLabel.trim();
    if (neighborhood.isNotEmpty && neighborhood != '—') {
      return neighborhood;
    }

    return null;
  }

  IconData _resolveMetaIcon(ExploreMode mode) {
    switch (mode) {
      case ExploreMode.online:
        return Icons.language_rounded;
      case ExploreMode.drops:
        return Icons.local_shipping_rounded;
      case ExploreMode.nearby:
        return Icons.location_on_rounded;
    }
  }

  String _formatTry(double value) {
    final fixed = value.toStringAsFixed(2).replaceAll('.', ',');
    return '$fixed₺';
  }
}
