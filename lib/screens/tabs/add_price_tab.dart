import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../../widgets/prototype_ui.dart';

class AddPriceTab extends StatefulWidget {
  const AddPriceTab({super.key});

  @override
  State<AddPriceTab> createState() => _AddPriceTabState();
}

class _AddPriceTabState extends State<AddPriceTab> {
  String store = 'Trendyol';
  final priceCtrl = TextEditingController();
  final noteCtrl = TextEditingController();

  @override
  void dispose() {
    priceCtrl.dispose();
    noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickStore(List<String> stores) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: ProtoColors.bgSecondary,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 38, height: 4, decoration: BoxDecoration(color: ProtoColors.border, borderRadius: FRRadii.pill)),
              const SizedBox(height: 12),
              const Text('Fiyat Kaynağı Seç', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              ...stores.map(
                (s) => ListTile(
                  shape: RoundedRectangleBorder(borderRadius: FRRadii.md),
                  tileColor: s == store ? ProtoColors.tan.withOpacity(0.12) : ProtoColors.surface,
                  title: Text(s, style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: s == store ? const Icon(Icons.check, color: ProtoColors.tan) : null,
                  onTap: () => Navigator.pop(context, s),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) setState(() => store = picked);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    return SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 16, 24, 12),
            child: Row(children: [
              Icon(Icons.arrow_back, size: 20),
              SizedBox(width: 12),
              Expanded(child: Text('Fiyat Ekle', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
              SizedBox(width: 36),
            ]),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              children: [
                Container(
                  height: 72,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(color: ProtoColors.surface, borderRadius: FRRadii.lg, border: Border.all(color: ProtoColors.border)),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: ProtoColors.surfaceAlt,
                          borderRadius: FRRadii.md,
                          border: Border.all(color: ProtoColors.border),
                        ),
                        alignment: Alignment.center,
                        child: const Text('⌚', style: TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Apple Watch SE 2. Nesil',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(foregroundColor: ProtoColors.tan, textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        child: const Text('Değiştir'),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: ProtoColors.success.withOpacity(0.1),
                    borderRadius: FRRadii.lg,
                    border: Border.all(color: ProtoColors.success.withOpacity(0.2)),
                  ),
                  child: const Text('Bu fiyatı eklersen +24 XP ve +1 Trust kazanırsın.', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
                _label('Fiyat Kaynağı'),
                InkWell(
                  onTap: () => _pickStore(state.stores),
                  borderRadius: FRRadii.lg,
                  child: Container(
                    height: 50,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: ProtoColors.surface,
                      borderRadius: FRRadii.lg,
                      border: Border.all(color: ProtoColors.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: Text(store, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500))),
                        const Icon(Icons.keyboard_arrow_down, color: ProtoColors.textSubtle),
                      ],
                    ),
                  ),
                ),
                _label('Fiyat (TL)'),
                Container(
                  height: 50,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(color: ProtoColors.surface, borderRadius: FRRadii.lg, border: Border.all(color: ProtoColors.border)),
                  child: TextField(
                    controller: priceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                    decoration: const InputDecoration(border: InputBorder.none, hintText: '0,00'),
                  ),
                ),
                _label('Not'),
                Container(
                  height: 50,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(color: ProtoColors.surface, borderRadius: FRRadii.lg, border: Border.all(color: ProtoColors.border)),
                  child: TextField(controller: noteCtrl, decoration: const InputDecoration(border: InputBorder.none, hintText: 'Opsiyonel notlar')),
                ),
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: ProtoColors.success.withOpacity(0.12),
                    borderRadius: FRRadii.md,
                    border: Border.all(color: ProtoColors.success.withOpacity(0.3)),
                  ),
                  child: const Row(children: [
                    Icon(Icons.check_circle, color: ProtoColors.success, size: 16),
                    SizedBox(width: 8),
                    Text('Fiyat makul aralıkta', style: TextStyle(fontSize: 12, color: ProtoColors.success, fontWeight: FontWeight.w600)),
                  ]),
                ),
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: ProtoColors.surface, borderRadius: FRRadii.lg, border: Border.all(color: ProtoColors.border)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('GÜVEN KATKILARI', style: TextStyle(fontSize: 11, color: ProtoColors.textSubtle, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                    const SizedBox(height: 10),
                    GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 2.4,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: const [_Impact('Kaynak Kalitesi +2'), _Impact('Hız +1'), _Impact('Tutarlılık +3'), _Impact('Topluluk +1')],
                    )
                  ]),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 18),
            decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, ProtoColors.bgPrimary.withOpacity(0.95)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
            child: Column(children: [
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final pid = state.products.isEmpty ? '' : state.products.first.id;
                    if (pid.isEmpty) return;
                    final value = double.tryParse(priceCtrl.text.replaceAll(',', '.')) ?? 0;
                    await state.addPrice(productId: pid, store: store, price: value);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Fiyat başarıyla eklendi!')));
                  },
                  icon: const Icon(Icons.send),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ProtoColors.tan,
                    foregroundColor: ProtoColors.bgPrimary,
                    shape: RoundedRectangleBorder(borderRadius: FRRadii.lg),
                  ),
                  label: const Text('Fiyatı Gönder', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Katkınız topluluk tarafından doğrulanacaktır.', style: TextStyle(fontSize: 10, color: ProtoColors.textSubtle)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      );
}

class _Impact extends StatelessWidget {
  const _Impact(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ProtoColors.surfaceAlt,
        borderRadius: FRRadii.md,
        border: Border.all(color: ProtoColors.border),
      ),
      child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }
}
