import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/product_model.dart';
import '../../models/special_list_item_model.dart';
import '../../models/special_list_model.dart';
import '../../models/store_model.dart';
import '../../providers/product_provider.dart';
import '../../providers/special_list_provider.dart';

class AdminCuratedListsTab extends ConsumerStatefulWidget {
  const AdminCuratedListsTab({super.key});

  @override
  ConsumerState<AdminCuratedListsTab> createState() => _AdminCuratedListsTabState();
}

class _AdminCuratedListsTabState extends ConsumerState<AdminCuratedListsTab> {
  String? _selectedListId;

  @override
  Widget build(BuildContext context) {
    final listsAsync = ref.watch(adminSpecialListsProvider);
    final products = ref.watch(allProductsProvider).valueOrNull ?? const <ProductModel>[];
    final stores = ref.watch(allStoresStreamProvider).valueOrNull ?? const <StoreModel>[];

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: listsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(child: Text('Özel listeler yüklenemedi.')),
            data: (lists) {
              if (lists.isEmpty) {
                return _ListPanel(
                  selectedListId: _selectedListId,
                  lists: lists,
                  onCreate: () => _showCreateListDialog(context),
                  onSelect: (_) {},
                );
              }

              _selectedListId ??= lists.first.id;
              final selected = lists.where((item) => item.id == _selectedListId).firstOrNull ?? lists.first;
              if (_selectedListId != selected.id) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() => _selectedListId = selected.id);
                  }
                });
              }

              return _ListPanel(
                selectedListId: _selectedListId,
                lists: lists,
                onCreate: () => _showCreateListDialog(context),
                onSelect: (id) => setState(() => _selectedListId = id),
              );
            },
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 3,
          child: _selectedListId == null
              ? const Center(child: Text('Düzenlemek için sol taraftan bir liste seç.'))
              : _SpecialListEditor(
                  listId: _selectedListId!,
                  products: products,
                  stores: stores,
                  onDeleted: () => setState(() => _selectedListId = null),
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
              final id = await service.createSpecialList({
                'title': titleController.text.trim(),
                'subtitle': subtitleController.text.trim(),
                'badgeText': 'ÖZEL LİSTE',
                'description': '',
                'coverType': 'default',
                'coverImageUrl': null,
                'totalPrice': 0,
                'savingsAmount': 0,
                'savingsLabel': '',
                'bestMarketName': '',
                'ctaText': 'Sepeti Kıyasla',
                'ctaActionType': SpecialListCtaActionType.compareCart.value,
                'isActive': true,
                'sortOrder': DateTime.now().millisecondsSinceEpoch,
              });
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
}

class _ListPanel extends StatelessWidget {
  const _ListPanel({
    required this.selectedListId,
    required this.lists,
    required this.onCreate,
    required this.onSelect,
  });

  final String? selectedListId;
  final List<SpecialListModel> lists;
  final VoidCallback onCreate;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Expanded(child: Text('Özel Listeler', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
              ElevatedButton.icon(onPressed: onCreate, icon: const Icon(Icons.add), label: const Text('Yeni Liste')),
            ],
          ),
        ),
        Expanded(
          child: lists.isEmpty
              ? const Center(child: Text('Henüz özel liste oluşturulmadı.'))
              : ListView.builder(
                  itemCount: lists.length,
                  itemBuilder: (context, index) {
                    final list = lists[index];
                    return ListTile(
                      selected: selectedListId == list.id,
                      title: Text(list.title),
                      subtitle: Text('Sıra: ${list.sortOrder} · ${list.isActive ? 'Aktif' : 'Pasif'}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => onSelect(list.id),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _SpecialListEditor extends ConsumerStatefulWidget {
  const _SpecialListEditor({
    required this.listId,
    required this.products,
    required this.stores,
    required this.onDeleted,
  });

  final String listId;
  final List<ProductModel> products;
  final List<StoreModel> stores;
  final VoidCallback onDeleted;

  @override
  ConsumerState<_SpecialListEditor> createState() => _SpecialListEditorState();
}

class _SpecialListEditorState extends ConsumerState<_SpecialListEditor> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _subtitleController;
  late final TextEditingController _badgeController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _totalPriceController;
  late final TextEditingController _savingsAmountController;
  late final TextEditingController _savingsLabelController;
  late final TextEditingController _bestMarketController;
  late final TextEditingController _ctaController;
  late final TextEditingController _sortOrderController;

  bool _isActive = true;
  SpecialListCtaActionType _ctaType = SpecialListCtaActionType.compareCart;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _subtitleController = TextEditingController();
    _badgeController = TextEditingController();
    _descriptionController = TextEditingController();
    _totalPriceController = TextEditingController();
    _savingsAmountController = TextEditingController();
    _savingsLabelController = TextEditingController();
    _bestMarketController = TextEditingController();
    _ctaController = TextEditingController();
    _sortOrderController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _badgeController.dispose();
    _descriptionController.dispose();
    _totalPriceController.dispose();
    _savingsAmountController.dispose();
    _savingsLabelController.dispose();
    _bestMarketController.dispose();
    _ctaController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(specialListByIdProvider(widget.listId));
    final itemsAsync = ref.watch(specialListServiceProvider).watchItems(widget.listId, activeOnly: false);

    return listAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Liste verisi yüklenemedi.')),
      data: (list) {
        if (list == null) {
          return const Center(child: Text('Liste bulunamadı.'));
        }

        _syncControllers(list);

        return StreamBuilder<List<SpecialListItemModel>>(
          stream: itemsAsync,
          builder: (context, snapshot) {
            final items = snapshot.data ?? const <SpecialListItemModel>[];
            return SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Liste Ayarları', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _input(_titleController, 'Liste adı'),
                        _input(_subtitleController, 'Hero başlık'),
                        _input(_badgeController, 'Badge metni'),
                        _input(_descriptionController, 'Açıklama', maxLines: 2),
                        _input(_totalPriceController, 'Toplam fiyat', type: TextInputType.number),
                        _input(_savingsAmountController, 'Tasarruf tutarı', type: TextInputType.number),
                        _input(_savingsLabelController, 'Tasarruf etiketi'),
                        _input(_bestMarketController, 'En iyi market adı'),
                        _input(_ctaController, 'CTA metni'),
                        _input(_sortOrderController, 'Sıralama', type: TextInputType.number),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Switch(value: _isActive, onChanged: (v) => setState(() => _isActive = v)),
                        const Text('Aktif'),
                        const SizedBox(width: 24),
                        DropdownButton<SpecialListCtaActionType>(
                          value: _ctaType,
                          onChanged: (value) => setState(() => _ctaType = value ?? SpecialListCtaActionType.none),
                          items: SpecialListCtaActionType.values
                              .map((type) => DropdownMenuItem(value: type, child: Text(type.value)))
                              .toList(),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: _save,
                          icon: const Icon(Icons.save),
                          label: const Text('Kaydet'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () => _deleteList(context),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Sil'),
                        ),
                      ],
                    ),
                    const Divider(height: 28),
                    Row(
                      children: [
                        const Text('Liste Ürünleri', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: () => _showAddItemDialog(context, items),
                          icon: const Icon(Icons.add),
                          label: const Text('Ürün Ekle'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (items.isEmpty)
                      const Text('Bu listeye henüz ürün eklenmemiş.')
                    else
                      ...items.indexed.map((entry) {
                        final index = entry.$1;
                        final item = entry.$2;
                        return Card(
                          child: ListTile(
                            title: Text('${item.productBrandSnapshot} ${item.productNameSnapshot}'),
                            subtitle: Text('${item.selectedStoreNameSnapshot} · ${item.selectedPrice.toStringAsFixed(2)}₺'),
                            leading: Switch(
                              value: item.isActive,
                              onChanged: (value) {
                                ref.read(specialListServiceProvider).updateItem(widget.listId, item.id, {'isActive': value});
                              },
                            ),
                            trailing: Wrap(
                              spacing: 4,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_upward),
                                  onPressed: index == 0 ? null : () => _swapSortOrder(items[index - 1], item),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.arrow_downward),
                                  onPressed: index == items.length - 1 ? null : () => _swapSortOrder(item, items[index + 1]),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => ref.read(specialListServiceProvider).deleteItem(widget.listId, item.id),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _input(TextEditingController controller, String label, {int maxLines = 1, TextInputType? type}) {
    return SizedBox(
      width: 280,
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: type,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      ),
    );
  }

  void _syncControllers(SpecialListModel list) {
    if (_titleController.text != list.title) _titleController.text = list.title;
    if (_subtitleController.text != list.subtitle) _subtitleController.text = list.subtitle;
    if (_badgeController.text != list.badgeText) _badgeController.text = list.badgeText;
    if (_descriptionController.text != list.description) _descriptionController.text = list.description;
    if (_totalPriceController.text != list.totalPrice.toString()) _totalPriceController.text = list.totalPrice.toString();
    if (_savingsAmountController.text != list.savingsAmount.toString()) _savingsAmountController.text = list.savingsAmount.toString();
    if (_savingsLabelController.text != list.savingsLabel) _savingsLabelController.text = list.savingsLabel;
    if (_bestMarketController.text != list.bestMarketName) _bestMarketController.text = list.bestMarketName;
    if (_ctaController.text != list.ctaText) _ctaController.text = list.ctaText;
    if (_sortOrderController.text != list.sortOrder.toString()) _sortOrderController.text = list.sortOrder.toString();
    _isActive = list.isActive;
    _ctaType = list.ctaActionType;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(specialListServiceProvider).updateSpecialList(widget.listId, {
      'title': _titleController.text.trim(),
      'subtitle': _subtitleController.text.trim(),
      'badgeText': _badgeController.text.trim(),
      'description': _descriptionController.text.trim(),
      'totalPrice': double.tryParse(_totalPriceController.text.replaceAll(',', '.')) ?? 0,
      'savingsAmount': double.tryParse(_savingsAmountController.text.replaceAll(',', '.')) ?? 0,
      'savingsLabel': _savingsLabelController.text.trim(),
      'bestMarketName': _bestMarketController.text.trim(),
      'ctaText': _ctaController.text.trim(),
      'ctaActionType': _ctaType.value,
      'isActive': _isActive,
      'sortOrder': int.tryParse(_sortOrderController.text) ?? 0,
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Liste güncellendi.')));
  }

  Future<void> _deleteList(BuildContext context) async {
    final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Liste silinsin mi?'),
            content: const Text('Liste ve tüm ürünleri kalıcı olarak silinecek.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
              ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sil')),
            ],
          ),
        ) ??
        false;
    if (!confirm) return;

    await ref.read(specialListServiceProvider).deleteSpecialList(widget.listId);
    widget.onDeleted();
  }

  Future<void> _swapSortOrder(SpecialListItemModel first, SpecialListItemModel second) async {
    await ref.read(specialListServiceProvider).updateItem(widget.listId, first.id, {'sortOrder': second.sortOrder});
    await ref.read(specialListServiceProvider).updateItem(widget.listId, second.id, {'sortOrder': first.sortOrder});
  }

  Future<void> _showAddItemDialog(BuildContext context, List<SpecialListItemModel> existingItems) async {
    ProductModel? selectedProduct;
    StoreModel? selectedStore;
    final quantityController = TextEditingController();
    final tagController = TextEditingController();
    final priceController = TextEditingController();
    final imageController = TextEditingController();
    final nameController = TextEditingController();
    final brandController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Listeye Ürün Ekle'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 420,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<ProductModel>(
                        value: selectedProduct,
                        hint: const Text('Ürün seç'),
                        onChanged: (value) {
                          setStateDialog(() {
                            selectedProduct = value;
                            if (value != null) {
                              nameController.text = value.name;
                              brandController.text = value.brand;
                              imageController.text = value.mainImage ?? value.imageUrl ?? '';
                              priceController.text = (value.lastPrice ?? 0).toString();
                            }
                          });
                        },
                        items: widget.products
                            .map((product) => DropdownMenuItem(value: product, child: Text('${product.brand} ${product.name}')))
                            .toList(),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<StoreModel>(
                        value: selectedStore,
                        hint: const Text('Market seç'),
                        onChanged: (value) => setStateDialog(() => selectedStore = value),
                        items: widget.stores
                            .map((store) => DropdownMenuItem(value: store, child: Text(store.displayName)))
                            .toList(),
                      ),
                      const SizedBox(height: 8),
                      TextField(controller: quantityController, decoration: const InputDecoration(labelText: 'Miktar etiketi')),
                      TextField(controller: tagController, decoration: const InputDecoration(labelText: 'Tag etiketi')),
                      TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Fiyat override')),
                      TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Ürün adı snapshot')),
                      TextField(controller: brandController, decoration: const InputDecoration(labelText: 'Marka snapshot')),
                      TextField(controller: imageController, decoration: const InputDecoration(labelText: 'Görsel URL snapshot')),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedProduct == null) return;
                    final item = SpecialListItemModel(
                      id: '',
                      productId: selectedProduct!.id,
                      productNameSnapshot: nameController.text.trim(),
                      productBrandSnapshot: brandController.text.trim(),
                      productImageUrlSnapshot: imageController.text.trim(),
                      quantityLabel: quantityController.text.trim(),
                      tagLabel: tagController.text.trim(),
                      selectedStoreId: selectedStore?.id,
                      selectedStoreNameSnapshot: selectedStore?.displayName ?? '',
                      selectedStoreColor: '#BF9470',
                      selectedPrice: double.tryParse(priceController.text.replaceAll(',', '.')) ?? 0,
                      sortOrder: existingItems.length,
                      isActive: true,
                    );
                    await ref.read(specialListServiceProvider).addItem(widget.listId, item);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Kaydet'),
                ),
              ],
            );
          },
        );
      },
    );

    quantityController.dispose();
    tagController.dispose();
    priceController.dispose();
    imageController.dispose();
    nameController.dispose();
    brandController.dispose();
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
