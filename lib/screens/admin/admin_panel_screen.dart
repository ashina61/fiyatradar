import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../utils/theme.dart';
import '../../models/product_model.dart';
import '../../models/brand_model.dart';
import '../../models/store_model.dart';
import 'report_detail_screen.dart';
import '../../models/banner_model.dart';
import '../../providers/product_provider.dart';
import '../../providers/banner_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/storage_service.dart';

import '../../widgets/barcode_scanner_sheet.dart';

class AdminPanelScreen extends ConsumerStatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  ConsumerState<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends ConsumerState<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
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
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: Theme.of(context).textTheme.bodyLarge?.color,
          unselectedLabelColor: Theme.of(context).hintColor,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: 'Urunler', icon: Icon(Icons.inventory_2_outlined)),
            Tab(text: 'Magazalar', icon: Icon(Icons.storefront_outlined)),
            Tab(text: 'Kategoriler', icon: Icon(Icons.category_outlined)),
            Tab(text: 'Bannerlar', icon: Icon(Icons.view_carousel_outlined)),
            Tab(text: 'Raporlar', icon: Icon(Icons.flag_outlined)),
            Tab(text: 'Kullanicilar', icon: Icon(Icons.people_outlined)),
            Tab(text: 'Istatistikler', icon: Icon(Icons.bar_chart_outlined)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ProductManagementTab(),
          _StoreHubTab(),
          _CategoryManagementTab(),
          _BannerManagementTab(),
          _ReportsManagementTab(),
          _UserManagementTab(),
          _StatisticsTab(),
        ],
      ),
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
    _tabController = TabController(length: 3, vsync: this);
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
              Tab(text: 'Zincirler'),
              Tab(text: 'Subeler'),
              Tab(text: 'Oneriler'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              _BrandManagementTab(),
              _StoreManagementTab(initialFilter: 'active'),
              _StoreManagementTab(initialFilter: 'pending'),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 1: Urun Yonetimi
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
      final response = await http
          .get(
            uri,
            headers: const {
              'User-Agent': 'FiyatRadar/1.0 (admin-panel)',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 7));

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

  void _showAddProductDialog(BuildContext context, WidgetRef ref, List<Map<String, dynamic>> categories) {
    final nameController = TextEditingController();
    final brandController = TextEditingController();
    final barcodeController = TextEditingController();
    final descriptionController = TextEditingController();
    String? selectedCategory;
    final List<File> selectedImages = [];
    final picker = ImagePicker();
    bool isUploading = false;
    String? uploadError;
    Timer? barcodeDebounce;
    bool isFetchingBarcode = false;
    String? barcodeHint;
    String? openFoodFactsImageUrl;

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
              barcodeHint = 'Barkoddan urun bilgisi aliniyor...';
            });

            final result = await _openFoodFactsService.fetchByBarcode(barcode);
            if (!ctx.mounted) return;

            setDialogState(() {
              isFetchingBarcode = false;
              if (result == null) {
                barcodeHint = 'Urun bulunamadi, manuel ekleyebilirsiniz';
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
                  ? 'Gorsel bulunamadi / Manuel ekle'
                  : 'OpenFoodFacts gorseli bulundu';
            });
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
            const Text('Yeni Urun Ekle'),
          ]),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Urun Adi', prefixIcon: Icon(Icons.label_outline)),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Aciklama (Opsiyonel)', prefixIcon: Icon(Icons.description_outlined)),
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
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(labelText: 'Kategori', prefixIcon: Icon(Icons.category_outlined)),
                items: categories.map((c) => DropdownMenuItem(value: c['name'] as String, child: Text(c['name'] as String))).toList(),
                onChanged: (val) => setDialogState(() => selectedCategory = val),
              ),
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Urun Gorselleri',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final images = await picker.pickMultiImage(imageQuality: 85);
                        if (images.isNotEmpty) {
                          setDialogState(() {
                            selectedImages.addAll(images.map((e) => File(e.path)));
                          });
                        }
                      },
                      icon: const Icon(Icons.photo_library_outlined, size: 18),
                      label: const Text('Galeriden Sec'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final image = await picker.pickImage(
                          source: ImageSource.camera,
                          imageQuality: 85,
                        );
                        if (image != null) {
                          setDialogState(() {
                            selectedImages.add(File(image.path));
                          });
                        }
                      },
                      icon: const Icon(Icons.camera_alt_outlined, size: 18),
                      label: const Text('Kamera'),
                    ),
                  ),
                ],
              ),
              if (selectedImages.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  height: 70,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      final file = selectedImages[index];
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            child: Image.file(
                              file,
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            right: 2,
                            top: 2,
                            child: GestureDetector(
                              onTap: () {
                                setDialogState(() => selectedImages.removeAt(index));
                              },
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                    itemCount: selectedImages.length,
                  ),
                ),
              ],
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
                      color: barcodeHint!.contains('bulunamadi') || barcodeHint!.contains('Manuel')
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
                      child: const Text('Gorsel bulunamadi / Manuel ekle'),
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
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || selectedCategory == null || isUploading) return;
                setDialogState(() {
                  isUploading = true;
                  uploadError = null;
                });
                try {
                  final service = ref.read(firestoreServiceProvider);
                  final productId = await service.addProduct(ProductModel(
                    id: '',
                    name: nameController.text,
                    brand: brandController.text.isEmpty ? 'Genel' : brandController.text,
                    category: selectedCategory!,
                    barcode: barcodeController.text.isEmpty ? null : barcodeController.text,
                    description: descriptionController.text.isEmpty
                        ? null
                        : descriptionController.text,
                    imageUrls: openFoodFactsImageUrl != null ? [openFoodFactsImageUrl!] : const [],
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ));

                  final List<String> imageUrls = [];
                  if (selectedImages.isNotEmpty) {
                    final storageService = StorageService();
                    final urls = await storageService.uploadMultipleImages(
                      files: selectedImages,
                      folder: 'products/$productId',
                    );
                    imageUrls.addAll(urls);
                  }

                  final allImageUrls = <String>[];
                  if (openFoodFactsImageUrl != null) {
                    allImageUrls.add(openFoodFactsImageUrl!);
                  }
                  allImageUrls.addAll(imageUrls);

                  await service.updateProduct(productId, {
                    if (allImageUrls.isNotEmpty) 'imageUrls': allImageUrls,
                    if (allImageUrls.isNotEmpty) 'mainImage': allImageUrls.first,
                    'updatedAt': DateTime.now(),
                  });

                  barcodeDebounce?.cancel();
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  setDialogState(() {
                    uploadError = 'Yukleme basarisiz: $e';
                  });
                } finally {
                  setDialogState(() => isUploading = false);
                }
              },
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(allProductsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_product',
        onPressed: () => _showAddProductDialog(context, ref, categoriesAsync.valueOrNull ?? []),
        icon: const Icon(Icons.add),
        label: const Text('Urun Ekle'),
      ),
      body: productsAsync.when(
        data: (products) {
          if (products.isEmpty) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.inventory_2_outlined, size: 64, color: theme.hintColor),
              const SizedBox(height: AppSpacing.md),
              Text('Henuz urun yok', style: TextStyle(color: theme.hintColor, fontSize: 16)),
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
                          _InfoChip(icon: Icons.category_outlined, label: product.category),
                          const SizedBox(width: AppSpacing.xs),
                          if (product.lastStore != null) _InfoChip(icon: Icons.store_outlined, label: product.lastStore!),
                        ]),
                      ])),
                      Icon(Icons.chevron_left, color: theme.hintColor, size: 20),
                    ]),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Urunler yuklenemedi')),
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
// Tab 2: Zincir (Brand) Yonetimi
// ---------------------------------------------------------------------------
class _BrandManagementTab extends ConsumerWidget {
  const _BrandManagementTab();

  void _showAddBrandDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    BrandType selectedType = BrandType.chain;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
          title: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(AppRadius.sm)),
              child: const Icon(Icons.business_outlined, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Text('Yeni Zincir Ekle'),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Zincir Adi', hintText: 'Orn: A-101, BIM, Migros', prefixIcon: Icon(Icons.business)),
                autofocus: true,
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<BrandType>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'Tur', prefixIcon: Icon(Icons.category_outlined)),
                items: const [
                  DropdownMenuItem(value: BrandType.chain, child: Text('Zincir')),
                  DropdownMenuItem(value: BrandType.online, child: Text('Online')),
                  DropdownMenuItem(value: BrandType.local, child: Text('Yerel')),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedType = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Iptal')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) return;
                final brand = BrandModel(
                  id: '',
                  name: nameController.text.trim(),
                  type: selectedType,
                  createdAt: DateTime.now(),
                );
                await ref.read(firestoreServiceProvider).addBrand(brand);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Ekle'),
            ),
          ],
        ),
      ),
    );
  }

  Color _typeColor(BrandType type) {
    switch (type) {
      case BrandType.chain: return AppColors.primary;
      case BrandType.online: return AppColors.info;
      case BrandType.local: return AppColors.accent;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brandsAsync = ref.watch(allBrandsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_brand',
        onPressed: () => _showAddBrandDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Zincir Ekle'),
      ),
      body: brandsAsync.when(
        data: (brands) {
          if (brands.isEmpty) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.business_outlined, size: 64, color: theme.hintColor),
              const SizedBox(height: AppSpacing.md),
              Text('Henuz zincir yok', style: TextStyle(color: theme.hintColor, fontSize: 16)),
            ]));
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 80),
            itemCount: brands.length,
            itemBuilder: (context, index) {
              final brand = brands[index];
              final color = _typeColor(brand.type);
              return Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  leading: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(AppRadius.md)),
                    child: Icon(Icons.business, color: color, size: 22),
                  ),
                  title: Text(brand.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  subtitle: Container(
                    margin: const EdgeInsets.only(top: 4),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(AppRadius.xs)),
                        child: Text(brand.typeLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
                      ),
                    ]),
                  ),
                  trailing: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(AppRadius.sm)),
                      child: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                    ),
                    onPressed: () {
                      ref.read(firestoreServiceProvider).deleteBrand(brand.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${brand.name} silindi'), behavior: SnackBarBehavior.floating),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Zincirler yuklenemedi')),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 3: Sube (Store) Yonetimi
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

    final brands = ref.read(allBrandsProvider).valueOrNull ?? [];

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final canSave =
              nameController.text.trim().isNotEmpty && selectedLat != null && selectedLng != null;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
            title: Text(isEdit ? 'Sube Duzenle' : 'Yeni Sube Ekle'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedBrandId,
                    decoration: const InputDecoration(labelText: 'Zincir (opsiyonel)', prefixIcon: Icon(Icons.business)),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Yerel / Bagimsiz')),
                      ...brands.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))),
                    ],
                    onChanged: (val) => setDialogState(() => selectedBrandId = val),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Goruntuleme Adi', prefixIcon: Icon(Icons.store_outlined)),
                    onChanged: (_) => setDialogState(() {}),
                  ),
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
                          'city': cityController.text.trim(),
                          'district': districtController.text.trim(),
                          'neighborhood': neighborhoodController.text.trim(),
                          'lat': selectedLat,
                          'lng': selectedLng,
                          'status': store?.status.name ?? StoreStatus.active.name,
                        };
                        if (isEdit) {
                          await ref.read(firestoreServiceProvider).updateStore(store!.id, payload);
                        } else {
                          await ref.read(firestoreServiceProvider).addStore(
                            StoreModel(
                              id: '',
                              brandId: selectedBrandId,
                              displayName: nameController.text.trim(),
                              city: cityController.text.trim(),
                              district: districtController.text.trim(),
                              neighborhood: neighborhoodController.text.trim(),
                              lat: selectedLat!,
                              lng: selectedLng!,
                              status: StoreStatus.active,
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
    LatLng marker = LatLng(initialLat ?? 41.0082, initialLng ?? 28.9784);
    String city = '';
    String district = '';
    String neighborhood = '';
    bool isResolving = false;

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
            setModalState(() => isResolving = false);
          }

          return SafeArea(
            child: SizedBox(
              height: MediaQuery.of(ctx).size.height * 0.82,
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
                  Expanded(
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: marker,
                        initialZoom: 14,
                        onTap: (_, latLng) async {
                          setModalState(() => marker = latLng);
                          await resolveAddress();
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
                  ListTile(
                    title: Text('Lat/Lng: ${marker.latitude.toStringAsFixed(5)}, ${marker.longitude.toStringAsFixed(5)}'),
                    subtitle: Text(isResolving ? 'Adres cozuluyor...' : '$neighborhood / $district / $city'),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(
                            ctx,
                            _StoreLocationDraft(
                              lat: marker.latitude,
                              lng: marker.longitude,
                              city: city,
                              district: district,
                              neighborhood: neighborhood,
                            ),
                          );
                        },
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
    );
  }

  void _showMergeDialog(BuildContext context, WidgetRef ref, StoreModel source, List<StoreModel> allStores) {
    final targets = allStores.where((s) => s.id != source.id && s.status == StoreStatus.active).toList();
    if (targets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Birlestirmek icin aktif baska magaza yok'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: const Text('Magazayi Birlestir'),
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
        label: const Text('Sube Ekle'),
      ),
      body: storesAsync.when(
        data: (stores) {
          if (stores.isEmpty) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.store_outlined, size: 64, color: theme.hintColor),
              const SizedBox(height: AppSpacing.md),
              Text('Henuz sube yok', style: TextStyle(color: theme.hintColor, fontSize: 16)),
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
                                    const SnackBar(content: Text('Sube onaylandi'), behavior: SnackBarBehavior.floating),
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
                            label: const Text('Duzenle', style: TextStyle(fontSize: 12)),
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
        error: (_, __) => const Center(child: Text('Subeler yuklenemedi')),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 3: Kategori Yonetimi
// ---------------------------------------------------------------------------
class _CategoryManagementTab extends ConsumerWidget {
  const _CategoryManagementTab();

  IconData _categoryIcon(String name) {
    switch (name) {
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

  Color _categoryColor(int index) {
    final colors = [AppColors.primary, AppColors.secondary, AppColors.accent, AppColors.info, AppColors.error, const Color(0xFF8B5CF6), const Color(0xFFEC4899), const Color(0xFF14B8A6), const Color(0xFFF97316), const Color(0xFF6366F1)];
    return colors[index % colors.length];
  }

  void _showAddCategoryDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
        content: TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Kategori Adi', prefixIcon: Icon(Icons.label_outline)), autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Iptal')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) return;
              await ref.read(firestoreServiceProvider).addCategory(nameController.text, 'category');
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Ekle'),
          ),
        ],
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
              Text('Henuz kategori yok', style: TextStyle(color: theme.hintColor, fontSize: 16)),
            ]));
          }
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 80),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: AppSpacing.sm, mainAxisSpacing: AppSpacing.sm, childAspectRatio: 1.1),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              final catName = cat['name'] ?? '';
              final color = _categoryColor(index);
              final productCount = products.where((p) => p.category == catName).length;

              return Card(
                child: Stack(children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(AppRadius.md)),
                        child: Icon(_categoryIcon(catName), color: color, size: 24),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(catName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text('$productCount urun', style: TextStyle(fontSize: 12, color: theme.hintColor)),
                    ]),
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
                      onPressed: () {
                        ref.read(firestoreServiceProvider).deleteCategory(cat['id']);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$catName silindi'), behavior: SnackBarBehavior.floating),
                        );
                      },
                    ),
                  ),
                ]),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Kategoriler yuklenemedi')),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 4: Banner Yonetimi
// ---------------------------------------------------------------------------
class _BannerManagementTab extends ConsumerWidget {
  const _BannerManagementTab();

  void _showAddBannerDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final imageUrlController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(AppRadius.sm)),
            child: const Icon(Icons.view_carousel_outlined, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Text('Yeni Banner Ekle'),
        ]),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Baslik', prefixIcon: Icon(Icons.title))),
            const SizedBox(height: AppSpacing.md),
            TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Aciklama', prefixIcon: Icon(Icons.subtitles_outlined))),
            const SizedBox(height: AppSpacing.md),
            TextField(controller: imageUrlController, decoration: const InputDecoration(labelText: 'Resim URL (opsiyonel)', prefixIcon: Icon(Icons.image_outlined), hintText: 'https://...')),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Iptal')),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isEmpty) return;
              final banner = BannerModel(
                id: '',
                title: titleController.text,
                description: descriptionController.text.isEmpty ? null : descriptionController.text,
                imageUrl: imageUrlController.text.isEmpty ? '' : imageUrlController.text,
                isActive: true,
                createdAt: DateTime.now(),
              );
              await ref.read(firestoreServiceProvider).addBanner(banner);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bannersAsync = ref.watch(allBannersProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_banner',
        onPressed: () => _showAddBannerDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Banner Ekle'),
      ),
      body: bannersAsync.when(
        data: (banners) {
          if (banners.isEmpty) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.view_carousel_outlined, size: 64, color: theme.hintColor),
              const SizedBox(height: AppSpacing.md),
              Text('Henuz banner yok', style: TextStyle(color: theme.hintColor, fontSize: 16)),
            ]));
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 80),
            itemCount: banners.length,
            itemBuilder: (context, index) {
              final banner = banners[index];
              return Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Column(children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AppColors.primary, AppColors.primary.withOpacity(0.75)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
                      image: banner.imageUrl.isNotEmpty ? DecorationImage(
                        image: NetworkImage(banner.imageUrl),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(AppColors.primary.withOpacity(0.3), BlendMode.darken),
                        onError: (_, __) {},
                      ) : null,
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      if (!banner.isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                          decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(AppRadius.xs)),
                          child: const Text('PASIF', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      Text(banner.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, shadows: [Shadow(blurRadius: 4, color: Colors.black38)])),
                      if (banner.description != null && banner.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(banner.description!, style: const TextStyle(color: Colors.white70, fontSize: 13, shadows: [Shadow(blurRadius: 4, color: Colors.black38)])),
                      ],
                    ]),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppRadius.lg)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                    child: Row(children: [
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () {
                          ref.read(bannerNotifierProvider.notifier).toggleBannerActive(banner.id, !banner.isActive);
                        },
                        icon: Icon(banner.isActive ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                        label: Text(banner.isActive ? 'Gizle' : 'Goster'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                        onPressed: () {
                          ref.read(bannerNotifierProvider.notifier).deleteBanner(banner.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: const Text('Banner silindi'), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm))),
                          );
                        },
                      ),
                    ]),
                  ),
                ]),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Bannerlar yuklenemedi')),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 5: Rapor Yonetimi
// ---------------------------------------------------------------------------
class _ReportsManagementTab extends ConsumerStatefulWidget {
  final String? initialFilter;

  const _ReportsManagementTab({this.initialFilter});

  @override
  ConsumerState<_ReportsManagementTab> createState() =>
      _ReportsManagementTabState();
}

class _ReportsManagementTabState extends ConsumerState<_ReportsManagementTab> {
  late String _statusFilter;

  @override
  void initState() {
    super.initState();
    _statusFilter = widget.initialFilter ?? 'all';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending': return AppColors.accent;
      case 'resolved': return AppColors.success;
      case 'rejected': return AppColors.error;
      default: return AppColors.info;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending': return 'Bekliyor';
      case 'resolved': return 'Cozuldu';
      case 'rejected': return 'Reddedildi';
      default: return status;
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'priceEntry': return 'Fiyat';
      case 'comment': return 'Yorum';
      case 'product': return 'Urun';
      case 'user': return 'Kullanici';
      case 'other': return 'Diger';
      default: return type;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'priceEntry': return Icons.price_change_outlined;
      case 'comment': return Icons.comment_outlined;
      case 'product': return Icons.inventory_2_outlined;
      case 'user': return Icons.person_outline;
      default: return Icons.flag_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(reportsProvider);
    final theme = Theme.of(context);

    return reportsAsync.when(
      data: (reports) {
        if (reports.isEmpty) {
          return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.flag_outlined, size: 64, color: theme.hintColor),
            const SizedBox(height: AppSpacing.md),
            Text('Henuz rapor yok', style: TextStyle(color: theme.hintColor, fontSize: 16)),
          ]));
        }
        final filteredReports = _statusFilter == 'all'
            ? reports
            : reports.where((report) => report['status'] == _statusFilter).toList();
        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: filteredReports.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    _StatusChip(
                      label: 'Tumu',
                      selected: _statusFilter == 'all',
                      onTap: () => setState(() => _statusFilter = 'all'),
                    ),
                    _StatusChip(
                      label: 'Bekleyen',
                      selected: _statusFilter == 'pending',
                      onTap: () => setState(() => _statusFilter = 'pending'),
                    ),
                    _StatusChip(
                      label: 'Cozuldu',
                      selected: _statusFilter == 'resolved',
                      onTap: () => setState(() => _statusFilter = 'resolved'),
                    ),
                    _StatusChip(
                      label: 'Reddedildi',
                      selected: _statusFilter == 'rejected',
                      onTap: () => setState(() => _statusFilter = 'rejected'),
                    ),
                  ],
                ),
              );
            }
            final report = filteredReports[index - 1];
            final status = report['status'] as String;
            final type = report['targetType'] as String? ?? '';
            final reason = report['reason'] as String;
            final createdAt = report['createdAt'] as DateTime;

            return Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReportDetailScreen(report: report),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: _statusColor(status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Icon(_typeIcon(type), color: _statusColor(status), size: 20),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: _statusColor(status).withOpacity(0.1), borderRadius: BorderRadius.circular(AppRadius.xs)),
                            child: Text(_typeLabel(type), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _statusColor(status))),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: _statusColor(status).withOpacity(0.15), borderRadius: BorderRadius.circular(AppRadius.xs)),
                            child: Text(_statusLabel(status), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _statusColor(status))),
                          ),
                        ]),
                        const SizedBox(height: 4),
                        Text(reason, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ])),
                    ]),
                    const SizedBox(height: AppSpacing.sm),
                    Row(children: [
                      Icon(Icons.access_time, size: 12, color: theme.hintColor),
                      const SizedBox(width: 4),
                      Text('${createdAt.day}.${createdAt.month}.${createdAt.year}', style: TextStyle(fontSize: 11, color: theme.hintColor)),
                      const Spacer(),
                      if (status == 'pending') ...[
                        SizedBox(
                          height: 30,
                          child: TextButton.icon(
                            onPressed: () {
                              ref.read(firestoreServiceProvider).updateReportStatus(report['id'], 'resolved');
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rapor cozuldu olarak isaretlendi'), behavior: SnackBarBehavior.floating));
                            },
                            icon: const Icon(Icons.check_circle_outline, size: 16),
                            label: const Text('Coz', style: TextStyle(fontSize: 12)),
                            style: TextButton.styleFrom(foregroundColor: AppColors.success, padding: const EdgeInsets.symmetric(horizontal: 8)),
                          ),
                        ),
                        SizedBox(
                          height: 30,
                          child: TextButton.icon(
                            onPressed: () {
                              ref.read(firestoreServiceProvider).updateReportStatus(report['id'], 'rejected');
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rapor reddedildi'), behavior: SnackBarBehavior.floating));
                            },
                            icon: const Icon(Icons.cancel_outlined, size: 16),
                            label: const Text('Reddet', style: TextStyle(fontSize: 12)),
                            style: TextButton.styleFrom(foregroundColor: AppColors.error, padding: const EdgeInsets.symmetric(horizontal: 8)),
                          ),
                        ),
                      ],
                      SizedBox(
                        height: 30,
                        child: IconButton(
                          onPressed: () {
                            ref.read(firestoreServiceProvider).deleteReport(report['id']);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rapor silindi'), behavior: SnackBarBehavior.floating));
                          },
                          icon: const Icon(Icons.delete_outline, size: 18),
                          color: AppColors.error,
                          padding: EdgeInsets.zero,
                          iconSize: 18,
                        ),
                      ),
                    ]),
                  ]),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Raporlar yuklenemedi')),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 6: Kullanici Yonetimi
// ---------------------------------------------------------------------------
class _UserManagementTab extends ConsumerWidget {
  const _UserManagementTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);
    final theme = Theme.of(context);

    return usersAsync.when(
      data: (users) {
        if (users.isEmpty) {
          return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.people_outlined, size: 64, color: theme.hintColor),
            const SizedBox(height: AppSpacing.md),
            Text('Henuz kullanici yok', style: TextStyle(color: theme.hintColor, fontSize: 16)),
          ]));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withOpacity(0.1),
                      image: user.photoUrl != null ? DecorationImage(
                        image: NetworkImage(user.photoUrl!),
                        fit: BoxFit.cover,
                        onError: (_, __) {},
                      ) : null,
                    ),
                    child: user.photoUrl == null ? Center(
                      child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 18)),
                    ) : null,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Flexible(child: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), overflow: TextOverflow.ellipsis)),
                      if (user.isAdmin) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, color: Colors.lightBlueAccent, size: 16),
                      ],
                    ]),
                    const SizedBox(height: 2),
                    Text(user.email, style: TextStyle(fontSize: 12, color: theme.hintColor), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(children: [
                      _InfoChip(icon: Icons.price_change, label: '${user.priceEntries} fiyat'),
                      const SizedBox(width: 4),
                      _InfoChip(icon: Icons.stars, label: '${user.points} puan'),
                      const SizedBox(width: 4),
                      _InfoChip(icon: Icons.verified_outlined, label: '${user.validations} d.'),
                    ]),
                  ])),
                  Switch(
                    value: user.isAdmin,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      ref.read(userNotifierProvider.notifier).toggleUserAdmin(user.uid, val);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(val ? '${user.name} admin yapildi' : '${user.name} admin kaldirildi'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ]),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Kullanicilar yuklenemedi')),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 7: Istatistikler
// ---------------------------------------------------------------------------
class _StatisticsTab extends ConsumerWidget {
  const _StatisticsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final productsAsync = ref.watch(allProductsProvider);
    final storesAsync = ref.watch(allStoresStreamProvider);
    final brandsAsync = ref.watch(allBrandsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final bannersAsync = ref.watch(allBannersProvider);
    final usersAsync = ref.watch(allUsersProvider);
    final reportsAsync = ref.watch(reportsProvider);
    final maintenanceAsync = ref.watch(maintenanceModeProvider);

    final productCount = productsAsync.valueOrNull?.length ?? 0;
    final storeCount = storesAsync.valueOrNull?.length ?? 0;
    final brandCount = brandsAsync.valueOrNull?.length ?? 0;
    final categoryCount = categoriesAsync.valueOrNull?.length ?? 0;
    final bannerCount = bannersAsync.valueOrNull?.length ?? 0;
    final userCount = usersAsync.valueOrNull?.length ?? 0;
    final reportCount = reportsAsync.valueOrNull?.length ?? 0;

    // Calculate total price entries and total points from users
    final users = usersAsync.valueOrNull ?? [];
    int totalPriceEntries = 0;
    int totalPoints = 0;
    for (final user in users) {
      totalPriceEntries += user.priceEntries;
      totalPoints += user.points;
    }

    final stats = [
      _StatItem('Toplam Urun', productCount, Icons.inventory_2_outlined, AppColors.primary),
      _StatItem('Toplam Zincir', brandCount, Icons.business_outlined, AppColors.secondary),
      _StatItem('Toplam Sube', storeCount, Icons.store_outlined, AppColors.accent),
      _StatItem('Toplam Kategori', categoryCount, Icons.category_outlined, const Color(0xFF6366F1)),
      _StatItem('Toplam Kullanici', userCount, Icons.people_outlined, AppColors.info),
      _StatItem('Toplam Fiyat Girisi', totalPriceEntries, Icons.price_change_outlined, const Color(0xFF10B981)),
      _StatItem('Toplam Rapor', reportCount, Icons.flag_outlined, AppColors.error),
      _StatItem('Toplam Banner', bannerCount, Icons.view_carousel_outlined, const Color(0xFF8B5CF6)),
      _StatItem('Toplam Puan', totalPoints, Icons.stars, const Color(0xFFF59E0B)),
    ];

    final maxVal = stats.map((s) => s.value).fold(1, (a, b) => a > b ? a : b).toDouble();
    final maintenanceEnabled = maintenanceAsync.valueOrNull ?? false;
    final maintenanceBusy = maintenanceAsync.isLoading;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const Icon(Icons.build_circle_outlined, color: AppColors.error),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Bakim Modu',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(
                          maintenanceEnabled
                              ? 'Uygulama bakim modunda'
                              : 'Uygulama normal calisiyor',
                          style: TextStyle(fontSize: 12, color: theme.hintColor),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: maintenanceEnabled,
                    onChanged: maintenanceBusy
                        ? null
                        : (value) async {
                            await ref
                                .read(firestoreServiceProvider)
                                .setMaintenanceMode(value);
                          },
                    activeColor: AppColors.error,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: stats.map((stat) {
              return SizedBox(
                width: (MediaQuery.of(context).size.width - AppSpacing.md * 2 - AppSpacing.sm) / 2,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(color: stat.color.withOpacity(0.12), borderRadius: BorderRadius.circular(AppRadius.sm)),
                          child: Icon(stat.icon, color: stat.color, size: 20),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(stat.value.toString(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: stat.color)),
                        const SizedBox(height: 2),
                        Text(stat.label, style: TextStyle(fontSize: 11, color: theme.hintColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.lg),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Genel Bakis', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: AppSpacing.md),
                  ...stats.map((stat) {
                    final ratio = maxVal > 0 ? stat.value / maxVal : 0.0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Flexible(child: Text(stat.label, style: TextStyle(fontSize: 12, color: theme.hintColor), overflow: TextOverflow.ellipsis)),
                          Text(stat.value.toString(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: stat.color)),
                        ]),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          child: Stack(children: [
                            Container(height: 10, width: double.infinity, color: theme.colorScheme.surfaceVariant),
                            FractionallySizedBox(
                              widthFactor: ratio,
                              child: Container(
                                height: 10,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [stat.color.withOpacity(0.7), stat.color]),
                                  borderRadius: BorderRadius.circular(AppRadius.full),
                                ),
                              ),
                            ),
                          ]),
                        ),
                      ]),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  const _StatItem(this.label, this.value, this.icon, this.color);
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

