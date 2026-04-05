import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/product_model.dart';
import '../../models/store.dart';
import '../../providers/add_price_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/fr_colors.dart';

const _kHeaderRadius = 36.0;
const _kCardRadius = 18.0;
const _kPagePad = 20.0;
const _kCardShadow = BoxShadow(
  color: Color(0x0F170D08),
  blurRadius: 14,
  offset: Offset(0, 4),
);

const _kPlatforms = [
  ('Trendyol', Icons.storefront_rounded),
  ('Hepsiburada', Icons.store_rounded),
  ('Amazon', Icons.shopping_bag_outlined),
  ('N11', Icons.local_mall_rounded),
  ('ÇiçekSepeti', Icons.local_florist_rounded),
  ('Diğer', Icons.more_horiz_rounded),
];

class AddPriceScreen extends ConsumerStatefulWidget {
  const AddPriceScreen({super.key, this.initialProductId});
  final String? initialProductId;

  @override
  ConsumerState<AddPriceScreen> createState() => _AddPriceScreenState();
}

class _AddPriceScreenState extends ConsumerState<AddPriceScreen> {
  final _priceCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  String? _platform;
  bool _submitting = false;
  ProductModel? _product;

  @override
  void initState() {
    super.initState();
    if (widget.initialProductId?.trim().isNotEmpty == true) {
      _loadProduct(widget.initialProductId!.trim());
    }
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProduct(String id) async {
    final p = await ref.read(productProvider(id).future);
    if (mounted) setState(() => _product = p);
  }

  bool get _valid =>
      _platform != null &&
      _priceCtrl.text.trim().isNotEmpty &&
      double.tryParse(_priceCtrl.text.trim().replaceAll(',', '.')) != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FRColors.backgroundWarm,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                _kPagePad,
                20,
                _kPagePad,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPointsStrip(context),
                  const SizedBox(height: 24),
                  _buildSectionLabel('PLATFORM'),
                  const SizedBox(height: 12),
                  _buildPlatformGrid(),
                  const SizedBox(height: 24),
                  _buildSectionLabel('FİYAT'),
                  const SizedBox(height: 12),
                  _buildPriceInput(),
                  const SizedBox(height: 4),
                  if (_priceCtrl.text.isNotEmpty) _buildValidationHint(),
                  const SizedBox(height: 24),
                  _buildSectionLabel('NOT (opsiyonel)'),
                  const SizedBox(height: 12),
                  _buildNoteInput(),
                  const SizedBox(height: 24),
                  _buildImpactRow(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          _buildSubmitBar(context),
        ],
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: FRColors.espresso,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(_kHeaderRadius),
          bottomRight: Radius.circular(_kHeaderRadius),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button row
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 8, _kPagePad, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 17),
                    color: Colors.white.withOpacity(0.7),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                ],
              ),
            ),
            // Title + product chip
            Padding(
              padding: const EdgeInsets.fromLTRB(_kPagePad, 4, _kPagePad, 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fiyat Bildir',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.8,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'RADARA KATKI SAĞ',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withOpacity(0.28),
                      letterSpacing: 1.4,
                    ),
                  ),
                  if (_product != null) ...[
                    const SizedBox(height: 16),
                    _buildProductChip(_product!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductChip(ProductModel p) {
    final cat = p.categories.isNotEmpty ? p.categories.first : '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: FRColors.tan.withOpacity(0.15),
              borderRadius: BorderRadius.circular(11),
            ),
            child: p.effectiveImage?.isNotEmpty == true
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: CachedNetworkImage(imageUrl: p.effectiveImage!, fit: BoxFit.cover),
                  )
                : const Icon(Icons.category_outlined, size: 20, color: FRColors.tan),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (cat.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(cat, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.45))),
                ],
              ],
            ),
          ),
          TextButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ürün değiştirme yakında eklenecek.')),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
            ),
            child: const Text('Değiştir', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: FRColors.tan)),
          ),
        ],
      ),
    );
  }

  // ─── Points strip ─────────────────────────────────────────────────────────

  Widget _buildPointsStrip(BuildContext context) {
    final user = ref.watch(userModelStreamProvider).valueOrNull;
    final pts = user?.points ?? 0;
    final progress = (pts % 100).toDouble();
    final toNext = 100 - progress.toInt();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: FRColors.espresso,
        borderRadius: BorderRadius.circular(_kCardRadius),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: FRColors.tan.withOpacity(0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.bolt_rounded, size: 18, color: FRColors.tan),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sonraki seviyeye $toNext puan kaldı',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                ),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress / 100,
                    backgroundColor: Colors.white.withOpacity(0.10),
                    color: FRColors.tan,
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              Text(
                '+5 XP',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: FRColors.tan),
              ),
              Text(
                'bu katkı',
                style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.35)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Platform grid ────────────────────────────────────────────────────────

  Widget _buildPlatformGrid() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _kPlatforms.map((e) {
        final name = e.$1;
        final icon = e.$2;
        final active = _platform == name;
        return GestureDetector(
          onTap: () => setState(() => _platform = name),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: active ? FRColors.espresso : FRColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: active ? FRColors.tan.withOpacity(0.5) : const Color(0x0C211510),
              ),
              boxShadow: active ? null : const [_kCardShadow],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15, color: active ? FRColors.tan : FRColors.textMuted),
                const SizedBox(width: 7),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white : FRColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Price input ──────────────────────────────────────────────────────────

  Widget _buildPriceInput() {
    return Container(
      decoration: BoxDecoration(
        color: FRColors.surface,
        borderRadius: BorderRadius.circular(_kCardRadius),
        boxShadow: const [_kCardShadow],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Text(
              '₺',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: FRColors.tan,
                height: 1,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _priceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*[\.,]?\d{0,2}'))],
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: FRColors.textPrimary,
                letterSpacing: -1,
              ),
              decoration: const InputDecoration(
                hintText: '0,00',
                hintStyle: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: FRColors.textSubtle,
                  letterSpacing: -1,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.fromLTRB(8, 20, 20, 20),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValidationHint() {
    final raw = _priceCtrl.text.trim().replaceAll(',', '.');
    final price = double.tryParse(raw);
    if (price == null || price <= 0) {
      return _hint(Icons.info_outline_rounded, 'Geçerli bir fiyat girin', FRColors.gold);
    }
    if (price >= 100000) {
      return _hint(Icons.warning_amber_rounded, 'Fiyat beklenenden yüksek — kontrol edin', FRColors.gold);
    }
    return _hint(Icons.check_circle_outline_rounded, 'Fiyat makul aralıkta', FRColors.success);
  }

  Widget _hint(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.22)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 8),
            Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }

  // ─── Note input ───────────────────────────────────────────────────────────

  Widget _buildNoteInput() {
    return Container(
      decoration: BoxDecoration(
        color: FRColors.surface,
        borderRadius: BorderRadius.circular(_kCardRadius),
        boxShadow: const [_kCardShadow],
      ),
      child: TextField(
        controller: _noteCtrl,
        maxLines: 3,
        style: const TextStyle(fontSize: 14, color: FRColors.textPrimary),
        decoration: const InputDecoration(
          hintText: 'Kampanya, stok durumu, notlar...',
          hintStyle: TextStyle(color: FRColors.textSubtle, fontSize: 14),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16),
        ),
      ),
    );
  }

  // ─── Impact row ───────────────────────────────────────────────────────────

  Widget _buildImpactRow() {
    return Row(
      children: [
        _impactPill('+5 XP', Icons.star_rounded),
        const SizedBox(width: 8),
        _impactPill('+2 Güven', Icons.shield_rounded),
        const SizedBox(width: 8),
        _impactPill('Rozet', Icons.emoji_events_rounded),
      ],
    );
  }

  Widget _impactPill(String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: FRColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [_kCardShadow],
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: FRColors.tan),
            const SizedBox(height: 5),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: FRColors.tan),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Submit bar ───────────────────────────────────────────────────────────

  Widget _buildSubmitBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(_kPagePad, 12, _kPagePad, 0),
      decoration: const BoxDecoration(
        color: FRColors.surface,
        border: Border(top: BorderSide(color: Color(0x0C211510))),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting || !_valid ? null : () => _submit(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FRColors.espresso,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0x22211510),
                  disabledForegroundColor: FRColors.textSubtle,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: FRColors.tan),
                      )
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.send_rounded, size: 17, color: FRColors.tan),
                          SizedBox(width: 8),
                          Text('Fiyatı Gönder', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Katkınız topluluk tarafından doğrulanacaktır.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: FRColors.textSubtle),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ─── Section label ────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: FRColors.textMuted,
        letterSpacing: 1.0,
      ),
    );
  }

  // ─── Submit logic ─────────────────────────────────────────────────────────

  Future<void> _submit(BuildContext context) async {
    if (!_valid) return;
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      _snack(context, 'Fiyat göndermek için giriş yapmalısın.');
      return;
    }
    if (widget.initialProductId == null || widget.initialProductId!.trim().isEmpty) {
      _snack(context, 'Lütfen önce bir ürün seçin.');
      return;
    }
    if (_product == null) {
      _snack(context, 'Ürün bilgisi yükleniyor, lütfen tekrar dene.');
      return;
    }

    setState(() => _submitting = true);
    try {
      final notifier = ref.read(addPriceProvider.notifier);
      notifier.selectProductSuggestion(_product!);
      notifier.setSelectedStore(Store(
        id: _platform!.toLowerCase().replaceAll(' ', '_'),
        name: _platform!,
        type: 'online',
        distanceMeters: null,
        logoUrl: _platform!.isNotEmpty ? _platform![0].toUpperCase() : '?',
      ));
      notifier.setPrice(_priceCtrl.text.trim().replaceAll(',', '.'));
      notifier.setStoreNote(_noteCtrl.text.trim());
      await notifier.submitPrice(userId: user.uid);
      if (!mounted) return;
      _snack(context, '✅ Fiyat başarıyla eklendi!');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _snack(context, '❌ Hata: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
