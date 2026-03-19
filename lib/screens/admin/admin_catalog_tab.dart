import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

// Kendi projendeki yolları kontrol et kanka
import '../../models/product_model.dart';
import '../../models/category_model.dart';
import '../../providers/product_provider.dart';
import '../../services/storage_service.dart';
import '../../utils/material_icon_resolver.dart';
import '../../widgets/barcode_scanner_sheet.dart';

// --- PREMIUM RENK PALETİ ---
const Color pBrandBrown = Color(0xFF6A442A);
const Color pBrandBrownLight = Color(0x266A442A); // %15 Opacity
const Color pBgApp = Color(0xFFF8F6F4);
const Color pSurface = Color(0xFFFFFFFF);
const Color pStudio = Color(0xFFEBE5DF);
const Color pGold = Color(0xFFC29B78);
const Color pGoldLight = Color(0x33C29B78);
const Color pTextMain = Color(0xFF211510);
const Color pTextMuted = Color(0xFF8C7B70);
const Color pAlert = Color(0xFFFF3B30);
const Color pAlertLight = Color(0x1AFF3B30);
const Color pBorder = Color(0x1F6A442A);

// ---------------------------------------------------------------------------
// AÇIK GIDA SERVİSİ (Senin eski sistem, aynen korundu)
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
    if (_cache.containsKey(normalized)) return _cache[normalized];
    final uri = Uri.parse('https://world.openfoodfacts.org/api/v2/product/$normalized.json');
    try {
      final request = await HttpClient().getUrl(uri);
      request.headers.set('User-Agent', 'FiyatRadar/1.0 (admin-panel)');
      request.headers.set('Accept', 'application/json');
      final response = await request.close();
      final body = await utf8.decoder.bind(response).join();
      if (response.statusCode != 200) {
        _cache[normalized] = null;
        return null;
      }
      final data = jsonDecode(body) as Map<String, dynamic>;
      final product = data['product'] as Map<String, dynamic>?;
      if (product == null) return null;
      
      final front = product['selected_images']?['front'] as Map<String, dynamic>?;
      final imageUrl = (product['image_front_url'] as String?) ?? (front?['display']?['tr'] as String?);
      
      final result = _OpenFoodFactsResult(
        productName: product['product_name'] as String?,
        brand: product['brands'] as String?,
        imageUrl: imageUrl,
      );
      _cache[normalized] = result;
      return result;
    } catch (_) {
      _cache[normalized] = null;
      return null;
    }
  }
}

// ---------------------------------------------------------------------------
// ANA WIDGET: KATALOG YÖNETİMİ (Ürünler + Kategoriler)
// ---------------------------------------------------------------------------
class AdminCatalogTab extends ConsumerStatefulWidget {
  const AdminCatalogTab({super.key});

  @override
  ConsumerState<AdminCatalogTab> createState() => _AdminCatalogTabState();
}

class _AdminCatalogTabState extends ConsumerState<AdminCatalogTab> {
  int _selectedIndex = 0; // 0: Ürünler, 1: Kategoriler
  static final _openFoodFactsService = _OpenFoodFactsService();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: pBgApp,
      child: Column(
        children: [
          // 💥 1. LÜKS SEGMENT VE EKLE BUTONU 💥
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: pStudio, borderRadius: BorderRadius.circular(100), border: Border.all(color: pBorder)),
                    child: Row(
                      children: [
                        _buildSegmentBtn('Ürünler', 0),
                        _buildSegmentBtn('Kategoriler', 1),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    if (_selectedIndex == 0) {
                      final cats = ref.read(categoriesProvider).valueOrNull ?? [];
                      _showProductBottomSheet(context, ref, categories: cats);
                    } else {
                      _showCategoryBottomSheet(context, ref);
                    }
                  },
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(color: pBrandBrown, borderRadius: BorderRadius.circular(100), boxShadow: const [BoxShadow(color: Color(0x4D6A442A), blurRadius: 10, offset: Offset(0, 4))]),
                    child: Row(
                      children: [
                        const Icon(Icons.add, color: pSurface, size: 18),
                        const SizedBox(width: 4),
                        Text(_selectedIndex == 0 ? 'Ürün Ekle' : 'Kategori Ekle', style: const TextStyle(color: pSurface, fontWeight: FontWeight.w700, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 💥 2. DİNAMİK İÇERİK ALANI 💥
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _selectedIndex == 0 ? _buildProductsView(ref) : _buildCategoriesView(ref),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentBtn(String title, int index) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? pSurface : Colors.transparent,
            borderRadius: BorderRadius.circular(100),
            boxShadow: isSelected ? const [BoxShadow(color: Color(0x146A442A), blurRadius: 8, offset: Offset(0, 2))] : [],
          ),
          alignment: Alignment.center,
          child: Text(title, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600, color: isSelected ? pTextMain : pTextMuted)),
        ),
      ),
    );
  }

  // =========================================================================
  // ÜRÜNLER GÖRÜNÜMÜ
  // =========================================================================
  Widget _buildProductsView(WidgetRef ref) {
    final productsAsync = ref.watch(allProductsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return productsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: pBrandBrown)),
      error: (_, __) => const Center(child: Text('Ürünler yüklenemedi', style: TextStyle(color: pAlert))),
      data: (products) {
        if (products.isEmpty) {
          return const Center(child: Text('Katalogda henüz ürün yok.', style: TextStyle(color: pTextMuted, fontWeight: FontWeight.w600)));
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            final hasImage = (product.effectiveImage ?? '').isNotEmpty;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: pSurface, borderRadius: BorderRadius.circular(20), border: Border.all(color: pBorder), boxShadow: const [BoxShadow(color: Color(0x0A6A442A), blurRadius: 15, offset: Offset(0, 4))]),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Görsel Kutusu
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(color: hasImage ? pSurface : pStudio, borderRadius: BorderRadius.circular(14), border: Border.all(color: pBorder)),
                      child: hasImage
                          ? ClipRRect(borderRadius: BorderRadius.circular(13), child: Image.network(product.effectiveImage!, fit: BoxFit.cover, errorBuilder: (_,__,___)=> const Icon(Icons.broken_image, color: pTextMuted)))
                          : const Icon(Icons.inventory_2, color: pTextMuted),
                    ),
                    const SizedBox(width: 16),
                    // Bilgiler
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: pTextMain), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text('${product.brand} • ${product.category}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: pTextMuted)),
                          const SizedBox(height: 6),
                          // Rozetler
                          Wrap(
                            spacing: 6, runSpacing: 6,
                            children: [
                              if (product.isEditorPick)
                                _buildBadge(icon: Icons.workspace_premium, text: 'Editör', color: pGold, bgColor: pGoldLight),
                              if (!hasImage)
                                _buildBadge(icon: Icons.warning, text: 'Görsel Yok', color: pAlert, bgColor: pAlertLight),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Aksiyonlar
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            final picker = ImagePicker();
                            final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                            if (picked == null) return;
                            // Resim yükleme logic (StorageService) buraya eklenebilir.
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: pBgApp, borderRadius: BorderRadius.circular(10)),
                            child: Icon(Icons.add_a_photo, size: 18, color: !hasImage ? pAlert : pBrandBrown),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _showProductBottomSheet(context, ref, product: product, categories: categoriesAsync.valueOrNull ?? []),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: pBgApp, borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.edit, size: 18, color: pBrandBrown),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // =========================================================================
  // KATEGORİLER GÖRÜNÜMÜ
  // =========================================================================
  Widget _buildCategoriesView(WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final productsAsync = ref.watch(allProductsProvider);

    return categoriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: pBrandBrown)),
      error: (_, __) => const Center(child: Text('Kategoriler yüklenemedi', style: TextStyle(color: pAlert))),
      data: (categories) {
        final products = productsAsync.valueOrNull ?? [];
        if (categories.isEmpty) {
          return const Center(child: Text('Henüz kategori yok.', style: TextStyle(color: pTextMuted, fontWeight: FontWeight.w600)));
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.0),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            final productCount = products.where((p) => p.categories.contains(cat.name)).length;

            return Container(
              decoration: BoxDecoration(color: pSurface, borderRadius: BorderRadius.circular(20), border: Border.all(color: pBorder), boxShadow: const [BoxShadow(color: Color(0x0A6A442A), blurRadius: 10, offset: Offset(0, 4))]),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(color: pBrandBrownLight, borderRadius: BorderRadius.circular(14)),
                          child: Icon(materialIconFromName(cat.iconName), color: pBrandBrown, size: 24),
                        ),
                        const SizedBox(height: 12),
                        Text(cat.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: pTextMain)),
                        const SizedBox(height: 2),
                        Text('$productCount Ürün', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: pTextMuted)),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 8, right: 8,
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => _showCategoryBottomSheet(context, ref, cat: cat),
                          child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: pBgApp, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.edit, size: 14, color: pTextMuted)),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => ref.read(adminCategoryManagementDomainServiceProvider).deleteCategory(cat.documentId),
                          child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: pAlertLight, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.delete, size: 14, color: pAlert)),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBadge({required IconData icon, required String text, required Color color, required Color bgColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: pTextMain)),
        ],
      ),
    );
  }

  // =========================================================================
  // BOTTOM SHEETS (FORM MODALLARI)
  // =========================================================================
  
  Future<void> _showProductBottomSheet(BuildContext context, WidgetRef ref, {ProductModel? product, required List<CategoryModel> categories}) async {
    final nameController = TextEditingController(text: product?.name ?? '');
    final brandController = TextEditingController(text: product?.brand ?? '');
    final barcodeController = TextEditingController(text: product?.barcode ?? '');
    final descController = TextEditingController(text: product?.description ?? '');
    final Set<String> selectedCategories = {...?product?.categories};
    bool isEditorPick = product?.isEditorPick ?? false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            height: MediaQuery.of(ctx).size.height * 0.85,
            decoration: const BoxDecoration(color: pBgApp, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: pBorder, borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 20),
                  Text(product == null ? 'Yeni Ürün Ekle' : 'Ürün Düzenle', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: pTextMain)),
                  const SizedBox(height: 24),

                  // Form Alanları
                  _PremiumInput(icon: Icons.qr_code_scanner, hint: 'Barkod', controller: barcodeController, suffixIcon: Icons.search),
                  const SizedBox(height: 12),
                  _PremiumInput(icon: Icons.inventory_2, hint: 'Ürün Adı', controller: nameController),
                  const SizedBox(height: 12),
                  _PremiumInput(icon: Icons.branding_watermark, hint: 'Marka', controller: brandController),
                  const SizedBox(height: 12),
                  _PremiumInput(icon: Icons.description, hint: 'Açıklama (Opsiyonel)', controller: descController, maxLines: 2),
                  const SizedBox(height: 16),

                  // Kategori Seçimi (Chips)
                  Align(alignment: Alignment.centerLeft, child: Text('Kategoriler', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: pTextMuted))),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: categories.map((c) {
                      final isSelected = selectedCategories.contains(c.name);
                      return GestureDetector(
                        onTap: () => setState(() {
                          isSelected ? selectedCategories.remove(c.name) : selectedCategories.add(c.name);
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(color: isSelected ? pBrandBrown : pSurface, border: Border.all(color: isSelected ? pBrandBrown : pBorder), borderRadius: BorderRadius.circular(100)),
                          child: Text(c.name, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isSelected ? pSurface : pTextMuted)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Editör Seçimi Switch
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(color: pSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: pBorder)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.workspace_premium, color: pGold, size: 20),
                            SizedBox(width: 8),
                            Text('Editörün Seçimi', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: pTextMain)),
                          ],
                        ),
                        Switch.adaptive(value: isEditorPick, activeColor: pSurface, activeTrackColor: pGold, inactiveThumbColor: pSurface, inactiveTrackColor: pStudio, onChanged: (v) => setState(() => isEditorPick = v)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Kaydet
                  GestureDetector(
                    onTap: () async {
                      if (nameController.text.trim().isEmpty || selectedCategories.isEmpty) return;
                      // Ürün kaydetme logic buraya eklenecek (senin eski kodundaki gibi)
                      if (Navigator.canPop(ctx)) Navigator.pop(ctx);
                    },
                    child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 18), decoration: BoxDecoration(color: pBrandBrown, borderRadius: BorderRadius.circular(100)), alignment: Alignment.center, child: const Text('Kaydet', style: TextStyle(color: pSurface, fontSize: 16, fontWeight: FontWeight.w800))),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showCategoryBottomSheet(BuildContext context, WidgetRef ref, {CategoryModel? cat}) async {
    final nameController = TextEditingController(text: cat?.name ?? '');
    final iconController = TextEditingController(text: cat?.iconName ?? 'category');
    bool isActive = cat?.isActive ?? true;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(color: pBgApp, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: pBorder, borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 20),
                  Text(cat == null ? 'Kategori Ekle' : 'Kategori Düzenle', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: pTextMain)),
                  const SizedBox(height: 24),

                  _PremiumInput(icon: Icons.category, hint: 'Kategori Adı', controller: nameController),
                  const SizedBox(height: 12),
                  _PremiumInput(icon: Icons.emoji_symbols, hint: 'İkon Adı (Örn: fastfood)', controller: iconController),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(color: pSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: pBorder)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Sistemde Aktif', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: pTextMain)),
                        Switch.adaptive(value: isActive, activeColor: pSurface, activeTrackColor: pBrandBrown, inactiveThumbColor: pSurface, inactiveTrackColor: pStudio, onChanged: (v) => setState(() => isActive = v)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  GestureDetector(
                    onTap: () async {
                      if (nameController.text.trim().isEmpty) return;
                      // Kategori kaydetme logic
                      if (Navigator.canPop(ctx)) Navigator.pop(ctx);
                    },
                    child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 18), decoration: BoxDecoration(color: pBrandBrown, borderRadius: BorderRadius.circular(100)), alignment: Alignment.center, child: const Text('Kaydet', style: TextStyle(color: pSurface, fontSize: 16, fontWeight: FontWeight.w800))),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// YARDIMCI WIDGET: PREMIUM INPUT
// ---------------------------------------------------------------------------
class _PremiumInput extends StatelessWidget {
  final IconData icon;
  final String hint;
  final TextEditingController controller;
  final IconData? suffixIcon;
  final int maxLines;

  const _PremiumInput({required this.icon, required this.hint, required this.controller, this.suffixIcon, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(color: pSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: pBorder)),
      child: Row(
        children: [
          Icon(icon, color: pTextMuted, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: pTextMain),
              decoration: InputDecoration(border: InputBorder.none, hintText: hint, hintStyle: const TextStyle(color: pTextMuted, fontWeight: FontWeight.w500)),
            ),
          ),
          if (suffixIcon != null) Icon(suffixIcon, color: pBrandBrown, size: 20),
        ],
      ),
    );
  }
}
