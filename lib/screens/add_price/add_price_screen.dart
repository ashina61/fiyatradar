import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/store.dart';
import '../../providers/auth_provider.dart';
import '../../providers/price_report_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/barcode_scanner_sheet.dart';
import '../../widgets/premium_pressable.dart';

class AddPriceScreen extends ConsumerStatefulWidget {
  const AddPriceScreen({super.key, this.initialProductId});

  final String? initialProductId;

  @override
  ConsumerState<AddPriceScreen> createState() => _AddPriceScreenState();
}

class _AddPriceScreenState extends ConsumerState<AddPriceScreen>
    with SingleTickerProviderStateMixin {
  static const _headerBg = Color(0xFF1C1108);
  static const _appBg = Color(0xFFECEAE4);
  static const _tan = Color(0xFFB88C50);
  static const _gold = Color(0xFFC09A60);
  static const _textPrimary = Color(0xFF1C1108);
  static const _textSecondary = Color(0xFF6B5D4E);
  static const _textTertiary = Color(0xFFA89A8A);

  final _priceController = TextEditingController();
  final _productController = TextEditingController();
  final _searchController = TextEditingController();

  final _priceFocus = FocusNode();
  final _productFocus = FocusNode();

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
    _priceGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pid = widget.initialProductId?.trim() ?? '';
      if (pid.isEmpty) return;
      ref.read(addPriceProvider.notifier).initializeForProduct(pid);
    });
  }

  @override
  void dispose() {
    _priceController.dispose();
    _productController.dispose();
    _searchController.dispose();
    _priceFocus.dispose();
    _productFocus.dispose();
    _priceGlowController.dispose();
    super.dispose();
  }

  String _normalizePriceInput(String raw) {
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      },
    );

    final state = ref.watch(addPriceProvider);
    final notifier = ref.read(addPriceProvider.notifier);

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
        backgroundColor: _appBg,
        body: Stack(
          children: [
            Column(
              children: [
                _buildPremiumHeader(state, notifier),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(14, 12, 14, 100 + bottomSafe),
                    child: Column(
                      children: [
                        _buildSectionCard(
                          title: 'Ürün',
                          icon: Icons.sell_outlined,
                          iconBg: _tan.withOpacity(0.14),
                          iconColor: _gold,
                          child: _buildProductSection(state, notifier),
                        ),
                        const SizedBox(height: 12),
                        _buildSectionCard(
                          title: 'Nerede Gördün?',
                          icon: Icons.location_on_outlined,
                          iconBg: _headerBg.withOpacity(0.08),
                          iconColor: _textSecondary,
                          child: _buildLocationSection(state, notifier),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            _buildStickySaveBar(state, bottomSafe),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumHeader(AddPriceState state, AddPriceNotifier notifier) {
    return Container(
      decoration: const BoxDecoration(
        color: _headerBg,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _headerButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.maybePop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Fiyat Ekle',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color.fromRGBO(255, 255, 255, 0.55),
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  _headerButton(
                    icon: Icons.info_outline_rounded,
                    onTap: _showInfoModal,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              AnimatedBuilder(
                animation: _priceGlowController,
                builder: (context, child) => Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: _gold.withOpacity(
                          state.price.trim().isEmpty
                              ? 0
                              : (0.08 + (_priceGlowController.value * 0.08)),
                        ),
                        blurRadius: 26,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: child,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _priceController,
                            focusNode: _priceFocus,
                            onChanged: (v) => notifier.setPrice(_normalizePriceInput(v)),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[0-9,\.]')),
                            ],
                            style: const TextStyle(
                              fontSize: 62,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -3,
                              height: 1,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                            decoration: const InputDecoration(
                              hintText: '0,00',
                              hintStyle: TextStyle(
                                fontSize: 62,
                                fontWeight: FontWeight.w900,
                                color: Color.fromRGBO(255, 255, 255, 0.16),
                                letterSpacing: -3,
                                height: 1,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 10),
                          child: Text(
                            '₺',
                            style: TextStyle(
                              color: _gold,
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      state.price.trim().isEmpty ? 'Fiyatı girmek için dokun' : 'Güncel fiyat giriliyor',
                      style: const TextStyle(
                        color: Color.fromRGBO(255, 255, 255, 0.32),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            _gold.withOpacity(0.48),
                            _gold.withOpacity(0.48),
                            Colors.transparent,
                          ],
                        ),
                      ),
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

  Widget _headerButton({required IconData icon, required VoidCallback onTap}) {
    return PremiumPressable(
      borderRadius: BorderRadius.circular(13),
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, color: Colors.white.withOpacity(0.85), size: 18),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(28, 17, 8, 0.08),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, size: 16, color: iconColor),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: _textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color.fromRGBO(28, 17, 8, 0.09)),
          child,
        ],
      ),
    );
  }

  Widget _buildProductSection(AddPriceState state, AddPriceNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _productController,
                  focusNode: _productFocus,
                  onChanged: notifier.onProductInputChanged,
                  decoration: const InputDecoration(
                    hintText: 'ürün adı ya da marka…',
                    hintStyle: TextStyle(
                      color: _textTertiary,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  style: const TextStyle(
                    color: _textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              PremiumPressable(
                onTap: _scanBarcode,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: _tan.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _tan.withOpacity(0.25), width: 1.5),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.qr_code_scanner_rounded, size: 14, color: _tan),
                      SizedBox(width: 4),
                      Text(
                        'Tara',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: _tan,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_productFocus.hasFocus && state.productSuggestions.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF9F7F3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color.fromRGBO(28, 17, 8, 0.08)),
              ),
              child: ListView.separated(
                itemCount: state.productSuggestions.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final suggestion = state.productSuggestions[index];
                  return ListTile(
                    dense: true,
                    title: Text(
                      suggestion.name,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      [
                        if (suggestion.brand.trim().isNotEmpty) suggestion.brand.trim(),
                        ...suggestion.categories.take(1),
                      ].join(' • '),
                      style: const TextStyle(fontSize: 11, color: _textSecondary),
                    ),
                    onTap: () {
                      notifier.selectProductSuggestion(suggestion);
                      _productFocus.unfocus();
                    },
                  );
                },
              ),
            ),
          ],
          if (state.barcode != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Barkod: ${state.barcode}',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color.fromRGBO(28, 17, 8, 0.09)),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: state.categories.map((category) {
                final isSelected = state.selectedCategoryId == category.id;
                final icon = _categoryIcons[category.title] ?? Icons.label_outline_rounded;
                return PremiumPressable(
                  borderRadius: BorderRadius.circular(10),
                  onTap: state.lockedCategoryByProduct
                      ? null
                      : () => notifier.setCategory(category),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected ? _headerBg : const Color(0xFFECEAE4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 14,
                          color: isSelected ? Colors.white : _textSecondary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          category.title,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: isSelected ? Colors.white : _textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection(AddPriceState state, AddPriceNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _locationTab(
                  label: 'Yakınımda',
                  icon: Icons.location_on_outlined,
                  selected: state.activeTab == 0,
                  onTap: () => notifier.setActiveTab(0),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _locationTab(
                  label: 'Online',
                  icon: Icons.language_rounded,
                  selected: state.activeTab == 1,
                  onTap: () => notifier.setActiveTab(1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F1EC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: notifier.setSearchQuery,
              decoration: const InputDecoration(
                icon: Icon(Icons.search_rounded, color: _tan, size: 18),
                hintText: 'Market veya platform ara...',
                hintStyle: TextStyle(color: _textTertiary, fontSize: 13),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (state.locationMessage != null && state.isNearbyMode)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F2EC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                state.locationMessage!,
                style: const TextStyle(color: _textSecondary, fontSize: 12),
              ),
            ),
          if (state.isStoresLoading)
            const Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(strokeWidth: 2.2),
            )
          else if (state.storesError != null)
            _storesError(notifier)
          else if (state.visibleStores.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('Aramanıza uygun mağaza bulunamadı',
                  style: TextStyle(color: _textTertiary, fontSize: 12)),
            )
          else
            ...state.visibleStores.map(
              (store) => _storeTile(
                store: store,
                selected: state.selectedStore?.id == store.id,
                onTap: () {
                  HapticFeedback.selectionClick();
                  notifier.setSelectedStore(store);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _locationTab({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return PremiumPressable(
      borderRadius: BorderRadius.circular(13),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 40,
        decoration: BoxDecoration(
          color: selected ? _headerBg : const Color(0xFFECEAE4),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: selected ? Colors.white : _textTertiary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : _textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _storeTile({
    required Store store,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final distanceText = store.distanceMeters == null
        ? (store.subtitle?.isNotEmpty == true ? store.subtitle! : 'Online')
        : '${store.distanceMeters}m${store.subtitle?.isNotEmpty == true ? ' · ${store.subtitle}' : ''}';

    final source = (store.logoUrl?.isNotEmpty == true ? store.logoUrl! : store.name).trim();
    final initial = source.isEmpty ? '?' : source.substring(0, 1).toUpperCase();

    return PremiumPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color.fromRGBO(28, 17, 8, 0.04) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: selected ? _gold : _tan.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selected ? _gold : _tan,
                borderRadius: BorderRadius.circular(13),
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.name,
                    style: const TextStyle(
                      color: _textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    distanceText,
                    style: const TextStyle(
                      color: _textTertiary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (store.distanceMeters != null && store.distanceMeters! <= 200)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'EN YAKIN',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: selected ? _headerBg : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: selected
                      ? _headerBg
                      : const Color.fromRGBO(28, 17, 8, 0.1),
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _storesError(AddPriceNotifier notifier) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4F4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mağaza listesi yüklenemedi.',
            style: TextStyle(fontWeight: FontWeight.w700, color: Colors.redAccent),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: notifier.loadStoresAndCategories,
            child: const Text('Tekrar dene'),
          ),
        ],
      ),
    );
  }

  Widget _buildStickySaveBar(AddPriceState state, double bottomSafe) {
    final isReady = _isSubmitReady(state);
    final enabled = isReady && !state.isLoading && !state.isStoresLoading;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(14, 12, 14, 20 + bottomSafe),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [_appBg, Color.fromRGBO(236, 234, 228, 0)],
            stops: [0.58, 1],
          ),
        ),
        child: PremiumPressable(
          borderRadius: BorderRadius.circular(20),
          onTap: enabled ? _submit : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: 56,
            decoration: BoxDecoration(
              color: enabled ? _headerBg : const Color.fromRGBO(28, 17, 8, 0.08),
              borderRadius: BorderRadius.circular(20),
              boxShadow: enabled
                  ? const [
                      BoxShadow(
                        color: Color.fromRGBO(28, 17, 8, 0.28),
                        blurRadius: 24,
                        offset: Offset(0, 10),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: state.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_rounded,
                          color: enabled ? Colors.white : _textTertiary,
                          size: 17,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Fiyatı Kaydet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: enabled ? Colors.white : _textTertiary,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _scanBarcode() async {
    final barcode = await BarcodeScannerSheet.scan(context, title: 'Barkod Tara');
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        const SnackBar(content: Text('Fiyat gönderebilmek için giriş yapmalısın.')),
      );
      return;
    }

    if (currentUser.isAnonymous) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fiyat eklemek için giriş yapman gerekiyor.')),
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
              Expanded(child: Text('Fiyat başarıyla kaydedildi. +10 puan hesabına eklendi!')),
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
            kDebugMode
                ? 'Kaydedilemedi: $e'
                : 'Fiyat kaydedilemedi. Lütfen tekrar deneyin.',
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
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Bilgilendirme',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 18),
                  _InfoRow(
                    icon: Icons.stars_rounded,
                    iconColor: AppColors.accent,
                    text: 'Her fiyat girişi +10 puan kazandırır!',
                  ),
                  SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.groups_rounded,
                    iconColor: AppColors.primary,
                    text: 'Fiyatlar tamamen kullanıcılar tarafından bildirilmektedir.',
                  ),
                  SizedBox(height: 12),
                  _InfoRow(
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
