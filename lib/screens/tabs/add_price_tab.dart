import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../state/app_state.dart';
import '../../theme.dart';

class AddPriceTab extends StatefulWidget {
  const AddPriceTab({super.key});

  @override
  State<AddPriceTab> createState() => _AddPriceTabState();
}

class _AddPriceTabState extends State<AddPriceTab> {
  final _formKey = GlobalKey<FormState>();
  Product? _selectedProduct;
  String? _selectedStore;
  final _priceCtrl = TextEditingController();
  final _newProductCtrl = TextEditingController();
  bool _newProductMode = false;

  @override
  void dispose() {
    _priceCtrl.dispose();
    _newProductCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStore == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Market seç')),
      );
      return;
    }
    final state = AppStateScope.of(context);
    final price = double.parse(_priceCtrl.text.replaceAll(',', '.'));

    if (_newProductMode) {
      await state.addProduct(
        name: _newProductCtrl.text.trim(),
        brand: '-',
        category: 'Tümü',
        emoji: '🛒',
        unit: '1 adet',
      );
      // Newly added product will stream in; skip price add this round.
    } else {
      if (_selectedProduct == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ürün seç')),
        );
        return;
      }
      await state.addPrice(
        productId: _selectedProduct!.id,
        store: _selectedStore!,
        price: price,
      );
    }
    if (!mounted) return;

    _priceCtrl.clear();
    _newProductCtrl.clear();
    setState(() {
      _selectedProduct = null;
      _selectedStore = null;
      _newProductMode = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Teşekkürler ☕ Katkın için puan kazandın'),
        backgroundColor: CoffeeColors.darkRoast,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Fiyat Ekle',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: CoffeeColors.espresso)),
              const SizedBox(height: 4),
              const Text(
                'Markette gördüğün fiyatı paylaş, topluluğa katkıda bulun.',
                style: TextStyle(color: CoffeeColors.cocoa),
              ),
              const SizedBox(height: 24),
              _Label('Ürün'),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Mevcut ürün'),
                    selected: !_newProductMode,
                    onSelected: (_) =>
                        setState(() => _newProductMode = false),
                    selectedColor: CoffeeColors.espresso,
                    labelStyle: TextStyle(
                      color: !_newProductMode
                          ? CoffeeColors.cream
                          : CoffeeColors.darkRoast,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Yeni ürün'),
                    selected: _newProductMode,
                    onSelected: (_) =>
                        setState(() => _newProductMode = true),
                    selectedColor: CoffeeColors.espresso,
                    labelStyle: TextStyle(
                      color: _newProductMode
                          ? CoffeeColors.cream
                          : CoffeeColors.darkRoast,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_newProductMode)
                TextFormField(
                  controller: _newProductCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Ürün adı (örn: Süt 1L)',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Zorunlu' : null,
                )
              else
                DropdownButtonFormField<Product>(
                  value: _selectedProduct,
                  isExpanded: true,
                  decoration: const InputDecoration(
                      hintText: 'Ürün seç'),
                  items: state.products
                      .map((p) => DropdownMenuItem(
                            value: p,
                            child: Text('${p.emoji}  ${p.name}'),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedProduct = v),
                ),
              const SizedBox(height: 20),
              _Label('Market'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: state.stores.map((s) {
                  final selected = s == _selectedStore;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedStore = s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? CoffeeColors.espresso
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: selected
                                ? CoffeeColors.espresso
                                : CoffeeColors.crema),
                      ),
                      child: Text(
                        s,
                        style: TextStyle(
                          color: selected
                              ? CoffeeColors.cream
                              : CoffeeColors.darkRoast,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              _Label('Fiyat (₺)'),
              TextFormField(
                controller: _priceCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(hintText: 'örn: 24,90'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Zorunlu';
                  final p =
                      double.tryParse(v.replaceAll(',', '.'));
                  if (p == null || p <= 0) return 'Geçerli fiyat gir';
                  return null;
                },
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.check),
                label: const Text('Fiyatı Paylaş'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: const TextStyle(
              color: CoffeeColors.darkRoast,
              fontWeight: FontWeight.w700,
              fontSize: 14)),
    );
  }
}
