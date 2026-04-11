import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../../widgets/prototype_ui.dart';

class AddPriceTab extends StatefulWidget {
  const AddPriceTab({super.key});

  @override
  State<AddPriceTab> createState() => _AddPriceTabState();
}

class _AddPriceTabState extends State<AddPriceTab> {
  String? productId;
  String? store;
  final priceCtrl = TextEditingController();

  @override
  void dispose() {
    priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    return SafeArea(
      child: Column(
        children: [
          const ProtoTopBar(title: 'Fiyat Ekle'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 90),
              children: [
                const ProtoCard(
                  child: Text('Bu fiyatı eklersen +24 XP ve +1 Trust kazanırsın.', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: productId,
                  hint: const Text('Ürün seç'),
                  items: state.products
                      .map((e) => DropdownMenuItem(value: e.id, child: Text('${e.emoji} ${e.name}', overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (v) => setState(() => productId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: store,
                  hint: const Text('Market seç'),
                  items: state.stores.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setState(() => store = v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(labelText: 'Fiyat (TL)', hintText: '0,00'),
                ),
                const SizedBox(height: 12),
                const ProtoCard(
                  child: Row(children: [
                    Icon(Icons.check_circle_outline, color: ProtoColors.success),
                    SizedBox(width: 8),
                    Text('Fiyat makul aralıkta', style: TextStyle(color: ProtoColors.success, fontSize: 12, fontWeight: FontWeight.w600)),
                  ]),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [ProtoColors.tan, ProtoColors.tanLight]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: InkWell(
                    onTap: () async {
                      if (productId == null || store == null || priceCtrl.text.trim().isEmpty) return;
                      final price = double.tryParse(priceCtrl.text.replaceAll(',', '.'));
                      if (price == null) return;
                      await state.addPrice(productId: productId!, store: store!, price: price);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fiyat gönderildi')));
                    },
                    child: const Center(
                      child: Text('Fiyatı Gönder', style: TextStyle(color: ProtoColors.bgPrimary, fontWeight: FontWeight.w800)),
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
