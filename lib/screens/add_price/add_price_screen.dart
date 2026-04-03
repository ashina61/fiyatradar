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
import '../../theme/fr_radius.dart';
import '../../theme/fr_spacing.dart';
import '../../widgets/fr_button.dart';
import '../../widgets/fr_surface_card.dart';

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
    if (mounted) {
      setState(() => _cachedProduct = product);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = _cachedProduct;

    return Scaffold(
      backgroundColor: FRColors.bgPrimary,
      appBar: _buildAppBar(context),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (product != null) _buildProductSummary(product),
            Expanded(
              child: SingleChildScrollView(
                padding: FRSpaceInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildMotivationBanner(context),
                      FRSurfaceCard(
                        color: FRColors.bgSecondary,
                        borderColor: FRColors.borderDark,
                        shadow: const <BoxShadow>[],
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildSourceField(),
                            const SizedBox(height: 16),
                            _buildPriceField(),
                            const SizedBox(height: 16),
                            _buildNoteField(),
                          ],
                        ),
                      ),
                      if (_priceController.text.isNotEmpty) _buildValidationHint(),
                      _buildTrustImpactPreview(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
            _buildSubmitSection(context),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: FRColors.bgPrimary,
      elevation: 0,
      toolbarHeight: 56,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        color: FRColors.textPrimaryDark,
        onPressed: () => Navigator.maybePop(context),
      ),
      title: const Text(
        'Fiyat Bildir',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: FRColors.textPrimaryDark,
        ),
      ),
      centerTitle: false,
    );
  }

  Widget _buildProductSummary(ProductModel product) {
    final category = product.categories.isNotEmpty ? product.categories.first : 'Kategori';

    return Container(
      margin: FRSpaceInsets.fromLTRB(16, 0, 16, 12),
      child: FRSurfaceCard(
        padding: FRSpaceInsets.fromLTRB(14, 12, 14, 12),
        color: FRColors.bgSecondary,
        borderColor: FRColors.borderDark,
        shadow: const <BoxShadow>[],
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: FRColors.surfaceAltDark,
                borderRadius: FRRadius.all(FRRadius.md),
                border: Border.all(color: FRColors.borderDark),
              ),
              child: product.effectiveImage != null && product.effectiveImage!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: FRRadius.all(FRRadius.md),
                      child: CachedNetworkImage(
                        imageUrl: product.effectiveImage!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => const Icon(
                          Icons.category_outlined,
                          size: 26,
                          color: FRColors.tan,
                        ),
                      ),
                    )
                  : const Icon(Icons.category_outlined, size: 26, color: FRColors.tan),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: FRColors.textPrimaryDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${product.brand} • $category',
                    style: const TextStyle(
                      fontSize: 11,
                      color: FRColors.textSubtleDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _changeProduct(context),
              child: const Text(
                'Değiştir',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: FRColors.tanLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMotivationBanner(BuildContext context) {
    final userModel = ref.watch(userModelStreamProvider).valueOrNull;
    final points = userModel?.points ?? 0;
    final progress = (points % 100).toDouble();

    return FRSurfaceCard(
      margin: FRSpaceInsets.only(bottom: 16),
      padding: FRSpaceInsets.all(14),
      color: FRColors.bgSecondary,
      borderColor: FRColors.borderDark,
      shadow: const <BoxShadow>[],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [FRColors.tan, FRColors.tanLight],
                  ),
                  borderRadius: FRRadius.all(FRRadius.pill),
                ),
                child: const Icon(
                  Icons.verified_rounded,
                  size: 14,
                  color: FRColors.bgPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${100 - progress.toInt()} puan sonra yeni katkı seviyesi',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: FRColors.textPrimaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 5,
            decoration: BoxDecoration(
              color: FRColors.surfaceAltDark,
              borderRadius: FRRadius.all(FRRadius.pill),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress / 100,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [FRColors.tan, FRColors.tanLight],
                  ),
                  borderRadius: FRRadius.all(FRRadius.pill),
                ),
              ),
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Katkın fiyat güvenini güçlendirir.',
            style: TextStyle(
              fontSize: 11,
              color: FRColors.textSubtleDark,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildRewardChip('+5 XP', Icons.star_rounded),
              const SizedBox(width: 8),
              _buildRewardChip('+2 Güven', Icons.shield_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRewardChip(String label, IconData icon) {
    return Container(
      padding: FRSpaceInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: FRColors.surfaceAltDark,
        borderRadius: FRRadius.all(FRRadius.sm),
        border: Border.all(color: FRColors.borderDark),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: FRColors.tan),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: FRColors.tan,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fiyat Kaynağı',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: FRColors.textPrimaryDark,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: FRColors.surfaceDark,
            borderRadius: FRRadius.all(FRRadius.lg),
            border: Border.all(color: FRColors.borderDark),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedSource,
              dropdownColor: FRColors.surfaceDark,
              iconEnabledColor: FRColors.textSecondaryDark,
              isExpanded: true,
              hint: const Padding(
                padding: EdgeInsets.all(14),
                child: Text(
                  'Fiyat gördüğün yeri seç...',
                  style: TextStyle(
                    color: FRColors.textSubtleDark,
                    fontSize: 15,
                  ),
                ),
              ),
              items: ['Trendyol', 'Hepsiburada', 'Amazon', 'N11', 'ÇiçekSepeti', 'Diğer']
                  .map(
                    (source) => DropdownMenuItem(
                      value: source,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          source,
                          style: const TextStyle(
                            fontSize: 15,
                            color: FRColors.textPrimaryDark,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedSource = value);
                _validateForm();
              },
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Fiyatı gördüğün mağaza / platform kaynağı',
          style: TextStyle(
            fontSize: 10,
            color: FRColors.textSubtleDark,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fiyat',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: FRColors.textPrimaryDark,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: FRColors.surfaceDark,
            borderRadius: FRRadius.all(FRRadius.lg),
            border: Border.all(color: FRColors.borderDark),
          ),
          child: TextField(
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*[\.,]?\d{0,2}'))],
            decoration: const InputDecoration(
              hintText: '0,00',
              hintStyle: TextStyle(
                color: FRColors.textSubtleDark,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
              prefixIcon: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '₺',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: FRColors.tan,
                  ),
                ),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: FRColors.textPrimaryDark,
            ),
            textAlign: TextAlign.right,
            onChanged: (_) => _validateForm(),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Yalnızca fiyat girmen yeterli',
          style: TextStyle(
            fontSize: 10,
            color: FRColors.textSubtleDark,
          ),
        ),
      ],
    );
  }

  Widget _buildNoteField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kısa Not (Opsiyonel)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: FRColors.textPrimaryDark,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: FRColors.surfaceDark,
            borderRadius: FRRadius.all(FRRadius.lg),
            border: Border.all(color: FRColors.borderDark),
          ),
          child: TextField(
            controller: _noteController,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'Örn: kampanyalı etiket, kasada görülen fiyat...',
              hintStyle: TextStyle(
                color: FRColors.textSubtleDark,
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(14),
            ),
            style: const TextStyle(
              fontSize: 14,
              color: FRColors.textPrimaryDark,
            ),
            onChanged: (_) => _validateForm(),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Kısa bağlam bırakmak istersen',
          style: TextStyle(
            fontSize: 10,
            color: FRColors.textSubtleDark,
          ),
        ),
      ],
    );
  }

  Widget _buildValidationHint() {
    final priceText = _priceController.text.trim().replaceAll(',', '.');
    final price = double.tryParse(priceText);

    if (price == null || price <= 0) {
      return Container(
        margin: FRSpaceInsets.only(top: 12, bottom: 8),
        padding: FRSpaceInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: FRColors.goldBg(0.12),
          borderRadius: FRRadius.all(FRRadius.md),
          border: Border.all(color: FRColors.gold.withOpacity(0.35)),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline_rounded, size: 16, color: FRColors.gold),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Geçerli bir fiyat girin',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: FRColors.gold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final isReasonable = price > 0 && price < 100000;
    return Container(
      margin: FRSpaceInsets.only(top: 12, bottom: 8),
      padding: FRSpaceInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isReasonable ? FRColors.successBgMuted : FRColors.goldBg(0.12),
        borderRadius: FRRadius.all(FRRadius.md),
        border: Border.all(color: isReasonable ? FRColors.successMuted.withOpacity(0.35) : FRColors.gold.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(
            isReasonable ? Icons.check_circle_outline_rounded : Icons.info_outline_rounded,
            size: 16,
            color: isReasonable ? FRColors.success : FRColors.gold,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isReasonable ? 'Fiyat makul aralıkta' : 'Fiyat beklenenden yüksek, kontrol edin',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isReasonable ? FRColors.success : FRColors.gold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustImpactPreview() {
    return FRSurfaceCard(
      margin: FRSpaceInsets.only(top: 8),
      padding: FRSpaceInsets.all(14),
      color: FRColors.bgSecondary,
      borderColor: FRColors.borderDark,
      shadow: const <BoxShadow>[],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Katkı Etkisi',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: FRColors.textSubtleDark,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildImpactItem('+5', 'XP', Icons.star_rounded),
              const SizedBox(width: 10),
              _buildImpactItem('+2', 'Güven', Icons.shield_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImpactItem(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: FRSpaceInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: FRColors.surfaceAltDark,
          borderRadius: FRRadius.all(FRRadius.md),
          border: Border.all(color: FRColors.borderDark),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: FRColors.tan),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: FRColors.tan,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: FRColors.textSubtleDark,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitSection(BuildContext context) {
    return FRSurfaceCard(
      margin: FRSpaceInsets.fromLTRB(16, 8, 16, 16),
      padding: FRSpaceInsets.fromLTRB(14, 12, 14, 14),
      color: FRColors.bgSecondary,
      borderColor: FRColors.borderDark,
      shadow: const <BoxShadow>[],
      child: Column(
        children: [
          _isSubmitting
              ? const SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2, color: FRColors.tan),
                  ),
                )
              : FRButton.primary(
                  expanded: true,
                  label: 'Fiyat Kaydını Gönder',
                  icon: Icons.send_rounded,
                  onPressed: _isFormValid() ? () => _submitPrice(context) : null,
                ),
          const SizedBox(height: 12),
          const Text(
            'Katkınız topluluk tarafından doğrulanacaktır.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: FRColors.textSubtleDark,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  bool _isFormValid() {
    return _selectedSource != null &&
        _selectedSource!.isNotEmpty &&
        _priceController.text.trim().isNotEmpty &&
        double.tryParse(_priceController.text.trim().replaceAll(',', '.')) != null;
  }

  void _validateForm() {
    setState(() {});
  }

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
