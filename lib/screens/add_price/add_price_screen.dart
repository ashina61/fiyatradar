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

class AddPriceScreen extends ConsumerStatefulWidget {
  const AddPriceScreen({
    super.key,
    this.initialProductId,
  });

  final String? initialProductId;

  @override
  ConsumerState<AddPriceScreen> createState() => _AddPriceScreenState();
}

class _AddPriceScreenState extends ConsumerState<AddPriceScreen> {
  final _priceController = TextEditingController();
  final _noteController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _selectedSource;
  bool _isSubmitting = false;
  ProductModel? _cachedProduct;

  static const _platforms = ['Trendyol', 'Hepsiburada', 'Amazon', 'N11', 'ÇiçekSepeti', 'Diğer'];

  @override
  void initState() {
    super.initState();
    if (widget.initialProductId != null && widget.initialProductId!.trim().isNotEmpty) {
      _loadProduct(widget.initialProductId!.trim());
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadProduct(String productId) async {
    final product = await ref.read(productProvider(productId).future);
    if (mounted) setState(() => _cachedProduct = product);
  }

  @override
  Widget build(BuildContext context) {
    final product = _cachedProduct;

    return Scaffold(
      backgroundColor: FRColors.backgroundWarm,
      body: Column(
        children: [
          _buildDarkHeader(context, product),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildMotivationCard(context),
                    const SizedBox(height: 16),
                    _buildSectionHeader('Fiyat Kaynağı'),
                    const SizedBox(height: 10),
                    _buildPlatformSelector(),
                    const SizedBox(height: 20),
                    _buildSectionHeader('Fiyat'),
                    const SizedBox(height: 10),
                    _buildPriceInput(),
                    const SizedBox(height: 4),
                    const Text(
                      'Güncel fiyatı girin',
                      style: TextStyle(fontSize: 11, color: FRColors.textSubtle),
                    ),
                    if (_priceController.text.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _buildValidationHint(),
                    ],
                    const SizedBox(height: 20),
                    _buildSectionHeader('Not'),
                    const SizedBox(height: 10),
                    _buildNoteInput(),
                    const SizedBox(height: 4),
                    const Text(
                      'Ek bilgi eklemek istersen (isteğe bağlı)',
                      style: TextStyle(fontSize: 11, color: FRColors.textSubtle),
                    ),
                    const SizedBox(height: 20),
                    _buildImpactCard(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
          _buildSubmitBar(context),
        ],
      ),
    );
  }

  Widget _buildDarkHeader(BuildContext context, ProductModel? product) {
    return Container(
      decoration: const BoxDecoration(
        color: FRColors.espresso,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nav bar
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                    color: Colors.white.withOpacity(0.8),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                  const Spacer(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fiyat Bildir',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'RADARINIZA KATKIDA BULUNUN',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: FRColors.textMuted,
                      letterSpacing: 1.2,
                    ),
                  ),
                  if (product != null) ...[
                    const SizedBox(height: 16),
                    _buildProductChip(product),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductChip(ProductModel product) {
    final category = product.categories.isNotEmpty ? product.categories.first : 'Kategori';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: FRColors.tan.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: product.effectiveImage != null && product.effectiveImage!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: product.effectiveImage!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) =>
                          const Icon(Icons.category_outlined, size: 22, color: FRColors.tan),
                    ),
                  )
                : const Icon(Icons.category_outlined, size: 22, color: FRColors.tan),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${product.brand} • $category',
                  style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.5)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _changeProduct(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
            ),
            child: const Text(
              'Değiştir',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: FRColors.tan),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String label) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: FRColors.textMuted,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildMotivationCard(BuildContext context) {
    final userModel = ref.watch(userModelStreamProvider).valueOrNull;
    final points = userModel?.points ?? 0;
    final progress = (points % 100).toDouble();
    final toNext = 100 - progress.toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FRColors.espresso,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: FRColors.tan.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.trending_up_rounded, size: 16, color: FRColors.tan),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Sonraki seviyeye $toNext puan kaldı',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress / 100,
              backgroundColor: Colors.white.withOpacity(0.1),
              color: FRColors.tan,
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Bu katkı +5 XP • +2 Güven puanı kazandırır',
            style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.5)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildRewardBadge('+5 XP', Icons.star_rounded),
              const SizedBox(width: 8),
              _buildRewardBadge('+2 Güven', Icons.shield_rounded),
              const SizedBox(width: 8),
              _buildRewardBadge('Rozet', Icons.emoji_events_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRewardBadge(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: FRColors.tan.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: FRColors.tan),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: FRColors.tan),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformSelector() {
    return Container(
      decoration: BoxDecoration(
        color: FRColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x08170D08), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedSource,
          isExpanded: true,
          borderRadius: BorderRadius.circular(16),
          hint: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              'Platform seçin...',
              style: TextStyle(color: FRColors.textSubtle, fontSize: 15),
            ),
          ),
          items: _platforms.map(
            (source) => DropdownMenuItem(
              value: source,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: FRColors.tan.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          source[0],
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: FRColors.tan,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(source, style: const TextStyle(fontSize: 15, color: FRColors.textPrimary)),
                  ],
                ),
              ),
            ),
          ).toList(),
          onChanged: (value) {
            setState(() => _selectedSource = value);
            _validateForm();
          },
        ),
      ),
    );
  }

  Widget _buildPriceInput() {
    return Container(
      decoration: BoxDecoration(
        color: FRColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x08170D08), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: TextField(
        controller: _priceController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*[\.,]?\d{0,2}'))],
        decoration: const InputDecoration(
          hintText: '0,00',
          hintStyle: TextStyle(
            color: FRColors.textSubtle,
            fontSize: 32,
            fontWeight: FontWeight.w700,
          ),
          prefixIcon: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              '₺',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: FRColors.tan,
              ),
            ),
          ),
          prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: FRColors.textPrimary,
        ),
        textAlign: TextAlign.right,
        onChanged: (_) => _validateForm(),
      ),
    );
  }

  Widget _buildNoteInput() {
    return Container(
      decoration: BoxDecoration(
        color: FRColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x08170D08), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: TextField(
        controller: _noteController,
        maxLines: 3,
        decoration: const InputDecoration(
          hintText: 'Kampanyalı fiyat, indirim, stok durumu... (opsiyonel)',
          hintStyle: TextStyle(color: FRColors.textSubtle, fontSize: 14),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16),
        ),
        style: const TextStyle(fontSize: 14, color: FRColors.textPrimary),
        onChanged: (_) => _validateForm(),
      ),
    );
  }

  Widget _buildValidationHint() {
    final priceText = _priceController.text.trim().replaceAll(',', '.');
    final price = double.tryParse(priceText);

    if (price == null || price <= 0) {
      return _buildHintBanner(
        color: FRColors.gold,
        icon: Icons.info_outline_rounded,
        text: 'Geçerli bir fiyat girin',
      );
    }

    final isReasonable = price > 0 && price < 100000;
    return _buildHintBanner(
      color: isReasonable ? FRColors.success : FRColors.gold,
      icon: isReasonable ? Icons.check_circle_outline_rounded : Icons.info_outline_rounded,
      text: isReasonable ? 'Fiyat makul aralıkta' : 'Fiyat beklenenden yüksek, kontrol edin',
    );
  }

  Widget _buildHintBanner({required Color color, required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FRColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: FRColors.border),
        boxShadow: const [
          BoxShadow(color: Color(0x06170D08), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'BU KATKI İLE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: FRColors.textMuted,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildImpactItem('+5', 'XP', Icons.star_rounded),
              const SizedBox(width: 10),
              _buildImpactItem('+2', 'Güven', Icons.shield_rounded),
              const SizedBox(width: 10),
              _buildImpactItem('1', 'Rozet', Icons.emoji_events_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImpactItem(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: FRColors.backgroundWarm,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: FRColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: FRColors.tan),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: FRColors.tan),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: FRColors.textSubtle, letterSpacing: 0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitBar(BuildContext context) {
    final isValid = _isFormValid();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: FRColors.surface,
        border: const Border(top: BorderSide(color: FRColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting || !isValid ? null : () => _submitPrice(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FRColors.espresso,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: FRColors.border,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: FRColors.tan),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.send_rounded, size: 18, color: FRColors.tan),
                          const SizedBox(width: 8),
                          const Text(
                            'Fiyatı Gönder',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
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

  bool _isFormValid() {
    return _selectedSource != null &&
        _selectedSource!.isNotEmpty &&
        _priceController.text.trim().isNotEmpty &&
        double.tryParse(_priceController.text.trim().replaceAll(',', '.')) != null;
  }

  void _validateForm() => setState(() {});

  void _changeProduct(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ürün değiştirme yakında eklenecek.')),
    );
  }

  Future<void> _submitPrice(BuildContext context) async {
    if (!_isFormValid()) return;
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fiyat göndermek için giriş yapmalısın.')),
      );
      return;
    }

    if (widget.initialProductId == null || widget.initialProductId!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen önce bir ürün seçin.')),
      );
      return;
    }
    if (_cachedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ürün bilgisi yükleniyor, lütfen tekrar dene.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final notifier = ref.read(addPriceProvider.notifier);
      final source = _selectedSource!;
      notifier.selectProductSuggestion(_cachedProduct!);
      notifier.setSelectedStore(
        Store(
          id: source.toLowerCase().replaceAll(' ', '_'),
          name: source,
          type: 'online',
          distanceMeters: null,
          logoUrl: source.isNotEmpty ? source[0].toUpperCase() : '?',
        ),
      );
      notifier.setPrice(_priceController.text.trim().replaceAll(',', '.'));
      notifier.setStoreNote(_noteController.text.trim());

      await notifier.submitPrice(userId: user.uid);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Fiyat başarıyla eklendi!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Hata: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
