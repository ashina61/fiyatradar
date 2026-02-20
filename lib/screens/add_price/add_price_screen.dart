import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/product_provider.dart';
import '../../services/firestore_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/price_provider.dart';
import '../../models/product_model.dart';
import '../../models/price_model.dart';
import '../../models/store_model.dart';
import '../../utils/constants.dart';
import '../../widgets/barcode_scanner_sheet.dart';
import '../../widgets/premium_scaffold_shell.dart';
import 'widgets/add_price_header_banner.dart';
import 'widgets/add_price_submit_bar.dart';
import 'widgets/price_input_section.dart';
import 'widgets/product_selection_section.dart';
import 'widgets/store_picker_sheet.dart';

const Color radarBrown900 = Color(0xFF5D4037);
const Color radarBrown700 = Color(0xFF795548);
const Color radarBrown500 = Color(0xFF8D6E63);
const Color radarAmber600 = Color(0xFFC8956C);
const Color radarCream100 = Color(0xFFFFF8F0);
const Color radarCream300 = Color(0xFFEDE0D4);

const double radarBodySize = 15;

class AddPriceScreen extends ConsumerStatefulWidget {
  const AddPriceScreen({super.key});

  @override
  ConsumerState<AddPriceScreen> createState() => _AddPriceScreenState();
}

class _AddPriceScreenState extends ConsumerState<AddPriceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productController = TextEditingController();
  final _priceController = TextEditingController();

  StoreModel? _selectedStore;
  String? _selectedCategory;
  ProductModel? _selectedProduct;
  List<ProductModel> _productSuggestions = const [];
  bool _showProductSuggestions = false;
  bool _isSubmitting = false;
  Position? _userPosition;
  bool _isResolvingUserPosition = false;
  bool _locationPermissionDenied = false;
  bool _locationPermissionDeniedForever = false;
  bool _locationServiceDisabled = false;
  bool _locationUnavailable = false;
  Map<String, double> _storeDistanceMeters = const {};

  @override
  void initState() {
    super.initState();
    _loadUserPosition();
  }

  @override
  void dispose() {
    _productController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadUserPosition({bool requestPermission = true}) async {
    if (_isResolvingUserPosition) return;
    setState(() {
      _isResolvingUserPosition = true;
      _locationPermissionDenied = false;
      _locationPermissionDeniedForever = false;
      _locationServiceDisabled = false;
      _locationUnavailable = false;
    });

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (!mounted) return;
        setState(() {
          _locationServiceDisabled = true;
          _userPosition = null;
          _storeDistanceMeters = const {};
        });
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && requestPermission) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _locationPermissionDenied = permission == LocationPermission.denied;
          _locationPermissionDeniedForever = permission == LocationPermission.deniedForever;
          _userPosition = null;
          _storeDistanceMeters = const {};
        });
        return;
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 8),
        );
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
      }

      if (!mounted) return;
      setState(() {
        _userPosition = position;
        _locationUnavailable = position == null;
        _storeDistanceMeters = const {};
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _locationUnavailable = true;
        _userPosition = null;
        _storeDistanceMeters = const {};
      });
    } finally {
      if (mounted) {
        setState(() => _isResolvingUserPosition = false);
      }
    }
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

  void _matchScannedBarcode(String code, List<ProductModel> allProducts) {
    final normalized = code.trim().toLowerCase();
    final match = allProducts.where((p) => (p.barcode?.trim().toLowerCase() ?? '') == normalized).firstOrNull;
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
        content: const Text('Barkodla eşleşen ürün bulunamadı. Listeden seçim yapabilirsiniz.'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
      ),
    );
  }

  Future<void> _showStorePicker() async {
    if (_userPosition == null && !_isResolvingUserPosition) {
      await _loadUserPosition(requestPermission: false);
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => StorePickerSheet(
        userPosition: _userPosition,
        storeDistanceMeters: _storeDistanceMeters,
        isResolvingUserPosition: _isResolvingUserPosition,
        locationPermissionDenied: _locationPermissionDenied,
        locationPermissionDeniedForever: _locationPermissionDeniedForever,
        locationServiceDisabled: _locationServiceDisabled,
        locationUnavailable: _locationUnavailable,
        onRetryLocation: () => _loadUserPosition(requestPermission: true),
        onSelectStore: (store) => setState(() => _selectedStore = store),
        onDistanceMapChanged: (map) {
          if (!mounted) return;
          setState(() => _storeDistanceMeters = map);
        },
        onAddNewStore: _showAddNewStoreDialog,
      ),
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
          title: const Text('Yeni Mağaza Öner'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Mağaza Adı',
              hintText: 'Orn: Cagri Market',
            ),
            autofocus: true,
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
                        await firestoreService.addStoreSuggestion(
                          displayName: nameController.text.trim(),
                          lat: position?.latitude ?? 0,
                          lng: position?.longitude ?? 0,
                        );

                        if (!mounted) return;
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Mağaza önerisi gönderildi! Admin onayı bekleniyor.'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Mağaza önerisi gönderilemedi: $e'),
                            backgroundColor: Colors.red,
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
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
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
          content: const Text('Lütfen bir ürün seçin. Listeden seç veya öneriden dokunun.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
        ),
      );
      return;
    }
    if (_selectedStore == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Lütfen bir mağaza (şube) seçin'),
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
      final price = double.tryParse(_priceController.text.replaceAll(',', '.')) ?? 0.0;

      final latestPrice = await firestoreService.getLatestPriceForStore(
        productId: _selectedProduct!.id,
        branchStoreId: _selectedStore!.id,
      );
      if (latestPrice != null && (latestPrice.price - price).abs() <= 0.01) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Bu ürün için aynı mağazada aynı fiyat zaten mevcut.'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
            ),
          );
        }
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
        addedByLevelSnapshot: userModel.points >= 5000 ? 'Elmas' : (userModel.points >= 2000 ? 'Gümüş' : (userModel.points >= 500 ? 'Bronz' : 'Standart')),
        addedByVerifiedBadge: userModel.isAdmin,
      );

      await firestoreService.addPriceReport(priceModel);
      await ref.read(authServiceProvider).incrementPriceEntries(userModel.uid);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Fiyat eklendi! Puanın hesabına işlendi.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
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
    } on DuplicatePriceException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  InputDecoration _radarFieldDecoration({
    required String hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: radarBrown500, fontSize: radarBodySize, fontFamily: 'Inter'),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: radarCream300,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: radarAmber600, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final productsAsync = ref.watch(allProductsProvider);

    return Scaffold(
      backgroundColor: radarCream100,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: radarCream100,
        surfaceTintColor: Colors.transparent,
        title: const Text('Fiyat Ekle', style: TextStyle(fontFamily: 'Google Sans', fontSize: 28, color: radarBrown900, fontWeight: FontWeight.w700)),
      ),
      bottomNavigationBar: AddPriceSubmitBar(
        isSubmitting: _isSubmitting,
        onSubmit: _submit,
      ),
      body: PremiumScaffoldShell(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AddPriceHeaderBanner(),
                const SizedBox(height: 16),
                ProductSelectionSection(
                  productController: _productController,
                  categoriesAsync: categoriesAsync,
                  selectedCategory: _selectedCategory,
                  productSuggestions: _productSuggestions,
                  showProductSuggestions: _showProductSuggestions,
                  decorationBuilder: _radarFieldDecoration,
                  onCategoryChanged: (value) => setState(() => _selectedCategory = value),
                  onProductChanged: (value) {
                    productsAsync.whenData((products) => _updateProductSuggestions(products, value));
                    if (_selectedProduct != null && value.trim() != _selectedProduct!.name) {
                      setState(() => _selectedProduct = null);
                    }
                  },
                  onProductSuggestionTap: _selectProduct,
                  onBarcodeTap: () async {
                    final code = await BarcodeScannerSheet.scan(context, title: 'Barkod Okut');
                    if (!mounted || code == null) return;
                    productsAsync.whenData((products) => _matchScannedBarcode(code, products));
                  },
                ),
                const SizedBox(height: 16),
                PriceInputSection(
                  priceController: _priceController,
                  selectedStore: _selectedStore,
                  onStoreTap: _showStorePicker,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
