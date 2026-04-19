import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../../widgets/executive_ui.dart';

class AddPriceTab extends StatefulWidget {
  const AddPriceTab({super.key});

  @override
  State<AddPriceTab> createState() => _AddPriceTabState();
}

class _AddPriceTabState extends State<AddPriceTab> {
  String store = 'A101';
  final priceCtrl = TextEditingController();
  final noteCtrl = TextEditingController();

  @override
  void dispose() {
    priceCtrl.dispose();
    noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    return SafeArea(
      child: Column(
        children: [
          const _PageHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: ExecRadii.xl,
                    gradient: const LinearGradient(colors: [ExecColors.espresso2, ExecColors.espresso]),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('RADAR EKOSİSTEMİ', style: manrope(10, FontWeight.w800, color: ExecColors.gold, letterSpacing: 1.9)),
                    const SizedBox(height: 8),
                    Text('Her katkın topluluğu güçlendirir', style: fraunces(26, FontWeight.w700, color: ExecColors.onDark)),
                    const SizedBox(height: 8),
                    Text('Eklediğin her fiyat onaylandığında puan kazanırsın. Doğrulamalar güven skorunu yükseltir.', style: manrope(13, FontWeight.w600, color: const Color(0xFFC9BCA6))),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: const Color(0x26C9A063), borderRadius: ExecRadii.pill),
                      child: Text('+25 PT · Eklenen her onaylı fiyat için', style: manrope(11, FontWeight.w800, color: ExecColors.gold)),
                    )
                  ]),
                ),
                const SizedBox(height: 16),
                _label('Ürün'),
                _inputRow(icon: Icons.search, hint: 'Sadece onaylı ürünlerde ara…', suffix: TextButton(onPressed: () {}, child: Text('Yeni talep', style: manrope(11, FontWeight.w800, color: ExecColors.goldDeep)))),
                const SizedBox(height: 8),
                Text('Aradığın ürün listede yok mu? Yeni ürün talep et — admin inceledikten sonra katalogta yerini alır.', style: manrope(11, FontWeight.w600, color: ExecColors.ink3)),
                const SizedBox(height: 12),
                _label('Mağaza / Market'),
                Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: execCard(radius: 16),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: store,
                      icon: const Icon(Icons.keyboard_arrow_down),
                      items: state.stores.map((e) => DropdownMenuItem(value: e, child: Text(e, style: manrope(14, FontWeight.w700)))).toList(),
                      onChanged: (v) => setState(() => store = v ?? store),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: ['Online', 'Yerel Zincir', 'Büyük Mağaza', 'Mahalle'].map((e) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: ExecColors.surface2, borderRadius: ExecRadii.pill, border: Border.all(color: ExecColors.bgDeep)), child: Text(e, style: manrope(11, FontWeight.w700, color: ExecColors.ink3)))).toList()),
                const SizedBox(height: 14),
                _label('Fiyat'),
                Container(height: 52, padding: const EdgeInsets.symmetric(horizontal: 12), decoration: execCard(radius: 16), child: TextField(controller: priceCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(border: InputBorder.none, hintText: '0,00 ₺', hintStyle: manrope(16, FontWeight.w700, color: ExecColors.ink4)), style: manrope(24, FontWeight.w800, color: ExecColors.ink), textAlign: TextAlign.right)),
                const SizedBox(height: 12),
                _label('Not (isteğe bağlı)'),
                Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2), decoration: execCard(radius: 16), child: TextField(controller: noteCtrl, maxLines: 3, decoration: InputDecoration(border: InputBorder.none, hintText: 'Fiş no, raf etiketi, kampanya bilgisi…', hintStyle: manrope(13, FontWeight.w600, color: ExecColors.ink4)))),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: ExecColors.successSoft, borderRadius: ExecRadii.md),
                  child: Row(children: [const Icon(Icons.check_circle, color: ExecColors.success), const SizedBox(width: 8), Expanded(child: Text('Bu fiyat makul aralıkta görünüyor.', style: manrope(12, FontWeight.w700, color: ExecColors.success)))]),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final pid = state.products.isEmpty ? '' : state.products.first.id;
                  if (pid.isEmpty) return;
                  final value = double.tryParse(priceCtrl.text.replaceAll(',', '.')) ?? 0;
                  await state.addPrice(productId: pid, store: store, price: value);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Fiyat başarıyla eklendi!')));
                },
                style: ElevatedButton.styleFrom(backgroundColor: ExecColors.espresso, foregroundColor: ExecColors.gold, shape: RoundedRectangleBorder(borderRadius: ExecRadii.pill)),
                icon: const Icon(Icons.send_rounded),
                label: Text('Fiyatı Gönder', style: manrope(15, FontWeight.w800, color: ExecColors.gold)),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: manrope(13, FontWeight.w800, color: ExecColors.ink2)),
      );

  Widget _inputRow({required IconData icon, required String hint, Widget? suffix}) => Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: execCard(radius: 16),
      child: Row(children: [Icon(icon, color: ExecColors.ink3, size: 18), const SizedBox(width: 8), Expanded(child: Text(hint, style: manrope(13, FontWeight.w600, color: ExecColors.ink4))), if (suffix != null) suffix]));
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Topluluğa katkı ver'.toUpperCase(), style: manrope(10, FontWeight.w800, color: ExecColors.goldDeep, letterSpacing: 2.2)),
        const SizedBox(height: 6),
        RichText(text: TextSpan(text: 'Fiyat ', style: fraunces(44, FontWeight.w700), children: [TextSpan(text: 'Ekle', style: fraunces(44, FontWeight.w400, color: ExecColors.ink3, style: FontStyle.italic))])),
      ]),
    );
  }
}
