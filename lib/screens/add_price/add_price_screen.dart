import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/price_provider.dart';
import '../../providers/product_provider.dart';
import '../../models/product_model.dart';
import '../../services/location_service.dart';
import '../../widgets/photo_gallery.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';

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

  final List<File> _selectedImages = [];
  ProductModel? _selectedProduct;
  LocationData? _locationData;
  bool _isLoading = false;
  bool _isLoadingLocation = true;
  String? _selectedStore;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  @override
  void dispose() {
    _productController.dispose();
    _priceController.dispose();
    _storeController.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    final locationService = ref.read(locationServiceProvider);
    final locationData = await locationService.getLocationData();
    if (mounted) {
      setState(() {
        _locationData = locationData;
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(
      maxWidth: AppConstants.maxImageWidth.toDouble(),
      maxHeight: AppConstants.maxImageHeight.toDouble(),
      imageQuality: AppConstants.imageQuality,
    );

    if (images.isNotEmpty) {
      setState(() {
        for (final image in images) {
          if (_selectedImages.length < AppConstants.maxImagesPerPrice) {
            _selectedImages.add(File(image.path));
          }
        }
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _searchProducts(String query) async {
    if (query.isEmpty) return;

    final products =
        await ref.read(firestoreServiceProvider).searchProducts(query);

    if (products.isNotEmpty && mounted) {
      showModalBottomSheet(
        context: context,
        builder: (context) => Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ürün Seç',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              ...products.take(5).map(
                    (product) => ListTile(
                      title: Text(product.name),
                      subtitle: Text(product.brand),
                      onTap: () {
                        setState(() {
                          _selectedProduct = product;
                          _productController.text = product.name;
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Yeni ürün ekle'),
                onTap: () {
                  Navigator.pop(context);
                  // Keep the product name as entered
                },
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String productId;

      // If no product selected, create new product
      if (_selectedProduct == null) {
        final newProduct = ProductModel(
          id: '',
          name: _productController.text.trim(),
          brand: '',
          category: 'Diğer',
          createdAt: DateTime.now(),
        );
        productId = await ref.read(productNotifierProvider.notifier).addProduct(newProduct);
      } else {
        productId = _selectedProduct!.id;
      }

      // Add price
      await ref.read(priceNotifierProvider.notifier).addPrice(
            productId: productId,
            price: double.parse(_priceController.text.replaceAll(',', '.')),
            storeName: _selectedStore ?? _storeController.text.trim(),
            images: _selectedImages.isNotEmpty ? _selectedImages : null,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    _selectedImages.isNotEmpty
                        ? 'Fiyat eklendi! +20 puan kazandınız (2x fotoğraf bonusu)'
                        : 'Fiyat eklendi! +10 puan kazandınız',
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );

        // Clear form
        _productController.clear();
        _priceController.clear();
        _storeController.clear();
        setState(() {
          _selectedProduct = null;
          _selectedImages.clear();
          _selectedStore = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.accent),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.camera_alt, color: AppColors.accent),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Fotoğraf ekleyenler 2x puan kazanır!',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
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
                  labelText: 'Ürün Adı / Barkod',
                  hintText: 'Ürün adı veya barkod numarası',
                  prefixIcon: const Icon(Icons.shopping_bag_outlined),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () => _searchProducts(_productController.text),
                  ),
                ),
                textInputAction: TextInputAction.next,
                onFieldSubmitted: _searchProducts,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ürün adı gerekli';
                  }
                  return null;
                },
              ),
              if (_selectedProduct != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Chip(
                    label: Text(_selectedProduct!.name),
                    onDeleted: () {
                      setState(() {
                        _selectedProduct = null;
                      });
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
                  prefixIcon: Icon(Icons.attach_money),
                  suffixText: '₺',
                ),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Fiyat gerekli';
                  }
                  final price = double.tryParse(value.replaceAll(',', '.'));
                  if (price == null || price <= 0) {
                    return 'Geçerli bir fiyat girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Store selection
              Text(
                'Mağaza',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: AppConstants.popularStores.take(8).map((store) {
                  return ChoiceChip(
                    label: Text(store),
                    selected: _selectedStore == store,
                    onSelected: (selected) {
                      setState(() {
                        _selectedStore = selected ? store : null;
                        if (selected) {
                          _storeController.text = store;
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.md),

              // Custom store field
              TextFormField(
                controller: _storeController,
                decoration: const InputDecoration(
                  labelText: 'Mağaza Adı',
                  hintText: 'Mağaza adını yazın',
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
                    return 'Mağaza adı gerekli';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Location
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: _isLoadingLocation
                          ? Theme.of(context).colorScheme.outline
                          : AppColors.success,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _isLoadingLocation
                          ? const Text('Konum alınıyor...')
                          : Text(
                              _locationData?.address ?? 'Konum bulunamadı',
                              style: TextStyle(
                                color: _locationData != null
                                    ? null
                                    : Theme.of(context).colorScheme.outline,
                              ),
                            ),
                    ),
                    if (!_isLoadingLocation)
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _getLocation,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Photo section
              Text(
                'Fotoğraflar (Opsiyonel)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              ImagePickerGrid(
                images: _selectedImages,
                onAdd: _pickImages,
                onRemove: _removeImage,
                maxImages: AppConstants.maxImagesPerPrice,
              ),
              const SizedBox(height: AppSpacing.xl),

              // Submit button
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Fiyat Ekle'),
              ),
              const SizedBox(height: AppSpacing.md),

              // Points info
              Center(
                child: Text(
                  _selectedImages.isNotEmpty
                      ? 'Bu fiyat girişi için +20 puan kazanacaksınız'
                      : 'Bu fiyat girişi için +10 puan kazanacaksınız',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.outline,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
