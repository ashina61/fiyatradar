// lib/screens/add_price/add_price_screen.dart
// GREENFIELD — 3-step wizard, mission-like contribution flow
// Rejected: single-page form, platform pill grid, motivational header bolted on top
// UX goal: "Complete a mission, not fill a form" — each step is full-focus, guided

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/product_model.dart';
import '../../models/store.dart';
import '../../providers/add_price_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../theme/fr_colors.dart';
import '../../utils/formatters.dart';

const _kPad = 24.0;
const _kCardR = 20.0;
const _kShadow = BoxShadow(color: Color(0x0A211510), blurRadius: 12, offset: Offset(0, 3));

const _kPlatforms = [
  'Trendyol', 'Hepsiburada', 'Amazon', 'N11', 'ÇiçekSepeti',
  'A101', 'BİM', 'Migros', 'CarrefourSA', 'Diğer',
];

// ─────────────────────────────────────────────────────────────────────────────
class AddPriceScreen extends ConsumerStatefulWidget {
  const AddPriceScreen({super.key, this.initialProductId});
  final String? initialProductId;

  @override
  ConsumerState<AddPriceScreen> createState() => _AddPriceScreenState();
}

class _AddPriceScreenState extends ConsumerState<AddPriceScreen> {
  final _pageCtrl = PageController();
  final _priceCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  int _step = 0;
  ProductModel? _product;
  String? _platform;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialProductId?.isNotEmpty == true) {
      _loadProduct(widget.initialProductId!);
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _priceCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProduct(String id) async {
    final p = await ref.read(productProvider(id).future);
    if (mounted && p != null) setState(() => _product = p);
  }

  bool get _step1Valid => _product != null;
  bool get _step2Valid =>
      _platform != null &&
      _priceCtrl.text.trim().isNotEmpty &&
      double.tryParse(_priceCtrl.text.trim().replaceAll(',', '.')) != null;

  void _goToStep(int step) {
    setState(() => _step = step);
    _pageCtrl.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _submit() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null || !_step2Valid || _product == null) return;

    setState(() => _submitting = true);
    try {
      final notifier = ref.read(addPriceProvider.notifier);
      notifier.selectProductSuggestion(_product!);
      notifier.setSelectedStore(Store(
        id: _platform!.toLowerCase().replaceAll(' ', '_'),
        name: _platform!,
        type: 'online',
        distanceMeters: 0,
        logoUrl: '',
      ));
      notifier.setPrice(_priceCtrl.text.trim().replaceAll(',', '.'));
      await notifier.submitPrice(userId: user.uid);
      if (!mounted) return;
      _goToStep(2);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: FRColors.espresso),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FRColors.backgroundWarm,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _WizardHeader(
              step: _step,
              onBack: () {
                if (_step > 0 && _step < 2) {
                  _goToStep(_step - 1);
                } else {
                  Navigator.maybePop(context);
                }
              },
            ),
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _Step1Product(
                    ctrl: _searchCtrl,
                    selected: _product,
                    onSelect: (p) {
                      setState(() => _product = p);
                      _goToStep(1);
                    },
                  ),
                  _Step2Price(
                    product: _product,
                    priceCtrl: _priceCtrl,
                    platform: _platform,
                    submitting: _submitting,
                    onPlatformSelect: (v) => setState(() => _platform = v),
                    onPriceChanged: (_) => setState(() {}),
                    onSubmit: _step2Valid ? _submit : null,
                  ),
                  _Step3Done(
                    product: _product,
                    onDone: () => Navigator.maybePop(context),
                    onAddAnother: () {
                      setState(() {
                        _product = null;
                        _platform = null;
                        _priceCtrl.clear();
                        _searchCtrl.clear();
                      });
                      _goToStep(0);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Wizard header ────────────────────────────────────────────────────────────
class _WizardHeader extends StatelessWidget {
  const _WizardHeader({required this.step, required this.onBack});
  final int step;
  final VoidCallback onBack;

  static const _titles = ['Ürün Seç', 'Fiyat Gir', 'Tamamlandı'];
  static const _subs = ['Hangi ürünün fiyatını ekleyeceksin?', 'Kaça aldın? Nereden?', 'Katkın kaydedildi!'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, _kPad, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(
                  step == 2 ? Icons.close_rounded : Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: FRColors.textMuted,
                ),
                onPressed: onBack,
              ),
              const Spacer(),
              // Step dots
              Row(
                children: List.generate(3, (i) {
                  final active = i == step;
                  final done = i < step;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.only(left: 6),
                    width: active ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: done || active ? FRColors.espresso : FRColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(_kPad - 8, 10, 0, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _titles[step],
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: FRColors.espresso,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _subs[step],
                  style: const TextStyle(fontSize: 13, color: FRColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Step 1: Product selection ────────────────────────────────────────────────
class _Step1Product extends ConsumerStatefulWidget {
  const _Step1Product({required this.ctrl, required this.selected, required this.onSelect});
  final TextEditingController ctrl;
  final ProductModel? selected;
  final ValueChanged<ProductModel> onSelect;

  @override
  ConsumerState<_Step1Product> createState() => _Step1ProductState();
}

class _Step1ProductState extends ConsumerState<_Step1Product> {
  List<ProductModel> _suggestions = [];

  @override
  Widget build(BuildContext context) {
    final allProducts = ref.watch(allProductsProvider).valueOrNull ?? [];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(_kPad, 20, _kPad, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search input
          Container(
            decoration: BoxDecoration(
              color: FRColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: FRColors.border),
              boxShadow: const [_kShadow],
            ),
            child: TextField(
              controller: widget.ctrl,
              autofocus: widget.selected == null,
              onChanged: (q) {
                setState(() {
                  _suggestions = q.length < 2
                      ? []
                      : allProducts
                          .where((p) => p.name.toLowerCase().contains(q.toLowerCase()))
                          .take(6)
                          .toList();
                });
              },
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: FRColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Ürün adı yaz…',
                hintStyle: TextStyle(fontSize: 15, color: FRColors.textSubtle),
                prefixIcon: Icon(Icons.search_rounded, color: FRColors.textMuted, size: 20),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ),
          // Suggestions
          if (_suggestions.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: FRColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: FRColors.border),
                boxShadow: const [_kShadow],
              ),
              child: Column(
                children: [
                  for (var i = 0; i < _suggestions.length; i++) ...[
                    _ProductSuggestionRow(
                      product: _suggestions[i],
                      onTap: () {
                        widget.ctrl.text = _suggestions[i].name;
                        widget.onSelect(_suggestions[i]);
                      },
                    ),
                    if (i < _suggestions.length - 1)
                      const Divider(height: 1, indent: 60, endIndent: 16, color: Color(0x08211510)),
                  ],
                ],
              ),
            ),
          ],
          // Currently selected
          if (widget.selected != null && _suggestions.isEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'SEÇİLEN ÜRÜN',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: FRColors.textMuted,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            _SelectedProductCard(product: widget.selected!),
          ],
          // Trending products shortcut
          if (_suggestions.isEmpty && widget.selected == null) ...[
            const SizedBox(height: 28),
            const Text(
              'POPÜLER ÜRÜNLER',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: FRColors.textMuted,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            ...allProducts.take(5).map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ProductSuggestionRow(
                    product: p,
                    onTap: () => widget.onSelect(p),
                    standalone: true,
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

class _ProductSuggestionRow extends StatelessWidget {
  const _ProductSuggestionRow({required this.product, required this.onTap, this.standalone = false});
  final ProductModel product;
  final VoidCallback onTap;
  final bool standalone;

  @override
  Widget build(BuildContext context) {
    final url = product.effectiveImage;
    Widget content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: url != null
                ? CachedNetworkImage(imageUrl: url, width: 40, height: 40, fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _thumb())
                : _thumb(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: FRColors.textPrimary),
                ),
                if (product.brand.isNotEmpty)
                  Text(
                    product.brand,
                    style: const TextStyle(fontSize: 11, color: FRColors.textMuted),
                  ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, size: 18, color: FRColors.textSubtle),
        ],
      ),
    );

    if (standalone) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: FRColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: FRColors.border),
            boxShadow: const [_kShadow],
          ),
          child: content,
        ),
      );
    }
    return InkWell(onTap: onTap, child: content);
  }

  Widget _thumb() => Container(
        width: 40,
        height: 40,
        color: FRColors.backgroundWarm,
        child: const Icon(Icons.category_outlined, size: 18, color: FRColors.textSubtle),
      );
}

class _SelectedProductCard extends StatelessWidget {
  const _SelectedProductCard({required this.product});
  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final url = product.effectiveImage;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FRColors.surface,
        borderRadius: BorderRadius.circular(_kCardR),
        border: Border.all(color: FRColors.tan.withOpacity(0.4)),
        boxShadow: const [_kShadow],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: url != null
                ? CachedNetworkImage(imageUrl: url, width: 56, height: 56, fit: BoxFit.cover)
                : Container(
                    width: 56,
                    height: 56,
                    color: FRColors.backgroundWarm,
                    child: const Icon(Icons.category_outlined, size: 22, color: FRColors.textSubtle),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: FRColors.textPrimary),
                ),
                if (product.brand.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(product.brand, style: const TextStyle(fontSize: 12, color: FRColors.textMuted)),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: FRColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.check_rounded, size: 16, color: FRColors.success),
          ),
        ],
      ),
    );
  }
}

// ─── Step 2: Price + Platform ─────────────────────────────────────────────────
class _Step2Price extends StatelessWidget {
  const _Step2Price({
    required this.product,
    required this.priceCtrl,
    required this.platform,
    required this.submitting,
    required this.onPlatformSelect,
    required this.onPriceChanged,
    required this.onSubmit,
  });

  final ProductModel? product;
  final TextEditingController priceCtrl;
  final String? platform;
  final bool submitting;
  final ValueChanged<String> onPlatformSelect;
  final ValueChanged<String> onPriceChanged;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(_kPad, 20, _kPad, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product context chip
                if (product != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: FRColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: FRColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.inventory_2_outlined, size: 14, color: FRColors.tan),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            product!.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: FRColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                // Price input — hero
                const Text(
                  'FİYAT',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: FRColors.textMuted, letterSpacing: 1.4),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  decoration: BoxDecoration(
                    color: FRColors.surface,
                    borderRadius: BorderRadius.circular(_kCardR),
                    border: Border.all(color: FRColors.border),
                    boxShadow: const [_kShadow],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        '₺',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: FRColors.tan,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: priceCtrl,
                          onChanged: onPriceChanged,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: FRColors.espresso,
                            height: 1,
                          ),
                          decoration: const InputDecoration(
                            hintText: '0,00',
                            hintStyle: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: FRColors.textSubtle,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                // Platform selection
                const Text(
                  'PLATFORM',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: FRColors.textMuted, letterSpacing: 1.4),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: FRColors.surface,
                    borderRadius: BorderRadius.circular(_kCardR),
                    border: Border.all(color: FRColors.border),
                    boxShadow: const [_kShadow],
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < _kPlatforms.length; i++) ...[
                        _PlatformRow(
                          name: _kPlatforms[i],
                          selected: platform == _kPlatforms[i],
                          onTap: () => onPlatformSelect(_kPlatforms[i]),
                        ),
                        if (i < _kPlatforms.length - 1)
                          const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0x06211510)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
        // Submit bar
        Container(
          padding: const EdgeInsets.fromLTRB(_kPad, 14, _kPad, 0),
          decoration: BoxDecoration(
            color: FRColors.surface,
            border: const Border(top: BorderSide(color: Color(0x08211510))),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: submitting ? null : onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: FRColors.espresso,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: FRColors.textSubtle,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: submitting
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: FRColors.tan))
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send_rounded, size: 18, color: FRColors.tan),
                          SizedBox(width: 10),
                          Text(
                            'Fiyatı Bildir',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PlatformRow extends StatelessWidget {
  const _PlatformRow({required this.name, required this.selected, required this.onTap});
  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        color: selected ? FRColors.espresso.withOpacity(0.04) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? FRColors.espresso : FRColors.border,
                  width: selected ? 6 : 2,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Text(
              name,
              style: TextStyle(
                fontSize: 15,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? FRColors.espresso : FRColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Step 3: Done ─────────────────────────────────────────────────────────────
class _Step3Done extends StatelessWidget {
  const _Step3Done({required this.product, required this.onDone, required this.onAddAnother});
  final ProductModel? product;
  final VoidCallback onDone;
  final VoidCallback onAddAnother;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(_kPad, 32, _kPad, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: FRColors.success.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded, size: 44, color: FRColors.success),
          ),
          const SizedBox(height: 24),
          const Text(
            'Fiyat Eklendi!',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: FRColors.espresso,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Katkın topluluk tarafından değerlendirilecek.\nTeşekkürler!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: FRColors.textMuted, height: 1.5),
          ),
          const SizedBox(height: 32),
          // XP card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: FRColors.espresso,
              borderRadius: BorderRadius.circular(_kCardR),
            ),
            child: Column(
              children: [
                const Text(
                  'KAZANDIĞIN PUAN',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: FRColors.tan,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '+10',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 12, left: 8),
                      child: Text(
                        'PT',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: FRColors.tan),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Fotoğraf ekleyerek +10 daha kazanabilirdin',
                  style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.45)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onAddAnother,
              style: ElevatedButton.styleFrom(
                backgroundColor: FRColors.surface,
                foregroundColor: FRColors.espresso,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: FRColors.border),
                ),
              ),
              child: const Text('Başka Fiyat Ekle', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: TextButton(
              onPressed: onDone,
              child: const Text(
                'Kapat',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: FRColors.textMuted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
