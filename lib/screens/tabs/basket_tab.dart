import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../state/app_state.dart';
import '../../widgets/executive_ui.dart';

class BasketTab extends StatefulWidget {
  const BasketTab({super.key});

  @override
  State<BasketTab> createState() => _BasketTabState();
}

class _BasketTabState extends State<BasketTab> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final items = state.cart.isNotEmpty ? state.cart : state.products.take(3).map((p) => CartItem(product: p, quantity: 1)).toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 120),
        children: [
          Text('Topluca sorgula'.toUpperCase(), style: manrope(10, FontWeight.w800, color: ExecColors.goldDeep, letterSpacing: 2.2)),
          const SizedBox(height: 6),
          Text('Sepet', style: fraunces(44, FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Ürünleri sepete ekle — hangi mağazada en ucuza alacağını tek tıkla görelim.', style: manrope(13, FontWeight.w600, color: ExecColors.ink3)),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: execCard(radius: 16),
            child: Row(children: [Expanded(child: _tab('Sepetim', tab == 0, () => setState(() => tab = 0), items.length)), Expanded(child: _tab('Sonuçlar', tab == 1, () => setState(() => tab = 1), items.length + 1))]),
          ),
          const SizedBox(height: 14),
          if (tab == 0) ...[
            ...items.map((c) => _item(c, state)),
            const SizedBox(height: 6),
            SizedBox(
              height: 46,
              child: ElevatedButton.icon(onPressed: () => setState(() => tab = 1), style: ElevatedButton.styleFrom(backgroundColor: ExecColors.espresso, foregroundColor: ExecColors.gold, shape: RoundedRectangleBorder(borderRadius: ExecRadii.pill)), icon: const Icon(Icons.bolt_rounded), label: Text('En Ucuz Sepeti Bul', style: manrope(13, FontWeight.w800, color: ExecColors.gold))),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(borderRadius: ExecRadii.xl, gradient: const LinearGradient(colors: [ExecColors.espresso2, ExecColors.espresso])),
              child: Column(children: [Text('En Ucuz Sepet', style: manrope(11, FontWeight.w800, color: ExecColors.gold, letterSpacing: 1.8)), const SizedBox(height: 4), Text('Migros Kadıköy', style: fraunces(30, FontWeight.w700, color: ExecColors.onDark)), const SizedBox(height: 6), Text('${state.cartTotal.toStringAsFixed(0)} ₺', style: fraunces(46, FontWeight.w700, color: ExecColors.onDark)), const SizedBox(height: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: const Color(0x2648A05A), borderRadius: ExecRadii.pill), child: Text('${state.cartSavings.toStringAsFixed(0)} ₺ daha uygun · %14 tasarruf', style: manrope(11, FontWeight.w800, color: const Color(0xFFBDE5C8)))), const SizedBox(height: 10), Row(children: [Expanded(child: _resultBtn('Yol Tarifi', true)), const SizedBox(width: 8), Expanded(child: _resultBtn('Paylaş', false))])]),
            ),
            const SizedBox(height: 18),
            Text('Ürün bazlı dağılım'.toUpperCase(), style: manrope(10, FontWeight.w800, color: ExecColors.goldDeep, letterSpacing: 2)),
            const SizedBox(height: 4),
            Text('Sepetinin detayı', style: fraunces(30, FontWeight.w700)),
            const SizedBox(height: 10),
            ...items.map((c) => _breakdown(c)),
          ],
        ],
      ),
    );
  }

  Widget _tab(String title, bool active, VoidCallback onTap, int n) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 40,
          decoration: BoxDecoration(color: active ? ExecColors.espresso : Colors.transparent, borderRadius: BorderRadius.circular(12)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(title, style: manrope(12, FontWeight.w800, color: active ? ExecColors.gold : ExecColors.ink3)), const SizedBox(width: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: active ? const Color(0x26C9A063) : ExecColors.bgSoft, borderRadius: BorderRadius.circular(8)), child: Text('$n', style: manrope(10, FontWeight.w800, color: active ? ExecColors.gold : ExecColors.ink3)))]),
        ),
      );

  Widget _item(CartItem c, AppState state) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: execCard(radius: 18),
        child: Row(children: [Container(width: 42, height: 42, decoration: BoxDecoration(color: ExecColors.bgSoft, borderRadius: BorderRadius.circular(12)), alignment: Alignment.center, child: Text(c.product.emoji, style: const TextStyle(fontSize: 20))), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(c.product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: manrope(13, FontWeight.w800)), Text('${c.product.category} · ${c.product.priceHistory.length} mağaza karşılaştır', style: manrope(11, FontWeight.w600, color: ExecColors.ink3))])), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), decoration: BoxDecoration(color: ExecColors.bgSoft, borderRadius: BorderRadius.circular(10)), child: Row(children: [_q('−', c.quantity > 1 ? () => state.changeQty(c.product.id, -1) : null), const SizedBox(width: 8), Text('${c.quantity}', style: manrope(13, FontWeight.w800)), const SizedBox(width: 8), _q('+', state.cart.isNotEmpty ? () => state.changeQty(c.product.id, 1) : null)]))]),
      );

  Widget _q(String t, VoidCallback? onTap) => InkWell(onTap: onTap, child: Text(t, style: manrope(16, FontWeight.w800, color: onTap == null ? ExecColors.ink4 : ExecColors.ink2)));

  Widget _resultBtn(String t, bool p) => Container(height: 38, decoration: BoxDecoration(color: p ? ExecColors.gold : Colors.white, borderRadius: BorderRadius.circular(12)), child: Center(child: Text(t, style: manrope(12, FontWeight.w800, color: p ? ExecColors.espresso : ExecColors.ink2))));

  Widget _breakdown(CartItem c) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: execCard(radius: 18),
        child: Row(children: [Expanded(child: Text('${c.product.name} × ${c.quantity}', maxLines: 1, overflow: TextOverflow.ellipsis, style: manrope(12, FontWeight.w800))), Text('${((c.product.lowestPrice ?? 0) * c.quantity).toStringAsFixed(0)} ₺', style: manrope(14, FontWeight.w800))]),
      );
}
