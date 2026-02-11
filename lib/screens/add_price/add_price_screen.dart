import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/price_provider.dart';
import '../../models/product_model.dart';
import '../../models/price_model.dart';
import '../../models/store_model.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/barcode_scanner_sheet.dart';

class AddPriceScreen extends ConsumerStatefulWidget {
  const AddPriceScreen({super.key});

  @override
  ConsumerState<AddPriceScreen> createState() => _AddPriceScreenState();
}

enum StorePickerTab { nearby, online }

class _AddPriceScreenState extends ConsumerState<AddPriceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productController = TextEditingController();
  final _priceController = TextEditingController();

  StoreModel? _selectedStore;
  String? _selectedCategory;
  ProductModel? _selectedProduct;
  List<ProductModel> _productSuggestions = const [];
  bool _showProductSuggestions = false;
  String _productQuery = '';
  bool _isSubmitting = false;
  Position? _userPosition;
  bool _isResolvingUserPosition = false;
  bool _locationPermissionDenied = false;

  @override
  void initState() {
    super.initState();
    _loadUserPosition();
  }

  Future<void> _loadUserPosition({bool requestPermission = true}) async {
    if (_isResolvingUserPosition) return;
    setState(() {
      _isResolvingUserPosition = true;
      _locationPermissionDenied = false;
    });

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (!mounted) return;
        setState(() => _locationPermissionDenied = true);
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && requestPermission) {
        permission = await Geolocator.requestPermission();
      }

      final denied = permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever;
      if (denied) {
        if (!mounted) return;
        setState(() => _locationPermissionDenied = true);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      if (!mounted) return;
      setState(() {
        _userPosition = position;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _locationPermissionDenied = true);
    } finally {
      if (mounted) {
        setState(() => _isResolvingUserPosition = false);
      }
    }
  }

  @override
  void dispose() {
    _productController.dispose();
    _priceController.dispose();
    super.dispose();
  }


  void _selectProduct(ProductModel product) {
    setState(() {
      _selectedProduct = product;
      _productController.text = product.name;
      _selectedCategory = product.categories.isNotEmpty ? product.categories.first : null;
      _showProductSuggestions = false;
      _productSuggestions = const [];
    });
  }

  void _updateProductSuggestions(List<ProductModel> allProducts, String rawQuery) {
    final query = rawQuery.trim().toLowerCase();
    if (query.length < 2) {
      setState(() {
        _showProductSuggestions = false;
        _productSuggestions = const [];
      });
      return;
    }

    final suggestions = allProducts.where((product) {
      return product.name.toLowerCase().contains(query) ||
          product.brand.toLowerCase().contains(query) ||
          (product.barcode?.toLowerCase().contains(query) ?? false);
    }).take(8).toList();

    setState(() {
      _showProductSuggestions = suggestions.isNotEmpty;
      _productSuggestions = suggestions;
    });
  }

  Future<void> _showProductSuggestionDialog() async {
    final user = ref.read(userModelStreamProvider).value;
    if (user == null) return;

    final nameController = TextEditingController(text: _productController.text.trim());
    final barcodeController = TextEditingController();
    final categoryController = TextEditingController(text: _selectedCategory ?? '');
    XFile? selectedImage;
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Ürün öner'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Ürün adı *'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: barcodeController,
                      decoration: const InputDecoration(labelText: 'Barkod (opsiyonel)'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: categoryController,
                      decoration: const InputDecoration(labelText: 'Kategori (opsiyonel)'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picker = ImagePicker();
                        final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                        if (image == null) return;
                        setDialogState(() => selectedImage = image);
                      },
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: Text(selectedImage == null ? 'Foto ekle (opsiyonel)' : 'Foto seçildi'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('İptal')),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final name = nameController.text.trim();
                          if (name.isEmpty) return;
                          setDialogState(() => isSubmitting = true);
                          try {
                            String? photoUrl;
                            if (selectedImage != null) {
                              photoUrl = await ref.read(storageServiceProvider).uploadImage(
                                    file: File(selectedImage!.path),
                                    folder: 'product_suggestions',
                                  );
                            }

                            await ref.read(firestoreServiceProvider).addProductSuggestion(
                                  name: name,
                                  barcode: barcodeController.text.trim().isEmpty ? null : barcodeController.text.trim(),
                                  category: categoryController.text.trim().isEmpty ? null : categoryController.text.trim(),
                                  photoUrl: photoUrl,
                                  userId: user.uid,
                                );

                            if (dialogContext.mounted) Navigator.pop(dialogContext);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Ürün önerisi gönderildi.')),
                              );
                            }
                          } finally {
                            if (dialogContext.mounted) {
                              setDialogState(() => isSubmitting = false);
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Gönder'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _matchScannedBarcode(String code, List<ProductModel> allProducts) {
    final normalized = code.trim().toLowerCase();
    final match = allProducts.where((p) {
      return (p.barcode?.trim().toLowerCase() ?? '') == normalized;
    }).firstOrNull;

    if (match != null) {
      _selectProduct(match);
      return;
    }

    setState(() {
      _selectedProduct = null;
      _productController.text = code;
      _showProductSuggestions = false;
      _productSuggestions = const [];
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Barkodla eslesen urun bulunamadi. Listeden secim yapabilirsiniz.'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
      ),
    );
  }

  void _showProductPicker() {
    final productsAsync = ref.read(allProductsProvider);

    productsAsync.when(
      loading: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Urunler yukleniyor...'),
            behavior: SnackBarBehavior.floating),
      ),
      error: (e, _) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Hata: $e'), behavior: SnackBarBehavior.floating),
      ),
      data: (products) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md),
                              itemCount: products.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final product = products[index];
                                return ListTile(
                                  leading: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight
                                          .withOpacity(0.1),
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.sm),
                                    ),
                                    child: const Icon(
                                        Icons.shopping_bag_outlined,
                                        color: AppColors.primary,
                                        size: 22),
                                  ),
                                  title: Text(product.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
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
                                    _selectProduct(product);
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

  /// Show store picker bottom sheet with nearby/online tabs
  Future<void> _showStorePicker() async {
    if (_userPosition == null && !_isResolvingUserPosition) {
      await _loadUserPosition(requestPermission: false);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) {
        StorePickerTab activeTab = StorePickerTab.nearby;

        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final nearbyStoresAsync = ref.watch(nearbyStoresProvider);
            final onlineStoresAsync = ref.watch(onlineStoresProvider);

            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              maxChildSize: 0.9,
              minChildSize: 0.3,
              expand: false,
              builder: (ctx, scrollController) {
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
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, color: AppColors.primary, size: 20),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Magaza (Sube) Secin',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: _buildStorePickerTabs(
                        activeTab: activeTab,
                        onChanged: (tab) => setModalState(() => activeTab = tab),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (activeTab == StorePickerTab.nearby)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        child: _buildLocationStatusBanner(),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        child: _buildOnlineInfoBanner(),
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    Expanded(
                      child: activeTab == StorePickerTab.nearby
                          ? _buildNearbyStoreList(nearbyStoresAsync, scrollController, ctx)
                          : _buildOnlineStoreList(onlineStoresAsync, scrollController, ctx),
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

  Widget _buildStorePickerTabs({
    required StorePickerTab activeTab,
    required ValueChanged<StorePickerTab> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: ChoiceChip(
            label: const Text('📍 Yakınımda'),
            selected: activeTab == StorePickerTab.nearby,
            onSelected: (_) => onChanged(StorePickerTab.nearby),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: ChoiceChip(
            label: const Text('🌐 Online'),
            selected: activeTab == StorePickerTab.online,
            onSelected: (_) => onChanged(StorePickerTab.online),
          ),
        ),
      ],
    );
  }

  Widget _buildNearbyStoreList(
    AsyncValue<List<StoreModel>> storesAsync,
    ScrollController scrollController,
    BuildContext ctx,
  ) {
    return storesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Hata: $e')),
      data: (stores) {
        final nearbyStores = List<StoreModel>.from(stores);
        if (_userPosition != null) {
          nearbyStores.sort((a, b) => _distanceInMeters(a).compareTo(_distanceInMeters(b)));
        }

        final filteredStores = nearbyStores.where((store) {
          if (_userPosition == null || _isStoreLocationMissing(store)) return true;
          return _distanceInMeters(store) <= 2000;
        }).toList();

        if (_userPosition != null && filteredStores.isNotEmpty) {
          final nearestStore = filteredStores.first;
          if (_distanceInMeters(nearestStore) <= 30 && _selectedStore == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() => _selectedStore = nearestStore);
            });
          }
        }

        if (filteredStores.isEmpty) {
          return const Center(child: Text('Yakınında mağaza yok. Haritadan pin seç.'));
        }

        return ListView.separated(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          itemCount: filteredStores.length + 1,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            if (index == filteredStores.length) {
              return _buildAddNewStoreItem(ctx);
            }

            final store = filteredStores[index];
            final distanceText = _distanceText(store);
            return ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(Icons.store, color: AppColors.secondary, size: 22),
              ),
              title: Text(
                store.displayName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${store.neighborhood.isEmpty ? '-' : store.neighborhood} mah.',
                    style: const TextStyle(fontSize: 12),
                  ),
                  if (_isStoreLocationMissing(store))
                    const Text(
                      'Admin uyarisi: Bu sube icin konum bilgisi eksik.',
                      style: TextStyle(fontSize: 11, color: AppColors.error),
                    ),
                ],
              ),
              trailing: Text(
                distanceText,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              onTap: () {
                setState(() {
                  _selectedStore = store;
                });
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildOnlineStoreList(
    AsyncValue<List<StoreModel>> storesAsync,
    ScrollController scrollController,
    BuildContext ctx,
  ) {
    return storesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) {
        debugPrint('Online stores load error: $e');
        debugPrintStack(stackTrace: st);
        if (e is FirebaseException && e.code == 'failed-precondition') {
          return const Center(
            child: Text('Online mağazalar yüklenemedi, tekrar deneyin'),
          );
        }
        return const Center(
          child: Text('Online mağazalar yüklenemedi, tekrar deneyin'),
        );
      },
      data: (stores) {
        final onlineStores = List<StoreModel>.from(stores)
          ..sort((a, b) => a.displayName.compareTo(b.displayName));

        if (onlineStores.isEmpty) {
          return const Center(child: Text('Henüz online mağaza eklenmemiş.'));
        }

        return ListView.separated(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          itemCount: onlineStores.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final store = onlineStores[index];
            return ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(Icons.language, color: AppColors.info, size: 22),
              ),
              title: Text(
                '🌐 ${store.displayName}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              trailing: const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
              onTap: () {
                setState(() {
                  _selectedStore = store.copyWith(type: StoreType.online);
                });
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildOnlineInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: const Text(
        '🌐 Online mağazalar konumdan bağımsızdır',
        style: TextStyle(fontSize: 12, color: AppColors.info),
      ),
    );
  }

  Widget _buildLocationStatusBanner() {
    if (_isResolvingUserPosition) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.info.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: const Row(
          children: [
            SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 8),
            Text('Mesafe hesaplanıyor…', style: TextStyle(fontSize: 12, color: AppColors.info)),
          ],
        ),
      );
    }

    if (_locationPermissionDenied) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.15),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_off, size: 14, color: AppColors.warning),
            const SizedBox(width: 8),
            Expanded(
              child: TextButton(
                onPressed: () => _loadUserPosition(requestPermission: true),
                style: TextButton.styleFrom(padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
                child: const Text(
                  'Yakın mağazaları görmek için konum izni gerekli • İzin ver',
                  style: TextStyle(fontSize: 12, color: AppColors.warning),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_userPosition != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.info.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: const Row(
          children: [
            Icon(Icons.near_me, size: 14, color: AppColors.info),
            SizedBox(width: 8),
            Text('Mesafeye göre sıralanıyor', style: TextStyle(fontSize: 12, color: AppColors.info)),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  bool _isStoreLocationMissing(StoreModel store) => store.lat == 0 || store.lng == 0;

  double _distanceInMeters(StoreModel store) {
    if (_userPosition == null || _isStoreLocationMissing(store)) {
      return double.infinity;
    }

    const earthRadius = 6371000.0;
    final dLat = _toRadians(store.lat - _userPosition!.latitude);
    final dLng = _toRadians(store.lng - _userPosition!.longitude);
    final startLat = _toRadians(_userPosition!.latitude);
    final endLat = _toRadians(store.lat);

    final a =
        (sin(dLat / 2) * sin(dLat / 2)) +
        cos(startLat) * cos(endLat) * (sin(dLng / 2) * sin(dLng / 2));
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) => degree * pi / 180.0;

  String _distanceText(StoreModel store) {
    if (_isStoreLocationMissing(store)) {
      return 'Konum bilgisi eksik';
    }
    if (_userPosition == null) {
      return _isResolvingUserPosition ? 'Mesafe hesaplanıyor…' : 'Konum izni gerekli';
    }

    final dist = _distanceInMeters(store);
    return dist < 1000 ? '${dist.round()} m' : '${(dist / 1000).toStringAsFixed(1)} km';
  }

  Widget _buildAddNewStoreItem(BuildContext ctx) {
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.accent.withOpacity(0.3), width: 1.5),
        ),
        child: const Icon(Icons.add_business, color: AppColors.accent, size: 22),
      ),
      title: const Text(
        'Bu magaza listede yok +',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.accent,
        ),
      ),
      subtitle: const Text(
        'Yeni magaza onerisi gonder',
        style: TextStyle(fontSize: 12),
      ),
      onTap: () {
        Navigator.pop(ctx);
        _showAddNewStoreDialog();
      },
    );
  }

  void _showAddNewStoreDialog() {
    final nameController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
          title: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(Icons.add_business, color: AppColors.accent, size: 20),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Expanded(
              child: Text('Yeni Magaza Oner', style: TextStyle(fontSize: 16)),
            ),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Magaza Adi',
                  hintText: 'Orn: Cagri Market',
                  prefixIcon: Icon(Icons.store_outlined),
                ),
                autofocus: true,
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: AppColors.info),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Konum otomatik olarak alinacaktir. Magaza admin onayi sonrasi aktif olur.',
                        style: TextStyle(fontSize: 11, color: AppColors.info),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
              child: const Text('Iptal'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (nameController.text.trim().isEmpty) return;
                      setDialogState(() => isSubmitting = true);

                      try {
                        final firestoreService = ref.read(firestoreServiceProvider);
                        final locationService = ref.read(locationServiceProvider);
                        final position = await locationService.getCurrentPosition();

                        final suggestionId = await firestoreService.addStoreSuggestion(
                          displayName: nameController.text.trim(),
                          lat: position?.latitude ?? 0,
                          lng: position?.longitude ?? 0,
                        );

                        if (!mounted) return;
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Magaza onerisi gonderildi! Admin onayi bekleniyor.'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Magaza onerisi gonderilemedi: $e'),
                            backgroundColor: AppColors.error,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      } finally {
                        if (dialogContext.mounted) {
                          setDialogState(() => isSubmitting = false);
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Gonder'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Lutfen bir urun secin. Listeden sec veya oneriden dokun.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm)),
        ),
      );
      return;
    }
    if (_selectedStore == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Lutfen bir magaza (sube) secin'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm)),
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
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm)),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      final priceText = _priceController.text.replaceAll(',', '.');
      final price = double.tryParse(priceText) ?? 0.0;

      final priceModel = PriceModel(
        id: '',
        productId: _selectedProduct!.id,
        userId: userModel.uid,
        userName: userModel.name,
        price: price,
        branchStoreId: _selectedStore!.id,
        chainId: _selectedStore!.brandId,
        storeName: _selectedStore!.displayName,
        barcode: _selectedProduct!.barcode,
        reportedAt: DateTime.now(),
      );

      await firestoreService.addPriceReport(priceModel);
      final authService = ref.read(authServiceProvider);
      await authService.incrementPriceEntries(userModel.uid);
      await authService.addPoints(
          userModel.uid, AppConstants.pointsForPriceEntry);

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
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _formatPrice(double price) => formatTRY(price);

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final productsAsync = ref.watch(allProductsProvider);

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
                          Text(
                            'Her fiyat girisi +${AppConstants.pointsForPriceEntry} puan, '
                            'fotografli +${AppConstants.pointsForPriceEntryWithPhoto} puan',
                            style: TextStyle(
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

              // Step 1: Product field
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
                          productsAsync.whenData((products) {
                            _matchScannedBarcode(code, products);
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.list),
                        onPressed: _showProductPicker,
                      ),
                    ],
                  ),
                ),
                onChanged: (value) {
                  setState(() => _productQuery = value.trim());
                  productsAsync.whenData((products) {
                    _updateProductSuggestions(products, value);
                  });
                  if (_selectedProduct != null && value.trim() != _selectedProduct!.name) {
                    setState(() => _selectedProduct = null);
                  }
                },
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Urun adi gerekli';
                  }
                  return null;
                },
              ),
              if (_showProductSuggestions)
                Container(
                  margin: const EdgeInsets.only(top: AppSpacing.xs),
                  constraints: const BoxConstraints(maxHeight: 220),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.outline),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _productSuggestions.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final product = _productSuggestions[index];
                      return ListTile(
                        dense: true,
                        title: Text(product.name),
                        subtitle: Text(
                          [product.brand, if (product.barcode != null) product.barcode!]
                              .where((item) => item.trim().isNotEmpty)
                              .join(' • '),
                        ),
                        onTap: () => _selectProduct(product),
                      );
                    },
                  ),
                ),
              if (_productQuery.length >= 2 && _productSuggestions.isEmpty)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  title: const Text('Bu ürün yok +', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Ürün öner'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: _showProductSuggestionDialog,
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
                        _showProductSuggestions = false;
                        _productSuggestions = const [];
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
                  decoration: InputDecoration(
                    labelText: 'Kategori',
                    helperText: _selectedProduct != null ? 'Kategori ürünle birlikte kilitlendi' : null,
                    prefixIcon: const Icon(Icons.category_outlined),
                  ),
                  items: categories
                      .map((cat) => DropdownMenuItem(
                            value: cat['name'] as String,
                            child: Text(cat['name'] as String),
                          ))
                      .toList(),
                  onChanged: _selectedProduct != null
                      ? null
                      : (value) {
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

              // Step 2: Price field
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
              const SizedBox(height: AppSpacing.lg),

              // Step 3: Store (Branch) selection
              Text(
                'Magaza (Sube) Secin',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Store selection button
              InkWell(
                onTap: _showStorePicker,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _selectedStore != null
                          ? AppColors.primary.withOpacity(0.5)
                          : AppColors.outline,
                      width: _selectedStore != null ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    color: _selectedStore != null
                        ? AppColors.primary.withOpacity(0.05)
                        : null,
                  ),
                  child: _selectedStore != null
                      ? Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                              child: Icon(
                                  _selectedStore!.isOnline ? Icons.language : Icons.store,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedStore!.isOnline
                                        ? '🌐 ${_selectedStore!.displayName}'
                                        : _selectedStore!.displayName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (_selectedStore!.isOnline)
                                    const Text(
                                      'Online mağaza • Konum gerektirmez',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    )
                                  else if (_selectedStore!.neighborhood.isNotEmpty)
                                    Text(
                                      '${_selectedStore!.neighborhood}, ${_selectedStore!.district}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                setState(() => _selectedStore = null);
                              },
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                color: AppColors.textSecondary),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                'Yakındaki veya online bir mağaza seçin',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const Icon(Icons.chevron_right,
                                color: AppColors.textSecondary),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Legal Disclaimer
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                      color: AppColors.info.withOpacity(0.3), width: 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.info, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        AppConstants.priceDisclaimer,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
