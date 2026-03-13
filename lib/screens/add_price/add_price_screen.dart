import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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
  const AddPriceScreen({super.key, this.initialProductId});

  final String? initialProductId;

  @override
  ConsumerState<AddPriceScreen> createState() => _AddPriceScreenState();
}

class _AddPriceScreenState extends ConsumerState<AddPriceScreen>
    with TickerProviderStateMixin {
  static const _headerBg = Color(0xFF1A120E);
  static const _brandBrown = Color(0xFFB88A5B);
  static const _bgApp = Color(0xFFEFECE6);
  static const _surfaceIvory = Color(0xFFFAFAFA);
  static const _gold = Color(0xFFC29B78);
  final _priceController = TextEditingController();
  final _productController = TextEditingController();
  final _searchController = TextEditingController();

  final _priceFocus = FocusNode();
  final _productFocus = FocusNode();

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
      // kullanıcı tab değiştirdiğinde state'e yaz
      if (_tabController.indexIsChanging) return;
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pid = widget.initialProductId?.trim() ?? '';
      if (pid.isEmpty) return;
      ref.read(addPriceProvider.notifier).initializeForProduct(pid);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _priceController.dispose();
    _productController.dispose();
    _searchController.dispose();
    _priceFocus.dispose();
    _productFocus.dispose();
    _headerAnimController.dispose();
    _priceGlowController.dispose();
    super.dispose();
  }

  String _normalizePriceInput(String raw) {
    // kullanıcı "12,50" yazınca provider tarafı genelde "12.50" ister
    return raw.replaceAll(' ', '').replaceAll(',', '.');
  }

  double? _parsePrice(String value) {
    final normalized = value.replaceAll(',', '.').trim();
    return double.tryParse(normalized);
  }

  bool _isSubmitReady(AddPriceState state) {
    final parsedPrice = _parsePrice(state.price);
    return (parsedPrice ?? 0) > 0 &&
        state.productName.trim().isNotEmpty &&
        state.selectedCategoryId != null &&
        state.selectedStoreId != null;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(
      addPriceProvider.select((s) => s.error),
      (_, next) {
        if (next != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      },
    );

    final state = ref.watch(addPriceProvider);
    final notifier = ref.read(addPriceProvider.notifier);
    final theme = Theme.of(context);

    // tab sync
    if (_tabController.index != state.activeTab) {
      _tabController.animateTo(state.activeTab);
    }

    // controller sync (cursor bozulmasın diye selection da koru)
    if (_priceController.text != state.price) {
      final sel = _priceController.selection;
      _priceController.text = state.price;
      _priceController.selection = sel;
    }

    if (_productController.text != state.productName) {
      final sel = _productController.selection;
      _productController.text = state.productName;
      _productController.selection = sel;
    }

    if (_searchController.text != state.searchQuery) {
      final sel = _searchController.selection;
      _searchController.text = state.searchQuery;
      _searchController.selection = sel;
    }

    final bottomSafe = MediaQuery.of(context).padding.bottom;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        FocusScope.of(context).unfocus();
        notifier.clearProductSuggestions();
      },
      child: Scaffold(
        backgroundColor: _bgApp,
        body: Stack(
          children: [
            Positioned(
              top: 120,
              left: 40,
              child: _AmbientOrb(
                size: 280,
                color: _brandBrown,
                opacity: 0.08,
              ),
            ),
            Positioned(
              top: 260,
              right: -90,
              child: _AmbientOrb(
                size: 200,
                color: _gold,
                opacity: 0.06,
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  FadeTransition(
                    opacity: _headerFade,
                    child: _buildHeader(theme),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      padding: EdgeInsets.fromLTRB(20, 20, 20, 100 + bottomSafe),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StaggeredFadeSlide(
                            index: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: _surfaceIvory,
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: _brandBrown.withOpacity(0.16),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _brandBrown.withOpacity(0.08),
                                    blurRadius: 28,
                                    offset: const Offset(0, 14),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  _buildPriceCard(state, theme, notifier),
                                  _buildDivider(),
                                  _buildProductSection(state, notifier, theme),
                                  _buildDivider(),
                                  _buildCategorySection(state, notifier, theme),
                                  _buildDivider(),
                                  _buildStoreSection(state, notifier, theme),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            _buildBottomAction(state, theme, bottomSafe),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Divider(
        height: 1,
        color: _brandBrown.withOpacity(0.12),
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────
  Widget _buildHeader(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 20),
      decoration: BoxDecoration(
        color: _headerBg,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.24),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          PremiumPressable(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _gold.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: _gold,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              children: [
                Text(
                  'Fiyat Ekle',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: _surfaceIvory,
                    fontWeight: FontWeight.w800,
                    fontSize: 19,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Topluluğa katkıda bulunun',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _gold.withOpacity(0.9),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          PremiumPressable(
            borderRadius: BorderRadius.circular(14),
            onTap: _showInfoModal,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _gold.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.info_outline_rounded,
                color: _gold,
                size: 21,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Price Card ──────────────────────────────────────────────
  Widget _buildPriceCard(
    AddPriceState state,
    ThemeData theme,
    AddPriceNotifier notifier,
  ) {
    return AnimatedBuilder(
      animation: _priceGlowController,
      builder: (context, child) {
        final glowOpacity = 0.05 + (_priceGlowController.value * 0.05);
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: _brandBrown.withOpacity(
                  state.price.isNotEmpty ? glowOpacity : 0.02,
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: _brandBrown.withOpacity(0.12),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sell_rounded, size: 14, color: _brandBrown),
                const SizedBox(width: 6),
                const Text(
                  'ÜRÜN FİYATI',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _brandBrown,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child: TextField(
                  controller: _priceController,
                  focusNode: _priceFocus,
                  onChanged: (v) => notifier.setPrice(_normalizePriceInput(v)),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9,\.]')),
                  ],
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 60,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -3,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    fillColor: Colors.transparent,
                    filled: false,
                    hintText: '0,00',
                    hintStyle: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 60,
                      fontWeight: FontWeight.w800,
                      color: AppColors.outline,
                      letterSpacing: -3,
                    ),
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text(
                  '₺',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    color: _brandBrown,
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
    AddPriceState state,
    AddPriceNotifier notifier,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(
          icon: Icons.inventory_2_outlined,
          label: 'Ürün Bilgisi',
          theme: theme,
        ),
        const SizedBox(height: 10),
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
                  focusNode: _productFocus,
                  onChanged: notifier.onProductInputChanged,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    fillColor: Colors.transparent,
                    filled: false,
                    hintText: 'Ürün adını yazın veya okutun...',
                    hintStyle: const TextStyle(color: AppColors.textHint),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    suffixIcon: state.productName.trim().isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _productController.clear();
                              notifier.onProductInputChanged('');
                            },
                            splashRadius: 16,
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: AppColors.textTertiary,
                            ),
                          ),
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

        if (_productFocus.hasFocus && state.productSuggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outline.withOpacity(0.35)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ListView.separated(
              itemCount: state.productSuggestions.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: AppColors.outline.withOpacity(0.2),
              ),
              itemBuilder: (context, index) {
                final suggestion = state.productSuggestions[index];
                final detail = [
                  if (suggestion.brand.trim().isNotEmpty)
                    suggestion.brand.trim(),
                  ...suggestion.categories.take(1),
                ].join(' • ');
                return ListTile(
                  dense: true,
                  visualDensity:
                      const VisualDensity(horizontal: -2, vertical: -3),
                  title: Text(
                    suggestion.name,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  subtitle: detail.isEmpty
                      ? null
                      : const Text(
                          '',
                          // placeholder; aşağıda override ediyoruz
                        ),
                  onTap: () {
                    notifier.selectProductSuggestion(suggestion);
                    _productFocus.unfocus();
                  },
                ).copyWithSubtitle(
                  detail.isEmpty
                      ? null
                      : Text(
                          detail,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                );
              },
            ),
          ),
        ],

        if (state.productName.trim().length >= 2 &&
            _productFocus.hasFocus &&
            state.productSuggestions.isEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outline.withOpacity(0.25)),
            ),
            child: const Text(
              'Ürün bulunamadı',
              style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
            ),
          ),
        ],

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
    ),
    );
  }

  // ─── Category Section ────────────────────────────────────────
  Widget _buildCategorySection(
    AddPriceState state,
    AddPriceNotifier notifier,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(
          icon: Icons.category_rounded,
          label: 'Kategori',
          theme: theme,
        ),
        const SizedBox(height: 10),
        if (state.categories.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant.withOpacity(0.45),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outline.withOpacity(0.25)),
            ),
            child: const Text(
              'Kategori verisi şu anda yüklenemedi.',
              style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
            ),
          )
        else
          Wrap(
          spacing: 10,
          runSpacing: 10,
          children: state.categories.map((category) {
            final isSelected = state.selectedCategoryId == category.id;
            final icon = _categoryIcons[category.title] ?? Icons.label_rounded;

            return PremiumPressable(
              borderRadius: BorderRadius.circular(14),
              onTap: state.lockedCategoryByProduct
                  ? null
                  : () => notifier.setCategory(category),
              child: AnimatedContainer(
                duration: MotionTokens.fast,
                curve: MotionTokens.standard,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: state.lockedCategoryByProduct && !isSelected
                      ? AppColors.surfaceVariant.withOpacity(0.5)
                      : (isSelected
                          ? AppColors.primary.withOpacity(0.1)
                          : AppColors.surface),
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
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
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
        if (state.lockedCategoryByProduct) ...[
          const SizedBox(height: 8),
          const Text(
            'Kategori seçilen ürüne göre kilitlendi.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    ),
    );
  }

  // ─── Store Section ───────────────────────────────────────────
  Widget _buildStoreSection(
    AddPriceState state,
    AddPriceNotifier notifier,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(
          icon: Icons.storefront_rounded,
          label: 'Nerede Gördün?',
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
                    Text('Yakınımda'),
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

        if (state.locationMessage != null && state.isNearbyMode) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant.withOpacity(0.45),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.outline.withOpacity(0.25)),
            ),
            child: Text(
              state.locationMessage!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

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
                      decoration: const InputDecoration(
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
    ),
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
    AddPriceState state,
    AddPriceNotifier notifier,
    ThemeData theme,
  ) {
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
                  'Mağazalar yüklenemedi',
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
            'Aramanıza uygun mağaza bulunamadı',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bottom Action ───────────────────────────────────────────
  Widget _buildBottomAction(AddPriceState state, ThemeData theme, double bottomSafe) {
    final isReady = _isSubmitReady(state);

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
              color: _bgApp.withOpacity(0.9),
              border: Border(
                top: BorderSide(color: AppColors.outline.withOpacity(0.3)),
              ),
            ),
            child: PremiumPressable(
              borderRadius: BorderRadius.circular(16),
              onTap: (!isReady || state.isLoading || state.isStoresLoading) ? null : _submit,
              pressedScale: 0.98,
              child: AnimatedContainer(
                duration: MotionTokens.fast,
                curve: MotionTokens.standard,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: isReady
                      ? const LinearGradient(
                          colors: [_brandBrown, AppColors.accent],
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
                            color: isReady ? Colors.white : AppColors.textTertiary,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Fiyatı Kaydet',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isReady ? Colors.white : AppColors.textTertiary,
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
    final barcode =
        await BarcodeScannerSheet.scan(context, title: 'Barkod Tara');
    if (barcode != null && mounted) {
      final knownProduct =
          await ref.read(addPriceProvider.notifier).applyScannedBarcode(barcode);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            knownProduct
                ? 'Barkod okundu ve ürün seçildi: $barcode'
                : 'Barkod okundu: $barcode',
          ),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _submit() async {
    final authStateUser = ref.read(authStateProvider).value;
    final currentUser = authStateUser ?? FirebaseAuth.instance.currentUser;

    final state = ref.read(addPriceProvider);
    if (currentUser == null || currentUser.uid.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fiyat gönderebilmek için giriş yapmalısın.'),
        ),
      );
      return;
    }

    if (currentUser.isAnonymous) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fiyat eklemek için giriş yapman gerekiyor.'),
        ),
      );
      return;
    }

    try {
      await ref.read(addPriceProvider.notifier).submitPrice(userId: currentUser.uid);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Expanded(
                child:
                    Text('Fiyat başarıyla kaydedildi. +10 puan hesabına eklendi!'),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      Navigator.maybePop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            kDebugMode ? 'Kaydedilemedi: $e' : 'Fiyat kaydedilemedi. Lütfen tekrar deneyin.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showInfoModal() async {
    await showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => Dialog(
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
                          decoration: const BoxDecoration(
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
                  const _InfoRow(
                    icon: Icons.stars_rounded,
                    iconColor: AppColors.accent,
                    text: 'Her fiyat girişi +10 puan kazandırır!',
                  ),
                  const SizedBox(height: 12),
                  const _InfoRow(
                    icon: Icons.groups_rounded,
                    iconColor: AppColors.primary,
                    text: 'Fiyatlar tamamen kullanıcılar tarafından bildirilmektedir.',
                  ),
                  const SizedBox(height: 12),
                  const _InfoRow(
                    icon: Icons.verified_rounded,
                    iconColor: AppColors.success,
                    text: 'Doğru fiyat girişleri güven puanınızı artırır.',
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

  String _formatDistance(int? meters) {
    if (meters == null) return '—';
    if (meters < 1000) return '${meters}m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

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
          color: selected ? AppColors.primary.withOpacity(0.04) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary.withOpacity(0.35) : AppColors.outline.withOpacity(0.4),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: selected ? AppColors.primary.withOpacity(0.08) : Colors.black.withOpacity(0.03),
              blurRadius: selected ? 12 : 8,
              offset: Offset(0, selected ? 4 : 2),
            ),
          ],
        ),
        child: Row(
          children: [
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (store.type != 'online') ...[
                        const Icon(Icons.near_me_rounded, size: 12, color: AppColors.textTertiary),
                        const SizedBox(width: 4),
                        Text(
                          _formatDistance(store.distanceMeters),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        if (store.subtitle != null) ...[
                          const Text(' · ', style: TextStyle(color: AppColors.textTertiary)),
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
                child: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
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

/// Tiny helper: ListTile'da subtitle'ı kolay override etmek için
extension on ListTile {
  ListTile copyWithSubtitle(Widget? subtitle) {
    return ListTile(
      key: key,
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      isThreeLine: isThreeLine,
      dense: dense,
      visualDensity: visualDensity,
      shape: shape,
      selectedColor: selectedColor,
      iconColor: iconColor,
      textColor: textColor,
      contentPadding: contentPadding,
      enabled: enabled,
      onTap: onTap,
      onLongPress: onLongPress,
      selected: selected,
      focusColor: focusColor,
      hoverColor: hoverColor,
      autofocus: autofocus,
      tileColor: tileColor,
      selectedTileColor: selectedTileColor,
      enableFeedback: enableFeedback,
      horizontalTitleGap: horizontalTitleGap,
      minVerticalPadding: minVerticalPadding,
      minLeadingWidth: minLeadingWidth,
    );
  }
}
