Haklısın kanka, düzeltilmiş hali:
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/store.dart';
import '../../providers/auth_provider.dart';
import '../../providers/price_report_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/barcode_scanner_sheet.dart';
import '../../widgets/premium_pressable.dart';

// ── Palette ──────────────────────────────────────────────────────
const _dark    = Color(0xFF1C1108);
const _bg      = Color(0xFFECEAE4);
const _white   = Color(0xFFFFFFFF);
const _tan     = Color(0xFFB88C50);
const _gold    = Color(0xFFC09A60);
const _green   = Color(0xFF27A85A);
const _greenBg = Color(0x1A27A85A);
const _t1      = Color(0xFF1C1108);
const _t2      = Color(0xFF6B5D4E);
const _t3      = Color(0xFFA89A8A);
const _border  = Color(0x121C1108);

TextStyle _pjs({
  double size = 14,
  FontWeight weight = FontWeight.w600,
  Color color = _t1,
  double? letterSpacing,
  double? height,
}) =>
    GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );

// ── Recent price model ───────────────────────────────────────────
class _RecentEntry {
  const _RecentEntry({required this.name, required this.price});
  final String name;
  final double price;
}

// ── Recent prices provider (Firestore) ──────────────────────────
final _recentPricesProvider =
    FutureProvider.family<List<_RecentEntry>, String>((ref, userId) async {
  if (userId.isEmpty) return [];
  final snap = await FirebaseFirestore.instance
      .collection('prices')
      .where('userId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .limit(3)
      .get();
  return snap.docs.map((d) {
    return _RecentEntry(
      name:  (d.data()['productName'] as String? ?? '').trim(),
      price: (d.data()['price'] as num? ?? 0).toDouble(),
    );
  }).where((e) => e.name.isNotEmpty && e.price > 0).toList();
});

// ─────────────────────────────────────────────────────────────────

class AddPriceScreen extends ConsumerStatefulWidget {
  const AddPriceScreen({super.key, this.initialProductId});
  final String? initialProductId;

  @override
  ConsumerState<AddPriceScreen> createState() => _AddPriceScreenState();
}

class _AddPriceScreenState extends ConsumerState<AddPriceScreen>
    with SingleTickerProviderStateMixin {
  final _priceController   = TextEditingController();
  final _productController = TextEditingController();
  final _searchController  = TextEditingController();
  final _priceFocus        = FocusNode();
  final _productFocus      = FocusNode();

  late final AnimationController _glowCtrl;

  static const _categoryIcons = <String, IconData>{
    'Gıda'         : Icons.restaurant_rounded,
    'Kişisel Bakım': Icons.spa_rounded,
    'Temizlik'     : Icons.cleaning_services_rounded,
    'Teknoloji'    : Icons.devices_rounded,
    'Ev & Yaşam'   : Icons.home_rounded,
    'Giyim'        : Icons.checkroom_rounded,
    'Kitap'        : Icons.menu_book_rounded,
    'Spor'         : Icons.sports_soccer_rounded,
    'Otomotiv'     : Icons.directions_car_rounded,
    'Elektronik'   : Icons.laptop_rounded,
  };

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _priceFocus.addListener(() => setState(() {}));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pid = widget.initialProductId?.trim() ?? '';
      if (pid.isNotEmpty) {
        ref.read(addPriceProvider.notifier).initializeForProduct(pid);
      }
    });
  }

  @override
  void dispose() {
    _priceController.dispose();
    _productController.dispose();
    _searchController.dispose();
    _priceFocus.dispose();
    _productFocus.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  String _normalizePriceInput(String raw) =>
      raw.replaceAll(' ', '').replaceAll(',', '.');

  double? _parsePrice(String v) =>
      double.tryParse(v.replaceAll(',', '.').trim());

  bool _isReady(AddPriceState s) {
    final p = _parsePrice(s.price);
    return (p ?? 0) > 0 &&
        s.productName.trim().isNotEmpty &&
        s.selectedCategoryId != null &&
        s.selectedStoreId != null;
  }

  void _syncControllers(AddPriceState s) {
    void sync(TextEditingController c, String v) {
      if (c.text != v) {
        final sel = c.selection;
        c.text = v;
        c.selection = sel;
      }
    }
    sync(_priceController,   s.price);
    sync(_productController, s.productName);
    sync(_searchController,  s.searchQuery);
  }

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(addPriceProvider);
    final notifier = ref.read(addPriceProvider.notifier);
    _syncControllers(state);

    ref.listen<String?>(
      addPriceProvider.select((s) => s.error),
      (_, next) {
        if (next != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      },
    );

    final bottomSafe = MediaQuery.of(context).padding.bottom;
    final currentUser =
        ref.watch(authStateProvider).valueOrNull ??
        FirebaseAuth.instance.currentUser;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
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
                _buildHeader(state, notifier, currentUser?.uid ?? ''),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding:
                        EdgeInsets.fromLTRB(14, 12, 14, 100 + bottomSafe),
                    child: Column(
                      children: [
                        _buildCard(
                          title: 'Ürün',
                          iconData: Icons.sell_outlined,
                          iconBg: _tan.withOpacity(0.12),
                          iconColor: _gold,
                          child: _buildProductBody(state, notifier),
                        ),
                        const SizedBox(height: 10),
                        _buildCard(
                          title: 'Nerede Gördün?',
                          iconData: Icons.location_on_outlined,
                          iconBg: _dark.withOpacity(0.07),
                          iconColor: _t2,
                          child: _buildLocationBody(state, notifier),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            _buildSaveBar(state, bottomSafe),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  DARK HEADER
  // ══════════════════════════════════════════════════════════════
  Widget _buildHeader(
      AddPriceState state, AddPriceNotifier notifier, String uid) {
    final hasPrice = state.price.trim().isNotEmpty;

    return Container(
      decoration: const BoxDecoration(
        color: _dark,
        borderRadius: BorderRadius.only(
          bottomLeft:  Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Stack(
        children: [
          // amber orb
          Positioned(
            right: -28, top: -28,
            child: Container(
              width: 150, height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [_gold.withOpacity(0.22), Colors.transparent],
                ),
              ),
            ),
          ),
          // shimmer bottom line
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    _gold.withOpacity(0.28),
                    _gold.withOpacity(0.28),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.35, 0.65, 1.0],
                ),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // nav row
                  Row(
                    children: [
                      _hdrBtn(Icons.arrow_back_ios_new_rounded,
                          onTap: () => Navigator.maybePop(context)),
                      Expanded(
                        child: Text(
                          'Fiyat Ekle',
                          textAlign: TextAlign.center,
                          style: _pjs(
                            size: 15,
                            weight: FontWeight.w800,
                            color: Colors.white.withOpacity(0.45),
                          ),
                        ),
                      ),
                      _hdrBtn(Icons.info_outline_rounded,
                          onTap: _showInfoModal),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // price with animated glow
                  AnimatedBuilder(
                    animation: _glowCtrl,
                    builder: (_, child) => Container(
                      decoration: BoxDecoration(
                        boxShadow: hasPrice
                            ? [
                                BoxShadow(
                                  color: _gold.withOpacity(
                                      0.07 + _glowCtrl.value * 0.07),
                                  blurRadius: 24,
                                  offset: const Offset(0, 6),
                                ),
                              ]
                            : null,
                      ),
                      child: child,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => _priceFocus.requestFocus(),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _priceController,
                                  focusNode: _priceFocus,
                                  onChanged: (v) => notifier
                                      .setPrice(_normalizePriceInput(v)),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'[0-9,\.]')),
                                  ],
                                  style: _pjs(
                                    size: 62,
                                    weight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -3,
                                    height: 1,
                                  ).copyWith(
                                    fontFeatures: const [
                                      FontFeature.tabularFigures()
                                    ],
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '0,00',
                                    hintStyle: _pjs(
                                      size: 62,
                                      weight: FontWeight.w900,
                                      color: Colors.white.withOpacity(0.13),
                                      letterSpacing: -3,
                                      height: 1,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                              // ₺ after the number
                              Padding(
                                padding: const EdgeInsets.only(
                                    bottom: 8, left: 4),
                                child: AnimatedDefaultTextStyle(
                                  duration:
                                      const Duration(milliseconds: 200),
                                  style: _pjs(
                                    size: 28,
                                    weight: FontWeight.w900,
                                    color: _gold.withOpacity(
                                        hasPrice ? 1.0 : 0.5),
                                  ),
                                  child: const Text('₺'),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // hint — only when empty
                        if (!hasPrice)
                          Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Text(
                              'Fiyatı girmek için dokun',
                              style: _pjs(
                                size: 12,
                                weight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.22),
                              ),
                            ),
                          ),

                        const SizedBox(height: 10),

                        // shimmer rule
                        Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                _gold.withOpacity(0.45),
                                _gold.withOpacity(0.45),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.30, 0.70, 1.0],
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // recent prices
                        _buildRecentRow(uid, notifier),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Recent prices row ─────────────────────────────────────────
  Widget _buildRecentRow(String uid, AddPriceNotifier notifier) {
    if (uid.isEmpty) return const SizedBox.shrink();

    final async = ref.watch(_recentPricesProvider(uid));

    return async.when(
      loading: () => const SizedBox(
        height: 28,
        child: Center(
          child: SizedBox(
            width: 14, height: 14,
            child: CircularProgressIndicator(
                strokeWidth: 1.8,
                color: Colors.white38),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (entries) {
        if (entries.isEmpty) return const SizedBox.shrink();
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              Text(
                'SON',
                style: _pjs(
                  size: 9,
                  weight: FontWeight.w800,
                  color: Colors.white.withOpacity(0.25),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(width: 8),
              ...entries.map((r) {
                final priceStr =
                    r.price.toStringAsFixed(2).replaceAll('.', ',');
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: PremiumPressable(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      _priceController.text = priceStr;
                      notifier.setPrice(r.price.toString());
                      notifier.setProductName(r.name);
                      _productController.text = r.name;
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.09)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ConstrainedBox(
                            constraints:
                                const BoxConstraints(maxWidth: 72),
                            child: Text(
                              r.name,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: _pjs(
                                size: 10,
                                weight: FontWeight.w700,
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '$priceStr ₺',
                            style: _pjs(
                              size: 12,
                              weight: FontWeight.w900,
                              color: _gold,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _hdrBtn(IconData icon, {required VoidCallback onTap}) {
    return PremiumPressable(
      borderRadius: BorderRadius.circular(13),
      onTap: onTap,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, color: Colors.white.withOpacity(0.8), size: 17),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  WHITE SECTION CARD
  // ══════════════════════════════════════════════════════════════
  Widget _buildCard({
    required String title,
    required IconData iconData,
    required Color iconBg,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(28, 17, 8, 0.07),
            blurRadius: 14,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(iconData, size: 15, color: iconColor),
                ),
                const SizedBox(width: 8),
                Text(title,
                    style: _pjs(size: 13, weight: FontWeight.w900)),
              ],
            ),
          ),
          const Divider(
              height: 1, color: Color.fromRGBO(28, 17, 8, 0.07)),
          child,
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  ÜRÜN + KATEGORİ
  // ══════════════════════════════════════════════════════════════
  Widget _buildProductBody(AddPriceState state, AddPriceNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _productController,
                  focusNode: _productFocus,
                  onChanged: notifier.onProductInputChanged,
                  style: _pjs(size: 14, weight: FontWeight.w700),
                  decoration: InputDecoration(
                    hintText: 'ürün adı ya da marka…',
                    hintStyle: _pjs(
                      size: 14,
                      weight: FontWeight.w500,
                      color: _t3,
                    ).copyWith(fontStyle: FontStyle.italic),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PremiumPressable(
                borderRadius: BorderRadius.circular(10),
                onTap: _scanBarcode,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: _tan.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: _tan.withOpacity(0.22), width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.qr_code_scanner_rounded,
                          size: 13, color: _tan),
                      const SizedBox(width: 4),
                      Text('Tara',
                          style: _pjs(
                            size: 11,
                            weight: FontWeight.w800,
                            color: _tan,
                          )),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // product suggestions
          if (_productFocus.hasFocus &&
              state.productSuggestions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF9F7F3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border),
              ),
              child: ListView.separated(
                itemCount: state.productSuggestions.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final s = state.productSuggestions[i];
                  return ListTile(
                    dense: true,
                    title: Text(s.name,
                        style:
                            _pjs(size: 13, weight: FontWeight.w700)),
                    subtitle: Text(
                      [
                        if (s.brand.trim().isNotEmpty) s.brand.trim(),
                        ...s.categories.take(1),
                      ].join(' • '),
                      style: _pjs(size: 11, color: _t2),
                    ),
                    onTap: () {
                      notifier.selectProductSuggestion(s);
                      _productFocus.unfocus();
                    },
                  );
                },
              ),
            ),
          ],

          // barcode badge
          if (state.barcode != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: _greenBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Barkod: ${state.barcode}',
                style: _pjs(
                    size: 11,
                    weight: FontWeight.w700,
                    color: _green),
              ),
            ),
          ],

          const SizedBox(height: 10),
          const Divider(
              height: 1, color: Color.fromRGBO(28, 17, 8, 0.07)),
          const SizedBox(height: 10),

          // categories
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: state.categories.map((cat) {
              final isOn = state.selectedCategoryId == cat.id;
              final ico = _categoryIcons[cat.title] ??
                  Icons.label_outline_rounded;
              return PremiumPressable(
                borderRadius: BorderRadius.circular(10),
                onTap: state.lockedCategoryByProduct
                    ? null
                    : () => notifier.setCategory(cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: isOn ? _dark : _bg,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: isOn
                        ? const [
                            BoxShadow(
                              color:
                                  Color.fromRGBO(28, 17, 8, 0.18),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            )
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(ico,
                          size: 13,
                          color: isOn
                              ? Colors.white.withOpacity(0.85)
                              : _t2),
                      const SizedBox(width: 5),
                      Text(
                        cat.title,
                        style: _pjs(
                          size: 12,
                          weight: FontWeight.w800,
                          color: isOn
                              ? Colors.white.withOpacity(0.9)
                              : _t2,
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
  }

  // ══════════════════════════════════════════════════════════════
  //  NEREDE GÖRDÜN
  // ══════════════════════════════════════════════════════════════
  Widget _buildLocationBody(
      AddPriceState state, AddPriceNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _locTab(
                  label: 'Yakınımda',
                  icon: Icons.location_on_outlined,
                  on: state.activeTab == 0,
                  onTap: () => notifier.setActiveTab(0),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _locTab(
                  label: 'Online',
                  icon: Icons.language_rounded,
                  on: state.activeTab == 1,
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
              color: _bg,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded,
                    color: _t3, size: 17),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: notifier.setSearchQuery,
                    style: _pjs(size: 13, weight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: 'Market veya platform ara…',
                      hintStyle: _pjs(
                          size: 13,
                          weight: FontWeight.w500,
                          color: _t3),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (state.locationMessage != null &&
              state.isNearbyMode) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F2EC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(state.locationMessage!,
                  style: _pjs(size: 12, color: _t2)),
            ),
          ],

          const SizedBox(height: 8),

          if (state.isStoresLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2.2, color: _tan),
              ),
            )
          else if (state.storesError != null)
            _buildStoresError(notifier)
          else if (state.visibleStores.isEmpty)
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'Aramanıza uygun mağaza bulunamadı.',
                style: _pjs(size: 12, color: _t3),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: _white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(28, 17, 8, 0.06),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              clipBehavior: Clip.hardEdge,
              child: Column(
                children: state.visibleStores
                    .asMap()
                    .entries
                    .map((e) {
                  final isLast =
                      e.key == state.visibleStores.length - 1;
                  return _storeTile(
                    store: e.value,
                    selected:
                        state.selectedStore?.id == e.value.id,
                    isLast: isLast,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      notifier.setSelectedStore(e.value);
                    },
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _locTab({
    required String label,
    required IconData icon,
    required bool on,
    required VoidCallback onTap,
  }) {
    return PremiumPressable(
      borderRadius: BorderRadius.circular(13),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 42,
        decoration: BoxDecoration(
          color: on ? _dark : _white,
          borderRadius: BorderRadius.circular(13),
          boxShadow: on
              ? const [
                  BoxShadow(
                    color: Color.fromRGBO(28, 17, 8, 0.20),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  )
                ]
              : const [
                  BoxShadow(
                    color: Color.fromRGBO(28, 17, 8, 0.06),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  )
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 13,
                color: on ? Colors.white : _t3),
            const SizedBox(width: 6),
            Text(
              label,
              style: _pjs(
                size: 12,
                weight: FontWeight.w800,
                color: on ? Colors.white : _t3,
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
    required bool isLast,
    required VoidCallback onTap,
  }) {
    final distText = store.distanceMeters == null
        ? (store.subtitle?.isNotEmpty == true
            ? store.subtitle!
            : 'Online')
        : '${store.distanceMeters}m'
            '${store.subtitle?.isNotEmpty == true ? ' · ${store.subtitle}' : ''}';

    final src =
        (store.logoUrl?.isNotEmpty == true
                ? store.logoUrl!
                : store.name)
            .trim();
    final initial =
        src.isEmpty ? '?' : src.substring(0, 1).toUpperCase();
    final isNearest =
        store.distanceMeters != null && store.distanceMeters! <= 200;

    return PremiumPressable(
      onTap: onTap,
      borderRadius: BorderRadius.zero,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected
              ? const Color.fromRGBO(28, 17, 8, 0.030)
              : Colors.transparent,
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(
                    color: Color.fromRGBO(28, 17, 8, 0.07),
                  ),
                ),
        ),
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 11),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 8, height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? _gold
                    : _tan.withOpacity(0.45),
              ),
            ),
            const SizedBox(width: 10),

            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: selected ? _gold : _tan,
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.15),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      )
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(initial,
                      style: _pjs(
                        size: 15,
                        weight: FontWeight.w900,
                        color: Colors.white,
                      )),
                ),
                if (selected)
                  Positioned(
                    top: -3, left: -3, right: -3, bottom: -3,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _gold, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(store.name,
                      style: _pjs(
                          size: 14, weight: FontWeight.w900)),
                  const SizedBox(height: 1),
                  Text(distText,
                      style: _pjs(
                          size: 11,
                          weight: FontWeight.w500,
                          color: _t3)),
                ],
              ),
            ),

            if (isNearest) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: _greenBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'EN YAKIN',
                  style: _pjs(
                    size: 8,
                    weight: FontWeight.w900,
                    color: _green,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],

            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: selected ? 1 : 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: _gold,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(store.name,
                        style: _pjs(
                          size: 10,
                          weight: FontWeight.w900,
                          color: Colors.white,
                        )),
                    Text(
                      store.distanceMeters != null
                          ? '${store.distanceMeters}m'
                          : 'Online',
                      style: _pjs(
                        size: 9,
                        weight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.65),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 6),

            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20, height: 20,
              decoration: BoxDecoration(
                color: selected ? _dark : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: selected
                      ? _dark
                      : const Color.fromRGBO(28, 17, 8, 0.12),
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check_rounded,
                      size: 11, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoresError(AddPriceNotifier notifier) {
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
          Text('Mağaza listesi yüklenemedi.',
              style: _pjs(
                size: 13,
                weight: FontWeight.w700,
                color: Colors.redAccent,
              )),
          const SizedBox(height: 8),
          TextButton(
            onPressed: notifier.loadStoresAndCategories,
            child: Text('Tekrar dene',
                style: _pjs(
                    size: 13,
                    weight: FontWeight.w700,
                    color: _tan)),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  SAVE BAR
  // ══════════════════════════════════════════════════════════════
  Widget _buildSaveBar(AddPriceState state, double bottomSafe) {
    final enabled = _isReady(state) &&
        !state.isLoading &&
        !state.isStoresLoading;

    return Positioned(
      left: 0, right: 0, bottom: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(14, 14, 14, 20 + bottomSafe),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [_bg, Color.fromRGBO(236, 234, 228, 0)],
            stops: [0.55, 1.0],
          ),
        ),
        child: PremiumPressable(
          borderRadius: BorderRadius.circular(20),
          onTap: enabled ? _submit : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: 56,
            decoration: BoxDecoration(
              color: enabled
                  ? _dark
                  : const Color.fromRGBO(28, 17, 8, 0.08),
              borderRadius: BorderRadius.circular(20),
              boxShadow: enabled
                  ? const [
                      BoxShadow(
                        color: Color.fromRGBO(28, 17, 8, 0.28),
                        blurRadius: 24,
                        offset: Offset(0, 10),
                      )
                    ]
                  : null,
            ),
            child: Center(
              child: state.isLoading
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white),
                    )
                  : Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_rounded,
                            size: 17,
                            color: enabled
                                ? Colors.white
                                : _t3),
                        const SizedBox(width: 8),
                        Text(
                          'Fiyatı Kaydet',
                          style: _pjs(
                            size: 16,
                            weight: FontWeight.w900,
                            color: enabled
                                ? Colors.white
                                : _t3,
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

  // ══════════════════════════════════════════════════════════════
  //  ACTIONS
  // ══════════════════════════════════════════════════════════════
  Future<void> _scanBarcode() async {
    final barcode = await BarcodeScannerSheet.scan(
        context, title: 'Barkod Tara');
    if (barcode != null && mounted) {
      final found = await ref
          .read(addPriceProvider.notifier)
          .applyScannedBarcode(barcode);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(found
              ? 'Ürün bulundu: $barcode'
              : 'Barkod okundu: $barcode'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _submit() async {
    final auth = ref.read(authStateProvider).value;
    final user = auth ?? FirebaseAuth.instance.currentUser;

    if (user == null ||
        user.uid.trim().isEmpty ||
        user.isAnonymous) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Fiyat eklemek için giriş yapman gerekiyor.'),
        ),
      );
      return;
    }

    try {
      await ref
          .read(addPriceProvider.notifier)
          .submitPrice(userId: user.uid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                    'Fiyat kaydedildi. +10 puan eklendi!'),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.maybePop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(kDebugMode
              ? 'Kaydedilemedi: $e'
              : 'Fiyat kaydedilemedi. Lütfen tekrar deneyin.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showInfoModal() async {
    await showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 28),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter:
                ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding:
                  const EdgeInsets.fromLTRB(24, 28, 24, 28),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color:
                        AppColors.outline.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Bilgilendirme',
                      style: _pjs(
                          size: 20,
                          weight: FontWeight.w700)),
                  const SizedBox(height: 18),
                  _InfoRow(
                    icon: Icons.stars_rounded,
                    iconColor: AppColors.accent,
                    text:
                        'Her fiyat girişi +10 puan kazandırır!',
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.groups_rounded,
                    iconColor: AppColors.primary,
                    text:
                        'Fiyatlar tamamen kullanıcılar tarafından bildirilmektedir.',
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.verified_rounded,
                    iconColor: AppColors.success,
                    text:
                        'Doğru fiyat girişleri güven puanınızı artırır.',
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

// ── _InfoRow ──────────────────────────────────────────────────────
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
            style: GoogleFonts.plusJakartaSans(
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
