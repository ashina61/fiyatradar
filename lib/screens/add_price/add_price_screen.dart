import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/product_model.dart';
import '../../models/price_model.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../../widgets/barcode_scanner_sheet.dart';

class AddPriceScreen extends ConsumerStatefulWidget {
  const AddPriceScreen({super.key});

  @override
  ConsumerState<AddPriceScreen> createState() => _AddPriceScreenState();
}

class _AddPriceScreenState extends ConsumerState<AddPriceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productController = TextEditingController();
  final _priceController = TextEditingController();
  final _storeController = TextEditingController();

  String? _selectedStore;
  String? _selectedCategory;
  ProductModel? _selectedProduct;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _productController.dispose();
    _priceController.dispose();
    _storeController.dispose();
    super.dispose();
  }

  void _showProductPicker() {
    final productsAsync = ref.read(allProductsProvider);

    productsAsync.when(
      loading: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Urunler yukleniyor...'), behavior: SnackBarBehavior.floating),
      ),
      error: (e, _) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), behavior: SnackBarBehavior.floating),
      ),
      data: (products) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
          ),
          builder: (context) {
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              maxChildSize: 0.9,
              minChildSize: 0.3,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: AppSpacing.sm),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Text(
                        'Urun Secin',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    Expanded(
                      child: products.isEmpty
                          ? const Center(child: Text('Henuz urun yok'))
                          : ListView.separated(
                              controller: scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                              itemCount: products.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final product = products[index];
                                return ListTile(
                                  leading: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(AppRadius.sm),
                                    ),
                                    child: const Icon(Icons.shopping_bag_outlined,
                                        color: AppColors.primary, size: 22),
                                  ),
                                  title: Text(product.name,
                                      style: const TextStyle(fontWeight: FontWeight.w600)),
                                  subtitle: Text(product.category),
                                  trailing: product.lastPrice != null
                                      ? Text(
                                          _formatPrice(product.lastPrice!),
                                          style: const TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                  onTap: () {
                                    setState(() {
                                      _selectedProduct = product;
                                      _productController.text = product.name;
                                      _selectedCategory = product.category;
                                    });
                                    Navigator.pop(context);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Lutfen bir urun secin'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
        ),
      );
      return;
    }

    final userModel = ref.read(userModelStreamProvider).value;
    if (userModel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Fiyat eklemek icin giris yapmalisiniz'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      final priceText = _priceController.text.replaceAll(',', '.');
      final price = double.tryParse(priceText) ?? 0.0;
      final storeName = _selectedStore ?? _storeController.text;

      final priceModel = PriceModel(
        id: '',
        productId: _selectedProduct!.id,
        userId: userModel.uid,
        userName: userModel.name,
        price: price,
        storeName: storeName,
        createdAt: DateTime.now(),
      );

      await firestoreService.addPrice(priceModel);
      final authService = ref.read(authServiceProvider);
      await authService.incrementPriceEntries(userModel.uid);
      await authService.addPoints(userModel.uid, AppConstants.pointsForPriceEntry);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Fiyat eklendi! +${AppConstants.pointsForPriceEntry} puan kazandiniz',
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            duration: const Duration(seconds: 3),
          ),
        );

        _productController.clear();
        _priceController.clear();
        _storeController.clear();
        setState(() {
          _selectedProduct = null;
          _selectedStore = null;
          _selectedCategory = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _formatPrice(double price) {
    if (price >= 1000) {
      final parts = price.toStringAsFixed(2).split('.');
      final intPart = parts[0];
      final decPart = parts[1];
      final buffer = StringBuffer();
      int count = 0;
      for (int i = intPart.length - 1; i >= 0; i--) {
        buffer.write(intPart[i]);
        count++;
        if (count == 3 && i > 0) {
          buffer.write('.');
          count = 0;
        }
      }
      return '\u20BA${buffer.toString().split('').reversed.join()},$decPart';
    }
    return '\u20BA${price.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  Widget build(BuildContext context) {
    final storesAsync = ref.watch(storesProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fiyat Ekle'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Photo bonus info
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accent.withOpacity(0.1),
                      AppColors.accent.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                      color: AppColors.accent.withOpacity(0.3), width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Icon(Icons.stars,
                          color: AppColors.accent, size: 22),
                    ),
                    const SizedBox(width: AppSpacing.sm + 4),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fiyat ekleyerek puan kazan!',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          const Text(

  'Her fiyat girisi +${AppConstants.pointsForPriceEntry} puan, '

  'fotografli +${AppConstants.pointsForPriceEntryWithPhoto} puan',

  style: TextStyle(
                          Text(
                            'Her fiyat girisi +${AppConstants.pointsForPriceEntry} puan, '
                            'fotografli +${AppConstants.pointsForPriceEntryWithPhoto} puan',
                            style: const TextStyle(
                              
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Product field
              TextFormField(
                controller: _productController,
                decoration: InputDecoration(
                  labelText: 'Urun Adi',
                  hintText: 'Urun adi veya barkod numarasi',
                  prefixIcon: const Icon(Icons.shopping_bag_outlined),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.qr_code_scanner),
                        onPressed: () async {
                          final code = await BarcodeScannerSheet.scan(
                            context,
                            title: 'Barkod Tara',
                          );
                          if (!mounted || code == null) return;
                          _productController.text = code;
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.list),
                        onPressed: _showProductPicker,
                      ),
                    ],
                  ),
                ),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Urun adi gerekli';
                  }
                  return null;
                },
              ),
              if (_selectedProduct != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Chip(
                    avatar: const Icon(Icons.check_circle,
                        color: AppColors.success, size: 18),
                    label: Text(_selectedProduct!.name),
                    onDeleted: () {
                      setState(() {
                        _selectedProduct = null;
                        _productController.clear();
                      });
                    },
                  ),
                ),
              const SizedBox(height: AppSpacing.md),

              // Category dropdown
              categoriesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Hata: $e'),
                data: (categories) => DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: categories
                      .map((cat) => DropdownMenuItem(
                            value: cat['name'] as String,
                            child: Text(cat['name'] as String),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Kategori secin';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Price field
              TextFormField(
                controller: _priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Fiyat',
                  hintText: '0.00',
                  prefixText: '\u20BA ',
                  prefixIcon: Icon(Icons.price_change_outlined),
                ),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Fiyat gerekli';
                  }
                  final price = double.tryParse(value.replaceAll(',', '.'));
                  if (price == null || price <= 0) {
                    return 'Gecerli bir fiyat girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Store selection
              Text(
                'Magaza Secin',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              storesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Hata: $e'),
                data: (stores) => Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: stores.map((store) {
                    final storeName = store['name'] as String;
                    return ChoiceChip(
                      label: Text(storeName),
                      selected: _selectedStore == storeName,
                      selectedColor: AppColors.primary.withOpacity(0.15),
                      labelStyle: TextStyle(
                        color: _selectedStore == storeName
                            ? AppColors.primary
                            : AppColors.textPrimary,
                        fontWeight: _selectedStore == storeName
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                      onSelected: (selected) {
                        setState(() {
                          _selectedStore = selected ? storeName : null;
                          if (selected) {
                            _storeController.text = storeName;
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Custom store field
              TextFormField(
                controller: _storeController,
                decoration: const InputDecoration(
                  labelText: 'veya Magaza Adi Yazin',
                  hintText: 'Magaza adini yazin',
                  prefixIcon: Icon(Icons.store_outlined),
                ),
                textInputAction: TextInputAction.done,
                onChanged: (value) {
                  if (_selectedStore != null && value != _selectedStore) {
                    setState(() {
                      _selectedStore = null;
                    });
                  }
                },
                validator: (value) {
                  if ((value == null || value.isEmpty) &&
                      _selectedStore == null) {
                    return 'Magaza adi gerekli';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Disclaimer
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: AppColors.info.withOpacity(0.25),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.info, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Onemli Bilgilendirme',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Lutfen dogru ve guncel fiyat girin. '
                            'Yanlis bildirimler raporlanabilir ve puaniniz dusurulebilir.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Submit button
              Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppColors.gradient,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Fiyat Ekle',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Points info
              Center(
                child: Text(
                  'Bu fiyat girisi icin +${AppConstants.pointsForPriceEntry} puan kazanacaksiniz',
                  style: TextStyle(
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
