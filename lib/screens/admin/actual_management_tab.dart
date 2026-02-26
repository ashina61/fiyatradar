import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/actual_item_model.dart';
import '../../models/actual_model.dart';
import '../../models/brand_model.dart';
import '../../providers/actual_provider.dart';
import '../../providers/product_provider.dart';
import '../../utils/theme.dart';

class ActualManagementTab extends ConsumerWidget {
  const ActualManagementTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actualsAsync = ref.watch(adminActualsProvider);
    final filter = ref.watch(actualAdminFilterProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
          child: Row(
            children: [
              Expanded(
                child: SegmentedButton<bool?>(
                  segments: const [
                    ButtonSegment<bool?>(value: null, label: Text('Tümü')),
                    ButtonSegment<bool?>(value: true, label: Text('Aktif')),
                    ButtonSegment<bool?>(value: false, label: Text('Pasif')),
                  ],
                  selected: {filter},
                  onSelectionChanged: (value) => ref.read(actualAdminFilterProvider.notifier).state = value.first,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilledButton.icon(
                onPressed: () => _showActualForm(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Aktüel Ekle'),
              ),
            ],
          ),
        ),
        Expanded(
          child: actualsAsync.when(
            data: (actuals) {
              if (actuals.isEmpty) {
                return const Center(child: Text('Henüz aktüel kaydı yok.'));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: actuals.length,
                itemBuilder: (context, index) {
                  final actual = actuals[index];
                  final date = DateFormat('dd.MM.yyyy').format;
                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      title: Text(actual.title),
                      subtitle: Text('${actual.marketName}\n${date(actual.startDate)} - ${date(actual.endDate)}'),
                      isThreeLine: true,
                      trailing: Switch(
                        value: actual.isActive,
                        onChanged: (value) => ref.read(actualAdminDomainServiceProvider).setActualActive(actual.id, value),
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => ActualItemsAdminScreen(actual: actual)),
                      ),
                      leading: IconButton(
                        onPressed: () => _showActualForm(context, ref, current: actual),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Center(
              child: FilledButton(
                onPressed: () => ref.invalidate(adminActualsProvider),
                child: const Text('Tekrar dene'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showActualForm(BuildContext context, WidgetRef ref, {ActualModel? current}) async {
    final titleController = TextEditingController(text: current?.title ?? '');
    final coverController = TextEditingController(text: current?.coverImageUrl ?? '');
    final descriptionController = TextEditingController(text: current?.description ?? '');
    DateTime startDate = current?.startDate ?? DateTime.now();
    DateTime endDate = current?.endDate ?? DateTime.now().add(const Duration(days: 7));
    bool isActive = current?.isActive ?? true;
    String? selectedMarketId = current?.marketId;
    String? selectedMarketName = current?.marketName;

    final markets = await ref.read(allBrandsProvider.future);
    if ((selectedMarketId ?? '').isEmpty && markets.isNotEmpty) {
      selectedMarketId = markets.first.id;
      selectedMarketName = markets.first.name;
    }

    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          Future<void> pickDate(bool isStart) async {
            final picked = await showDatePicker(
              context: ctx,
              initialDate: isStart ? startDate : endDate,
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
            );
            if (picked == null) return;
            setState(() {
              if (isStart) {
                startDate = picked;
                if (endDate.isBefore(startDate)) {
                  endDate = startDate;
                }
              } else {
                endDate = picked;
              }
            });
          }

          return AlertDialog(
            title: Text(current == null ? 'Aktüel Ekle' : 'Aktüel Düzenle'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedMarketId,
                    items: markets
                        .map((BrandModel brand) => DropdownMenuItem(value: brand.id, child: Text(brand.name)))
                        .toList(),
                    onChanged: (value) {
                      BrandModel? market;
                      for (final candidate in markets) {
                        if (candidate.id == value) {
                          market = candidate;
                          break;
                        }
                      }
                      setState(() {
                        selectedMarketId = value;
                        selectedMarketName = market?.name;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Market'),
                  ),
                  TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Başlık')),
                  TextField(controller: coverController, decoration: const InputDecoration(labelText: 'Kapak Görsel URL')),
                  TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Açıklama (opsiyonel)')),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => pickDate(true),
                          child: Text('Başlangıç: ${DateFormat('dd.MM.yyyy').format(startDate)}'),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => pickDate(false),
                          child: Text('Bitiş: ${DateFormat('dd.MM.yyyy').format(endDate)}'),
                        ),
                      ),
                    ],
                  ),
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
                  if (selectedMarketId == null || titleController.text.trim().isEmpty || coverController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Zorunlu alanları doldurun.')));
                    return;
                  }
                  final now = DateTime.now();
                  final payload = {
                    'marketId': selectedMarketId,
                    'marketName': selectedMarketName ?? '',
                    'title': titleController.text.trim(),
                    'startDate': startDate,
                    'endDate': endDate,
                    'coverImageUrl': coverController.text.trim(),
                    'description': descriptionController.text.trim(),
                    'isActive': isActive,
                  };

                  if (current == null) {
                    final actual = ActualModel(
                      id: '',
                      title: payload['title']! as String,
                      marketId: payload['marketId']! as String,
                      marketName: payload['marketName']! as String,
                      startDate: payload['startDate']! as DateTime,
                      endDate: payload['endDate']! as DateTime,
                      coverImageUrl: payload['coverImageUrl']! as String,
                      description: payload['description']! as String,
                      isActive: payload['isActive']! as bool,
                      createdAt: now,
                      updatedAt: now,
                    );
                    await ref.read(actualAdminDomainServiceProvider).addActual(actual);
                  } else {
                    await ref.read(actualAdminDomainServiceProvider).updateActual(current.id, payload);
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
}

class ActualItemsAdminScreen extends ConsumerWidget {
  const ActualItemsAdminScreen({super.key, required this.actual});

  final ActualModel actual;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(adminActualItemsProvider(actual.id));
    return Scaffold(
      appBar: AppBar(
        title: Text(actual.title),
        actions: [
          IconButton(
            onPressed: () => _showItemForm(context, ref),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: itemsAsync.when(
        data: (items) {
          if (items.isEmpty) return const Center(child: Text('Bu aktüelde henüz ürün eklenmedi.'));
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                child: ListTile(
                  title: Text(item.name),
                  subtitle: Text('₺${item.price.toStringAsFixed(2)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _showItemForm(context, ref, item: item),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        onPressed: () => ref.read(actualAdminDomainServiceProvider).deleteActualItem(actual.id, item.id),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: FilledButton(
            onPressed: () => ref.invalidate(adminActualItemsProvider(actual.id)),
            child: const Text('Tekrar dene'),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showItemForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Ürün Ekle'),
      ),
    );
  }

  Future<void> _showItemForm(BuildContext context, WidgetRef ref, {ActualItemModel? item}) async {
    final nameController = TextEditingController(text: item?.name ?? '');
    final priceController = TextEditingController(text: item == null ? '' : item.price.toString());
    final oldPriceController = TextEditingController(text: item?.oldPrice?.toString() ?? '');
    final imageController = TextEditingController(text: item?.imageUrl ?? '');
    final noteController = TextEditingController(text: item?.note ?? '');
    bool isActive = item?.isActive ?? true;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(item == null ? 'Ürün Ekle' : 'Ürün Düzenle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Ürün adı')),
                TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Fiyat'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                TextField(controller: oldPriceController, decoration: const InputDecoration(labelText: 'Eski fiyat (opsiyonel)'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                TextField(controller: imageController, decoration: const InputDecoration(labelText: 'Görsel URL (opsiyonel)')),
                TextField(controller: noteController, decoration: const InputDecoration(labelText: 'Not (opsiyonel)')),
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
                final price = double.tryParse(priceController.text.replaceAll(',', '.'));
                final oldPrice = double.tryParse(oldPriceController.text.replaceAll(',', '.'));
                if (nameController.text.trim().isEmpty || price == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ürün adı ve fiyat zorunludur.')));
                  return;
                }

                final payload = {
                  'name': nameController.text.trim(),
                  'price': price,
                  'oldPrice': oldPrice,
                  'imageUrl': imageController.text.trim(),
                  'note': noteController.text.trim(),
                  'isActive': isActive,
                };

                if (item == null) {
                  await ref.read(actualAdminDomainServiceProvider).addActualItem(
                        actual.id,
                        ActualItemModel(
                          id: '',
                          name: payload['name']! as String,
                          price: payload['price']! as double,
                          oldPrice: payload['oldPrice'] as double?,
                          imageUrl: payload['imageUrl']! as String,
                          note: payload['note']! as String,
                          type: '',
                          category: '',
                          isActive: payload['isActive']! as bool,
                          createdAt: DateTime.now(),
                        ),
                      );
                } else {
                  await ref.read(actualAdminDomainServiceProvider).updateActualItem(actual.id, item.id, payload);
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
}
