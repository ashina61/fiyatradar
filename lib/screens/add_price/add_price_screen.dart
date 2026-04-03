import 'package:flutter/material.dart';

import '../../theme/neo_design.dart';

class AddPriceScreen extends StatefulWidget {
  const AddPriceScreen({super.key, this.initialProductId});

  final String? initialProductId;

  @override
  State<AddPriceScreen> createState() => _AddPriceScreenState();
}

class _AddPriceScreenState extends State<AddPriceScreen> {
  final _product = TextEditingController();
  final _store = TextEditingController();
  final _price = TextEditingController();

  @override
  void initState() {
    super.initState();
    _product.text = widget.initialProductId ?? '';
  }

  @override
  void dispose() {
    _product.dispose();
    _store.dispose();
    _price.dispose();
    super.dispose();
  }

  void _submit() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yeni fiyat taslak olarak kaydedildi.')));
  }

  @override
  Widget build(BuildContext context) {
    return NeoScaffold(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Fiyat Ekle', style: NeoDesign.title()),
          const SizedBox(height: 8),
          Text('Temiz form yapısı ile hızlı veri girişi.', style: NeoDesign.body()),
          const SizedBox(height: 16),
          TextField(controller: _product, decoration: NeoDesign.input('Ürün adı / kodu', icon: Icons.inventory_2_outlined)),
          const SizedBox(height: 10),
          TextField(controller: _store, decoration: NeoDesign.input('Market', icon: Icons.store_outlined)),
          const SizedBox(height: 10),
          TextField(controller: _price, keyboardType: TextInputType.number, decoration: NeoDesign.input('Fiyat (₺)', icon: Icons.currency_lira)),
          const SizedBox(height: 18),
          FilledButton(onPressed: _submit, child: const Text('Kaydet')),
        ],
      ),
    );
  }
}
