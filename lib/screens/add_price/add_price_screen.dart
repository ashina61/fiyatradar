import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/category_model.dart';
import '../../models/store.dart';
import '../../providers/auth_provider.dart';
import '../../providers/price_report_provider.dart';
import '../../utils/theme.dart';
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

class _AddPriceScreenState extends ConsumerState<AddPriceScreen>
    with TickerProviderStateMixin {
  final _productController = TextEditingController();
  final _priceHiddenController = TextEditingController();
  final _productFocus = FocusNode();
  final _priceFocus = FocusNode();
  final _scrollController = ScrollController();

  final _productKey = GlobalKey();
  final _storeKey = GlobalKey();
  final _priceKey = GlobalKey();

  _AddStep _activeStep = _AddStep.product;
  bool _showSuccess = false;
  String _savedProduct = '';
  String _savedStore = '';
  String _savedPrice = '';

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
    _priceHiddenController.dispose();
    _productFocus.dispose();
    _priceFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool _isProductDone(AddPriceState state) {
    return state.productName.trim().isNotEmpty && state.selectedCategoryId != null;
  }

  bool _isStoreDone(AddPriceState state) => state.selectedStoreId != null;

  double? _parsePrice(String v) {
    final raw = v.replaceAll(' ', '').replaceAll(',', '.').trim();
    if (raw.isEmpty) return null;
    return double.tryParse(raw);
  }

  bool _isPriceDone(AddPriceState state) => (_parsePrice(state.price) ?? 0) > 0;

  bool _isFormReady(AddPriceState state) {
    return _isProductDone(state) && _isStoreDone(state) && _isPriceDone(state);
  }

  void _syncControllers(AddPriceState state) {
    if (_productController.text != state.productName) {
      _productController.value = _productController.value.copyWith(
        text: state.productName,
        selection: TextSelection.collapsed(offset: state.productName.length),
      );
    }

    if (_priceHiddenController.text != state.price) {
      _priceHiddenController.value = _priceHiddenController.value.copyWith(
        text: state.price,
        selection: TextSelection.collapsed(offset: state.price.length),
      );
    }
  }

  void _advanceStepIfNeeded(AddPriceState state) {
    final productDone = _isProductDone(state);
    final storeDone = _isStoreDone(state);

    final next = !productDone
        ? _AddStep.product
        : !storeDone
            ? _AddStep.store
            : _AddStep.price;

    if (_activeStep != next) {
      setState(() => _activeStep = next);
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToStep(next));
    }
  }

  void _scrollToStep(_AddStep step) {
    final key = switch (step) {
      _AddStep.product => _productKey,
      _AddStep.store => _storeKey,
      _AddStep.price => _priceKey,
    };
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      alignment: 0.04,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addPriceProvider);
    final notifier = ref.read(addPriceProvider.notifier);
    final bottomSafe = MediaQuery.of(context).padding.bottom;

    _syncControllers(state);
    _advanceStepIfNeeded(state);

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

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        notifier.clearProductSuggestions();
      },
      child: Scaffold(
        backgroundColor: _bg,
        body: Stack(
          children: [
            Column(
              children: [
                _buildHeader(state),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(16, 14, 16, 112 + bottomSafe),
                    child: Column(
                      children: [
                        _buildProductPanel(state, notifier),
                        const SizedBox(height: 10),
                        _buildStorePanel(state, notifier),
                        const SizedBox(height: 10),
                        _buildPricePanel(state, notifier),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            _buildSaveBar(state, bottomSafe),
            if (_showSuccess) _buildSuccessOverlay(bottomSafe),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AddPriceState state) {
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
            right: -24,
            top: -24,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [_gold.withOpacity(0.22), Colors.transparent],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
              child: Column(
                children: [
                  Row(
                    children: [
                      _headerButton(Icons.arrow_back_ios_new_rounded, () => Navigator.maybePop(context)),
                      Expanded(
                        child: Text(
                          'Fiyat Ekle',
                          textAlign: TextAlign.center,
                          style: _pjs(size: 15, weight: FontWeight.w800, color: Colors.white.withOpacity(0.45)),
                        ),
                      ),
                      _headerButton(Icons.info_outline_rounded, _showInfoModal),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _StepPill(
                          title: 'Ürün',
                          value: productDone ? _truncate(state.productName, 14) : 'Seçilmedi',
                          active: _activeStep == _AddStep.product,
                          done: productDone,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StepPill(
                          title: 'Market',
                          value: storeDone ? _truncate(state.selectedStoreName ?? '', 14) : 'Seçilmedi',
                          active: _activeStep == _AddStep.store,
                          done: storeDone,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StepPill(
                          title: 'Fiyat',
                          value: priceDone ? _formatPrice(_parsePrice(state.price) ?? 0) : '—',
                          active: _activeStep == _AddStep.price,
                          done: priceDone,
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

  Widget _buildProductPanel(AddPriceState state, AddPriceNotifier notifier) {
    final done = _isProductDone(state);

    return _panel(
      key: _productKey,
      title: 'Hangi ürün?',
      icon: Icons.sell_outlined,
      iconBg: _tan.withOpacity(0.1),
      iconColor: _gold,
      showEdit: done,
      onEdit: () => setState(() => _activeStep = _AddStep.product),
      visible: true,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: done
            ? _ProductDoneState(
                name: state.productName,
                category: state.selectedCategoryName ?? 'Kategori',
              )
            : Column(
                key: const ValueKey('product-input'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: _bg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _productFocus.hasFocus ? _tan.withOpacity(0.36) : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _productController,
                            focusNode: _productFocus,
                            onChanged: notifier.onProductInputChanged,
                            decoration: InputDecoration(
                              hintText: 'Ürün adını yaz…',
                              hintStyle: _pjs(size: 14, weight: FontWeight.w500, color: _t3),
                              isDense: true,
                              border: InputBorder.none,
                            ),
                            style: _pjs(size: 15, weight: FontWeight.w700),
                          ),
                        ),
                        PremiumPressable(
                          borderRadius: BorderRadius.circular(10),
                          onTap: _scanBarcode,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              color: _tan.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: _tan.withOpacity(0.2), width: 1.5),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.qr_code_scanner_rounded, size: 13, color: _tan),
                                const SizedBox(width: 4),
                                Text('Tara', style: _pjs(size: 11, weight: FontWeight.w800, color: _tan)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (state.productSuggestions.isNotEmpty && _productFocus.hasFocus) ...[
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: _bg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: state.productSuggestions.length,
                        separatorBuilder: (_, __) => Divider(height: 1, color: _border.withOpacity(0.4)),
                        itemBuilder: (_, i) {
                          final item = state.productSuggestions[i];
                          final subtitle = [
                            if (item.brand.trim().isNotEmpty) item.brand.trim(),
                            ...item.categories.take(1),
                          ].join(' · ');
                          return ListTile(
                            dense: true,
                            title: Text(item.name, style: _pjs(size: 14, weight: FontWeight.w800)),
                            subtitle: Text(subtitle, style: _pjs(size: 11, color: _t3)),
                            trailing: const Icon(Icons.chevron_right_rounded, size: 18, color: _t3),
                            onTap: () {
                              notifier.selectProductSuggestion(item);
                              _productFocus.unfocus();
                            },
                          );
                        },
                      ),
                    ),
                  ],
                  if (state.barcode != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(color: _greenBg, borderRadius: BorderRadius.circular(8)),
                      child: Text('Barkod: ${state.barcode}', style: _pjs(size: 11, weight: FontWeight.w700, color: _green)),
                    ),
                  ],
                  const SizedBox(height: 10),
                  _CategoryChips(state: state, notifier: notifier),
                ],
              ),
      ),
    );
  }

  Widget _buildStorePanel(AddPriceState state, AddPriceNotifier notifier) {
    final productDone = _isProductDone(state);
    final storeDone = _isStoreDone(state);

    return _panel(
      key: _storeKey,
      title: 'Nerede gördün?',
      icon: Icons.storefront_outlined,
      iconBg: _dark.withOpacity(0.07),
      iconColor: _t2,
      showEdit: storeDone,
      onEdit: () {
        notifier.setSearchQuery('');
        setState(() => _activeStep = _AddStep.store);
      },
      visible: productDone,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: storeDone
            ? _StoreDoneState(store: state.selectedStore!)
            : Column(
                key: const ValueKey('store-input'),
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
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StoreModeButton(
                          icon: Icons.public_rounded,
                          text: 'Online',
                          on: state.activeTab == 1,
                          onTap: () => notifier.setActiveTab(1),
                        ),
                      ),
                    ],
                  ),
                  if (state.locationMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(state.locationMessage!, style: _pjs(size: 11, color: _t3)),
                  ],
                  const SizedBox(height: 10),
                  if (state.isStoresLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator(color: _tan)),
                    )
                  else
                    ...state.visibleStores.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final store = entry.value;
                      final isSelected = state.selectedStore?.id == store.id;
                      return Padding(
                        padding: EdgeInsets.only(bottom: idx == state.visibleStores.length - 1 ? 0 : 6),
                        child: _StoreRow(
                          store: store,
                          selected: isSelected,
                          showNearestBadge: state.activeTab == 0 && idx == 0,
                          onTap: () {
                            notifier.setSelectedStore(store);
                            FocusScope.of(context).unfocus();
                          },
                        ),
                      );
                    }),
                ],
              ),
      ),
    );
  }

  Widget _buildPricePanel(AddPriceState state, AddPriceNotifier notifier) {
    final visible = _isProductDone(state) && _isStoreDone(state);
    final done = _isPriceDone(state);

    final value = _parsePrice(state.price) ?? 0;
    final intPart = NumberFormat.decimalPattern('tr_TR').format(value.floor());
    final frac = ((value - value.floor()) * 100).round().clamp(0, 99).toString().padLeft(2, '0');

    return _panel(
      key: _priceKey,
      title: 'Kaç lira?',
      icon: Icons.currency_lira_rounded,
      iconBg: _tan.withOpacity(0.1),
      iconColor: _gold,
      showEdit: done,
      onEdit: () => setState(() => _activeStep = _AddStep.price),
      visible: visible,
      child: GestureDetector(
        onTap: () => _priceFocus.requestFocus(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 0,
              height: 0,
              child: TextField(
                controller: _priceHiddenController,
                focusNode: _priceFocus,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,\.]'))],
                onChanged: (v) => notifier.setPrice(v.replaceAll(' ', '')),
                decoration: const InputDecoration(border: InputBorder.none),
              ),
            ),
            Container(
              height: 1.5,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(1),
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    _tan.withOpacity(0.4),
                    _tan.withOpacity(0.4),
                    Colors.transparent,
                  ],
                  stops: const [0, 0.35, 0.65, 1],
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    intPart,
                    overflow: TextOverflow.ellipsis,
                    style: _pjs(
                      size: 64,
                      weight: FontWeight.w900,
                      color: done ? _t1 : _t1.withOpacity(0.16),
                      letterSpacing: -3.8,
                      height: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 3),
                Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Text(',${frac}', style: _pjs(size: 30, weight: FontWeight.w700, color: _t1.withOpacity(done ? 0.42 : 0.18))),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 6, bottom: 9),
                  child: Text('₺', style: _pjs(size: 30, weight: FontWeight.w900, color: _gold.withOpacity(done ? 1 : 0.45))),
                ),
              ],
            ),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: done ? 0 : 1,
              child: Text('Fiyatı girmek için dokun', style: _pjs(size: 12, weight: FontWeight.w600, color: _t3)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveBar(AddPriceState state, double bottomSafe) {
    final enabled = _isFormReady(state) && !state.isLoading;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + bottomSafe),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [_bg, _bg, Colors.transparent],
            stops: [0, 0.55, 1],
          ),
        ),
        child: PremiumPressable(
          borderRadius: BorderRadius.circular(20),
          onTap: enabled ? _submit : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: 58,
            decoration: BoxDecoration(
              color: enabled ? _dark : _dark.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              boxShadow: enabled
                  ? const [BoxShadow(color: Color.fromRGBO(28, 17, 8, 0.26), blurRadius: 30, offset: Offset(0, 10))]
                  : null,
            ),
            child: Center(
              child: state.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_rounded, size: 18, color: enabled ? Colors.white : _t3),
                        const SizedBox(width: 8),
                        Text('Fiyatı Kaydet', style: _pjs(size: 16, weight: FontWeight.w900, color: enabled ? Colors.white : _t3)),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessOverlay(double bottomSafe) {
    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 240),
          opacity: _showSuccess ? 1 : 0,
          child: Container(
            color: _bg,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 72, 24, 30),
                  decoration: const BoxDecoration(
                    color: _dark,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(36),
                      bottomRight: Radius.circular(36),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text('🎉', style: _pjs(size: 44, weight: FontWeight.w700, color: Colors.white)),
                      const SizedBox(height: 10),
                      Text('Kaydedildi!', style: _pjs(size: 24, weight: FontWeight.w900, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text('Katkın için teşekkürler · +10 puan', style: _pjs(size: 12, color: Colors.white.withOpacity(0.42))),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: _white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [BoxShadow(color: Color.fromRGBO(28, 17, 8, 0.07), blurRadius: 14, offset: Offset(0, 2))],
                          ),
                          child: Column(
                            children: [
                              Text('GİRİLEN FİYAT', style: _pjs(size: 10, weight: FontWeight.w800, color: _t3, letterSpacing: 1)),
                              const SizedBox(height: 6),
                              Text(_savedPrice, style: _pjs(size: 50, weight: FontWeight.w900, color: _green, letterSpacing: -2.2)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: _white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [BoxShadow(color: Color.fromRGBO(28, 17, 8, 0.07), blurRadius: 14, offset: Offset(0, 2))],
                          ),
                          child: Column(
                            children: [
                              _SummaryRow(label: 'Ürün', value: _savedProduct),
                              _SummaryRow(label: 'Market', value: _savedStore),
                              const _SummaryRow(label: 'Kazanılan', value: '+10 puan ⭐', highlight: true, isLast: true),
                            ],
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _dark,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            ),
                            onPressed: () => Navigator.of(context).maybePop(),
                            child: Text('Ana Sayfaya Dön', style: _pjs(size: 15, weight: FontWeight.w800, color: Colors.white)),
                          ),
                        ),
                        SizedBox(height: bottomSafe > 0 ? bottomSafe : 18),
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

  Widget _panel({
    required Key key,
    required String title,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required bool showEdit,
    required bool visible,
    required Widget child,
    required VoidCallback onEdit,
  }) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 230),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: !visible
          ? const SizedBox.shrink()
          : Container(
              key: key,
              decoration: BoxDecoration(
                color: _white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(28, 17, 8, 0.07),
                    blurRadius: 14,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
                          child: Icon(icon, size: 15, color: iconColor),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(title, style: _pjs(size: 14, weight: FontWeight.w900))),
                        if (showEdit)
                          TextButton(
                            onPressed: onEdit,
                            style: TextButton.styleFrom(
                              foregroundColor: _tan,
                              backgroundColor: _tan.withOpacity(0.1),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text('Değiştir', style: _pjs(size: 11, weight: FontWeight.w700, color: _tan)),
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: _border),
                  Padding(padding: const EdgeInsets.fromLTRB(18, 14, 18, 16), child: child),
                ],
              ),
            ),
    );
  }

  Future<void> _scanBarcode() async {
    final barcode = await BarcodeScannerSheet.scan(context, title: 'Barkod Tara');
    if (barcode == null || !mounted) return;

    final found = await ref.read(addPriceProvider.notifier).applyScannedBarcode(barcode);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(found ? 'Ürün bulundu: $barcode' : 'Barkod okundu: $barcode'),
        behavior: SnackBarBehavior.floating,
      ),
    );
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

      final raw = _parsePrice(stateBefore.price) ?? 0;
      setState(() {
        _savedPrice = '${_formatPrice(raw)} ₺';
        _savedProduct = stateBefore.productName;
        _savedStore = stateBefore.selectedStoreName ?? '—';
        _showSuccess = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            kDebugMode ? 'Kaydedilemedi: $e' : 'Fiyat kaydedilemedi. Lütfen tekrar deneyin.',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _showInfoModal() async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Dialog(
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _InfoBullet(icon: Icons.stars_rounded, text: 'Her fiyat girişi +10 puan kazandırır.'),
                  SizedBox(height: 10),
                  _InfoBullet(icon: Icons.groups_rounded, text: 'Fiyatlar kullanıcılar tarafından raporlanır.'),
                  SizedBox(height: 10),
                  _InfoBullet(icon: Icons.verified_rounded, text: 'Doğru fiyat girişleri güven skorunu artırır.'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerButton(IconData icon, VoidCallback onTap) {
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
        child: Icon(icon, color: Colors.white.withOpacity(0.8), size: 16),
      ),
    );
  }

  String _truncate(String value, int max) {
    if (value.length <= max) return value;
    return '${value.substring(0, max - 1)}…';
  }

  String _formatPrice(double value) {
    return NumberFormat.currency(locale: 'tr_TR', symbol: '', decimalDigits: 2)
        .format(value)
        .trim();
  }
}

class _StepPill extends StatelessWidget {
  const _StepPill({
    required this.title,
    required this.value,
    required this.active,
    required this.done,
  });

  final String title;
  final String value;
  final bool active;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: done
            ? _greenBg
            : active
                ? Colors.white.withOpacity(0.1)
                : Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: done
              ? _green.withOpacity(0.26)
              : active
                  ? _gold.withOpacity(0.4)
                  : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: _pjs(
              size: 9,
              weight: FontWeight.w800,
              letterSpacing: 0.6,
              color: done
                  ? _green.withOpacity(0.9)
                  : active
                      ? _gold.withOpacity(0.9)
                      : Colors.white.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _pjs(
                    size: 12,
                    weight: FontWeight.w800,
                    color: active || done
                        ? Colors.white.withOpacity(0.72)
                        : Colors.white.withOpacity(0.25),
                  ),
                ),
              ),
              if (done) const Icon(Icons.check_rounded, size: 13, color: _green),
            ],
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
              borderRadius: BorderRadius.circular(99),
              onTap: state.lockedCategoryByProduct ? null : () => notifier.setCategory(cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? _dark : _bg,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: selected ? Colors.transparent : _tan.withOpacity(0.24), width: 1.2),
                ),
                child: Text(
                  '${_categoryEmoji(cat)} ${cat.title}',
                  style: _pjs(size: 12, weight: FontWeight.w800, color: selected ? Colors.white : _t2),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _categoryEmoji(CategoryModel c) => c.emoji?.trim().isNotEmpty == true ? c.emoji!.trim() : '🏷️';
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
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: on ? _white : _bg,
          borderRadius: BorderRadius.circular(12),
          boxShadow: on
              ? const [BoxShadow(color: Color.fromRGBO(28, 17, 8, 0.08), blurRadius: 8, offset: Offset(0, 1))]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: on ? _dark : _t3),
            const SizedBox(width: 5),
            Text(text, style: _pjs(size: 12, weight: FontWeight.w800, color: on ? _dark : _t3)),
          ],
        ),
      ),
    );
  }
}

class _StoreRow extends StatelessWidget {
  const _StoreRow({
    required this.store,
    required this.selected,
    required this.showNearestBadge,
    required this.onTap,
  });

  final Store store;
  final bool selected;
  final bool showNearestBadge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = store.distanceMeters != null
        ? '${store.distanceMeters}m${store.subtitle == null ? '' : ' · ${store.subtitle}'}'
        : (store.subtitle ?? 'Online');

    return PremiumPressable(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? _dark : Colors.transparent, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _avatarColor(store.name),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                store.logoUrl.isNotEmpty ? store.logoUrl[0] : '?',
                style: _pjs(size: 14, weight: FontWeight.w900, color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(store.name, style: _pjs(size: 13, weight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: _pjs(size: 11, color: _t3)),
                ],
              ),
            ),
            if (showNearestBadge)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: _greenBg, borderRadius: BorderRadius.circular(4)),
                child: Text('EN YAKIN', style: _pjs(size: 8, weight: FontWeight.w900, color: _green, letterSpacing: 0.5)),
              ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: selected ? _dark : Colors.transparent,
                border: Border.all(color: selected ? _dark : _border, width: 2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: selected ? const Icon(Icons.check_rounded, size: 12, color: Colors.white) : null,
            ),
          ],
        ),
      ),
    );
  }

  Color _avatarColor(String text) {
    final palette = [
      const Color(0xFFD44020),
      const Color(0xFFC89018),
      const Color(0xFF6020C0),
      const Color(0xFF1840C0),
      const Color(0xFFB01818),
    ];
    final idx = text.isEmpty ? 0 : text.codeUnitAt(0) % palette.length;
    return palette[idx];
  }
}

class _ProductDoneState extends StatelessWidget {
  const _ProductDoneState({required this.name, required this.category});

  final String name;
  final String category;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: _pjs(size: 16, weight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(category, style: _pjs(size: 11, weight: FontWeight.w600, color: _t3)),
          ],
        ),
      ],
    );
  }
}

class _StoreDoneState extends StatelessWidget {
  const _StoreDoneState({required this.store});

  final Store store;

  @override
  Widget build(BuildContext context) {
    final subtitle = store.distanceMeters != null
        ? '${store.distanceMeters}m${store.subtitle == null ? '' : ' · ${store.subtitle}'}'
        : (store.subtitle ?? 'Online');

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFC89018),
            borderRadius: BorderRadius.circular(11),
          ),
          alignment: Alignment.center,
          child: Text(
            store.logoUrl.isNotEmpty ? store.logoUrl[0] : '?',
            style: _pjs(size: 12, weight: FontWeight.w900, color: Colors.white),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(store.name, style: _pjs(size: 15, weight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(subtitle, style: _pjs(size: 11, weight: FontWeight.w500, color: _t3)),
          ],
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.highlight = false,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool highlight;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Text(label.toUpperCase(), style: _pjs(size: 10, weight: FontWeight.w700, color: _t3, letterSpacing: 0.5)),
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

class _InfoBullet extends StatelessWidget {
  const _InfoBullet({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.accent),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: _pjs(size: 13, color: AppColors.textSecondary))),
      ],
    );
  }
}
