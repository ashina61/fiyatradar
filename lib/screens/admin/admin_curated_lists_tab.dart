import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/product_model.dart';
import '../../models/special_list_item_model.dart';
import '../../models/special_list_model.dart';
import '../../models/store_model.dart';
import '../../providers/product_provider.dart';
import '../../providers/special_list_provider.dart';
import '../../services/special_list_service.dart';
import '../../theme/fr_colors.dart';

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

  final _productSearch = TextEditingController();
  final _storeSearch = TextEditingController();
  final _quantity = TextEditingController();
  final _tag = TextEditingController();
  final _itemPrice = TextEditingController(text: '0');

  String? _selectedListId;
  String? _selectedProductId;
  String? _selectedStoreId;
  bool _listActive = true;
  bool _itemActive = true;
  SpecialListCtaActionType _ctaActionType = SpecialListCtaActionType.compareCart;
  List<SpecialListModel> _listsCache = const [];
  List<SpecialListItemModel> _itemsCache = const [];

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
      _productSearch,
      _storeSearch,
      _quantity,
      _tag,
      _itemPrice,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(specialListServiceProvider);
    final listsAsync = ref.watch(adminSpecialListsProvider);
    final productsAsync = ref.watch(allProductsProvider);
    final storesAsync = ref.watch(allStoresStreamProvider);

    return Container(
      color: FRColors.backgroundWarm,
      child: Row(
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
                      _listsCache = lists;
                      if (lists.isEmpty) return const Center(child: Text('Henüz özel liste yok.'));
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        itemCount: lists.length,
                        itemBuilder: (context, index) {
                          final list = lists[index];
                          return Card(
                            color: FRColors.surface,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: FRColors.camelOverlay(0.2)),
                            ),
                            child: ListTile(
                              selected: list.id == _selectedListId,
                              title: Text(list.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                              subtitle: Text(list.subtitle),
                              onTap: () => _fillListForm(list),
                              trailing: Wrap(
                                spacing: 2,
                                children: [
                                  IconButton(
                                    tooltip: 'Yukarı taşı',
                                    icon: const Icon(Icons.arrow_upward_rounded),
                                    onPressed: index == 0 ? null : () => _moveList(service, lists, index, index - 1),
                                  ),
                                  IconButton(
                                    tooltip: 'Aşağı taşı',
                                    icon: const Icon(Icons.arrow_downward_rounded),
                                    onPressed: index == lists.length - 1 ? null : () => _moveList(service, lists, index, index + 1),
                                  ),
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
                            final itemsAsync = ref.watch(adminSpecialListItemsProvider(_selectedListId!));
                            return itemsAsync.when(
                              loading: () => const Center(child: CircularProgressIndicator()),
                              error: (_, __) => const Center(child: Text('Liste ürünleri yüklenemedi.')),
                              data: (items) {
                                _itemsCache = items;
                                if (items.isEmpty) return const Center(child: Text('Bu listede ürün yok.'));
                                return ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                                  itemCount: items.length,
                                  itemBuilder: (context, index) {
                                    final item = items[index];
                                    return Card(
                                      key: ValueKey(item.id),
                                      color: FRColors.surface,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        side: BorderSide(color: FRColors.camelOverlay(0.2)),
                                      ),
                                      child: ListTile(
                                        leading: ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: SizedBox(
                                            width: 46,
                                            height: 46,
                                            child: item.productImageUrlSnapshot.isNotEmpty
                                                ? Image.network(
                                                    item.productImageUrlSnapshot,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_outlined),
                                                  )
                                                : const Icon(Icons.shopping_bag_outlined),
                                          ),
                                        ),
                                        title: Text(item.productNameSnapshot, style: const TextStyle(fontWeight: FontWeight.w700)),
                                        subtitle: Text(
                                          '${item.productBrandSnapshot} • ${item.selectedStoreNameSnapshot}\n'
                                          '${item.selectedPrice.toStringAsFixed(2)}₺'
                                          '${item.quantityLabel.isNotEmpty ? ' • ${item.quantityLabel}' : ''}'
                                          '${item.tagLabel.isNotEmpty ? ' • ${item.tagLabel}' : ''}',
                                        ),
                                        isThreeLine: true,
                                        trailing: Wrap(
                                          spacing: 2,
                                          children: [
                                            IconButton(
                                              tooltip: 'Yukarı taşı',
                                              icon: const Icon(Icons.arrow_upward_rounded),
                                              onPressed: index == 0
                                                  ? null
                                                  : () => _moveItem(service, _selectedListId!, items, index, index - 1),
                                            ),
                                            IconButton(
                                              tooltip: 'Aşağı taşı',
                                              icon: const Icon(Icons.arrow_downward_rounded),
                                              onPressed: index == items.length - 1
                                                  ? null
                                                  : () => _moveItem(service, _selectedListId!, items, index, index + 1),
                                            ),
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
      ),
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
                sortOrder: _nextListSortOrder(),
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
      color: FRColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: FRColors.camelOverlay(0.2))),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
            TextField(controller: _totalPrice, decoration: const InputDecoration(labelText: 'totalPrice')),
            TextField(controller: _savingsAmount, decoration: const InputDecoration(labelText: 'savingsAmount')),
            TextField(controller: _savingsLabel, decoration: const InputDecoration(labelText: 'savingsLabel')),
            TextField(controller: _bestMarket, decoration: const InputDecoration(labelText: 'bestMarketName')),
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
                        sortOrder: _nextListSortOrder(),
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
      color: FRColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: FRColors.camelOverlay(0.2))),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Align(alignment: Alignment.centerLeft, child: Text('Liste Ürün Ekleme', style: TextStyle(fontWeight: FontWeight.w800))),
            _searchableProductField(products),
            const SizedBox(height: 8),
            _searchableStoreField(stores),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SizedBox(width: 130, child: TextField(controller: _itemPrice, decoration: const InputDecoration(labelText: 'selectedPrice'))),
                SizedBox(width: 160, child: TextField(controller: _quantity, decoration: const InputDecoration(labelText: 'quantityLabel'))),
                SizedBox(width: 160, child: TextField(controller: _tag, decoration: const InputDecoration(labelText: 'tagLabel'))),
              ],
            ),
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
                      productNameSnapshot: product.name,
                      productBrandSnapshot: product.brand,
                      productImageUrlSnapshot: product.mainImage ?? product.imageUrl ?? '',
                      quantityLabel: _quantity.text.trim(),
                      tagLabel: _tag.text.trim(),
                      selectedStoreId: _selectedStoreId!,
                      selectedStoreNameSnapshot: store.displayName,
                      selectedStoreColor: _storeColorHex(store.displayName),
                      selectedPrice: double.tryParse(_itemPrice.text.replaceAll(',', '.')) ?? 0,
                      sortOrder: _nextItemSortOrder(),
                      isActive: _itemActive,
                    ),
                  );
                  _quantity.clear();
                  _tag.clear();
                  _itemPrice.text = '0';
                },
                icon: const Icon(Icons.add),
                label: const Text('Listeye Ekle'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchableProductField(List<ProductModel> products) {
    return Autocomplete<ProductModel>(
      optionsBuilder: (value) {
        final query = value.text.trim().toLowerCase();
        if (query.isEmpty) return products.take(30);
        return products.where((product) {
          final label = '${product.brand} ${product.name}'.toLowerCase();
          return label.contains(query);
        }).take(30);
      },
      displayStringForOption: (option) => '${option.brand} - ${option.name}',
      onSelected: (product) {
        setState(() {
          _selectedProductId = product.id;
          _productSearch.text = '${product.brand} - ${product.name}';
          if ((_itemPrice.text.trim().isEmpty || _itemPrice.text.trim() == '0') && product.lastPrice != null) {
            _itemPrice.text = product.lastPrice!.toStringAsFixed(2);
          }
        });
      },
      fieldViewBuilder: (context, textEditingController, focusNode, _) {
        textEditingController
          ..text = _productSearch.text
          ..selection = TextSelection.collapsed(offset: _productSearch.text.length);
        return TextField(
          controller: textEditingController,
          focusNode: focusNode,
          onChanged: (value) {
            _productSearch.text = value;
            _selectedProductId = null;
          },
          decoration: const InputDecoration(
            labelText: 'Ürün ara / ürün seç',
            prefixIcon: Icon(Icons.search),
          ),
        );
      },
    );
  }

  Widget _searchableStoreField(List<StoreModel> stores) {
    return Autocomplete<StoreModel>(
      optionsBuilder: (value) {
        final query = value.text.trim().toLowerCase();
        if (query.isEmpty) return stores.take(30);
        return stores.where((store) => store.displayName.toLowerCase().contains(query)).take(30);
      },
      displayStringForOption: (option) => option.displayName,
      onSelected: (store) {
        setState(() {
          _selectedStoreId = store.id;
          _storeSearch.text = store.displayName;
        });
      },
      fieldViewBuilder: (context, textEditingController, focusNode, _) {
        textEditingController
          ..text = _storeSearch.text
          ..selection = TextSelection.collapsed(offset: _storeSearch.text.length);
        return TextField(
          controller: textEditingController,
          focusNode: focusNode,
          onChanged: (value) {
            _storeSearch.text = value;
            _selectedStoreId = null;
          },
          decoration: const InputDecoration(
            labelText: 'Market ara / market seç',
            prefixIcon: Icon(Icons.storefront_outlined),
          ),
        );
      },
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
      _listActive = true;
      _ctaActionType = SpecialListCtaActionType.compareCart;
      _selectedProductId = null;
      _selectedStoreId = null;
      _productSearch.clear();
      _storeSearch.clear();
    });
  }

  int _nextListSortOrder() {
    if (_listsCache.isEmpty) return 0;
    final maxSortOrder = _listsCache.map((e) => e.sortOrder).reduce((a, b) => a > b ? a : b);
    return maxSortOrder + 1;
  }

  int _nextItemSortOrder() {
    if (_itemsCache.isEmpty) return 0;
    final maxSortOrder = _itemsCache.map((e) => e.sortOrder).reduce((a, b) => a > b ? a : b);
    return maxSortOrder + 1;
  }

  Future<void> _moveList(SpecialListService service, List<SpecialListModel> lists, int oldIndex, int newIndex) async {
    final reordered = [...lists];
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);
    for (var i = 0; i < reordered.length; i++) {
      await service.updateSpecialList(reordered[i].id, {'sortOrder': i});
    }
  }

  Future<void> _moveItem(
    SpecialListService service,
    String listId,
    List<SpecialListItemModel> items,
    int oldIndex,
    int newIndex,
  ) async {
    final reordered = [...items];
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);
    for (var i = 0; i < reordered.length; i++) {
      await service.upsertSpecialListItem(
        listId: listId,
        itemId: reordered[i].id,
        item: reordered[i].copyWith(sortOrder: i),
      );
    }
  }

  String _storeColorHex(String storeName) {
    final normalized = storeName.toLowerCase();
    if (normalized.contains('bim')) return '#F5C518';
    if (normalized.contains('a101')) return '#E8502A';
    if (normalized.contains('şok') || normalized.contains('sok')) return '#8B5CF6';
    if (normalized.contains('migros')) return '#F0A030';
    return '#D0A278';
  }
}
