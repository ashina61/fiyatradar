import 'dart:io';
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../models/category_model.dart';
import '../../models/product_model.dart';
import '../../models/store.dart';
import '../../providers/auth_provider.dart';
import '../../providers/price_report_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/app_network_image.dart';
import '../../widgets/barcode_scanner_sheet.dart';
import '../../widgets/premium_pressable.dart';

const _dark = Color(0xFF1C1108);
const _bg = Color(0xFFECEAE4);
const _white = Color(0xFFFFFFFF);
const _tan = Color(0xFFB88C50);
const _gold = Color(0xFFC09A60);
const _green = Color(0xFF27A85A);
const _greenBg = Color(0x1A27A85A);
const _t1 = Color(0xFF1C1108);
const _t2 = Color(0xFF6B5D4E);
const _t3 = Color(0xFFA89A8A);
const _border = Color(0x121C1108);

enum _AddStep { product, store, price }

TextStyle _pjs({
  double size = 14,
  FontWeight weight = FontWeight.w600,
  Color color = _t1,
  double? letterSpacing,
  double? height,
}) {
  return GoogleFonts.plusJakartaSans(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
  );
}

class AddPriceScreen extends ConsumerStatefulWidget {
  const AddPriceScreen({super.key, this.initialProductId});

  final String? initialProductId;

  @override
  ConsumerState<AddPriceScreen> createState() => _AddPriceScreenState();
}

class _AddPriceScreenState extends ConsumerState<AddPriceScreen> {
  final _productController = TextEditingController();
  final _priceController = TextEditingController();
  final _productFocus = FocusNode();
  final _priceFocus = FocusNode();
  final _scrollController = ScrollController();

  final _productKey = GlobalKey();
  final _storeKey = GlobalKey();
  final _priceKey = GlobalKey();


  _AddStep _activeStep = _AddStep.product;
  bool _productCollapsed = false;
  bool _storeCollapsed = false;
  bool _showSuccess = false;
  XFile? _productPhoto;

  String _savedProduct = '—';
  String _savedStore = '—';
  String _savedPrice = '—';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pid = widget.initialProductId?.trim() ?? '';
      if (pid.isNotEmpty) {
        ref.read(addPriceProvider.notifier).initializeForProduct(pid);
      }
    });
  }

  @override
  void dispose() {
    _productController.dispose();
    _priceController.dispose();
    _productFocus.dispose();
    _priceFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool _isProductDone(AddPriceState state) =>
      state.productName.trim().isNotEmpty && state.selectedCategoryId != null;
  bool _isStoreDone(AddPriceState state) => state.selectedStoreId != null;
  bool _isPriceDone(AddPriceState state) => _parsePriceInput(state.price) != null;

  bool _isFormReady(AddPriceState state) =>
      _isProductDone(state) && _isStoreDone(state) && _isPriceDone(state);

  void _syncControllers(AddPriceState state) {
    if (_productController.text != state.productName) {
      _productController.value = TextEditingValue(
        text: state.productName,
        selection: TextSelection.collapsed(offset: state.productName.length),
      );
    }
    if (_priceController.text != state.price) {
      _priceController.value = TextEditingValue(
        text: state.price,
        selection: TextSelection.collapsed(offset: state.price.length),
      );
    }
  }


  void _updateStep(AddPriceState state) {
    final next = !_isProductDone(state)
        ? _AddStep.product
        : !_isStoreDone(state)
            ? _AddStep.store
            : _AddStep.price;
    if (next != _activeStep) {
      setState(() => _activeStep = next);
    }
  }

  Future<void> _scrollToStep(_AddStep step, {bool expand = false}) async {
    if (expand) {
      setState(() {
        if (step == _AddStep.product) _productCollapsed = false;
        if (step == _AddStep.store) _storeCollapsed = false;
      });
    }
    final key = switch (step) {
      _AddStep.product => _productKey,
      _AddStep.store => _storeKey,
      _AddStep.price => _priceKey,
    };
    final ctx = key.currentContext;
    if (ctx == null) return;
    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      alignment: 0.02,
    );
    if (step == _AddStep.price) _priceFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addPriceProvider);
    final notifier = ref.read(addPriceProvider.notifier);
    final safeBottom = MediaQuery.of(context).padding.bottom;

    _syncControllers(state);
    _updateStep(state);

    ref.listen<String?>(addPriceProvider.select((s) => s.error), (_, next) {
      if (next != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next), behavior: SnackBarBehavior.floating),
        );
      }
    });

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        notifier.clearProductSuggestions();
      },
      child: Scaffold(
        backgroundColor: _bg,
        resizeToAvoidBottomInset: false,
        bottomNavigationBar: _buildSaveBar(state, safeBottom),
        body: Stack(
          children: [
            Column(
              children: [
                _buildHeader(state, notifier),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: Column(
                      children: [
                        _buildProductSection(state, notifier),
                        const SizedBox(height: 24),
                        _buildStoreSection(state, notifier),
                        const SizedBox(height: 24),
                        _buildPriceSection(state, notifier),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            _buildSuccessOverlay(safeBottom, notifier),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AddPriceState state, AddPriceNotifier notifier) {
    final productDone = _isProductDone(state);
    final storeDone = _isStoreDone(state);
    final priceDone = _isPriceDone(state);

    return Container(
      decoration: const BoxDecoration(
        color: _dark,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -28,
            top: -28,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [_gold.withOpacity(0.2), Colors.transparent],
                  stops: const [0, 0.62],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 26),
              child: Column(
                children: [
                  Row(
                    children: [
                      _headerButton(Icons.arrow_back_ios_new_rounded, () => Navigator.maybePop(context)),
                      Expanded(
                        child: Text(
                          'Fiyat Ekle',
                          textAlign: TextAlign.center,
                          style: _pjs(size: 15, weight: FontWeight.w800, color: Colors.white.withOpacity(0.4)),
                        ),
                      ),
                      PremiumPressable(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => _resetAll(notifier),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Text('Sıfırla', style: _pjs(size: 11, weight: FontWeight.w800, color: Colors.white.withOpacity(0.3))),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _AnswerPill(
                          label: 'Ürün',
                          value: productDone ? _truncate(state.productName, 12) : '—',
                          filled: productDone,
                          onTap: () => _scrollToStep(_AddStep.product, expand: true),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: _AnswerPill(
                          label: 'Market',
                          value: storeDone ? _truncate(state.selectedStoreName ?? '', 12) : '—',
                          filled: storeDone,
                          onTap: () => _scrollToStep(_AddStep.store, expand: true),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: _AnswerPill(
                          label: 'Fiyat',
                          value: priceDone ? '${_displayAmount(state.price)} ₺' : '—',
                          filled: priceDone,
                          onTap: () => _scrollToStep(_AddStep.price),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductSection(AddPriceState state, AddPriceNotifier notifier) {
    final done = _isProductDone(state);
    return Column(
      key: _productKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('🏷️  Hangi ürün?', style: _pjs(size: 13, weight: FontWeight.w900, letterSpacing: -0.15)),
        const SizedBox(height: 10),
        AnimatedSize(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          child: _productCollapsed && done
              ? _SummaryRowCard(
                  icon: Icons.sell_outlined,
                  iconBg: _tan.withOpacity(0.1),
                  iconColor: _gold,
                  title: state.productName,
                  subtitle: state.selectedCategoryName ?? 'Ürün',
                  onTap: () => setState(() => _productCollapsed = false),
                )
              : Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: _white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [BoxShadow(color: Color.fromRGBO(28, 17, 8, .08), blurRadius: 18, offset: Offset(0, 2))],
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _productController,
                                    focusNode: _productFocus,
                                    onChanged: notifier.onProductInputChanged,
                                    style: _pjs(size: 16, weight: FontWeight.w800),
                                    decoration: InputDecoration(
                                      hintText: 'ürün adını yaz…',
                                      hintStyle: _pjs(size: 16, weight: FontWeight.w500, color: _t3),
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                PremiumPressable(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: _scanBarcode,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: _tan.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.qr_code_2_rounded, size: 13, color: _tan),
                                        const SizedBox(width: 4),
                                        Text('Tara', style: _pjs(size: 11, weight: FontWeight.w800, color: _tan)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOutCubic,
                            height: _showSuggestions(state) ? math.min(52.0 * state.productSuggestions.length + 1, 260) : 0,
                            child: ClipRect(
                              child: ListView.separated(
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: state.productSuggestions.length,
                                separatorBuilder: (_, __) => const Divider(height: 1, color: _border),
                                itemBuilder: (context, i) {
                                  final p = state.productSuggestions[i];
                                  return InkWell(
                                    onTap: () => _onProductPicked(p, notifier),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      child: Row(
                                        children: [
                                          Expanded(child: Text(p.name, style: _pjs(size: 14, weight: FontWeight.w800))),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: _gold.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text((p.categories.isNotEmpty ? p.categories.first : 'Ürün'), style: _pjs(size: 10, weight: FontWeight.w800, color: _gold)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: _showRequestProductCta(state)
                          ? Padding(
                              key: const ValueKey('request-product-cta'),
                              padding: const EdgeInsets.only(top: 10),
                              child: _buildRequestProductButton(state, notifier),
                            )
                          : const SizedBox.shrink(),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: done
                          ? Padding(
                              key: const ValueKey('product-image-row'),
                              padding: const EdgeInsets.only(top: 10),
                              child: _ProductImageRow(
                                imagePath: _productPhoto?.path,
                                imageUrl: state.selectedProductImageUrl,
                                productName: state.productName,
                                subtitle: state.selectedCategoryName ?? 'Ürün seçildi',
                                onTapPhoto: _pickProductImage,
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 8),
                    _CategoryChips(state: state, notifier: notifier),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildStoreSection(AddPriceState state, AddPriceNotifier notifier) {
    final done = _isStoreDone(state);
    return Column(
      key: _storeKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('📍  Nerede gördün?', style: _pjs(size: 13, weight: FontWeight.w900, letterSpacing: -0.15)),
        const SizedBox(height: 10),
        AnimatedSize(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          child: _storeCollapsed && done && state.selectedStore != null
              ? _SummaryRowCard(
                  icon: Icons.store_mall_directory_outlined,
                  iconBg: _dark.withOpacity(0.07),
                  iconColor: _t2,
                  title: state.selectedStore!.name,
                  subtitle: _storeSubtitle(state.selectedStore!),
                  onTap: () => setState(() => _storeCollapsed = false),
                )
              : Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _StoreModeButton(
                            icon: Icons.location_on_outlined,
                            text: 'Yakınımda',
                            on: state.activeTab == 0,
                            onTap: () => notifier.setActiveTab(0),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _StoreModeButton(
                            icon: Icons.language,
                            text: 'Online',
                            on: state.activeTab == 1,
                            onTap: () => notifier.setActiveTab(1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: _white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [BoxShadow(color: Color.fromRGBO(28, 17, 8, .08), blurRadius: 18, offset: Offset(0, 2))],
                      ),
                      child: state.isStoresLoading
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 26),
                              child: Center(child: CircularProgressIndicator(color: _tan)),
                            )
                          : Column(
                              children: state.visibleStores.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final store = entry.value;
                                final selected = state.selectedStore?.id == store.id;
                                return _StoreRow(
                                  store: store,
                                  selected: selected,
                                  showDivider: idx != state.visibleStores.length - 1,
                                  showNearestBadge: state.activeTab == 0 && idx == 0,
                                  onTap: () {
                                    notifier.setSelectedStore(store);
                                    Future.delayed(const Duration(milliseconds: 320), () {
                                      if (!mounted) return;
                                      setState(() => _storeCollapsed = true);
                                      _scrollToStep(_AddStep.price);
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildPriceSection(AddPriceState state, AddPriceNotifier notifier) {
    final hasPrice = _isPriceDone(state);
    final parts = _displayAmount(state.price).split(',');
    return Column(
      key: _priceKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('💰  Kaç lira?', style: _pjs(size: 13, weight: FontWeight.w900, letterSpacing: -0.15)),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => _priceFocus.requestFocus(),
          child: Container(
            decoration: BoxDecoration(
              color: _white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Color.fromRGBO(28, 17, 8, .08), blurRadius: 18, offset: Offset(0, 2))],
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _priceController,
                  focusNode: _priceFocus,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                  onChanged: (v) => _onPriceInput(v, notifier),
                  style: _pjs(size: 16, weight: FontWeight.w700, color: _t2),
                  decoration: InputDecoration(
                    hintText: 'Örn: 50,75',
                    hintStyle: _pjs(size: 14, weight: FontWeight.w500, color: _t3),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 130),
                      transitionBuilder: (child, animation) => ScaleTransition(scale: Tween<double>(begin: 1.05, end: 1).animate(animation), child: child),
                      child: Text(
                        parts.first,
                        key: ValueKey(parts.first),
                        style: _pjs(
                          size: 64,
                          weight: FontWeight.w900,
                          color: hasPrice ? _t1 : _t1.withOpacity(.1),
                          letterSpacing: -3.5,
                          height: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 3),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(',${parts[1]}', style: _pjs(size: 28, weight: FontWeight.w700, color: _t1.withOpacity(hasPrice ? .42 : .18), letterSpacing: -1)),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 6),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: hasPrice ? 1 : 0.45,
                        child: Text('₺', style: _pjs(size: 28, weight: FontWeight.w900, color: _gold)),
                      ),
                    ),
                  ],
                ),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 170),
                  opacity: hasPrice ? 0 : 1,
                  child: Row(
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: .55, end: 1),
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.easeInOut,
                        builder: (context, value, child) => Transform.scale(scale: value, child: Opacity(opacity: value, child: child)),
                        onEnd: () {
                          if (mounted && !_isPriceDone(state)) setState(() {});
                        },
                        child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: _gold, shape: BoxShape.circle)),
                      ),
                      const SizedBox(width: 6),
                      Text('Dokunarak fiyatı gir', style: _pjs(size: 12, weight: FontWeight.w600, color: _t3)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveBar(AddPriceState state, double safeBottom) {
    final enabled = _isFormReady(state) && !state.isLoading;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 14 + safeBottom),
      decoration: const BoxDecoration(
        color: _bg,
      ),
      child: SafeArea(
        top: false,
        child: IgnorePointer(
          ignoring: !enabled,
          child: PremiumPressable(
            borderRadius: BorderRadius.circular(20),
            onTap: enabled ? _submit : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 58,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: enabled ? const LinearGradient(colors: [_dark, Color(0xFF2C1A0A)], begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
                color: enabled ? null : _dark.withOpacity(.07),
                boxShadow: enabled
                    ? const [BoxShadow(color: Color.fromRGBO(28, 17, 8, .26), blurRadius: 30, offset: Offset(0, 10))]
                    : null,
              ),
              child: Center(
                child: state.isLoading
                    ? const CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_rounded, size: 17, color: enabled ? Colors.white : _t3),
                          const SizedBox(width: 9),
                          Text('Fiyatı Kaydet', style: _pjs(size: 16, weight: FontWeight.w900, color: enabled ? Colors.white : _t3)),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessOverlay(double safeBottom, AddPriceNotifier notifier) {
    return IgnorePointer(
      ignoring: !_showSuccess,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        opacity: _showSuccess ? 1 : 0,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          offset: _showSuccess ? Offset.zero : const Offset(0, .03),
          child: Container(
            color: _bg,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(28, 52, 28, 32),
                  decoration: const BoxDecoration(
                    color: _dark,
                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(36), bottomRight: Radius.circular(36)),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      children: [
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 500),
                          tween: Tween(begin: .3, end: 1),
                          curve: Curves.easeOutBack,
                          builder: (context, value, child) => Opacity(opacity: value.clamp(0, 1), child: Transform.scale(scale: value, child: child)),
                          child: Text('🎉', style: _pjs(size: 48, weight: FontWeight.w700, color: Colors.white)),
                        ),
                        const SizedBox(height: 14),
                        Text('Kaydedildi!', style: _pjs(size: 24, weight: FontWeight.w900, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text('Katkın için teşekkürler · +10 puan', style: _pjs(size: 12, weight: FontWeight.w500, color: Colors.white.withOpacity(.35))),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: _white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [BoxShadow(color: Color.fromRGBO(28, 17, 8, .07), blurRadius: 14, offset: Offset(0, 2))],
                          ),
                          child: Column(
                            children: [
                              Text('Girilen Fiyat'.toUpperCase(), style: _pjs(size: 10, weight: FontWeight.w800, color: _t3, letterSpacing: .8)),
                              const SizedBox(height: 6),
                              Text(_savedPrice, style: _pjs(size: 52, weight: FontWeight.w900, color: _green, letterSpacing: -2.5)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: _white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [BoxShadow(color: Color.fromRGBO(28, 17, 8, .07), blurRadius: 10, offset: Offset(0, 1))],
                          ),
                          child: Column(
                            children: [
                              _SuccessSummaryRow(label: 'Ürün', value: _savedProduct),
                              _SuccessSummaryRow(label: 'Market', value: _savedStore),
                              const _SuccessSummaryRow(label: 'Kazanılan', value: '+10 puan ⭐', highlight: true, last: true),
                            ],
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: () async {
                              setState(() => _showSuccess = false);
                              await Future.delayed(const Duration(milliseconds: 200));
                              _resetAll(notifier);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _dark,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            ),
                            child: Text('Yeni Fiyat Ekle', style: _pjs(size: 15, weight: FontWeight.w800, color: Colors.white)),
                          ),
                        ),
                        SizedBox(height: safeBottom > 0 ? safeBottom : 6),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _showSuggestions(AddPriceState state) =>
      _productFocus.hasFocus && state.productSuggestions.isNotEmpty;

  bool _showRequestProductCta(AddPriceState state) {
    final query = state.productName.trim();
    return query.length >= 2 && state.productSuggestions.isEmpty && state.selectedProductId == null;
  }

  Widget _buildRequestProductButton(AddPriceState state, AddPriceNotifier notifier) {
    return PremiumPressable(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _submitProductSuggestion(notifier),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _gold.withOpacity(0.35)),
        ),
        child: Row(
          children: [
            const Icon(Icons.campaign_outlined, color: _tan, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Aradığın ürünü bulamadın mı? Ürün talebi gönder',
                style: _pjs(size: 12, weight: FontWeight.w800, color: _t2),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: _tan),
          ],
        ),
      ),
    );
  }

  Future<void> _onProductPicked(ProductModel p, AddPriceNotifier notifier) async {
    notifier.selectProductSuggestion(p);
    FocusScope.of(context).unfocus();
    await Future<void>.delayed(const Duration(milliseconds: 320));
    if (!mounted) return;
    setState(() => _productCollapsed = true);
    await _scrollToStep(_AddStep.store);
  }

  void _onPriceInput(String value, AddPriceNotifier notifier) {
    notifier.setPrice(value);
  }

  double? _parsePriceInput(String input) {
    final normalized = input.replaceAll(' ', '').replaceAll(',', '.').trim();
    if (normalized.isEmpty) return null;
    if (!RegExp(r'^\d+(\.\d{0,2})?$').hasMatch(normalized)) return null;
    final parsed = double.tryParse(normalized);
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }

  String _displayAmount(String input) {
    final parsed = _parsePriceInput(input);
    if (parsed == null) return '0,00';
    final formatted = parsed.toStringAsFixed(2).split('.');
    final intPart = NumberFormat.decimalPattern('tr_TR').format(int.parse(formatted[0]));
    return '$intPart,${formatted[1]}';
  }

  String _storeSubtitle(Store store) {
    if (store.distanceMeters != null) {
      return '${store.distanceMeters}m${store.subtitle != null ? ' · ${store.subtitle}' : ''}';
    }
    return store.subtitle ?? 'Online';
  }

  Future<void> _scanBarcode() async {
    final barcode = await BarcodeScannerSheet.scan(context, title: 'Barkod Tara');
    if (barcode == null || !mounted) return;
    final found = await ref.read(addPriceProvider.notifier).applyScannedBarcode(barcode);
    if (!mounted) return;
    if (found) {
      await Future<void>.delayed(const Duration(milliseconds: 320));
      if (!mounted) return;
      setState(() => _productCollapsed = true);
      _scrollToStep(_AddStep.store);
    }
  }

  Future<void> _submitProductSuggestion(AddPriceNotifier notifier) async {
    final auth = ref.read(authStateProvider).value;
    final user = auth ?? FirebaseAuth.instance.currentUser;
    if (user == null || user.uid.trim().isEmpty || user.isAnonymous) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ürün talebi göndermek için giriş yapman gerekiyor.')),
      );
      return;
    }

    try {
      await notifier.submitProductSuggestion(userId: user.uid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ürün talebi alındı, teşekkürler!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _submit() async {
    final auth = ref.read(authStateProvider).value;
    final user = auth ?? FirebaseAuth.instance.currentUser;
    if (user == null || user.uid.trim().isEmpty || user.isAnonymous) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fiyat eklemek için giriş yapman gerekiyor.')),
      );
      return;
    }

    final stateBefore = ref.read(addPriceProvider);
    try {
      await ref.read(addPriceProvider.notifier).submitPrice(userId: user.uid);
      if (!mounted) return;
      setState(() {
        _savedPrice = '${_displayAmount(stateBefore.price)} ₺';
        _savedProduct = stateBefore.productName;
        _savedStore = stateBefore.selectedStoreName ?? '—';
        _showSuccess = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(kDebugMode ? 'Kaydedilemedi: $e' : 'Fiyat kaydedilemedi. Lütfen tekrar deneyin.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _pickProductImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null || !mounted) return;
    setState(() => _productPhoto = file);
  }

  void _resetAll(AddPriceNotifier notifier) {
    notifier.onProductInputChanged('');
    notifier.setCategory(null);
    notifier.setPrice('');
    notifier.setActiveTab(0);
    notifier.setSearchQuery('');
    setState(() {
      _productCollapsed = false;
      _storeCollapsed = false;
      _showSuccess = false;
      _productPhoto = null;
      _activeStep = _AddStep.product;
    });
    _scrollController.animateTo(0, duration: const Duration(milliseconds: 260), curve: Curves.easeOutCubic);
  }

  Widget _headerButton(IconData icon, VoidCallback onTap) {
    return PremiumPressable(
      borderRadius: BorderRadius.circular(13),
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.08),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, size: 16, color: Colors.white.withOpacity(.8)),
      ),
    );
  }

  String _truncate(String value, int max) {
    if (value.length <= max) return value;
    return '${value.substring(0, max - 1)}…';
  }
}

class _AnswerPill extends StatelessWidget {
  const _AnswerPill({required this.label, required this.value, required this.filled, required this.onTap});

  final String label;
  final String value;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PremiumPressable(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: filled ? _gold.withOpacity(.15) : Colors.white.withOpacity(.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: filled ? _gold.withOpacity(.35) : Colors.white.withOpacity(.08), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), style: _pjs(size: 9, weight: FontWeight.w800, letterSpacing: .7, color: filled ? _gold.withOpacity(.7) : Colors.white.withOpacity(.28))),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _pjs(size: 12, weight: FontWeight.w800, color: filled ? Colors.white.withOpacity(.75) : Colors.white.withOpacity(.22)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRowCard extends StatelessWidget {
  const _SummaryRowCard({required this.icon, required this.iconBg, required this.iconColor, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PremiumPressable(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Color.fromRGBO(28, 17, 8, .07), blurRadius: 14, offset: Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 14, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, overflow: TextOverflow.ellipsis, style: _pjs(size: 14, weight: FontWeight.w800)),
                  const SizedBox(height: 1),
                  Text(subtitle, style: _pjs(size: 11, weight: FontWeight.w500, color: _t3)),
                ],
              ),
            ),
            Text('Değiştir', style: _pjs(size: 11, weight: FontWeight.w700, color: _tan)),
            const SizedBox(width: 8),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(7)),
              child: const Icon(Icons.check_rounded, size: 12, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductImageRow extends StatelessWidget {
  const _ProductImageRow({required this.imagePath, required this.imageUrl, required this.productName, required this.subtitle, required this.onTapPhoto});

  final String? imagePath;
  final String? imageUrl;
  final String productName;
  final String subtitle;
  final VoidCallback onTapPhoto;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color.fromRGBO(28, 17, 8, .07), blurRadius: 14, offset: Offset(0, 2))],
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Row(
        children: [
          PremiumPressable(
            borderRadius: BorderRadius.circular(16),
            onTap: onTapPhoto,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border, width: 1.5),
              ),
              child: imagePath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(File(imagePath!), fit: BoxFit.cover),
                    )
                  : AppNetworkImage(
                      imageUrl: imageUrl,
                      cacheKey: 'add-price-selected-product',
                      fit: BoxFit.cover,
                      borderRadius: BorderRadius.circular(14),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(productName, maxLines: 1, overflow: TextOverflow.ellipsis, style: _pjs(size: 15, weight: FontWeight.w800, letterSpacing: -0.2)),
                const SizedBox(height: 2),
                Text(subtitle, style: _pjs(size: 11, weight: FontWeight.w500, color: _t3)),
                const SizedBox(height: 6),
                PremiumPressable(
                  borderRadius: BorderRadius.circular(8),
                  onTap: onTapPhoto,
                  child: Text('+ Fotoğraf ekle', style: _pjs(size: 10, weight: FontWeight.w700, color: _tan)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.state, required this.notifier});

  final AddPriceState state;
  final AddPriceNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: state.categories.map((cat) {
          final selected = state.selectedCategoryId == cat.id;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: PremiumPressable(
              borderRadius: BorderRadius.circular(999),
              onTap: state.lockedCategoryByProduct ? null : () => notifier.setCategory(cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                decoration: BoxDecoration(
                  color: selected ? _dark : _white,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: const [BoxShadow(color: Color.fromRGBO(28, 17, 8, .06), blurRadius: 5, offset: Offset(0, 1))],
                  border: Border.all(color: selected ? Colors.transparent : Colors.transparent, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      cat.iconAssetPath,
                      width: 14,
                      height: 14,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Text(
                        cat.emoji?.trim().isNotEmpty == true ? cat.emoji!.trim() : '🏷️',
                        style: _pjs(size: 12, weight: FontWeight.w800, color: selected ? Colors.white.withOpacity(.9) : _t2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      cat.title,
                      style: _pjs(size: 12, weight: FontWeight.w800, color: selected ? Colors.white.withOpacity(.9) : _t2),
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
}

class _StoreModeButton extends StatelessWidget {
  const _StoreModeButton({required this.icon, required this.text, required this.on, required this.onTap});

  final IconData icon;
  final String text;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PremiumPressable(
      borderRadius: BorderRadius.circular(13),
      onTap: onTap,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: on ? _dark : _white,
          borderRadius: BorderRadius.circular(13),
          boxShadow: const [BoxShadow(color: Color.fromRGBO(28, 17, 8, .06), blurRadius: 5, offset: Offset(0, 1))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 12, color: on ? Colors.white : _t3),
            const SizedBox(width: 6),
            Text(text, style: _pjs(size: 12, weight: FontWeight.w800, color: on ? Colors.white : _t3)),
          ],
        ),
      ),
    );
  }
}

class _StoreRow extends StatelessWidget {
  const _StoreRow({required this.store, required this.selected, required this.showDivider, required this.showNearestBadge, required this.onTap});

  final Store store;
  final bool selected;
  final bool showDivider;
  final bool showNearestBadge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PremiumPressable(
      borderRadius: BorderRadius.zero,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: selected ? _dark.withOpacity(.028) : Colors.transparent,
          border: showDivider ? const Border(bottom: BorderSide(color: _border)) : null,
        ),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _avatarColor(store.name),
                borderRadius: BorderRadius.circular(13),
                boxShadow: const [BoxShadow(color: Color.fromRGBO(0, 0, 0, .16), blurRadius: 8, offset: Offset(0, 3))],
                border: selected ? Border.all(color: _gold, width: 2) : null,
              ),
              alignment: Alignment.center,
              child: Text(store.logoUrl.isNotEmpty ? store.logoUrl[0] : '?', style: _pjs(size: 14, weight: FontWeight.w900, color: Colors.white)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(store.name, style: _pjs(size: 14, weight: FontWeight.w900)),
                  const SizedBox(height: 1),
                  Text(_subText(store), style: _pjs(size: 11, weight: FontWeight.w500, color: _t3)),
                ],
              ),
            ),
            if (showNearestBadge)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: _greenBg, borderRadius: BorderRadius.circular(5)),
                child: Text('En Yakın'.toUpperCase(), style: _pjs(size: 8, weight: FontWeight.w900, color: _green, letterSpacing: .4)),
              ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: selected ? _dark : _border, width: 2),
                color: selected ? _dark : Colors.transparent,
              ),
              child: selected ? const Icon(Icons.check_rounded, size: 12, color: Colors.white) : null,
            ),
          ],
        ),
      ),
    );
  }

  String _subText(Store store) {
    if (store.distanceMeters != null) {
      return '${store.distanceMeters}m${store.subtitle != null ? ' · ${store.subtitle}' : ''}';
    }
    return store.subtitle ?? 'Online';
  }

  Color _avatarColor(String text) {
    final palette = [
      const Color(0xFFD44020),
      const Color(0xFFC89018),
      const Color(0xFF6020C0),
      const Color(0xFF1840C0),
      const Color(0xFFC07010),
      const Color(0xFFB01818),
    ];
    final idx = text.isEmpty ? 0 : text.codeUnitAt(0) % palette.length;
    return palette[idx];
  }
}

class _SuccessSummaryRow extends StatelessWidget {
  const _SuccessSummaryRow({required this.label, required this.value, this.highlight = false, this.last = false});

  final String label;
  final String value;
  final bool highlight;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(border: last ? null : const Border(bottom: BorderSide(color: _border))),
      child: Row(
        children: [
          Text(label.toUpperCase(), style: _pjs(size: 10, weight: FontWeight.w700, color: _t3, letterSpacing: .5)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: _pjs(size: 13, weight: FontWeight.w800, color: highlight ? _gold : _t1),
            ),
          ),
        ],
      ),
    );
  }
}
