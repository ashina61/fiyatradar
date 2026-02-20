import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/price_model.dart';
import '../../models/product_model.dart';
import '../../models/store_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../utils/constants.dart';

class AddPriceScreen extends ConsumerStatefulWidget {
  const AddPriceScreen({super.key});

  @override
  ConsumerState<AddPriceScreen> createState() => _AddPriceScreenState();
}

class _AddPriceScreenState extends ConsumerState<AddPriceScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _priceController = TextEditingController(text: '0,00');
  final TextEditingController _productController = TextEditingController();

  ProductModel? _selectedProduct;
  String? _selectedCategory;
  StoreModel? _selectedStore;
  bool _isSubmitting = false;

  static const Color _bg = Color(0xFFF5EEE4);
  static const Color _paper = Color(0xFFFFFBF6);
  static const Color _bronze = Color(0xFFC08A5A);
  static const Color _hairline = Color(0x1F3A2A1A);
  static const Color _title = Color(0xFF2A211B);
  static const Color _muted = Color(0xFF7A695D);

  static const double _rLg = 24;
  static const double _rMd = 18;

  static const TextStyle _titleStyle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: _title,
    letterSpacing: -0.4,
    height: 1.1,
  );

  static const TextStyle _subtitleStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: _muted,
    height: 1.4,
  );

  static const TextStyle _sectionStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: _title,
    letterSpacing: -0.2,
  );

  static const TextStyle _rowLabelStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: _muted,
    letterSpacing: 1.2,
  );

  static const TextStyle _rowValueStyle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: _title,
    letterSpacing: -0.2,
  );

  @override
  void dispose() {
    _priceController.dispose();
    _productController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rewardPoints = AppConstants.pointsForPriceEntry;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 250),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopBar(context),
                    const SizedBox(height: 24),
                    _buildRewardStrip(rewardPoints),
                    const SizedBox(height: 28),
                    _buildDetailsSection(),
                    const SizedBox(height: 28),
                    _buildCommunityNote(),
                    const SizedBox(height: 28),
                    _buildPriceHero(),
                  ],
                ),
              ),
            ),
            _buildStickyFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _paper,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _hairline),
                ),
                child: IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  color: _title,
                ),
              ),
            ),
            const Spacer(),
            const SizedBox(width: 44),
          ],
        ),
        const SizedBox(height: 12),
        const Text('Fiyat Ekle', style: _titleStyle, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        const Text(
          'Etikette gördüğün fiyatı kaydet.',
          style: _subtitleStyle,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRewardStrip(int rewardPoints) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.circular(_rMd),
        border: Border.all(color: _hairline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(top: 4),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [Color(0xFFE2B07F), Color(0xFFA56A3A)]),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    text: 'Katkı Ödülü ',
                    style: const TextStyle(
                      fontSize: 15,
                      color: _title,
                      fontWeight: FontWeight.w500,
                    ),
                    children: [
                      TextSpan(
                        text: '+$rewardPoints',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: _bronze),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Doğrulanırsa güven skorun yükselir.',
                  style: _subtitleStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Detaylar', style: _sectionStyle),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: _paper,
            borderRadius: BorderRadius.circular(_rLg),
            border: Border.all(color: _hairline),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 14,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              _detailRow(
                label: 'ÜRÜN',
                value: _selectedProduct?.name ?? 'Seç veya yaz',
                trailing: '›',
                onTap: _onProductTap,
              ),
              _divider(),
              _detailRow(
                label: 'KATEGORİ',
                value: _selectedCategory ?? 'Kategori seç',
                trailing: '▾',
                onTap: _onCategoryTap,
              ),
              _divider(),
              _detailRow(
                label: 'MAĞAZA',
                value: _selectedStore?.displayName ?? 'Mağaza / Şube seç',
                trailing: '›',
                onTap: _onStoreTap,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _detailRow({
    required String label,
    required String value,
    required String trailing,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: _rowLabelStyle),
                  const SizedBox(height: 8),
                  Text(value, style: _rowValueStyle),
                ],
              ),
            ),
            Text(
              trailing,
              style: const TextStyle(fontSize: 20, color: _muted, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() => const Divider(height: 1, thickness: 1, color: _hairline);

  Widget _buildCommunityNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.circular(_rMd),
        border: Border.all(color: _hairline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 2,
            height: 86,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFE0AE7B), Color(0xFFA16A3D)],
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Topluluk Notu',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _title),
                ),
                SizedBox(height: 8),
                Text(
                  'FiyatRadar, kullanıcıların özenli katkılarıyla büyür. Lütfen ürün ve fiyat bilgisini mümkün olduğunca doğru gir—her doğru bildirim, başkasının tasarrufuna dönüşür.',
                  style: TextStyle(fontSize: 13, height: 1.5, color: _muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.circular(_rLg),
        border: Border.all(color: _hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Text('Etiket Fiyatı', style: _sectionStyle)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0x1AC08A5A),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0x4DC08A5A)),
                ),
                child: const Text(
                  'TL',
                  style: TextStyle(
                    color: _bronze,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text('Mağazada gördüğün değeri gir.', style: _subtitleStyle),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text(
                  '₺',
                  style: TextStyle(
                    fontSize: 36,
                    color: _bronze,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9,]')),
                  ],
                  validator: (value) {
                    final raw = (value ?? '').trim();
                    if (raw.isEmpty) return 'Fiyat girin';
                    final parsed = double.tryParse(raw.replaceAll(',', '.'));
                    if (parsed == null || parsed <= 0) return 'Geçerli fiyat girin';
                    return null;
                  },
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w600,
                    color: _title,
                    letterSpacing: -1.2,
                  ),
                  decoration: const InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Örn: 49,90', style: TextStyle(fontSize: 12, color: _muted)),
              const Spacer(),
              TextButton(
                onPressed: () => _priceController.text = '49,90',
                style: TextButton.styleFrom(
                  foregroundColor: _bronze,
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                child: const Text('Örneği yapıştır'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStickyFooter() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x00F5EEE4), Color(0xFFF5EEE4), Color(0xFFF5EEE4)],
            stops: [0.0, 0.25, 1.0],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _title,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('KAYDET'),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Yasal Uyarı: Bu ekrandan girilen fiyatlar kullanıcı bildirimi niteliğindedir. Fiyatlar mağazaya göre değişebilir. Satın alma öncesi mağazada teyit etmek kullanıcı sorumluluğundadır. Yanıltıcı bildirimler güven skorunu olumsuz etkileyebilir.',
              style: TextStyle(fontSize: 11, height: 1.35, color: _muted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onProductTap() async {
    final products = ref.read(allProductsProvider).valueOrNull ?? const <ProductModel>[];
    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ürünler yüklenemedi. Lütfen tekrar deneyin.')),
      );
      return;
    }

    final selected = await showModalBottomSheet<ProductModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: ListView.separated(
            itemCount: products.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final product = products[index];
              return ListTile(
                title: Text(product.name),
                subtitle: Text(product.brand),
                onTap: () => Navigator.pop(context, product),
              );
            },
          ),
        );
      },
    );

    if (!mounted || selected == null) return;
    setState(() {
      _selectedProduct = selected;
      _productController.text = selected.name;
      _selectedCategory = selected.categories.isNotEmpty ? selected.categories.first : _selectedCategory;
    });
  }

  Future<void> _onCategoryTap() async {
    final categories = ref.read(categoriesProvider).valueOrNull ?? const [];
    if (categories.isEmpty) return;

    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index].title;
              return ListTile(
                title: Text(category),
                trailing: category == _selectedCategory ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(context, category),
              );
            },
          ),
        );
      },
    );

    if (!mounted || selected == null) return;
    setState(() => _selectedCategory = selected);
  }

  Future<void> _onStoreTap() async {
    final stores = ref.read(allStoresStreamProvider).valueOrNull ?? const <StoreModel>[];
    if (stores.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mağazalar yüklenemedi. Lütfen tekrar deneyin.')),
      );
      return;
    }

    final selected = await showModalBottomSheet<StoreModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: ListView.separated(
            itemCount: stores.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final store = stores[index];
              return ListTile(
                title: Text(store.displayName),
                subtitle: Text('${store.city} / ${store.district}'),
                onTap: () => Navigator.pop(context, store),
              );
            },
          ),
        );
      },
    );

    if (!mounted || selected == null) return;
    setState(() => _selectedStore = selected);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir ürün seçin.')),
      );
      return;
    }

    if (_selectedStore == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir mağaza (şube) seçin')),
      );
      return;
    }

    final userModel = ref.read(userModelStreamProvider).value;
    if (userModel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fiyat eklemek için giriş yapmalısınız')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      final priceText = _priceController.text.replaceAll(',', '.');
      final price = double.tryParse(priceText) ?? 0.0;

      final latestPrice = await firestoreService.getLatestPriceForStore(
        productId: _selectedProduct!.id,
        branchStoreId: _selectedStore!.id,
      );
      if (latestPrice != null && (latestPrice.price - price).abs() <= 0.01) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bu ürün için aynı mağazada aynı fiyat zaten mevcut.')),
        );
        return;
      }

      final priceModel = PriceModel(
        id: '',
        productId: _selectedProduct!.id,
        userId: userModel.uid,
        userName: userModel.name,
        price: price,
        branchStoreId: _selectedStore!.id,
        chainId: _selectedStore!.brandId,
        priceSourceType: 'branch',
        storeName: _selectedStore!.displayName,
        barcode: _selectedProduct!.barcode,
        reportedAt: DateTime.now(),
        addedByDisplayName: userModel.name,
        addedByTrustScoreSnapshot: userModel.reliabilityScore,
        addedByLevelSnapshot: userModel.points >= 5000
            ? 'Elmas'
            : (userModel.points >= 2000 ? 'Gümüş' : (userModel.points >= 500 ? 'Bronz' : 'Standart')),
        addedByVerifiedBadge: userModel.isAdmin,
      );

      await firestoreService.addPriceReport(priceModel);
      await ref.read(authServiceProvider).incrementPriceEntries(userModel.uid);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fiyat eklendi! Puanın hesabına işlendi.')),
      );

      _priceController.clear();
      setState(() {
        _selectedProduct = null;
        _selectedStore = null;
        _selectedCategory = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
