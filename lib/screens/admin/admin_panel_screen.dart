import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/material_icon_resolver.dart';
import '../../utils/elite_level_engine.dart';
import '../../utils/theme.dart';
import '../../models/product_model.dart';
import '../../models/brand_model.dart';
import '../../models/store_model.dart';
import '../../models/store_suggestion_model.dart';
import '../../models/banner_model.dart';
import '../../models/category_model.dart';
import '../../models/campaign_basket_model.dart';
import '../../providers/product_provider.dart';
import '../../providers/banner_provider.dart';
import '../../providers/campaign_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/storage_service.dart';

import '../../widgets/barcode_scanner_sheet.dart';
import 'actual_management_tab.dart';
import 'admin_brand_management_tab.dart';
import 'admin_reports_management_tab.dart';
import 'admin_statistics_tab.dart';
import 'admin_product_suggestions_tab.dart';
import 'admin_badge_achievements_tab.dart';
import 'admin_user_management_tab.dart';

class AdminPanelScreen extends ConsumerStatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  ConsumerState<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends ConsumerState<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isMarketImportRunning = false;
  bool _isProductImportRunning = false;

  Future<void> _importMarketsFromAsset() async {
    if (_isMarketImportRunning) return;

    setState(() => _isMarketImportRunning = true);

    try {
      final rawJson = await rootBundle.loadString('assets/fiyatradar_marketler.json');
      final decoded = json.decode(rawJson);

      if (decoded is! List) {
        throw const FormatException('JSON formati List olmali.');
      }

      final markets = decoded.cast<Map<String, dynamic>>();
      final firestore = FirebaseFirestore.instance;
      final storesCollection = firestore.collection('stores');
      final brandsSnapshot = await firestore.collection('brands').get();
      final brandNameToId = <String, String>{
        for (final doc in brandsSnapshot.docs)
          (doc.data()['name'] ?? '').toString().trim().toLowerCase(): doc.id,
      };

      var insertedCount = 0;

      for (var i = 0; i < markets.length; i += 500) {
        final batch = firestore.batch();
        final chunk = markets.skip(i).take(500);

        for (final market in chunk) {
          final ad = (market['ad'] ?? market['name'] ?? '').toString().trim();
          final marka = (market['marka'] ?? market['brand'] ?? market['brand_name'] ?? '')
              .toString()
              .trim();
          final enlem = _toDouble(market['enlem'] ?? market['latitude']);
          final boylam = _toDouble(market['boylam'] ?? market['longitude']);

          if (ad.isEmpty || marka.isEmpty || enlem == null || boylam == null) {
            continue;
          }

          final normalizedBrandName = marka.toLowerCase();
          final brandId = brandNameToId[normalizedBrandName];
          final now = FieldValue.serverTimestamp();
          final docRef = storesCollection.doc();
          batch.set(docRef, {
            'name': ad,
            'displayName': ad,
            'brand_name': marka,
            'brandId': brandId,
            'latitude': enlem,
            'longitude': boylam,
            'lat': enlem,
            'lng': boylam,
            'status': 'active',
            'type': 'local',
            'isOnline': false,
            'city': '',
            'district': '',
            'neighborhood': '',
            'createdAt': now,
            'updatedAt': now,
          });
          insertedCount++;
        }

        await batch.commit();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Stores import tamamlandi. Toplam: ${markets.length}, eklenen: $insertedCount',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Market verileri yüklenemedi: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isMarketImportRunning = false);
      }
    }
  }

  Future<void> _importProducts(BuildContext context) async {
    if (_isProductImportRunning) return;

    setState(() => _isProductImportRunning = true);

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⏳ Ürünler işleniyor, lütfen bekleyin...'),
          duration: Duration(seconds: 2),
        ),
      );

      final String response = await rootBundle.loadString('assets/fiyatradar_urunler.json');
      final List<dynamic> data = json.decode(response);

      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      WriteBatch batch = firestore.batch();

      int count = 0;
      int totalAdded = 0;

      for (final item in data) {
        if (item['barcode'] == null || item['barcode'].toString().isEmpty) {
          continue;
        }

        final String barcode = item['barcode'].toString();
        final DocumentReference docRef = firestore.collection('products').doc(barcode);

        batch.set(docRef, {
          'name': item['name'] ?? '',
          'brand': item['brand_name'] ?? 'Bilinmeyen Marka',
          'imageUrl': item['image_url'] ?? '',
          'category': item['category'] ?? '',
          'categories': item['category'] != null ? [item['category']] : [],
          'status': 'active',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        count++;
        totalAdded++;

        if (count == 500) {
          await batch.commit();
          batch = firestore.batch();
          count = 0;
        }
      }

      if (count > 0) {
        await batch.commit();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Başarılı! Toplam $totalAdded ürün aktarıldı.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Ürün aktarma hatası: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Hata: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isProductImportRunning = false);
      }
    }
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.').trim());
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 10, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userModelStreamProvider);
    return userAsync.when(
      data: (user) {
        if (user?.isAdmin != true) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Admin Paneli'),
              elevation: 0,
            ),
            body: const Center(
              child: Text('Bu sayfaya erisim yetkiniz yok.'),
            ),
          );
        }
        return _buildAdminScaffold(context);
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const Scaffold(
        body: Center(child: Text('Bir hata olustu.')),
      ),
    );
  }

  Scaffold _buildAdminScaffold(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Paneli'),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: _isProductImportRunning ? null : () => _importProducts(context),
              icon: _isProductImportRunning
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.inventory_2_outlined),
              label: Text(
                _isProductImportRunning
                    ? 'Ürünler Yükleniyor...'
                    : 'Ürün Veritabanını Güncelle',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: _isMarketImportRunning ? null : _importMarketsFromAsset,
              icon: _isMarketImportRunning
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload_outlined),
              label: Text(_isMarketImportRunning ? 'Yükleniyor...' : 'Veritabanını Güncelle'),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: Theme.of(context).textTheme.bodyLarge?.color,
          unselectedLabelColor: Theme.of(context).hintColor,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: 'Ürünler', icon: Icon(Icons.inventory_2_outlined)),
            Tab(text: 'Mağazalar', icon: Icon(Icons.storefront_outlined)),
            Tab(text: 'Kategoriler', icon: Icon(Icons.category_outlined)),
            Tab(text: 'Bannerlar', icon: Icon(Icons.view_carousel_outlined)),
            Tab(text: 'Kampanyalar', icon: Icon(Icons.campaign_outlined)),
            Tab(text: 'Aktüel Yönetimi', icon: Icon(Icons.local_offer_outlined)),
            Tab(text: 'Raporlar', icon: Icon(Icons.flag_outlined)),
            Tab(text: 'Kullanıcılar', icon: Icon(Icons.people_outlined)),
            Tab(text: 'Istatistikler', icon: Icon(Icons.bar_chart_outlined)),
            Tab(text: 'Rozet Olaylari', icon: Icon(Icons.workspace_premium_outlined)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ProductHubTab(),
          _StoreHubTab(),
          _CategoryManagementTab(),
          _BannerManagementTab(),
          _CampaignManagementTab(),
          ActualManagementTab(),
          AdminReportsManagementTab(),
          AdminUserManagementTab(),
          const AdminStatisticsTab(),
          AdminBadgeAchievementsTab(),
        ],
      ),
    );
  }
}

class _ProductHubTab extends StatefulWidget {
  const _ProductHubTab();

  @override
  State<_ProductHubTab> createState() => _ProductHubTabState();
}

class _ProductHubTabState extends State<_ProductHubTab>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Ürünler'),
              Tab(text: 'Öneriler'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              _ProductManagementTab(),
              AdminProductSuggestionsTab(),
            ],
          ),
        ),
      ],
    );
  }
}



class _StoreHubTab extends StatefulWidget {
  const _StoreHubTab();

  @override
  State<_StoreHubTab> createState() => _StoreHubTabState();
}

class _StoreHubTabState extends State<_StoreHubTab>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Ana Mağazalar'),
              Tab(text: 'Şubeler'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              const AdminBrandManagementTab(),
              _StoreManagementTab(initialFilter: 'active'),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 1: Ürün Yönetimi
// ---------------------------------------------------------------------------
class _OpenFoodFactsResult {
  final String? productName;
  final String? brand;
  final String? imageUrl;

  const _OpenFoodFactsResult({this.productName, this.brand, this.imageUrl});
}

class _OpenFoodFactsService {
  final Map<String, _OpenFoodFactsResult?> _cache = {};

  Future<_OpenFoodFactsResult?> fetchByBarcode(String barcode) async {
    final normalized = barcode.trim();
    if (_cache.containsKey(normalized)) {
      return _cache[normalized];
    }

    final uri = Uri.parse('https://world.openfoodfacts.org/api/v2/product/$normalized.json');

    try {
      final response = await _getJson(
        uri,
        headers: const {
          'User-Agent': 'FiyatRadar/1.0 (admin-panel)',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 7));

      if (response.statusCode != 200) {
        _cache[normalized] = null;
        return null;
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final product = body['product'] as Map<String, dynamic>?;
      if (product == null) {
        _cache[normalized] = null;
        return null;
      }

      final selectedImages = product['selected_images'] as Map<String, dynamic>?;
      final front = selectedImages?['front'] as Map<String, dynamic>?;
      final display = front?['display'] as Map<String, dynamic>?;
      final imageUrl = (product['image_front_url'] as String?) ??
          (product['image_url'] as String?) ??
          (display?['en'] as String?) ??
          (display?['tr'] as String?);

      final result = _OpenFoodFactsResult(
        productName: product['product_name'] as String?,
        brand: product['brands'] as String?,
        imageUrl: imageUrl,
      );
      _cache[normalized] = result;
      return result;
    } on TimeoutException {
      _cache[normalized] = null;
      return null;
    } catch (_) {
      _cache[normalized] = null;
      return null;
    }
  }

  Future<_HttpStringResponse> _getJson(
    Uri uri, {
    Map<String, String>? headers,
  }) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      headers?.forEach(request.headers.set);
      final response = await request.close();
      final body = await utf8.decoder.bind(response).join();
      return _HttpStringResponse(response.statusCode, body);
    } finally {
      client.close(force: true);
    }
  }
}

class _HttpStringResponse {
  const _HttpStringResponse(this.statusCode, this.body);

  final int statusCode;
  final String body;
}

class _ProductManagementTab extends ConsumerWidget {
  const _ProductManagementTab();

  static final _openFoodFactsService = _OpenFoodFactsService();

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Elektronik': return Icons.devices;
      case 'Gida': return Icons.restaurant;
      case 'Temizlik': return Icons.cleaning_services;
      case 'Kisisel Bakim': return Icons.face;
      case 'Ev & Yasam': return Icons.home;
      case 'Giyim': return Icons.checkroom;
      case 'Spor': return Icons.sports;
      case 'Oyuncak': return Icons.toys;
      case 'Kitap': return Icons.book;
      case 'Otomotiv': return Icons.directions_car;
      default: return Icons.category;
    }
  }


  Future<bool> _isAdminAllowed() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final userData = userDoc.data() ?? <String, dynamic>{};
    if (userData['isAdmin'] == true) return true;

    final adminsDoc = await FirebaseFirestore.instance.collection('settings').doc('admins').get();
    final adminsData = adminsDoc.data() ?? <String, dynamic>{};
    final allowedUids = List<String>.from(adminsData['uids'] ?? const []);
    return allowedUids.contains(uid);
  }

  Future<void> _pickAndUploadProductImage({
    required BuildContext context,
    required WidgetRef ref,
    required String productId,
    String? currentImagePath,
    void Function(String imageUrl, String imagePath)? onUploaded,
  }) async {
    final isAdminAllowed = await _isAdminAllowed();
    if (!isAdminAllowed) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yalnızca admin görsel yükleyebilir.')),
        );
      }
      return;
    }

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 88);
    if (picked == null) return;

    final storageService = StorageService();
    try {
      if (currentImagePath != null && currentImagePath.trim().isNotEmpty) {
        try {
          await storageService.deleteByPath(currentImagePath.trim());
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Eski görsel silinemedi, yeni görsel yüklenecek.')),
            );
          }
        }
      }

      final result = await storageService.uploadProductCoverImage(
        file: File(picked.path),
        productId: productId,
      );

      await ref.read(firestoreServiceProvider).updateProduct(productId, {
        'imageUrl': result.downloadUrl,
        'imagePath': result.storagePath,
        'imageSource': 'admin_upload',
        'imageApproved': true,
        'updatedAt': DateTime.now(),
      });

      onUploaded?.call(result.downloadUrl, result.storagePath);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ürün görseli güncellendi.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Görsel yüklenemedi: $e')),
        );
      }
    }
  }

  void _showAddProductDialog(BuildContext context, WidgetRef ref, List<CategoryModel> categories) {
    final nameController = TextEditingController();
    final brandController = TextEditingController();
    final barcodeController = TextEditingController();
    final descriptionController = TextEditingController();
    final Set<String> selectedCategories = <String>{};
    bool isUploading = false;
    String? uploadError;
    Timer? barcodeDebounce;
    bool isFetchingBarcode = false;
    String? barcodeHint;
    String? openFoodFactsImageUrl;
    File? selectedImageFile;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          Future<void> fetchOpenFoodFacts(String input) async {
            final barcode = input.trim();
            if (barcode.length < 8) {
              setDialogState(() {
                isFetchingBarcode = false;
                barcodeHint = null;
                openFoodFactsImageUrl = null;
              });
              return;
            }

            setDialogState(() {
              isFetchingBarcode = true;
              barcodeHint = 'Barkoddan ürün bilgisi alınıyor...';
            });

            final result = await _openFoodFactsService.fetchByBarcode(barcode);
            if (!ctx.mounted) return;

            setDialogState(() {
              isFetchingBarcode = false;
              if (result == null) {
                barcodeHint = 'Ürün bulunamadı, manuel ekleyebilirsiniz';
                openFoodFactsImageUrl = null;
                return;
              }

              if (result.productName != null && nameController.text.trim().isEmpty) {
                nameController.text = result.productName!.trim();
              }
              if (result.brand != null && brandController.text.trim().isEmpty) {
                final firstBrand = result.brand!.split(',').first.trim();
                if (firstBrand.isNotEmpty) {
                  brandController.text = firstBrand;
                }
              }

              openFoodFactsImageUrl = result.imageUrl;
              barcodeHint = openFoodFactsImageUrl == null
                  ? 'Görsel bulunamadı / Manuel ekle'
                  : 'OpenFoodFacts görseli bulundu';
            });
          }


          Future<void> submitProduct() async {
            if (isUploading) return;

            if (nameController.text.trim().isEmpty || selectedCategories.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ürün adı ve en az bir kategori zorunludur'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }

            setDialogState(() {
              isUploading = true;
              uploadError = null;
            });

            try {
              final service = ref.read(firestoreServiceProvider);
              final productId = await service.addProduct(ProductModel(
                id: '',
                name: nameController.text.trim(),
                brand: brandController.text.trim().isEmpty ? 'Genel' : brandController.text.trim(),
                categories: selectedCategories.toList(),
                barcode: barcodeController.text.trim().isEmpty ? null : barcodeController.text.trim(),
                description: descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
                imageUrls: openFoodFactsImageUrl != null ? [openFoodFactsImageUrl!] : const [],
                imageUrl: openFoodFactsImageUrl,
                imageSource: openFoodFactsImageUrl != null ? 'openfoodfacts' : 'admin_manual',
                imageApproved: openFoodFactsImageUrl != null,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ));

              if (selectedImageFile != null) {
                final upload = await StorageService().uploadProductCoverImage(
                  file: selectedImageFile!,
                  productId: productId,
                );
                await service.updateProduct(productId, {
                  'imageUrl': upload.downloadUrl,
                  'imagePath': upload.storagePath,
                  'imageSource': 'admin_upload',
                  'imageApproved': true,
                  'updatedAt': DateTime.now(),
                });
              } else {
                await service.updateProduct(productId, {
                  if (openFoodFactsImageUrl != null) 'imageUrl': openFoodFactsImageUrl,
                  if (openFoodFactsImageUrl != null) 'imageSource': 'openfoodfacts',
                  if (openFoodFactsImageUrl != null) 'imageApproved': true,
                  'updatedAt': DateTime.now(),
                });
              }

              nameController.clear();
              brandController.clear();
              barcodeController.clear();
              descriptionController.clear();
              selectedCategories.clear();
              barcodeDebounce?.cancel();

              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ürün başarıyla eklendi'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            } catch (e) {
              setDialogState(() {
                uploadError = 'Yükleme başarısız: $e';
              });
              if (ctx.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Ürün eklenemedi: $e'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            } finally {
              if (ctx.mounted) {
                setDialogState(() => isUploading = false);
              } else {
                isUploading = false;
              }
            }
          }

          return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
          title: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(AppRadius.sm)),
              child: const Icon(Icons.add_box_outlined, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Text('Yeni Ürün Ekle'),
          ]),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Ürün Adı', prefixIcon: Icon(Icons.label_outline)),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Açıklama (Opsiyonel)', prefixIcon: Icon(Icons.description_outlined)),
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: barcodeController,
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  barcodeDebounce?.cancel();
                  barcodeDebounce = Timer(const Duration(milliseconds: 500), () {
                    fetchOpenFoodFacts(value);
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Barkod (Opsiyonel)',
                  prefixIcon: const Icon(Icons.qr_code),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: () async {
                      final code = await BarcodeScannerSheet.scan(
                        ctx,
                        title: 'Barkod Tara',
                      );
                      if (code != null) {
                        barcodeController.text = code;
                        fetchOpenFoodFacts(code);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: brandController,
                decoration: const InputDecoration(labelText: 'Marka', prefixIcon: Icon(Icons.branding_watermark)),
              ),

              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: () async {
                  final picker = ImagePicker();
                  final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 88);
                  if (picked == null) return;
                  setDialogState(() {
                    selectedImageFile = File(picked.path);
                    openFoodFactsImageUrl = null;
                    barcodeHint = null;
                  });
                },
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(selectedImageFile == null ? 'Görsel Yükle' : 'Görsel seçildi'),
              ),
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Kategoriler',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: categories
                    .map((c) => c.name)
                    .map(
                      (name) => FilterChip(
                        label: Text(name),
                        selected: selectedCategories.contains(name),
                        onSelected: (selected) {
                          setDialogState(() {
                            if (selected) {
                              selectedCategories.add(name);
                            } else {
                              selectedCategories.remove(name);
                            }
                          });
                        },
                      ),
                    )
                    .toList(),
              ),
              if (isFetchingBarcode) ...[
                const SizedBox(height: AppSpacing.sm),
                const LinearProgressIndicator(minHeight: 2),
              ],
              if (barcodeHint != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    barcodeHint!,
                    style: TextStyle(
                      color: barcodeHint!.contains('bulunamadı') || barcodeHint!.contains('Manuel')
                          ? AppColors.warning
                          : AppColors.success,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
              if (openFoodFactsImageUrl != null) ...[
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: Image.network(
                    openFoodFactsImageUrl!,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 120,
                      alignment: Alignment.center,
                      color: Colors.black12,
                      child: const Text('Görsel bulunamadı / Manuel ekle'),
                    ),
                  ),
                ),
              ],
              if (uploadError != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(uploadError!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
              ],
            ]),
          ),
          actions: [
            TextButton(onPressed: () { barcodeDebounce?.cancel(); Navigator.pop(ctx); }, child: const Text('Iptal')),
            FilledButton(
              onPressed: isUploading ? null : submitProduct,
              child: isUploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Ekle'),
            ),
          ],
          );
        },
      ),
    );
  }


  void _showEditProductDialog(
    BuildContext context,
    WidgetRef ref,
    ProductModel product,
    List<CategoryModel> categories,
  ) {
    final nameController = TextEditingController(text: product.name);
    final brandController = TextEditingController(text: product.brand);
    final barcodeController = TextEditingController(text: product.barcode ?? '');
    final descriptionController = TextEditingController(text: product.description ?? '');
    final Set<String> selectedCategories = {...product.categories};
    bool isSaving = false;
    File? selectedImageFile;
    String? currentImageUrl = product.effectiveImage;
    String? currentImagePath = product.imagePath;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
          title: const Text('Ürün Düzenle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Ürün Adı')),
                const SizedBox(height: AppSpacing.md),
                TextField(controller: descriptionController, maxLines: 2, decoration: const InputDecoration(labelText: 'Açıklama (Opsiyonel)')),
                const SizedBox(height: AppSpacing.md),
                TextField(controller: barcodeController, decoration: const InputDecoration(labelText: 'Barkod (Opsiyonel)')),
                const SizedBox(height: AppSpacing.md),
                TextField(controller: brandController, decoration: const InputDecoration(labelText: 'Marka')),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 88);
                    if (picked == null) return;
                    setDialogState(() {
                      selectedImageFile = File(picked.path);
                    });
                  },
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(selectedImageFile == null ? 'Görsel Yükle' : 'Yeni görsel seçildi'),
                ),
                if ((currentImageUrl ?? '').isNotEmpty && selectedImageFile == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('Mevcut görsel kullanılacak', style: Theme.of(context).textTheme.bodySmall),
                  ),
                const SizedBox(height: AppSpacing.md),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Kategoriler', style: Theme.of(context).textTheme.titleSmall),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: categories
                      .map((c) => c.name)
                      .map(
                        (name) => FilterChip(
                          label: Text(name),
                          selected: selectedCategories.contains(name),
                          onSelected: (selected) {
                            setDialogState(() {
                              if (selected) {
                                selectedCategories.add(name);
                              } else {
                                selectedCategories.remove(name);
                              }
                            });
                          },
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Iptal')),
            FilledButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (product.id.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ürün ID bulunamadı')));
                        return;
                      }
                      if (nameController.text.trim().isEmpty || selectedCategories.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ürün adı ve kategori zorunludur')));
                        return;
                      }

                      setDialogState(() => isSaving = true);
                      try {
                        String? nextImageUrl = currentImageUrl;
                        String? nextImagePath = currentImagePath;
                        if (selectedImageFile != null) {
                          final storageService = StorageService();
                          if ((currentImagePath ?? '').trim().isNotEmpty) {
                            try {
                              await storageService.deleteByPath(currentImagePath!.trim());
                            } catch (_) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Eski görsel silinemedi, yeni görsel yüklenecek.')),
                                );
                              }
                            }
                          }
                          final upload = await storageService.uploadProductCoverImage(
                            file: selectedImageFile!,
                            productId: product.id,
                          );
                          nextImageUrl = upload.downloadUrl;
                          nextImagePath = upload.storagePath;
                        }

                        await ref.read(firestoreServiceProvider).updateProduct(product.id, {
                          'name': nameController.text.trim(),
                          'brand': brandController.text.trim().isEmpty ? 'Genel' : brandController.text.trim(),
                          'barcode': barcodeController.text.trim().isEmpty ? null : barcodeController.text.trim(),
                          'description': descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
                          'categories': selectedCategories.toList(),
                          'category': selectedCategories.first,
                          'imageUrl': nextImageUrl,
                          'imagePath': nextImagePath,
                          'imageSource': selectedImageFile != null ? 'admin_upload' : product.imageSource,
                          'imageApproved': (nextImageUrl ?? '').isNotEmpty,
                          'updatedAt': DateTime.now(),
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ürün başarıyla güncellendi'), behavior: SnackBarBehavior.floating),
                        );
                        ref.invalidate(allProductsProvider);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ürün güncellenemedi: $e')));
                      } finally {
                        if (ctx.mounted) setDialogState(() => isSaving = false);
                      }
                    },
              child: isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }



  Future<void> _showEditUserDialog(BuildContext context, WidgetRef ref, dynamic user) async {
    final nameController = TextEditingController(text: user.name);
    final roleController = TextEditingController(text: user.isAdmin ? 'admin' : (user.role ?? 'user'));
    final pointsController = TextEditingController(text: user.points.toString());
    final levelController = TextEditingController();
    bool verifiedBadge = user.isAdmin;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Üye düzenleme'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'displayName')),
              const SizedBox(height: 8),
              TextField(controller: roleController, decoration: const InputDecoration(labelText: 'role (user/admin)')),
              const SizedBox(height: 8),
              TextField(controller: pointsController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'pointsTotal')),
              const SizedBox(height: 8),
              TextField(controller: levelController, decoration: const InputDecoration(labelText: 'level override (opsiyonel)')),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: verifiedBadge,
                title: const Text('Verified badge'),
                onChanged: (v) => verifiedBadge = v,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Vazgeç')),
          FilledButton(
            onPressed: () async {
              final updatedPoints = int.tryParse(pointsController.text.trim()) ?? user.points;
              final levelOverride = levelController.text.trim();
              final computedLevelName = EliteLevelEngine.getLevelStyle(
                EliteLevelEngine.getPointsLevel(updatedPoints),
              ).label;
              await ref.read(firestoreServiceProvider).updateUserByAdmin(user.uid, {
                'name': nameController.text.trim(),
                'displayName': nameController.text.trim(),
                'role': roleController.text.trim().isEmpty ? 'user' : roleController.text.trim(),
                'isAdmin': roleController.text.trim() == 'admin',
                'points': updatedPoints,
                'pointsTotal': updatedPoints,
                'totalPoints': updatedPoints,
                'level': levelOverride.isNotEmpty ? levelOverride : computedLevelName,
                'levelName': levelOverride.isNotEmpty ? levelOverride : computedLevelName,
                'verifiedBadge': verifiedBadge,
                'updatedAt': FieldValue.serverTimestamp(),
              });
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Üye güncellendi')));
              }
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(allProductsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_product',
        onPressed: () {
          _showAddProductDialog(context, ref, categoriesAsync.valueOrNull ?? []);
        },
        icon: const Icon(Icons.add),
        label: const Text('Ürün Ekle'),
      ),
      body: productsAsync.when(
        data: (products) {
          if (products.isEmpty) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.inventory_2_outlined, size: 64, color: theme.hintColor),
              const SizedBox(height: AppSpacing.md),
              Text('Henüz ürün yok', style: TextStyle(color: theme.hintColor, fontSize: 16)),
            ]));
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 80),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Dismissible(
                key: ValueKey(product.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: AppSpacing.lg),
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(AppRadius.lg)),
                  child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
                ),
                onDismissed: (_) {
                  ref.read(firestoreServiceProvider).deleteProduct(product.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${product.name} silindi'), behavior: SnackBarBehavior.floating),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Icon(_categoryIcon(product.category), color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Row(children: [
                          _InfoChip(icon: Icons.category_outlined, label: product.categories.join(', ')),
                          const SizedBox(width: AppSpacing.xs),
                          if (product.lastStore != null) _InfoChip(icon: Icons.store_outlined, label: product.lastStore!),
                        ]),
                        if ((product.effectiveImage ?? '').isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              'Bu ürün için görsel yok. Görsel Yükle ile ekleyin.',
                              style: TextStyle(fontSize: 11, color: AppColors.warning),
                            ),
                          ),
                      ])),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => _pickAndUploadProductImage(
                              context: context,
                              ref: ref,
                              productId: product.id,
                              currentImagePath: product.imagePath,
                            ),
                            icon: const Icon(Icons.photo_library_outlined, size: 20),
                            color: theme.colorScheme.primary,
                            tooltip: 'Görsel Yükle',
                          ),
                          IconButton(
                            onPressed: () => _showEditProductDialog(
                              context,
                              ref,
                              product,
                              categoriesAsync.valueOrNull ?? const [],
                            ),
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            color: theme.hintColor,
                            tooltip: 'Düzenle',
                          ),
                        ],
                      ),
                    ]),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Ürünler yüklenemedi')),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 10, color: Theme.of(context).hintColor),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 10, color: Theme.of(context).hintColor)),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 3: Şube (Store) Yönetimi
// ---------------------------------------------------------------------------
class _StoreManagementTab extends ConsumerStatefulWidget {
  final String initialFilter;
  const _StoreManagementTab({this.initialFilter = 'all'});

  @override
  ConsumerState<_StoreManagementTab> createState() => _StoreManagementTabState();
}

class _StoreLocationDraft {
  final double lat;
  final double lng;
  final String city;
  final String district;
  final String neighborhood;

  const _StoreLocationDraft({
    required this.lat,
    required this.lng,
    this.city = '',
    this.district = '',
    this.neighborhood = '',
  });
}

class _StoreManagementTabState extends ConsumerState<_StoreManagementTab> {
  late String _statusFilter;

  @override
  void initState() {
    super.initState();
    _statusFilter = widget.initialFilter;
  }

  Color _statusColor(StoreStatus status) {
    switch (status) {
      case StoreStatus.active: return AppColors.success;
      case StoreStatus.hidden: return AppColors.textTertiary;
      case StoreStatus.pending: return AppColors.accent;
    }
  }

  void _showAddStoreDialog(BuildContext context, WidgetRef ref) {
    _openStoreEditor(context: context, ref: ref);
  }

  Future<void> _openStoreEditor({
    required BuildContext context,
    required WidgetRef ref,
    StoreModel? store,
  }) async {
    final isEdit = store != null;
    final nameController = TextEditingController(text: store?.displayName ?? '');
    final cityController = TextEditingController(text: store?.city ?? '');
    final districtController = TextEditingController(text: store?.district ?? '');
    final neighborhoodController = TextEditingController(text: store?.neighborhood ?? '');
    String? selectedBrandId = store?.brandId;
    double? selectedLat = (store != null && store.lat != 0) ? store.lat : null;
    double? selectedLng = (store != null && store.lng != 0) ? store.lng : null;
    StoreType selectedType = store?.type ?? StoreType.local;

    final brands = ref.read(activeBrandsProvider).valueOrNull ?? [];

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final hasName = nameController.text.trim().isNotEmpty;
          final hasLocation = selectedType == StoreType.online || (selectedLat != null && selectedLng != null);
          final canSave = hasName && hasLocation && selectedBrandId != null;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
            title: Text(isEdit ? 'Şube Düzenle' : 'Yeni Şube Ekle'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedBrandId,
                    decoration: const InputDecoration(labelText: 'Ana Mağaza *', prefixIcon: Icon(Icons.business)),
                    items: brands.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))).toList(),
                    onChanged: (val) => setDialogState(() => selectedBrandId = val),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Yerel Şube'),
                          selected: selectedType == StoreType.local,
                          onSelected: (_) => setDialogState(() => selectedType = StoreType.local),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Online Mağaza'),
                          selected: selectedType == StoreType.online,
                          onSelected: (_) => setDialogState(() => selectedType = StoreType.online),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Goruntuleme Adi', prefixIcon: Icon(Icons.store_outlined)),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  if (selectedType == StoreType.local) ...[
                    const SizedBox(height: AppSpacing.md),
                    ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.place_outlined),
                    title: Text(selectedLat == null ? 'Konum sec (zorunlu)' : 'Konum secildi: ${selectedLat!.toStringAsFixed(5)}, ${selectedLng!.toStringAsFixed(5)}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final picked = await _pickStoreLocation(
                        context: context,
                        initialLat: selectedLat,
                        initialLng: selectedLng,
                      );
                      if (picked == null) return;
                      setDialogState(() {
                        selectedLat = picked.lat;
                        selectedLng = picked.lng;
                        if (cityController.text.trim().isEmpty) cityController.text = picked.city;
                        if (districtController.text.trim().isEmpty) districtController.text = picked.district;
                        if (neighborhoodController.text.trim().isEmpty) neighborhoodController.text = picked.neighborhood;
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(controller: cityController, decoration: const InputDecoration(labelText: 'Il', prefixIcon: Icon(Icons.location_city))),
                  const SizedBox(height: AppSpacing.md),
                  TextField(controller: districtController, decoration: const InputDecoration(labelText: 'Ilce', prefixIcon: Icon(Icons.map_outlined))),
                    const SizedBox(height: AppSpacing.md),
                    TextField(controller: neighborhoodController, decoration: const InputDecoration(labelText: 'Mahalle', prefixIcon: Icon(Icons.holiday_village_outlined))),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Iptal')),
              ElevatedButton(
                onPressed: canSave
                    ? () async {
                        final payload = {
                          'brandId': selectedBrandId,
                          'displayName': nameController.text.trim(),
                          'name': nameController.text.trim(),
                          'city': selectedType == StoreType.online ? '' : cityController.text.trim(),
                          'district': selectedType == StoreType.online ? '' : districtController.text.trim(),
                          'neighborhood': selectedType == StoreType.online ? '' : neighborhoodController.text.trim(),
                          'lat': selectedType == StoreType.online ? 0.0 : selectedLat!.toDouble(),
                          'lng': selectedType == StoreType.online ? 0.0 : selectedLng!.toDouble(),
                          'status': store?.status.name ?? StoreStatus.active.name,
                          'type': selectedType.name,
                          'isOnline': selectedType == StoreType.online,
                        };
                        if (isEdit) {
                          await ref.read(firestoreServiceProvider).updateStore(store!.id, payload);
                        } else {
                          await ref.read(firestoreServiceProvider).addStore(
                            StoreModel(
                              id: '',
                              brandId: selectedBrandId,
                              displayName: nameController.text.trim(),
                              city: selectedType == StoreType.online ? '' : cityController.text.trim(),
                              district: selectedType == StoreType.online ? '' : districtController.text.trim(),
                              neighborhood: selectedType == StoreType.online ? '' : neighborhoodController.text.trim(),
                              lat: selectedType == StoreType.online ? 0.0 : selectedLat!.toDouble(),
                              lng: selectedType == StoreType.online ? 0.0 : selectedLng!.toDouble(),
                              status: StoreStatus.active,
                              type: selectedType,
                              createdAt: DateTime.now(),
                            ),
                          );
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                      }
                    : null,
                child: Text(isEdit ? 'Kaydet' : 'Ekle'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<_StoreLocationDraft?> _pickStoreLocation({
    required BuildContext context,
    double? initialLat,
    double? initialLng,
  }) async {
    final mapController = MapController();
    LatLng marker = LatLng(initialLat ?? 41.0082, initialLng ?? 28.9784);
    String city = '';
    String district = '';
    String neighborhood = '';
    bool isResolving = false;
    bool isProgrammaticMapMove = false;

    final latController = TextEditingController(text: marker.latitude.toStringAsFixed(6));
    final lngController = TextEditingController(text: marker.longitude.toStringAsFixed(6));
    final pasteController = TextEditingController();
    Timer? debounce;
    String? coordinateError;

    LatLng? parseLatLng(String input) {
      final normalized = input.trim().replaceAll(';', ',').replaceAll(' ', '');
      if (normalized.isEmpty) return null;
      final parts = normalized.split(',');
      if (parts.length != 2) return null;
      final lat = double.tryParse(parts[0]);
      final lng = double.tryParse(parts[1]);
      if (lat == null || lng == null) return null;
      if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;
      return LatLng(lat, lng);
    }

    void syncControllersFromMarker() {
      latController.text = marker.latitude.toStringAsFixed(6);
      lngController.text = marker.longitude.toStringAsFixed(6);
      coordinateError = null;
    }

    return showModalBottomSheet<_StoreLocationDraft>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          Future<void> resolveAddress() async {
            setModalState(() => isResolving = true);
            try {
              final placemarks = await placemarkFromCoordinates(marker.latitude, marker.longitude);
              if (placemarks.isNotEmpty) {
                final p = placemarks.first;
                city = p.administrativeArea ?? p.locality ?? '';
                district = p.subAdministrativeArea ?? p.locality ?? '';
                neighborhood = p.subLocality ?? p.street ?? '';
              }
            } catch (_) {}
            if (ctx.mounted) {
              setModalState(() => isResolving = false);
            }
          }

          void moveMarkerFromText() {
            debounce?.cancel();
            debounce = Timer(const Duration(milliseconds: 300), () {
              final lat = double.tryParse(latController.text.trim());
              final lng = double.tryParse(lngController.text.trim());
              if (lat == null || lng == null) {
                if (ctx.mounted) {
                  setModalState(() => coordinateError = 'Gecerli sayisal enlem/boylam girin');
                }
                return;
              }
              if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
                if (ctx.mounted) {
                  setModalState(() => coordinateError = 'Enlem -90..90, boylam -180..180 olmali');
                }
                return;
              }

              final newMarker = LatLng(lat, lng);
              if (ctx.mounted) {
                setModalState(() {
                  marker = newMarker;
                  coordinateError = null;
                  isProgrammaticMapMove = true;
                });
              }
              mapController.move(newMarker, mapController.camera.zoom);
              unawaited(resolveAddress());
            });
          }

          Future<void> pasteFromClipboard() async {
            final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
            final text = clipboard?.text ?? '';
            pasteController.text = text;
            final parsed = parseLatLng(text);
            if (parsed == null) {
              if (ctx.mounted) {
                setModalState(() => coordinateError = 'Panodaki metin "Lat,Lng" formatinda degil');
              }
              return;
            }
            if (ctx.mounted) {
              setModalState(() {
                marker = parsed;
                syncControllersFromMarker();
                isProgrammaticMapMove = true;
              });
            }
            mapController.move(parsed, mapController.camera.zoom);
            unawaited(resolveAddress());
          }

          Future<void> openInGoogleMaps() async {
            final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${marker.latitude},${marker.longitude}');
            final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
            if (!launched && ctx.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Google Maps acilamadi'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }

          final canSave = coordinateError == null &&
              double.tryParse(latController.text.trim()) != null &&
              double.tryParse(lngController.text.trim()) != null;

          return SafeArea(
            child: SizedBox(
              height: MediaQuery.of(ctx).size.height * 0.88,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        const Expanded(child: Text('Haritadan pin secin', style: TextStyle(fontWeight: FontWeight.w700))),
                        TextButton(onPressed: () async => await resolveAddress(), child: const Text('Adresi Doldur')),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 300,
                    child: FlutterMap(
                      mapController: mapController,
                      options: MapOptions(
                        initialCenter: marker,
                        initialZoom: 14,
                        onTap: (_, latLng) {
                          setModalState(() {
                            marker = latLng;
                            syncControllersFromMarker();
                          });
                          unawaited(resolveAddress());
                        },
                        onPositionChanged: (position, hasGesture) {
                          if (!hasGesture) return;
                          if (isProgrammaticMapMove) {
                            isProgrammaticMapMove = false;
                            return;
                          }
                          final center = position.center;
                          if (center == null) return;
                          setModalState(() {
                            marker = center;
                            syncControllersFromMarker();
                          });
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.fiyatradar.app',
                        ),
                        MarkerLayer(markers: [
                          Marker(
                            point: marker,
                            width: 50,
                            height: 50,
                            child: const Icon(Icons.location_pin, color: Colors.red, size: 44),
                          ),
                        ]),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: latController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                                decoration: const InputDecoration(
                                  labelText: 'Enlem (Lat)',
                                  hintText: '41.00820',
                                ),
                                onChanged: (_) => moveMarkerFromText(),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: TextField(
                                controller: lngController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                                decoration: const InputDecoration(
                                  labelText: 'Boylam (Lng)',
                                  hintText: '28.97840',
                                ),
                                onChanged: (_) => moveMarkerFromText(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextField(
                          controller: pasteController,
                          keyboardType: TextInputType.text,
                          decoration: const InputDecoration(
                            labelText: 'Lat,Lng yapistir',
                            hintText: '41.00820,28.97840',
                          ),
                          onSubmitted: (value) {
                            final parsed = parseLatLng(value);
                            if (parsed == null) {
                              setModalState(() => coordinateError = 'Gecersiz format. Ornek: 41.00820,28.97840');
                              return;
                            }
                            setModalState(() {
                              marker = parsed;
                              syncControllersFromMarker();
                              isProgrammaticMapMove = true;
                            });
                            mapController.move(parsed, mapController.camera.zoom);
                            unawaited(resolveAddress());
                          },
                        ),
                        if (coordinateError != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              coordinateError!,
                              style: const TextStyle(color: AppColors.error, fontSize: 12),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  ListTile(
                    title: Text('Lat/Lng: ${marker.latitude.toStringAsFixed(6)}, ${marker.longitude.toStringAsFixed(6)}'),
                    subtitle: Text(isResolving ? 'Adres cozuluyor...' : '$neighborhood / $district / $city'),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: openInGoogleMaps,
                            child: const Text("Google Maps'te Ac"),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: pasteFromClipboard,
                            child: const Text("Google Maps'ten Yapistir"),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: canSave
                            ? () {
                                final lat = double.tryParse(latController.text.trim());
                                final lng = double.tryParse(lngController.text.trim());
                                if (lat == null || lng == null) return;
                                Navigator.pop(
                                  ctx,
                                  _StoreLocationDraft(
                                    lat: lat,
                                    lng: lng,
                                    city: city,
                                    district: district,
                                    neighborhood: neighborhood,
                                  ),
                                );
                              }
                            : null,
                        child: const Text('Konumu Kaydet'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).whenComplete(() {
      debounce?.cancel();
      latController.dispose();
      lngController.dispose();
      pasteController.dispose();
    });
  }

  void _showMergeDialog(BuildContext context, WidgetRef ref, StoreModel source, List<StoreModel> allStores) {
    final targets = allStores.where((s) => s.id != source.id && s.status == StoreStatus.active).toList();
    if (targets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Birleştirmek için aktif başka mağaza yok'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: const Text('Mağazayı Birleştir'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: targets.length,
            itemBuilder: (context, index) {
              final target = targets[index];
              return ListTile(
                title: Text(target.displayName),
                subtitle: Text('${target.neighborhood}, ${target.district}'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await ref.read(firestoreServiceProvider).mergeStores(source.id, target.id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${source.displayName} -> ${target.displayName} birlestirildi'), behavior: SnackBarBehavior.floating),
                    );
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Iptal')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storesAsync = ref.watch(allStoresStreamProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_store',
        onPressed: () => _showAddStoreDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Şube Ekle'),
      ),
      body: storesAsync.when(
        data: (stores) {
          if (stores.isEmpty) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.store_outlined, size: 64, color: theme.hintColor),
              const SizedBox(height: AppSpacing.md),
              Text('Henüz şube yok', style: TextStyle(color: theme.hintColor, fontSize: 16)),
            ]));
          }

          final filteredStores = _statusFilter == 'all'
              ? stores
              : stores.where((s) => s.status.name == _statusFilter).toList();

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 80),
            itemCount: filteredStores.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    children: [
                      _StatusChip(label: 'Tumu', selected: _statusFilter == 'all', onTap: () => setState(() => _statusFilter = 'all')),
                      _StatusChip(label: 'Aktif', selected: _statusFilter == 'active', onTap: () => setState(() => _statusFilter = 'active')),
                      _StatusChip(label: 'Bekleyen', selected: _statusFilter == 'pending', onTap: () => setState(() => _statusFilter = 'pending')),
                      _StatusChip(label: 'Gizli', selected: _statusFilter == 'hidden', onTap: () => setState(() => _statusFilter = 'hidden')),
                    ],
                  ),
                );
              }

              final store = filteredStores[index - 1];
              final color = _statusColor(store.status);

              return Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(AppRadius.md)),
                          child: Icon(Icons.store, color: color, size: 22),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(store.displayName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          const SizedBox(height: 4),
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(AppRadius.xs)),
                              child: Text(store.statusLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
                            ),
                            if (store.neighborhood.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              _InfoChip(icon: Icons.location_on, label: '${store.neighborhood}, ${store.district}'),
                            ],
                            if (store.lat == 0 || store.lng == 0) ...[
                              const SizedBox(width: 6),
                              const _InfoChip(icon: Icons.warning_amber_rounded, label: 'Konum eksik'),
                            ],
                          ]),
                        ])),
                      ]),
                      const SizedBox(height: AppSpacing.sm),
                      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                        if (store.status == StoreStatus.pending) ...[
                          SizedBox(
                            height: 30,
                            child: TextButton.icon(
                              onPressed: () async {
                                await ref.read(firestoreServiceProvider).approveStore(store.id);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Şube onaylandı'), behavior: SnackBarBehavior.floating),
                                  );
                                }
                              },
                              icon: const Icon(Icons.check_circle_outline, size: 16),
                              label: const Text('Onayla', style: TextStyle(fontSize: 12)),
                              style: TextButton.styleFrom(foregroundColor: AppColors.success, padding: const EdgeInsets.symmetric(horizontal: 8)),
                            ),
                          ),
                        ],
                        if (store.lat == 0 || store.lng == 0)
                          SizedBox(
                            height: 30,
                            child: TextButton.icon(
                              onPressed: () async {
                                final picked = await _pickStoreLocation(context: context);
                                if (picked == null) return;
                                await ref.read(firestoreServiceProvider).updateStore(store.id, {
                                  'lat': picked.lat,
                                  'lng': picked.lng,
                                  if (store.city.isEmpty && picked.city.isNotEmpty) 'city': picked.city,
                                  if (store.district.isEmpty && picked.district.isNotEmpty) 'district': picked.district,
                                  if (store.neighborhood.isEmpty && picked.neighborhood.isNotEmpty) 'neighborhood': picked.neighborhood,
                                });
                              },
                              icon: const Icon(Icons.add_location_alt_outlined, size: 16),
                              label: const Text('Konum Ekle', style: TextStyle(fontSize: 12)),
                              style: TextButton.styleFrom(foregroundColor: AppColors.warning, padding: const EdgeInsets.symmetric(horizontal: 8)),
                            ),
                          ),
                        SizedBox(
                          height: 30,
                          child: TextButton.icon(
                            onPressed: () => _openStoreEditor(context: context, ref: ref, store: store),
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            label: const Text('Düzenle', style: TextStyle(fontSize: 12)),
                            style: TextButton.styleFrom(foregroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(horizontal: 8)),
                          ),
                        ),
                        SizedBox(
                          height: 30,
                          child: TextButton.icon(
                            onPressed: () => _showMergeDialog(context, ref, store, stores),
                            icon: const Icon(Icons.merge_type, size: 16),
                            label: const Text('Birlestir', style: TextStyle(fontSize: 12)),
                            style: TextButton.styleFrom(foregroundColor: AppColors.info, padding: const EdgeInsets.symmetric(horizontal: 8)),
                          ),
                        ),
                        SizedBox(
                          height: 30,
                          child: IconButton(
                            onPressed: () {
                              ref.read(firestoreServiceProvider).deleteStore(store.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('${store.displayName} silindi'), behavior: SnackBarBehavior.floating),
                              );
                            },
                            icon: const Icon(Icons.delete_outline, size: 18),
                            color: AppColors.error,
                            padding: EdgeInsets.zero,
                            iconSize: 18,
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Şubeler yüklenemedi')),
      ),
    );
  }
}



class _SuggestionCluster {
  final StoreModel? nearestActiveStore;
  final List<StoreSuggestionModel> suggestions;
  final double centerLat;
  final double centerLng;

  const _SuggestionCluster({
    required this.suggestions,
    required this.centerLat,
    required this.centerLng,
    this.nearestActiveStore,
  });
}

class _StoreSuggestionsTab extends ConsumerWidget {
  const _StoreSuggestionsTab();

  static const double _clusterRadiusMeters = 20;

  double _distanceInMeters(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371000.0;
    final dLat = (lat2 - lat1) * pi / 180.0;
    final dLon = (lon2 - lon1) * pi / 180.0;
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180.0) *
            cos(lat2 * pi / 180.0) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  List<_SuggestionCluster> _buildClusters(List<StoreSuggestionModel> suggestions, List<StoreModel> activeStores) {
    final clusters = <_SuggestionCluster>[];

    for (final suggestion in suggestions) {
      int matchedIndex = -1;
      for (int i = 0; i < clusters.length; i++) {
        final c = clusters[i];
        final distance = _distanceInMeters(c.centerLat, c.centerLng, suggestion.lat, suggestion.lng);
        if (distance <= _clusterRadiusMeters) {
          matchedIndex = i;
          break;
        }
      }

      if (matchedIndex == -1) {
        clusters.add(_SuggestionCluster(
          suggestions: [suggestion],
          centerLat: suggestion.lat,
          centerLng: suggestion.lng,
        ));
      } else {
        final current = clusters[matchedIndex];
        final merged = [...current.suggestions, suggestion];
        final avgLat = merged.map((e) => e.lat).reduce((a, b) => a + b) / merged.length;
        final avgLng = merged.map((e) => e.lng).reduce((a, b) => a + b) / merged.length;
        clusters[matchedIndex] = _SuggestionCluster(
          suggestions: merged,
          centerLat: avgLat,
          centerLng: avgLng,
        );
      }
    }

    final withNearest = clusters.map((cluster) {
      StoreModel? nearest;
      double min = double.infinity;
      for (final store in activeStores) {
        if (store.lat == 0 || store.lng == 0) continue;
        final d = _distanceInMeters(cluster.centerLat, cluster.centerLng, store.lat, store.lng);
        if (d < min) {
          min = d;
          nearest = store;
        }
      }
      return _SuggestionCluster(
        suggestions: cluster.suggestions,
        centerLat: cluster.centerLat,
        centerLng: cluster.centerLng,
        nearestActiveStore: nearest,
      );
    }).toList();

    withNearest.sort((a, b) => b.suggestions.length.compareTo(a.suggestions.length));
    return withNearest;
  }

  Future<void> _showMergeDialog(BuildContext context, WidgetRef ref, StoreSuggestionModel suggestion, List<StoreModel> activeStores) async {
    if (activeStores.isEmpty) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mevcut Mağaza ile Birleştir'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: activeStores.length,
            itemBuilder: (_, i) {
              final target = activeStores[i];
              return ListTile(
                title: Text(target.displayName),
                subtitle: Text('${target.neighborhood}, ${target.district}'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await ref.read(firestoreServiceProvider).mergeStoreSuggestion(
                        suggestionId: suggestion.id,
                        targetStoreId: target.id,
                      );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestionsAsync = ref.watch(pendingStoreSuggestionsProvider);
    final activeStoresAsync = ref.watch(activeStoresProvider);

    return activeStoresAsync.when(
      data: (activeStores) => suggestionsAsync.when(
        data: (suggestions) {
          if (suggestions.isEmpty) {
            return const Center(child: Text('Bekleyen mağaza önerisi yok'));
          }
          final clusters = _buildClusters(suggestions, activeStores);
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: clusters.length,
            itemBuilder: (_, index) {
              final cluster = clusters[index];
              final first = cluster.suggestions.first;
              return Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${cluster.suggestions.length} önerinin merkezi (±20m)',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Konum: ${cluster.centerLat.toStringAsFixed(5)}, ${cluster.centerLng.toStringAsFixed(5)}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      if (cluster.nearestActiveStore != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'En yakin aktif: ${cluster.nearestActiveStore!.displayName}',
                            style: const TextStyle(fontSize: 12, color: AppColors.info),
                          ),
                        ),
                      const Divider(height: AppSpacing.lg),
                      ...cluster.suggestions.map((s) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(s.displayName),
                            subtitle: Text('${s.neighborhood} ${s.district}'),
                            trailing: Wrap(
                              spacing: 4,
                              children: [
                                TextButton(
                                  onPressed: () => ref.read(firestoreServiceProvider).approveStoreSuggestion(s.id),
                                  child: const Text('Onayla'),
                                ),
                                TextButton(
                                  onPressed: () => _showMergeDialog(context, ref, s, activeStores),
                                  child: const Text('Birlestir'),
                                ),
                                TextButton(
                                  onPressed: () => ref.read(firestoreServiceProvider).rejectStoreSuggestion(s.id),
                                  child: const Text('Reddet'),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Mağaza önerileri yüklenemedi')),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Mağazalar yüklenemedi')),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 3: Kategori Yönetimi
// ---------------------------------------------------------------------------
class _CategoryManagementTab extends ConsumerWidget {
  const _CategoryManagementTab();


  Color _categoryColor(int index) {
    final colors = [AppColors.primary, AppColors.secondary, AppColors.accent, AppColors.info, AppColors.error, const Color(0xFF8B5CF6), const Color(0xFFEC4899), const Color(0xFF14B8A6), const Color(0xFFF97316), const Color(0xFF6366F1)];
    return colors[index % colors.length];
  }

  void _showAddCategoryDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final orderController = TextEditingController();
    final iconNameController = TextEditingController(text: 'category');
    File? selectedImage;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
          title: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(AppRadius.sm)),
              child: const Icon(Icons.category_outlined, color: AppColors.accent, size: 20),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Text('Yeni Kategori Ekle'),
          ]),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Kategori Adı', prefixIcon: Icon(Icons.label_outline)),
                  autofocus: true,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: orderController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Sira (opsiyonel)', prefixIcon: Icon(Icons.format_list_numbered_outlined)),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: iconNameController,
                  decoration: const InputDecoration(
                    labelText: 'Material icon adı',
                    hintText: 'Örn: fastfood, local_mall, sports_soccer',
                    prefixIcon: Icon(Icons.emoji_symbols_outlined),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, imageQuality: 80);
                    if (picked != null) {
                      setDialogState(() => selectedImage = File(picked.path));
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.outline),
                    ),
                    child: selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            child: Image.file(selectedImage!, fit: BoxFit.cover),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined, size: 32, color: AppColors.textSecondary),
                              SizedBox(height: 4),
                              Text('Kategori Görseli Yukle', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                  ),
                ),
                if (isUploading) ...[
                  const SizedBox(height: AppSpacing.sm),
                  const LinearProgressIndicator(),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: isUploading ? null : () => Navigator.pop(ctx), child: const Text('Iptal')),
            ElevatedButton(
              onPressed: isUploading ? null : () async {
                if (nameController.text.trim().isEmpty) return;
                setDialogState(() => isUploading = true);
                try {
                  final orderValue = int.tryParse(orderController.text.trim());
                  final categoryId = await ref.read(adminCategoryManagementDomainServiceProvider).addCategory(
                    nameController.text.trim(),
                    iconNameController.text.trim().isEmpty ? 'category' : iconNameController.text.trim(),
                    isActive: true,
                    order: orderValue,
                  );

                  if (selectedImage != null) {
                    final storageService = StorageService();
                    final result = await storageService.uploadCategoryImage(file: selectedImage!, categoryId: categoryId);
                    await ref.read(adminCategoryManagementDomainServiceProvider).updateCategory(categoryId, {
                      'imageUrl': result.downloadUrl,
                      'imagePath': result.storagePath,
                    });
                  }

                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  setDialogState(() => isUploading = false);
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('Hata: $e'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
                    );
                  }
                }
              },
              child: isUploading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Ekle'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCategoryDialog(BuildContext context, WidgetRef ref, CategoryModel cat) {
    final nameController = TextEditingController(text: cat.name);
    final orderController = TextEditingController(text: cat.order?.toString() ?? '');
    final iconNameController = TextEditingController(text: cat.iconName);
    bool isActive = cat.isActive;
    File? selectedImage;
    bool isUploading = false;
    final currentImageUrl = cat.imageUrl;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
          title: Text('${cat.name} - Kategori Düzenle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Kategori Adı', prefixIcon: Icon(Icons.label_outline)),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: orderController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Sira (opsiyonel)', prefixIcon: Icon(Icons.format_list_numbered_outlined)),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: iconNameController,
                  decoration: const InputDecoration(
                    labelText: 'Material icon adı',
                    hintText: 'Örn: fastfood, local_mall, sports_soccer',
                    prefixIcon: Icon(Icons.emoji_symbols_outlined),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Aktif kategori'),
                  value: isActive,
                  onChanged: (value) => setDialogState(() => isActive = value),
                ),
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, imageQuality: 80);
                    if (picked != null) {
                      setDialogState(() => selectedImage = File(picked.path));
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.outline),
                    ),
                    child: selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            child: Image.file(selectedImage!, fit: BoxFit.cover),
                          )
                        : currentImageUrl != null && currentImageUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                child: Image.network(currentImageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 32)),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_outlined, size: 32, color: AppColors.textSecondary),
                                  SizedBox(height: 4),
                                  Text('Görsel Sec', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                ],
                              ),
                  ),
                ),
                if (isUploading) ...[
                  const SizedBox(height: AppSpacing.sm),
                  const LinearProgressIndicator(),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: isUploading ? null : () => Navigator.pop(ctx), child: const Text('Iptal')),
            ElevatedButton(
              onPressed: isUploading ? null : () async {
                if (nameController.text.trim().isEmpty) return;
                setDialogState(() => isUploading = true);
                try {
                  final storageService = StorageService();
                  String? imageUrl = cat.imageUrl;
                  String? imagePath = cat.imagePath;

                  if (selectedImage != null) {
                    final oldPath = cat.imagePath;
                    if (oldPath != null && oldPath.isNotEmpty) {
                      await storageService.deleteByPath(oldPath);
                    }
                    final result = await storageService.uploadCategoryImage(file: selectedImage!, categoryId: cat.id);
                    imageUrl = result.downloadUrl;
                    imagePath = result.storagePath;
                  }

                  await ref.read(adminCategoryManagementDomainServiceProvider).updateCategory(cat.id, {
                    'name': nameController.text.trim(),
                    'isActive': isActive,
                    'order': int.tryParse(orderController.text.trim()),
                    'iconName': iconNameController.text.trim().isEmpty ? 'category' : iconNameController.text.trim(),
                    'imageUrl': imageUrl,
                    'imagePath': imagePath,
                  });

                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Kategori güncellendi'), behavior: SnackBarBehavior.floating),
                    );
                  }
                } catch (e) {
                  setDialogState(() => isUploading = false);
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('Hata: $e'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
                    );
                  }
                }
              },
              child: isUploading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Güncelle'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final productsAsync = ref.watch(allProductsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_category',
        onPressed: () => _showAddCategoryDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Kategori Ekle'),
      ),
      body: categoriesAsync.when(
        data: (categories) {
          final products = productsAsync.valueOrNull ?? [];
          if (categories.isEmpty) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.category_outlined, size: 64, color: theme.hintColor),
              const SizedBox(height: AppSpacing.md),
              Text('Henüz kategori yok', style: TextStyle(color: theme.hintColor, fontSize: 16)),
            ]));
          }
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 80),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: AppSpacing.sm, mainAxisSpacing: AppSpacing.sm, childAspectRatio: 1.1),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              final catName = cat.name;
              final color = _categoryColor(index);
              final productCount = products.where((p) => p.categories.contains(catName)).length;
              return Card(
                child: Stack(children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Icon(materialIconFromName(cat.iconName), color: color, size: 24),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(catName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text('$productCount ürün', style: TextStyle(fontSize: 12, color: theme.hintColor)),
                    ]),
                  ),
                  Positioned(
                    top: 4, right: 30,
                    child: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(AppRadius.xs)),
                        child: const Icon(Icons.image_outlined, color: AppColors.primary, size: 14),
                      ),
                      iconSize: 22,
                      onPressed: () => _showEditCategoryDialog(context, ref, cat),
                    ),
                  ),
                  Positioned(
                    top: 4, right: 4,
                    child: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(AppRadius.xs)),
                        child: const Icon(Icons.close, color: AppColors.error, size: 14),
                      ),
                      iconSize: 22,
                      onPressed: () async {
                        final storageService = StorageService();
                        final oldPath = cat.imagePath;
                        if (oldPath != null && oldPath.isNotEmpty) {
                          await storageService.deleteByPath(oldPath);
                        }
                        ref.read(adminCategoryManagementDomainServiceProvider).deleteCategory(cat.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('$catName silindi'), behavior: SnackBarBehavior.floating),
                          );
                        }
                      },
                    ),
                  ),
                ]),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Kategoriler yüklenemedi')),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 4: Banner Yönetimi
// ---------------------------------------------------------------------------
class _BannerManagementTab extends ConsumerWidget {
  const _BannerManagementTab();

  void _showBannerDialog(BuildContext context, WidgetRef ref, {BannerModel? banner}) {
    final titleController = TextEditingController(text: banner?.title ?? '');
    final descriptionController = TextEditingController(text: banner?.description ?? '');
    final imageUrlController = TextEditingController(text: banner?.imageUrl ?? '');
    final ctaController = TextEditingController(text: banner?.ctaText ?? 'Keşfet');

    String selectedTargetType = 'campaign';
    String? selectedCampaignId = banner?.targetId;

    showDialog(
      context: context,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final campaignsAsync = ref.watch(activeCampaignsProvider);
          return StatefulBuilder(
            builder: (context, setModalState) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
              title: Text(banner == null ? 'Yeni Banner Ekle' : 'Banner Düzenle'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Baslik')),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Açıklama')),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(controller: imageUrlController, decoration: const InputDecoration(labelText: 'Resim URL')),
                    const SizedBox(height: AppSpacing.sm),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: AspectRatio(
                        aspectRatio: 16 / 7,
                        child: imageUrlController.text.trim().isEmpty
                            ? Container(color: AppColors.surfaceVariant)
                            : Image.network(
                                imageUrlController.text.trim(),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(color: AppColors.surfaceVariant),
                              ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(controller: ctaController, decoration: const InputDecoration(labelText: 'CTA Text')),
                    const SizedBox(height: AppSpacing.sm),
                    const ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.ads_click_outlined),
                      title: Text('Hedef Türü: campaign'),
                    ),
                    TextFormField(
                      initialValue: selectedCampaignId ?? '',
                      decoration: const InputDecoration(
                        labelText: 'Hedef ID (opsiyonel kampanyaId)',
                        helperText: 'Boş bırakılırsa kampanyalar listesi açılır. Doluysa ilgili kampanya açılır.',
                      ),
                      onChanged: (value) => selectedCampaignId = value.trim().isEmpty ? null : value.trim(),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    campaignsAsync.when(
                      data: (campaigns) => Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: campaigns
                              .take(8)
                              .map((c) => ActionChip(
                                    label: Text(c.title, overflow: TextOverflow.ellipsis),
                                    onPressed: () => setModalState(() => selectedCampaignId = c.id),
                                  ))
                              .toList(),
                        ),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Iptal')),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.trim().isEmpty) return;

                    final payload = {
                      'title': titleController.text.trim(),
                      'description': descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
                      'imageUrl': imageUrlController.text.trim(),
                      'ctaText': ctaController.text.trim().isEmpty ? 'Keşfet' : ctaController.text.trim(),
                      'targetType': selectedTargetType,
                      'targetId': selectedTargetType == 'campaign' ? selectedCampaignId : null,
                      'isActive': banner?.isActive ?? true,
                      'order': banner?.order ?? 0,
                      'aspectRatio': 'wide',
                    };

                    if (banner == null) {
                      final model = BannerModel(
                        id: '',
                        title: payload['title']! as String,
                        description: payload['description'] as String?,
                        imageUrl: payload['imageUrl']! as String,
                        targetType: payload['targetType']! as String,
                        targetId: payload['targetId'] as String?,
                        ctaText: payload['ctaText']! as String,
                        aspectRatio: 'wide',
                        isActive: true,
                        createdAt: DateTime.now(),
                      );
                      await ref.read(adminBannerManagementDomainServiceProvider).addBanner(model);
                    } else {
                      await ref.read(adminBannerManagementDomainServiceProvider).updateBanner(banner.id, payload);
                    }

                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Kaydet'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bannersAsync = ref.watch(allBannersProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_banner',
        onPressed: () => _showBannerDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Banner Ekle'),
      ),
      body: bannersAsync.when(
        data: (banners) {
          if (banners.isEmpty) return const Center(child: Text('Henüz banner yok'));
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 80),
            itemCount: banners.length,
            itemBuilder: (context, index) {
              final banner = banners[index];
              return Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                child: ListTile(
                  onTap: () => _showBannerDialog(context, ref, banner: banner),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: SizedBox(
                      width: 84,
                      height: 48,
                      child: banner.imageUrl.isNotEmpty
                          ? Image.network(banner.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image_outlined))
                          : const Icon(Icons.image_not_supported_outlined),
                    ),
                  ),
                  title: Text(banner.title),
                  subtitle: Text('${banner.targetType ?? 'none'} • ${banner.targetId ?? '-'}'),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        icon: Icon(banner.isActive ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                        onPressed: () => ref.read(bannerNotifierProvider.notifier).toggleBannerActive(banner.id, !banner.isActive),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _showBannerDialog(context, ref, banner: banner),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.error),
                        onPressed: () => ref.read(bannerNotifierProvider.notifier).deleteBanner(banner.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Bannerlar yüklenemedi')),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 5: Kampanya Yönetimi
// ---------------------------------------------------------------------------
class _CampaignManagementTab extends ConsumerWidget {
  const _CampaignManagementTab();

  void _showCampaignDialog(BuildContext context, WidgetRef ref, List<ProductModel> allProducts, {CampaignBasketModel? campaign}) {
    final titleController = TextEditingController(text: campaign?.title ?? '');
    final descriptionController = TextEditingController(text: campaign?.description ?? '');
    final imageUrlController = TextEditingController(text: campaign?.imageUrl ?? '');
    bool isActive = campaign?.isActive ?? true;
    final selectedIds = <String>{...campaign?.itemProductIds ?? const []};
    String search = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final filtered = allProducts.where((p) {
            if (search.trim().isEmpty) return true;
            final q = search.toLowerCase();
            return p.name.toLowerCase().contains(q) ||
                p.brand.toLowerCase().contains(q) ||
                (p.barcode?.contains(search) ?? false);
          }).take(30).toList();

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
            title: Text(campaign == null ? 'Kampanya Ekle' : 'Kampanya Düzenle'),
            content: SizedBox(
              width: 560,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Baslik')),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Açıklama')),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(controller: imageUrlController, decoration: const InputDecoration(labelText: 'Görsel URL')),
                    const SizedBox(height: AppSpacing.sm),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: isActive,
                      onChanged: (v) => setModalState(() => isActive = v),
                      title: const Text('Aktif'),
                    ),
                    TextField(
                      decoration: const InputDecoration(labelText: 'Ürün ara (isim/marka/barkod)'),
                      onChanged: (v) => setModalState(() => search = v),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: selectedIds
                          .map((id) {
                            for (final product in allProducts) {
                              if (product.id == id) return product;
                            }
                            return null;
                          })
                          .whereType<ProductModel>()
                          .map((p) => InputChip(
                                label: Text(p.name, overflow: TextOverflow.ellipsis),
                                onDeleted: () => setModalState(() => selectedIds.remove(p.id)),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      height: 220,
                      child: ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final p = filtered[i];
                          final isSelected = selectedIds.contains(p.id);
                          return ListTile(
                            dense: true,
                            title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text(p.brand),
                            trailing: Icon(isSelected ? Icons.check_circle : Icons.add_circle_outline),
                            onTap: () => setModalState(() {
                              if (isSelected) {
                                selectedIds.remove(p.id);
                              } else {
                                selectedIds.add(p.id);
                              }
                            }),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Iptal')),
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.trim().isEmpty) return;
                  final data = {
                    'title': titleController.text.trim(),
                    'description': descriptionController.text.trim(),
                    'imageUrl': imageUrlController.text.trim().isEmpty ? null : imageUrlController.text.trim(),
                    'isActive': isActive,
                    'itemProductIds': selectedIds.toList(),
                  };

                  if (campaign == null) {
                    await ref.read(adminCampaignManagementDomainServiceProvider).addCampaign(
                          CampaignBasketModel(
                            id: '',
                            title: titleController.text.trim(),
                            description: descriptionController.text.trim(),
                            imageUrl: imageUrlController.text.trim().isEmpty ? null : imageUrlController.text.trim(),
                            isActive: isActive,
                            itemProductIds: selectedIds.toList(),
                            createdAt: DateTime.now(),
                            updatedAt: DateTime.now(),
                          ),
                        );
                  } else {
                    await ref.read(adminCampaignManagementDomainServiceProvider).updateCampaign(campaign.id, data);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Kaydet'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaignsAsync = ref.watch(allCampaignsProvider);
    final productsAsync = ref.watch(allProductsProvider);

    return Scaffold(
      floatingActionButton: productsAsync.valueOrNull == null
          ? null
          : FloatingActionButton.extended(
              heroTag: 'fab_campaign',
              onPressed: () => _showCampaignDialog(context, ref, productsAsync.valueOrNull ?? const []),
              icon: const Icon(Icons.add),
              label: const Text('Kampanya Ekle'),
            ),
      body: campaignsAsync.when(
        data: (campaigns) {
          if (campaigns.isEmpty) return const Center(child: Text('Kampanya bulunamadı'));
          final products = productsAsync.valueOrNull ?? const <ProductModel>[];
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 90),
            itemCount: campaigns.length,
            itemBuilder: (context, index) {
              final c = campaigns[index];
              return Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: SizedBox(
                        width: 90,
                        child: c.imageUrl != null && c.imageUrl!.isNotEmpty
                            ? Image.network(c.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.campaign_outlined))
                            : Container(color: AppColors.surfaceVariant, child: const Icon(Icons.campaign_outlined)),
                      ),
                    ),
                  ),
                  title: Text(c.title),
                  subtitle: Text('${c.itemProductIds.length} ürün'),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      Chip(label: Text(c.isActive ? 'Aktif' : 'Pasif')),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _showCampaignDialog(context, ref, products, campaign: c),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.error),
                        onPressed: () => ref.read(adminCampaignManagementDomainServiceProvider).deleteCampaign(c.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Kampanyalar yüklenemedi')),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.outline,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
