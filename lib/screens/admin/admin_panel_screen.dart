import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/theme.dart';
import '../../models/product_model.dart';
import '../../models/banner_model.dart';
import '../../providers/product_provider.dart';
import '../../providers/banner_provider.dart';
import '../../services/storage_service.dart';

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
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            Tab(text: 'Magazalar', icon: Icon(Icons.store_outlined)),
            Tab(text: 'Kategoriler', icon: Icon(Icons.category_outlined)),
            Tab(text: 'Bannerlar', icon: Icon(Icons.view_carousel_outlined)),
            Tab(text: 'Bakim', icon: Icon(Icons.build_circle_outlined)),
            Tab(text: 'Istatistikler', icon: Icon(Icons.bar_chart_outlined)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ProductManagementTab(),
          _StoreManagementTab(),
          _CategoryManagementTab(),
          _BannerManagementTab(),
          _MaintenanceTab(),
          _StatisticsTab(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 1: Urun Yonetimi
// ---------------------------------------------------------------------------
class _ProductManagementTab extends ConsumerWidget {
  const _ProductManagementTab();

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
    String? selectedCategory;
    File? selectedImage;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
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
              // Image picker
              GestureDetector(
                onTap: () async {
                  final picker = ImagePicker();
                  final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800, maxHeight: 800, imageQuality: 80);
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
                    border: Border.all(color: AppColors.outlineVariant),
                    image: selectedImage != null ? DecorationImage(image: FileImage(selectedImage!), fit: BoxFit.cover) : null,
                  ),
                  child: selectedImage == null ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.add_photo_alternate_outlined, size: 36, color: AppColors.textTertiary),
                    SizedBox(height: 4),
                    Text('Resim Ekle (opsiyonel)', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                  ]) : null,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Urun Adi', prefixIcon: Icon(Icons.label_outline)),
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
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Iptal')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || selectedCategory == null) return;
                final service = ref.read(firestoreServiceProvider);

                String? imageUrl;
                if (selectedImage != null) {
                  final productId = DateTime.now().millisecondsSinceEpoch.toString();
                  final storage = StorageService();
                  imageUrl = await storage.uploadProductImage(file: selectedImage!, productId: productId);
                }

                await service.addProduct(ProductModel(
                  id: '',
                  name: nameController.text,
                  brand: brandController.text.isEmpty ? 'Genel' : brandController.text,
                  category: selectedCategory!,
                  mainImage: imageUrl,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ));
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Ekle'),
            ),
          ],
        ),
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
// Tab 2: Magaza Yonetimi
// ---------------------------------------------------------------------------
class _StoreManagementTab extends ConsumerWidget {
  const _StoreManagementTab();

  void _showAddStoreDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.secondary.withOpacity(0.1), borderRadius: BorderRadius.circular(AppRadius.sm)),
            child: const Icon(Icons.store_outlined, color: AppColors.secondary, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Text('Yeni Magaza Ekle'),
        ]),
        content: TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Magaza Adi', prefixIcon: Icon(Icons.storefront_outlined)), autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Iptal')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) return;
              await ref.read(firestoreServiceProvider).addStore(nameController.text);
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
    final storesAsync = ref.watch(storesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_store',
        onPressed: () => _showAddStoreDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Magaza Ekle'),
      ),
      body: storesAsync.when(
        data: (stores) {
          if (stores.isEmpty) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.store_outlined, size: 64, color: theme.hintColor),
              const SizedBox(height: AppSpacing.md),
              Text('Henuz magaza yok', style: TextStyle(color: theme.hintColor, fontSize: 16)),
            ]));
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 80),
            itemCount: stores.length,
            itemBuilder: (context, index) {
              final store = stores[index];
              return Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  leading: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: AppColors.secondary.withOpacity(0.1), borderRadius: BorderRadius.circular(AppRadius.md)),
                    child: const Icon(Icons.store, color: AppColors.secondary, size: 22),
                  ),
                  title: Text(store['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  trailing: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(AppRadius.sm)),
                      child: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                    ),
                    onPressed: () {
                      ref.read(firestoreServiceProvider).deleteStore(store['id']);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${store['name']} silindi'), behavior: SnackBarBehavior.floating),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Magazalar yuklenemedi')),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 3: Kategori Yonetimi
// ---------------------------------------------------------------------------
class _CategoryManagementTab extends ConsumerWidget {
  const _CategoryManagementTab();

  IconData _iconFromName(String iconName) {
    const iconMap = <String, IconData>{
      'category': Icons.category,
      'devices': Icons.devices,
      'restaurant': Icons.restaurant,
      'cleaning_services': Icons.cleaning_services,
      'face': Icons.face,
      'home': Icons.home,
      'checkroom': Icons.checkroom,
      'sports': Icons.sports,
      'toys': Icons.toys,
      'book': Icons.book,
      'directions_car': Icons.directions_car,
      'pets': Icons.pets,
      'local_pharmacy': Icons.local_pharmacy,
      'child_care': Icons.child_care,
      'build': Icons.build,
      'headphones': Icons.headphones,
      'watch': Icons.watch,
      'chair': Icons.chair,
      'local_florist': Icons.local_florist,
      'fitness_center': Icons.fitness_center,
    };
    return iconMap[iconName] ?? Icons.category;
  }

  Color _categoryColor(int index) {
    final colors = [AppColors.primary, AppColors.secondary, AppColors.accent, AppColors.info, AppColors.error, const Color(0xFF8B5CF6), const Color(0xFFEC4899), const Color(0xFF14B8A6), const Color(0xFFF97316), const Color(0xFF6366F1)];
    return colors[index % colors.length];
  }

  static const _availableIcons = <String, IconData>{
    'category': Icons.category,
    'devices': Icons.devices,
    'restaurant': Icons.restaurant,
    'cleaning_services': Icons.cleaning_services,
    'face': Icons.face,
    'home': Icons.home,
    'checkroom': Icons.checkroom,
    'sports': Icons.sports,
    'toys': Icons.toys,
    'book': Icons.book,
    'directions_car': Icons.directions_car,
    'pets': Icons.pets,
    'local_pharmacy': Icons.local_pharmacy,
    'child_care': Icons.child_care,
    'build': Icons.build,
    'headphones': Icons.headphones,
    'watch': Icons.watch,
    'chair': Icons.chair,
    'local_florist': Icons.local_florist,
    'fitness_center': Icons.fitness_center,
  };

  void _showAddCategoryDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    String selectedIconName = 'category';

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
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Kategori Adi', prefixIcon: Icon(Icons.label_outline)), autofocus: true),
              const SizedBox(height: AppSpacing.md),
              const Align(alignment: Alignment.centerLeft, child: Text('Ikon Sec:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 200,
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, crossAxisSpacing: 8, mainAxisSpacing: 8),
                  itemCount: _availableIcons.length,
                  itemBuilder: (context, index) {
                    final entry = _availableIcons.entries.elementAt(index);
                    final isSelected = entry.key == selectedIconName;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedIconName = entry.key),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary.withOpacity(0.15) : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: isSelected ? Border.all(color: AppColors.primary, width: 2) : null,
                        ),
                        child: Icon(entry.value, color: isSelected ? AppColors.primary : AppColors.textSecondary, size: 22),
                      ),
                    );
                  },
                ),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Iptal')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) return;
                await ref.read(firestoreServiceProvider).addCategory(nameController.text, selectedIconName);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Ekle'),
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
              final catIconName = cat['iconName'] ?? 'category';
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
                        child: Icon(_iconFromName(catIconName), color: color, size: 24),
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
// Tab 5: Bakim Modu
// ---------------------------------------------------------------------------
class _MaintenanceTab extends ConsumerStatefulWidget {
  const _MaintenanceTab();

  @override
  ConsumerState<_MaintenanceTab> createState() => _MaintenanceTabState();
}

class _MaintenanceTabState extends ConsumerState<_MaintenanceTab> {
  final _messageController = TextEditingController();
  bool _isUpdating = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final service = ref.watch(firestoreServiceProvider);

    return StreamBuilder<Map<String, dynamic>>(
      stream: service.getMaintenanceStatus(),
      builder: (context, snapshot) {
        final data = snapshot.data ?? {'enabled': false, 'message': ''};
        final isEnabled = data['enabled'] as bool;
        final message = data['message'] as String;

        if (_messageController.text.isEmpty && message.isNotEmpty) {
          _messageController.text = message;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      Icon(
                        isEnabled ? Icons.engineering : Icons.check_circle_outline,
                        size: 64,
                        color: isEnabled ? AppColors.accent : AppColors.success,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        isEnabled ? 'Bakim Modu Aktif' : 'Uygulama Normal Calisiyor',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isEnabled ? AppColors.accent : AppColors.success,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        isEnabled
                            ? 'Kullanicilar uygulamayi kullanamaz durumda.'
                            : 'Tum ozellikler aktif ve calisiyor.',
                        style: TextStyle(fontSize: 14, color: theme.hintColor),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Toggle Switch
              Card(
                child: SwitchListTile(
                  title: const Text('Bakim Modu', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(isEnabled ? 'Aktif - Kullanicilar giremez' : 'Pasif - Normal calisma'),
                  value: isEnabled,
                  activeColor: AppColors.accent,
                  secondary: Icon(
                    Icons.build_circle_outlined,
                    color: isEnabled ? AppColors.accent : theme.hintColor,
                  ),
                  onChanged: _isUpdating ? null : (val) async {
                    setState(() => _isUpdating = true);
                    await service.setMaintenanceMode(
                      val,
                      message: _messageController.text.isNotEmpty
                          ? _messageController.text
                          : null,
                    );
                    setState(() => _isUpdating = false);
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Message
              Text('Bakim Mesaji', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.sm),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      TextField(
                        controller: _messageController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Kullanicilara gosterilecek mesaj...',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.message_outlined),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isUpdating ? null : () async {
                            setState(() => _isUpdating = true);
                            await service.setMaintenanceMode(
                              isEnabled,
                              message: _messageController.text,
                            );
                            setState(() => _isUpdating = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Mesaj guncellendi'), behavior: SnackBarBehavior.floating),
                              );
                            }
                          },
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Mesaji Kaydet'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 6: Istatistikler
// ---------------------------------------------------------------------------
class _StatisticsTab extends ConsumerWidget {
  const _StatisticsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final productsAsync = ref.watch(allProductsProvider);
    final storesAsync = ref.watch(storesProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final bannersAsync = ref.watch(allBannersProvider);

    final productCount = productsAsync.valueOrNull?.length ?? 0;
    final storeCount = storesAsync.valueOrNull?.length ?? 0;
    final categoryCount = categoriesAsync.valueOrNull?.length ?? 0;
    final bannerCount = bannersAsync.valueOrNull?.length ?? 0;

    final stats = [
      _StatItem('Toplam Urun', productCount, Icons.inventory_2_outlined, AppColors.primary),
      _StatItem('Toplam Magaza', storeCount, Icons.store_outlined, AppColors.secondary),
      _StatItem('Toplam Kategori', categoryCount, Icons.category_outlined, AppColors.accent),
      _StatItem('Toplam Banner', bannerCount, Icons.view_carousel_outlined, const Color(0xFF8B5CF6)),
    ];

    final maxVal = stats.map((s) => s.value).fold(1, (a, b) => a > b ? a : b).toDouble();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
