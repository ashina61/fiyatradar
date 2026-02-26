import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/brand_model.dart';
import '../../providers/product_provider.dart';
import '../../utils/theme.dart';

class AdminBrandManagementTab extends ConsumerWidget {
  const AdminBrandManagementTab({super.key});

  Future<void> _showBrandDialog(BuildContext context, WidgetRef ref, {BrandModel? brand}) async {
    final nameController = TextEditingController(text: brand?.name ?? '');
    final logoController = TextEditingController(text: brand?.logoUrl ?? '');
    bool isActive = brand?.isActive ?? true;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(brand == null ? 'Ana Mağaza Ekle' : 'Ana Mağaza Düzenle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Mağaza Adı *')),
                TextField(controller: logoController, decoration: const InputDecoration(labelText: 'Logo URL')),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: isActive,
                  onChanged: (value) => setState(() => isActive = value),
                  title: const Text('Aktif'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
            FilledButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                if (brand == null) {
                  await ref.read(adminBrandManagementDomainServiceProvider).addBrand(
                    BrandModel(
                      id: '',
                      name: nameController.text.trim(),
                      type: BrandType.chain,
                      logoUrl: logoController.text.trim().isEmpty ? null : logoController.text.trim(),
                      isActive: isActive,
                      createdAt: DateTime.now(),
                    ),
                  );
                } else {
                  await ref.read(adminBrandManagementDomainServiceProvider).updateBrand(brand.id, {
                    'name': nameController.text.trim(),
                    'logoUrl': logoController.text.trim(),
                    'isActive': isActive,
                  });
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brandsAsync = ref.watch(allBrandsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_brand',
        onPressed: () => _showBrandDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Ana Mağaza Ekle'),
      ),
      body: brandsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Ana mağazalar yüklenemedi')),
        data: (brands) {
          if (brands.isEmpty) return const Center(child: Text('Henüz ana mağaza yok'));
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 80),
            itemCount: brands.length,
            itemBuilder: (context, index) {
              final brand = brands[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.surfaceVariant,
                    backgroundImage: (brand.logoUrl ?? '').trim().isNotEmpty ? NetworkImage(brand.logoUrl!.trim()) : null,
                    child: (brand.logoUrl ?? '').trim().isEmpty ? const Icon(Icons.business) : null,
                  ),
                  title: Text(brand.name),
                  subtitle: Text(brand.isActive ? 'Aktif' : 'Pasif'),
                  trailing: Switch(
                    value: brand.isActive,
                    onChanged: (value) => ref.read(adminBrandManagementDomainServiceProvider).updateBrand(brand.id, {'isActive': value}),
                  ),
                  onTap: () => _showBrandDialog(context, ref, brand: brand),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
