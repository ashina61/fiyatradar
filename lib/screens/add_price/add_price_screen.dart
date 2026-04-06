import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_system/design_system.dart';
import '../../models/product_model.dart';
import '../../models/store.dart';
import '../../providers/add_price_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';

const _platforms = [
  'Trendyol',
  'Hepsiburada',
  'Amazon',
  'N11',
  'ÇiçekSepeti',
  'A101',
  'BİM',
  'Migros',
  'CarrefourSA',
  'Diğer',
];

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
    final id = widget.initialProductId;
    if (id?.isNotEmpty == true) {
      _loadProduct(id!);
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
    if (mounted && p != null) {
      setState(() => _product = p);
    }
  }

  bool get _canSubmit {
    return _platform != null &&
        _product != null &&
        _priceCtrl.text.trim().isNotEmpty &&
        double.tryParse(_priceCtrl.text.trim().replaceAll(',', '.')) != null;
  }

  void _goToStep(int step) {
    setState(() => _step = step);
    _pageCtrl.animateToPage(step, duration: const Duration(milliseconds: 260), curve: Curves.easeInOut);
  }

  Future<void> _submit() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null || !_canSubmit || _product == null || _platform == null) {
      return;
    }

    setState(() => _submitting = true);
    try {
      final notifier = ref.read(addPriceProvider.notifier);
      notifier.selectProductSuggestion(_product!);
      notifier.setSelectedStore(
        Store(
          id: _platform!.toLowerCase().replaceAll(' ', '_'),
          name: _platform!,
          type: 'online',
          distanceMeters: 0,
          logoUrl: '',
        ),
      );
      notifier.setPrice(_priceCtrl.text.trim().replaceAll(',', '.'));
      await notifier.submitPrice(userId: user.uid);
      if (mounted) {
        _goToStep(2);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fiyat gönderilemedi: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FRAppScaffold(
      child: Column(
        children: [
          FRDarkHero(
            title: 'Fiyat Ekle',
            subtitle: 'Doğrulanabilir katkı akışı',
            kicker: const FRKickerPill('Trusted Contribution'),
            leading: FRHeroActionButton(
              icon: _step == 2 ? Icons.close : Icons.arrow_back,
              onPressed: () {
                if (_step > 0 && _step < 2) {
                  _goToStep(_step - 1);
                } else {
                  Navigator.maybePop(context);
                }
              },
            ),
            content: FRFormStepIndicator(steps: 3, currentStep: _step),
          ),
          Expanded(
            child: PageView(
              controller: _pageCtrl,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _SelectProductStep(
                  controller: _searchCtrl,
                  selected: _product,
                  onSelected: (product) {
                    setState(() => _product = product);
                    _goToStep(1);
                  },
                ),
                _EnterPriceStep(
                  product: _product,
                  priceController: _priceCtrl,
                  selectedPlatform: _platform,
                  onPlatformChanged: (value) => setState(() => _platform = value),
                  onPriceChanged: (_) => setState(() {}),
                ),
                _CompleteStep(
                  onClose: () => Navigator.maybePop(context),
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
          if (_step == 1)
            FRFloatingSubmitBar(
              label: _submitting ? 'Gönderiliyor...' : 'Fiyatı Bildir',
              onPressed: _submitting ? null : (_canSubmit ? _submit : null),
            ),
        ],
      ),
    );
  }
}

class _SelectProductStep extends ConsumerStatefulWidget {
  const _SelectProductStep({
    required this.controller,
    required this.selected,
    required this.onSelected,
  });

  final TextEditingController controller;
  final ProductModel? selected;
  final ValueChanged<ProductModel> onSelected;

  @override
  ConsumerState<_SelectProductStep> createState() => _SelectProductStepState();
}

class _SelectProductStepState extends ConsumerState<_SelectProductStep> {
  List<ProductModel> _suggestions = <ProductModel>[];

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(allProductsProvider).valueOrNull ?? <ProductModel>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(FRDsSpacing.space20, FRDsSpacing.space16, FRDsSpacing.space20, FRDsSpacing.space32),
      child: FRAddPriceFlowSection(
        eyebrow: '1. ADIM',
        title: 'Ürün seçimi',
        children: [
          FRSearchField(
            controller: widget.controller,
            hintText: 'Ürün adı yaz',
            onChanged: (query) {
              setState(() {
                _suggestions = query.length < 2
                    ? <ProductModel>[]
                    : all.where((p) => p.name.toLowerCase().contains(query.toLowerCase())).take(8).toList();
              });
            },
          ),
          const SizedBox(height: FRDsSpacing.space16),
          if (_suggestions.isNotEmpty)
            ..._suggestions.map(
              (product) => Padding(
                padding: const EdgeInsets.only(bottom: FRDsSpacing.space8),
                child: FRSelectionCard(
                  onTap: () {
                    widget.controller.text = product.name;
                    widget.onSelected(product);
                  },
                  child: Text(product.name, style: FRDsTypography.bodyLarge),
                ),
              ),
            )
          else ...[
            Text('Popüler ürünler', style: FRDsTypography.titleMedium),
            const SizedBox(height: FRDsSpacing.space12),
            ...all.take(6).map(
                  (product) => Padding(
                    padding: const EdgeInsets.only(bottom: FRDsSpacing.space8),
                    child: FRSelectionCard(
                      onTap: () => widget.onSelected(product),
                      child: Text(product.name, style: FRDsTypography.bodyLarge),
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

class _EnterPriceStep extends StatelessWidget {
  const _EnterPriceStep({
    required this.product,
    required this.priceController,
    required this.selectedPlatform,
    required this.onPlatformChanged,
    required this.onPriceChanged,
  });

  final ProductModel? product;
  final TextEditingController priceController;
  final String? selectedPlatform;
  final ValueChanged<String> onPlatformChanged;
  final ValueChanged<String> onPriceChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(FRDsSpacing.space20, FRDsSpacing.space16, FRDsSpacing.space20, FRDsSpacing.space32),
      child: FRAddPriceFlowSection(
        eyebrow: '2. ADIM',
        title: 'Fiyat ve market',
        children: [
          if (product != null)
            Padding(
              padding: const EdgeInsets.only(bottom: FRDsSpacing.space12),
              child: FRPill(product!.name, variant: FRPillVariant.selected),
            ),
          FRPriceInputField(
            controller: priceController,
            onChanged: onPriceChanged,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
          ),
          const SizedBox(height: FRDsSpacing.space16),
          for (final platform in _platforms)
            Padding(
              padding: const EdgeInsets.only(bottom: FRDsSpacing.space8),
              child: FRSelectionCard(
                selected: selectedPlatform == platform,
                onTap: () => onPlatformChanged(platform),
                child: Text(platform),
              ),
            ),
        ],
      ),
    );
  }
}

class _CompleteStep extends StatelessWidget {
  const _CompleteStep({required this.onClose, required this.onAddAnother});

  final VoidCallback onClose;
  final VoidCallback onAddAnother;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(FRDsSpacing.space20),
      child: FRAchievementsSection(
        eyebrow: '3. ADIM',
        title: 'Katkın kaydedildi',
        children: [
          const FRDarkFeatureCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '+10 PT',
                  style: FRDsTypography.displayLarge.copyWith(
                    color: FRDsColors.frSurface,
                  ),
                ),
                SizedBox(height: FRDsSpacing.space8),
                Text(
                  'Güvenilir fiyat katkısı için teşekkürler.',
                  style: FRDsTypography.bodyMedium.copyWith(color: FRDsColors.frGoldSoft),
                ),
              ],
            ),
          ),
          const SizedBox(height: FRDsSpacing.space16),
          FRSecondaryButton(label: 'Başka Fiyat Ekle', onPressed: onAddAnother),
          const SizedBox(height: FRDsSpacing.space8),
          FRGhostButton(label: 'Kapat', onPressed: onClose),
        ],
      ),
    );
  }
}
