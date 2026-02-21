import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/store.dart';
import '../../providers/auth_provider.dart';
import '../../providers/price_report_provider.dart';
import '../../utils/motion_tokens.dart';
import '../../utils/theme.dart';
import '../../widgets/barcode_scanner_sheet.dart';
import '../../widgets/premium_pressable.dart';
import '../../widgets/staggered_fade_slide.dart';

class AddPriceScreen extends ConsumerStatefulWidget {
  const AddPriceScreen({super.key});

  @override
  ConsumerState<AddPriceScreen> createState() => _AddPriceScreenState();
}

class _AddPriceScreenState extends ConsumerState<AddPriceScreen>
    with TickerProviderStateMixin {
  final _priceController = TextEditingController();
  final _productController = TextEditingController();
  final _searchController = TextEditingController();
  final _priceFocus = FocusNode();

  late final TabController _tabController;
  late final AnimationController _headerAnimController;
  late final Animation<double> _headerFade;
  late final AnimationController _priceGlowController;

  static const _categoryIcons = <String, IconData>{
    'Gıda': Icons.restaurant_rounded,
    'Kişisel Bakım': Icons.spa_rounded,
    'Temizlik': Icons.cleaning_services_rounded,
    'Teknoloji': Icons.devices_rounded,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) return;
      ref.read(addPriceProvider.notifier).setActiveTab(_tabController.index);
    });

    _headerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _headerFade = CurvedAnimation(
      parent: _headerAnimController,
      curve: Curves.easeOutCubic,
    );
    _headerAnimController.forward();

    _priceGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _priceController.dispose();
    _productController.dispose();
    _searchController.dispose();
    _priceFocus.dispose();
    _headerAnimController.dispose();
    _priceGlowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(addPriceProvider.select((s) => s.error), (_, next) {
      if (next != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    });

    final state = ref.watch(addPriceProvider);
    final notifier = ref.read(addPriceProvider.notifier);
    final theme = Theme.of(context);

    if (_tabController.index != state.activeTab) {
      _tabController.animateTo(state.activeTab);
    }
    if (_priceController.text != state.price) _priceController.text = state.price;
    if (_productController.text != state.productName) {
      _productController.text = state.productName;
    }
    if (_searchController.text != state.searchQuery) {
      _searchController.text = state.searchQuery;
    }

    final bottomSafe = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Ambient gradient orbs (like home screen)
          Positioned(
            top: -80,
            right: -60,
            child: _AmbientOrb(size: 240, color: AppColors.primary, opacity: 0.08),
          ),
          Positioned(
            top: 300,
            left: -80,
            child: _AmbientOrb(size: 200, color: AppColors.accent, opacity: 0.06),
          ),
          Positioned(
            bottom: 120,
            right: -40,
            child: _AmbientOrb(size: 160, color: AppColors.secondary, opacity: 0.05),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header
                FadeTransition(
                  opacity: _headerFade,
                  child: _buildHeader(theme),
                ),

                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: EdgeInsets.fromLTRB(20, 8, 20, 100 + bottomSafe),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Price input
                        StaggeredFadeSlide(
                          index: 0,
                          child: _buildPriceCard(state, theme),
                        ),
                        const SizedBox(height: 20),

                        // Product details
                        StaggeredFadeSlide(
                          index: 1,
                          child: _buildProductSection(state, notifier, theme),
                        ),
                        const SizedBox(height: 20),

                        // Category selection
                        StaggeredFadeSlide(
                          index: 2,
                          child: _buildCategorySection(state, notifier, theme),
                        ),
                        const SizedBox(height: 24),

                        // Store selection
                        StaggeredFadeSlide(
                          index: 3,
                          child: _buildStoreSection(state, notifier, theme),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom action
          _buildBottomAction(state, theme, bottomSafe),
        ],
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────
  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          PremiumPressable(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant.withOpacity(0.7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.outline.withOpacity(0.5)),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textSecondary,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fiyat Ekle',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Topluluga katkida bulun',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Points indicator
          PremiumPressable(
            borderRadius: BorderRadius.circular(24),
            onTap: _showInfoModal,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.accent.withOpacity(0.12),
                    AppColors.secondary.withOpacity(0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.accent.withOpacity(0.15)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline_rounded, color: AppColors.accent, size: 17),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Price Card ──────────────────────────────────────────────
  Widget _buildPriceCard(AddPriceState state, ThemeData theme) {
    return AnimatedBuilder(
      animation: _priceGlowController,
      builder: (context, child) {
        final glowOpacity = 0.06 + (_priceGlowController.value * 0.06);
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.xxl),
            border: Border.all(
              color: state.price.isNotEmpty
                  ? AppColors.primary.withOpacity(0.3)
                  : AppColors.outline.withOpacity(0.4),
              width: state.price.isNotEmpty ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(
                  state.price.isNotEmpty ? glowOpacity : 0.03,
                ),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        );
      },
      child: Column(
        children: [
          // Label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.price_change_outlined,
                    size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  'URUN FIYATI',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Price input
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '\u20BA',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _priceController,
                  focusNode: _priceFocus,
                  onChanged: ref.read(addPriceProvider.notifier).setPrice,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9,]')),
                  ],
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 56,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -2,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    fillColor: Colors.transparent,
                    filled: false,
                    hintText: '0,00',
                    hintStyle: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 56,
                      fontWeight: FontWeight.w700,
                      color: AppColors.outline,
                      letterSpacing: -2,
                    ),
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Product Section ─────────────────────────────────────────
  Widget _buildProductSection(
      AddPriceState state, AddPriceNotifier notifier, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(
          icon: Icons.inventory_2_outlined,
          label: 'Urun Bilgisi',
          theme: theme,
        ),
        const SizedBox(height: 10),
        // Product name input
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.outline.withOpacity(0.4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.edit_rounded,
                    size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _productController,
                  onChanged: notifier.setProductName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    fillColor: Colors.transparent,
                    filled: false,
                    hintText: 'Urun adini yazin',
                    hintStyle: TextStyle(color: AppColors.textHint),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              PremiumPressable(
                borderRadius: BorderRadius.circular(10),
                onTap: _scanBarcode,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    size: 20,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Barcode badge
        if (state.barcode != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.success.withOpacity(0.15)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded,
                    size: 14, color: AppColors.success),
                const SizedBox(width: 6),
                Text(
                  'Barkod: ${state.barcode}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ─── Category Section ────────────────────────────────────────
  Widget _buildCategorySection(
      AddPriceState state, AddPriceNotifier notifier, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(
          icon: Icons.category_rounded,
          label: 'Kategori',
          theme: theme,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: state.categories.map((category) {
            final isSelected = state.selectedCategoryId == category.id;
            final icon = _categoryIcons[category.title] ?? Icons.label_rounded;
            return PremiumPressable(
              borderRadius: BorderRadius.circular(14),
              onTap: () => notifier.setCategory(category),
              child: AnimatedContainer(
                duration: MotionTokens.fast,
                curve: MotionTokens.standard,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.1)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.4)
                        : AppColors.outline.withOpacity(0.4),
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 18,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textTertiary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      category.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.check_rounded,
                          size: 16, color: AppColors.primary),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ─── Store Section ───────────────────────────────────────────
  Widget _buildStoreSection(
      AddPriceState state, AddPriceNotifier notifier, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(
          icon: Icons.storefront_rounded,
          label: 'Nerede Gordun?',
          theme: theme,
        ),
        const SizedBox(height: 10),

        // Tab bar
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outline.withOpacity(0.3)),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textTertiary,
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
            ),
            tabs: const [
              Tab(
                height: 40,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on_rounded, size: 16),
                    SizedBox(width: 6),
                    Text('Yakinimda'),
                  ],
                ),
              ),
              Tab(
                height: 40,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.language_rounded, size: 16),
                    SizedBox(width: 6),
                    Text('Online'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Search field
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.85),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.outline.withOpacity(0.4)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.search_rounded,
                        color: AppColors.primary, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: notifier.setSearchQuery,
                      style: theme.textTheme.bodyMedium,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        fillColor: Colors.transparent,
                        filled: false,
                        hintText: 'Market veya platform ara...',
                        hintStyle:
                            TextStyle(color: AppColors.textHint, fontSize: 14),
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Store list
        if (state.isStoresLoading)
          _buildStoresLoading()
        else if (state.storesError != null)
          _buildStoresError(state, notifier, theme)
        else if (state.visibleStores.isEmpty)
          _buildStoresEmpty(theme)
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.visibleStores.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final store = state.visibleStores[index];
              final selected = state.selectedStore?.id == store.id;
              return StaggeredFadeSlide(
                index: index,
                baseDelayMs: 20,
                stepDelayMs: 30,
                child: _StoreCard(
                  store: store,
                  selected: selected,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    notifier.setSelectedStore(store);
                  },
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildStoresLoading() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.primary.withOpacity(0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildStoresError(
      AddPriceState state, AddPriceNotifier notifier, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.error_outline_rounded,
                    size: 16, color: AppColors.error),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Magazalar yuklenemedi',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            state.storesError!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 12),
          PremiumPressable(
            borderRadius: BorderRadius.circular(10),
            onTap: notifier.loadStoresAndCategories,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Tekrar Dene',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoresEmpty(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.storefront_outlined,
              size: 28,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Aramaniza uygun magaza bulunamadi',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bottom Action ───────────────────────────────────────────
  Widget _buildBottomAction(
      AddPriceState state, ThemeData theme, double bottomSafe) {
    final isReady = state.price.trim().isNotEmpty &&
        state.productName.trim().isNotEmpty &&
        state.selectedCategoryId != null &&
        state.selectedStoreId != null;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomSafe),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor.withOpacity(0.85),
              border: Border(
                top: BorderSide(color: AppColors.outline.withOpacity(0.3)),
              ),
            ),
            child: PremiumPressable(
              borderRadius: BorderRadius.circular(16),
              onTap: state.isLoading || state.isStoresLoading ? null : _submit,
              pressedScale: 0.98,
              child: AnimatedContainer(
                duration: MotionTokens.fast,
                curve: MotionTokens.standard,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: isReady
                      ? const LinearGradient(
                          colors: [AppColors.primary, AppColors.accent],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        )
                      : null,
                  color: isReady ? null : AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isReady
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                child: state.isLoading
                    ? const Center(
                        child: SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: isReady
                                ? Colors.white
                                : AppColors.textTertiary,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Fiyati Kaydet',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isReady
                                  ? Colors.white
                                  : AppColors.textTertiary,
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

  // ─── Actions ─────────────────────────────────────────────────
  Future<void> _scanBarcode() async {
    final barcode = await BarcodeScannerSheet.scan(context, title: 'Barkod Tara');
    if (barcode != null && mounted) {
      ref.read(addPriceProvider.notifier).setBarcode(barcode);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Barkod okundu: $barcode'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _submit() async {
    final user = ref.read(authStateProvider).value;
    final userId = user?.uid;
    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fiyat gonderebilmek icin giris yapmalisin.')),
      );
      return;
    }

    try {
      await ref.read(addPriceProvider.notifier).submitPrice(userId: userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text('Fiyat basariyla kaydedildi. +10 puan hesabina eklendi!'),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.maybePop(context);
    } catch (_) {}
  }

  Future<void> _showInfoModal() async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.outline.withOpacity(0.5)),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.15),
                    blurRadius: 40,
                    offset: Offset(0, 20),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withOpacity(0.12),
                              AppColors.accent.withOpacity(0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.info_rounded,
                            color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text(
                          'Bilgilendirme',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      PremiumPressable(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded,
                              size: 18, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _InfoRow(
                    icon: Icons.stars_rounded,
                    iconColor: AppColors.accent,
                    text: 'Her fiyat girisi +10 Puan kazandirir!',
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.groups_rounded,
                    iconColor: AppColors.primary,
                    text:
                        'Fiyatlar tamamen kullanicilar tarafindan bildirilmektedir.',
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.verified_rounded,
                    iconColor: AppColors.success,
                    text:
                        'Dogru fiyat girisleri guven puaninizi arttirir.',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// Supporting Widgets
// ════════════════════════════════════════════════════════════════

class _AmbientOrb extends StatelessWidget {
  const _AmbientOrb({
    required this.size,
    required this.color,
    required this.opacity,
  });

  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withOpacity(opacity),
              color.withOpacity(0),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.icon,
    required this.label,
    required this.theme,
  });

  final IconData icon;
  final String label;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

class _StoreCard extends StatelessWidget {
  const _StoreCard({
    required this.store,
    required this.selected,
    required this.onTap,
  });

  final Store store;
  final bool selected;
  final VoidCallback onTap;

  Color _storeColor() {
    switch (store.id) {
      case 'bim':
        return const Color(0xFFE31837);
      case 'a101':
        return const Color(0xFF00B1E7);
      case 'migros':
        return const Color(0xFFFF7B00);
      case 'sok':
        return const Color(0xFFFFD200);
      case 'trendyol':
        return const Color(0xFFF27A1A);
      case 'getir':
        return const Color(0xFF5D3EBC);
      default:
        return AppColors.primary;
    }
  }

  Color _logoTextColor() {
    if (store.id == 'sok') return const Color(0xFFE31837);
    if (store.id == 'getir') return const Color(0xFFFFCC00);
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return PremiumPressable(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: MotionTokens.fast,
        curve: MotionTokens.standard,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.04)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppColors.primary.withOpacity(0.35)
                : AppColors.outline.withOpacity(0.4),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? AppColors.primary.withOpacity(0.08)
                  : Colors.black.withOpacity(0.03),
              blurRadius: selected ? 12 : 8,
              offset: Offset(0, selected ? 4 : 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Store logo
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _storeColor(),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: _storeColor().withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Text(
                      store.logoUrl,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _logoTextColor(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Store info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? AppColors.textPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (store.type != 'online' && store.distanceMeters > 0) ...[
                        Icon(Icons.near_me_rounded,
                            size: 12, color: AppColors.textTertiary),
                        const SizedBox(width: 4),
                        Text(
                          '${store.distanceMeters}m',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        if (store.subtitle != null) ...[
                          const Text(' \u00B7 ',
                              style: TextStyle(color: AppColors.textTertiary)),
                        ],
                      ],
                      if (store.subtitle != null)
                        Expanded(
                          child: Text(
                            store.subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // Checkmark
            AnimatedScale(
              duration: MotionTokens.fast,
              curve: MotionTokens.standard,
              scale: selected ? 1 : 0,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.text,
  });

  final IconData icon;
  final Color iconColor;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: iconColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
