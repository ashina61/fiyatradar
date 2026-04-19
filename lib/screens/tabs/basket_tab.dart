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
    final items = state.cart.isNotEmpty
        ? state.cart
        : state.products.take(3).map((p) => CartItem(product: p, quantity: 1)).toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 110),
        children: [
          const _PageHeader(),
          Container(
            margin: const EdgeInsets.fromLTRB(20, 22, 20, 0),
            padding: const EdgeInsets.all(4),
            decoration: execCard(radius: 16),
            child: Row(children: [
              Expanded(child: _tabBtn('Sepetim', Icons.shopping_basket_rounded, tab == 0, () => setState(() => tab = 0), count: items.length)),
              Expanded(child: _tabBtn('Sonuçlar', Icons.leaderboard_rounded, tab == 1, () => setState(() => tab = 1), count: items.length + 1)),
            ]),
          ),
          if (tab == 0) ...[
            const SizedBox(height: 14),
            ...items.map((c) => _BasketItem(
                  item: c,
                  onMinus: c.quantity > 1 ? () => state.changeQty(c.product.id, -1) : null,
                  onPlus: state.cart.isNotEmpty ? () => state.changeQty(c.product.id, 1) : null,
                )),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: ElevatedButton.icon(
                onPressed: () => setState(() => tab = 1),
                style: ElevatedButton.styleFrom(backgroundColor: ExecColors.espresso, foregroundColor: ExecColors.gold, shape: RoundedRectangleBorder(borderRadius: ExecRadii.pill), padding: const EdgeInsets.symmetric(vertical: 15)),
                icon: const Icon(Icons.bolt_rounded),
                label: Text('En Ucuz Sepeti Bul', style: manrope(14, FontWeight.w800, color: ExecColors.gold)),
              ),
            ),
          ] else ...[
            Container(
              margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: ExecRadii.xl,
                gradient: const LinearGradient(colors: [ExecColors.espresso2, ExecColors.espresso]),
              ),
              child: Column(children: [
                Text('En Ucuz Sepet', style: manrope(11, FontWeight.w800, color: ExecColors.gold, letterSpacing: 1.8)),
                const SizedBox(height: 4),
                Text('Migros Kadıköy', style: fraunces(30, FontWeight.w700, color: ExecColors.onDark)),
                const SizedBox(height: 6),
                Text('${state.cartTotal.toStringAsFixed(0)} ₺', style: fraunces(46, FontWeight.w700, color: ExecColors.onDark)),
                const SizedBox(height: 8),
                Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: const Color(0x2648A05A), borderRadius: ExecRadii.pill), child: Text('${state.cartSavings.toStringAsFixed(0)} ₺ daha uygun · %14 tasarruf', style: manrope(11, FontWeight.w800, color: const Color(0xFFBDE5C8)))),
                const SizedBox(height: 10),
                Row(children: [Expanded(child: _rc('Yol Tarifi', true)), const SizedBox(width: 8), Expanded(child: _rc('Paylaş', false))]),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Ürün bazlı dağılım'.toUpperCase(), style: manrope(10, FontWeight.w800, color: ExecColors.goldDeep, letterSpacing: 2)),
                Text('Sepetinin detayı', style: fraunces(30, FontWeight.w700)),
              ]),
            ),
            ...items.map((c) => _Breakdown(product: c.product, qty: c.quantity)),
          ]
        ],
      ),
    );
  }

  Widget _tabBtn(String label, IconData icon, bool active, VoidCallback onTap, {required int count}) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 40,
          decoration: BoxDecoration(color: active ? ExecColors.espresso : Colors.transparent, borderRadius: BorderRadius.circular(12)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 14, color: active ? ExecColors.gold : ExecColors.ink3),
            const SizedBox(width: 6),
            Text(label, style: manrope(12, FontWeight.w800, color: active ? ExecColors.gold : ExecColors.ink3)),
            const SizedBox(width: 6),
            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: active ? const Color(0x26C9A063) : ExecColors.bgSoft, borderRadius: BorderRadius.circular(8)), child: Text('$count', style: manrope(10, FontWeight.w800, color: active ? ExecColors.goldSoft : ExecColors.ink3))),
          ]),
        ),
      );

  Widget _rc(String t, bool p) => Container(
      height: 38,
      decoration: BoxDecoration(color: p ? ExecColors.gold : Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Center(child: Text(t, style: manrope(12, FontWeight.w800, color: p ? ExecColors.espresso : ExecColors.ink2))));
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Topluca sorgula'.toUpperCase(), style: manrope(10, FontWeight.w800, color: ExecColors.goldDeep, letterSpacing: 2.2)),
        const SizedBox(height: 6),
        Text('Sepet', style: fraunces(44, FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Ürünleri sepete ekle — hangi mağazada en ucuza alacağını tek tıkla görelim.', style: manrope(13, FontWeight.w600, color: ExecColors.ink3)),
      ]),
    );
  }
}

class _BasketItem extends StatelessWidget {
  const _BasketItem({required this.item, this.onMinus, this.onPlus});
  final CartItem item;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        padding: const EdgeInsets.all(12),
        decoration: execCard(radius: 18),
        child: Row(children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: ExecColors.bgSoft, borderRadius: BorderRadius.circular(12)), alignment: Alignment.center, child: Text(item.product.emoji, style: const TextStyle(fontSize: 20))),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: manrope(13, FontWeight.w800)), Text('${item.product.category} · ${item.product.priceHistory.length} mağaza karşılaştır', style: manrope(11, FontWeight.w600, color: ExecColors.ink3))])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(color: ExecColors.bgSoft, borderRadius: BorderRadius.circular(10)),
            child: Row(children: [_q('−', onMinus), const SizedBox(width: 8), Text('${item.quantity}', style: manrope(13, FontWeight.w800)), const SizedBox(width: 8), _q('+', onPlus)]),
          )
        ]),
      );

  Widget _q(String t, VoidCallback? onTap) => InkWell(onTap: onTap, child: Text(t, style: manrope(16, FontWeight.w800, color: onTap == null ? ExecColors.ink4 : ExecColors.ink2)));
}

class _Breakdown extends StatelessWidget {
  const _Breakdown({required this.product, required this.qty});
  final Product product;
  final int qty;

  @override
  Widget build(BuildContext context) {
    final best = product.lowestPrice ?? 0;
    final stores = [
      ('Migros · Kadıköy', best, 'En ucuz burada', true),
      ('Teknosa · Maltepe', best + 751, '+751 ₺ daha pahalı', false),
      ('Apple Akasya · Üsküdar', best + 2000, '+2.000 ₺ daha pahalı', false),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      decoration: execCard(radius: 20),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Container(width: 42, height: 42, decoration: BoxDecoration(color: ExecColors.bgSoft, borderRadius: BorderRadius.circular(12)), alignment: Alignment.center, child: Text(product.emoji, style: const TextStyle(fontSize: 20))),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: manrope(13, FontWeight.w800)), Text('$qty adet · ${product.priceHistory.length} mağazada mevcut', style: manrope(11, FontWeight.w600, color: ExecColors.ink3))])),
          ]),
        ),
        ...stores.asMap().entries.map((entry) {
          final i = entry.key;
          final s = entry.value;
          return Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(color: s.$4 ? const Color(0xFFF1F8EE) : Colors.transparent, border: const Border(top: BorderSide(color: ExecColors.bgDeep))),
            child: Row(children: [
              CircleAvatar(radius: 10, backgroundColor: s.$4 ? ExecColors.gold : ExecColors.bgSoft, child: Text('${i + 1}', style: manrope(10, FontWeight.w800, color: s.$4 ? ExecColors.espresso : ExecColors.ink3))),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(s.$1, style: manrope(12, FontWeight.w700, color: ExecColors.ink2)), Text(s.$3, style: manrope(10, FontWeight.w700, color: s.$4 ? ExecColors.success : ExecColors.danger))])),
              Text('${s.$2.toStringAsFixed(0)} ₺', style: manrope(14, FontWeight.w800)),
            ]),
          );
        }),
      ]),
    );
  }
}
