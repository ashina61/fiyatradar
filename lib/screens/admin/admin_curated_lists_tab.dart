import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/product_model.dart';
import '../../models/special_list_item_model.dart';
import '../../models/special_list_model.dart';
import '../../models/store_model.dart';
import '../../providers/product_provider.dart';
import '../../providers/special_list_provider.dart';
import '../../services/special_list_service.dart';

class AdminCuratedListsTab extends ConsumerStatefulWidget {
  const AdminCuratedListsTab({super.key});

  @override
  ConsumerState<AdminCuratedListsTab> createState() => _AdminCuratedListsTabState();
}

class _AdminCuratedListsTabState extends ConsumerState<AdminCuratedListsTab> {
  final _title = TextEditingController();
  final _subtitle = TextEditingController();
  final _badge = TextEditingController();
  final _description = TextEditingController();
  final _totalPrice = TextEditingController(text: '0');
  final _savingsAmount = TextEditingController(text: '0');
  final _savingsLabel = TextEditingController(text: 'Daha Ucuz');
  final _bestMarket = TextEditingController();
  final _ctaText = TextEditingController(text: 'Sepeti Kıyasla');
  final _sortOrder = TextEditingController(text: '0');

  final _quantity = TextEditingController();
  final _tag = TextEditingController();
  final _itemPrice = TextEditingController(text: '0');
  final _itemSortOrder = TextEditingController(text: '0');
  final _itemNameOverride = TextEditingController();
  final _itemBrandOverride = TextEditingController();
  final _itemImageOverride = TextEditingController();
  final _itemColor = TextEditingController(text: '#D0A278');

  String? _selectedListId;
  String? _selectedProductId;
  String? _selectedStoreId;
  bool _listActive = true;
  bool _itemActive = true;
  SpecialListCtaActionType _ctaActionType = SpecialListCtaActionType.compareCart;

  @override
  void dispose() {
    for (final controller in [
      _title,
      _subtitle,
      _badge,
      _description,
      _totalPrice,
      _savingsAmount,
      _savingsLabel,
      _bestMarket,
      _ctaText,
      _sortOrder,
      _quantity,
      _tag,
      _itemPrice,
      _itemSortOrder,
      _itemNameOverride,
      _itemBrandOverride,
      _itemImageOverride,
      _itemColor,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(specialListServiceProvider);
    final listsAsync = ref.watch(specialListsProvider);
    final productsAsync = ref.watch(allProductsProvider);
    final storesAsync = ref.watch(allStoresStreamProvider);

    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Column(
            children: [
              _listFormCard(service),
              Expanded(
                child: listsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Center(child: Text('Özel listeler yüklenemedi.')),
                  data: (lists) {
                    if (lists.isEmpty) return const Center(child: Text('Henüz özel liste yok.'));
                    return ListView.builder(
                      itemCount: lists.length,
                      itemBuilder: (context, index) {
                        final list = lists[index];
                        return Card(
                          child: ListTile(
                            selected: list.id == _selectedListId,
                            title: Text(list.title),
                            subtitle: Text('${list.subtitle} • ${list.sortOrder}'),
                            onTap: () => _fillListForm(list),
                            trailing: Wrap(
                              spacing: 8,
                              children: [
                                Switch(
                                  value: list.isActive,
                                  onChanged: (v) => service.updateSpecialList(list.id, {'isActive': v}),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => service.deleteSpecialList(list.id),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 5,
          child: _selectedListId == null
              ? const Center(child: Text('Ürün yönetimi için soldan bir liste seçin.'))
              : Column(
                  children: [
                    _itemFormCard(service, productsAsync.valueOrNull ?? const [], storesAsync.valueOrNull ?? const []),
                    Expanded(
                      child: Consumer(
                        builder: (context, ref, _) {
                          final itemsAsync = ref.watch(specialListItemsProvider(_selectedListId!));
                          return itemsAsync.when(
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (_, __) => const Center(child: Text('Liste ürünleri yüklenemedi.')),
                            data: (items) {
                              if (items.isEmpty) return const Center(child: Text('Bu listede ürün yok.'));
                              return ReorderableListView.builder(
                                itemCount: items.length,
                                onReorder: (oldIndex, newIndex) async {
                                  final sorted = [...items];
                                  final item = sorted.removeAt(oldIndex);
                                  sorted.insert(newIndex > oldIndex ? newIndex - 1 : newIndex, item);
                                  for (var i = 0; i < sorted.length; i++) {
                                    await service.upsertSpecialListItem(
                                      listId: _selectedListId!,
                                      itemId: sorted[i].id,
                                      item: sorted[i].copyWith(sortOrder: i),
                                    );
                                  }
                                },
                                itemBuilder: (context, index) {
                                  final item = items[index];
                                  return ListTile(
                                    key: ValueKey(item.id),
                                    title: Text(item.productNameSnapshot),
                                    subtitle: Text('${item.selectedStoreNameSnapshot} • ${item.selectedPrice.toStringAsFixed(2)}₺'),
                                    trailing: Wrap(
                                      spacing: 8,
                                      children: [
                                        Switch(
                                          value: item.isActive,
                                          onChanged: (v) => service.upsertSpecialListItem(
                                            listId: _selectedListId!,
                                            itemId: item.id,
                                            item: item.copyWith(isActive: v),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline),
                                          onPressed: () => service.deleteSpecialListItem(listId: _selectedListId!, itemId: item.id),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Future<void> _showCreateListDialog(BuildContext context) async {
    final titleController = TextEditingController();
    final subtitleController = TextEditingController();

    final created = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Özel Liste'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Liste adı')),
            TextField(controller: subtitleController, decoration: const InputDecoration(labelText: 'Hero başlık')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.trim().isEmpty) return;
              final service = ref.read(specialListServiceProvider);
              final id = await service.createSpecialList(
                title: titleController.text.trim(),
                subtitle: subtitleController.text.trim(),
                badgeText: 'ÖZEL LİSTE',
                description: '',
                coverType: 'default',
                coverImageUrl: null,
                totalPrice: 0,
                savingsAmount: 0,
                savingsLabel: '',
                bestMarketName: '',
                ctaText: 'Sepeti Kıyasla',
                ctaActionType: SpecialListCtaActionType.compareCart,
                isActive: true,
                sortOrder: DateTime.now().millisecondsSinceEpoch,
              );
              if (!mounted) return;
              setState(() => _selectedListId = id);
              Navigator.pop(context, true);
            },
            child: const Text('Oluştur'),
          ),
        ],
      ),
    );

    if (created == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Özel liste oluşturuldu.')));
    }
  }

  Widget _listFormCard(SpecialListService service) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Özel Liste Bilgileri', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showCreateListDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Hızlı Oluştur'),
                ),
              ],
            ),
            TextField(controller: _title, decoration: const InputDecoration(labelText: 'title')),
            TextField(controller: _subtitle, decoration: const InputDecoration(labelText: 'subtitle')),
            TextField(controller: _badge, decoration: const InputDecoration(labelText: 'badgeText')),
            TextField(controller: _description, decoration: const InputDecoration(labelText: 'description')),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SizedBox(width: 130, child: TextField(controller: _totalPrice, decoration: const InputDecoration(labelText: 'totalPrice'))),
                SizedBox(width: 130, child: TextField(controller: _savingsAmount, decoration: const InputDecoration(labelText: 'savingsAmount'))),
                SizedBox(width: 150, child: TextField(controller: _savingsLabel, decoration: const InputDecoration(labelText: 'savingsLabel'))),
                SizedBox(width: 150, child: TextField(controller: _bestMarket, decoration: const InputDecoration(labelText: 'bestMarketName'))),
                SizedBox(width: 130, child: TextField(controller: _sortOrder, decoration: const InputDecoration(labelText: 'sortOrder'))),
              ],
            ),
            TextField(controller: _ctaText, decoration: const InputDecoration(labelText: 'ctaText')),
            DropdownButtonFormField<SpecialListCtaActionType>(
              value: _ctaActionType,
              decoration: const InputDecoration(labelText: 'ctaActionType'),
              items: SpecialListCtaActionType.values.map((e) => DropdownMenuItem(value: e, child: Text(e.value))).toList(),
              onChanged: (value) => setState(() => _ctaActionType = value ?? SpecialListCtaActionType.none),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('isActive'),
              value: _listActive,
              onChanged: (value) => setState(() => _listActive = value),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: _clearListForm, child: const Text('Temizle')),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    final payload = {
                      'title': _title.text.trim(),
                      'subtitle': _subtitle.text.trim(),
                      'badgeText': _badge.text.trim(),
                      'description': _description.text.trim(),
                      'totalPrice': double.tryParse(_totalPrice.text.replaceAll(',', '.')) ?? 0,
                      'savingsAmount': double.tryParse(_savingsAmount.text.replaceAll(',', '.')) ?? 0,
                      'savingsLabel': _savingsLabel.text.trim(),
                      'bestMarketName': _bestMarket.text.trim(),
                      'ctaText': _ctaText.text.trim(),
                      'ctaActionType': _ctaActionType.value,
                      'isActive': _listActive,
                      'sortOrder': int.tryParse(_sortOrder.text) ?? 0,
                      'coverType': 'gradient',
                    };

                    if (_selectedListId == null) {
                      final id = await service.createSpecialList(
                        title: payload['title'] as String,
                        subtitle: payload['subtitle'] as String,
                        badgeText: payload['badgeText'] as String,
                        description: payload['description'] as String,
                        coverType: payload['coverType'] as String,
                        totalPrice: payload['totalPrice'] as double,
                        savingsAmount: payload['savingsAmount'] as double,
                        savingsLabel: payload['savingsLabel'] as String,
                        bestMarketName: payload['bestMarketName'] as String,
                        ctaText: payload['ctaText'] as String,
                        ctaActionType: _ctaActionType,
                        isActive: payload['isActive'] as bool,
                        sortOrder: payload['sortOrder'] as int,
                      );
                      setState(() => _selectedListId = id);
                    } else {
                      await service.updateSpecialList(_selectedListId!, payload);
                    }
                  },
                  child: Text(_selectedListId == null ? 'Liste Oluştur' : 'Listeyi Güncelle'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemFormCard(SpecialListService service, List<ProductModel> products, List<StoreModel> stores) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Align(alignment: Alignment.centerLeft, child: Text('Liste Ürün Yönetimi', style: TextStyle(fontWeight: FontWeight.w800))),
            DropdownButtonFormField<String>(
              value: _selectedProductId,
              decoration: const InputDecoration(labelText: 'Ürün seç'),
              items: products.map<DropdownMenuItem<String>>((p) => DropdownMenuItem(value: p.id, child: Text('${p.brand} - ${p.name}'))).toList(),
              onChanged: (value) => setState(() => _selectedProductId = value),
            ),
            DropdownButtonFormField<String>(
              value: _selectedStoreId,
              decoration: const InputDecoration(labelText: 'Market seç'),
              items: stores.map<DropdownMenuItem<String>>((s) => DropdownMenuItem(value: s.id, child: Text(s.displayName))).toList(),
              onChanged: (value) => setState(() => _selectedStoreId = value),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SizedBox(width: 110, child: TextField(controller: _itemPrice, decoration: const InputDecoration(labelText: 'selectedPrice'))),
                SizedBox(width: 140, child: TextField(controller: _quantity, decoration: const InputDecoration(labelText: 'quantityLabel'))),
                SizedBox(width: 140, child: TextField(controller: _tag, decoration: const InputDecoration(labelText: 'tagLabel'))),
                SizedBox(width: 110, child: TextField(controller: _itemSortOrder, decoration: const InputDecoration(labelText: 'sortOrder'))),
                SizedBox(width: 120, child: TextField(controller: _itemColor, decoration: const InputDecoration(labelText: 'storeColor'))),
              ],
            ),
            TextField(controller: _itemNameOverride, decoration: const InputDecoration(labelText: 'productNameSnapshot override (opsiyonel)')),
            TextField(controller: _itemBrandOverride, decoration: const InputDecoration(labelText: 'productBrandSnapshot override (opsiyonel)')),
            TextField(controller: _itemImageOverride, decoration: const InputDecoration(labelText: 'productImageUrlSnapshot override (opsiyonel)')),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('isActive'),
              value: _itemActive,
              onChanged: (value) => setState(() => _itemActive = value),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (_selectedProductId == null || _selectedStoreId == null || _selectedListId == null) return;
                  final product = products.firstWhere((p) => p.id == _selectedProductId);
                  final store = stores.firstWhere((s) => s.id == _selectedStoreId);

                  await service.upsertSpecialListItem(
                    listId: _selectedListId!,
                    item: SpecialListItemModel(
                      id: '',
                      productId: _selectedProductId!,
                      productNameSnapshot: _itemNameOverride.text.trim().isEmpty ? product.name : _itemNameOverride.text.trim(),
                      productBrandSnapshot: _itemBrandOverride.text.trim().isEmpty ? product.brand : _itemBrandOverride.text.trim(),
                      productImageUrlSnapshot: _itemImageOverride.text.trim().isEmpty
                          ? (product.mainImage ?? product.imageUrl ?? '')
                          : _itemImageOverride.text.trim(),
                      quantityLabel: _quantity.text.trim(),
                      tagLabel: _tag.text.trim(),
                      selectedStoreId: _selectedStoreId!,
                      selectedStoreNameSnapshot: store.displayName,
                      selectedStoreColor: _itemColor.text.trim().isEmpty ? '#D0A278' : _itemColor.text.trim(),
                      selectedPrice: double.tryParse(_itemPrice.text.replaceAll(',', '.')) ?? 0,
                      sortOrder: int.tryParse(_itemSortOrder.text) ?? 0,
                      isActive: _itemActive,
                    ),
                  );
                  _quantity.clear();
                  _tag.clear();
                  _itemPrice.text = '0';
                },
                icon: const Icon(Icons.add),
                label: const Text('Ürünü Listeye Ekle'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _fillListForm(SpecialListModel list) {
    setState(() {
      _selectedListId = list.id;
      _title.text = list.title;
      _subtitle.text = list.subtitle;
      _badge.text = list.badgeText;
      _description.text = list.description;
      _totalPrice.text = list.totalPrice.toString();
      _savingsAmount.text = list.savingsAmount.toString();
      _savingsLabel.text = list.savingsLabel;
      _bestMarket.text = list.bestMarketName;
      _ctaText.text = list.ctaText;
      _sortOrder.text = list.sortOrder.toString();
      _listActive = list.isActive;
      _ctaActionType = list.ctaActionType;
    });
  }

  void _clearListForm() {
    setState(() {
      _selectedListId = null;
      _title.clear();
      _subtitle.clear();
      _badge.clear();
      _description.clear();
      _bestMarket.clear();
      _totalPrice.text = '0';
      _savingsAmount.text = '0';
      _savingsLabel.text = 'Daha Ucuz';
      _ctaText.text = 'Sepeti Kıyasla';
      _sortOrder.text = '0';
      _listActive = true;
      _ctaActionType = SpecialListCtaActionType.compareCart;
    });
  }
}
