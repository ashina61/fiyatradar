import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../../theme.dart';

class CartTab extends StatelessWidget {
  const CartTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final items = state.cart;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Sepetim',
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: CoffeeColors.espresso)),
                ),
                if (items.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => state.clearCart(),
                    icon: const Icon(Icons.delete_outline,
                        size: 18, color: CoffeeColors.cocoa),
                    label: const Text('Temizle',
                        style: TextStyle(color: CoffeeColors.cocoa)),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: CoffeeColors.foam,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('${state.cartItemCount} ürün',
                      style: const TextStyle(
                          color: CoffeeColors.darkRoast,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          if (items.isEmpty)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shopping_basket_outlined,
                        size: 64, color: CoffeeColors.cocoa),
                    SizedBox(height: 12),
                    Text('Sepetin boş',
                        style: TextStyle(
                            color: CoffeeColors.espresso,
                            fontWeight: FontWeight.w700,
                            fontSize: 18)),
                    SizedBox(height: 4),
                    Text('Keşfet sekmesinden ürün ekle',
                        style: TextStyle(color: CoffeeColors.cocoa)),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: [
                  ...items.map((c) {
                    final unit = c.product.lowestPrice ?? 0;
                    final lineTotal = unit * c.quantity;
                    return Dismissible(
                      key: ValueKey('cart-${c.product.id}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC62828),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(Icons.delete,
                            color: Colors.white),
                      ),
                      onDismissed: (_) =>
                          state.removeFromCart(c.product.id),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: CoffeeColors.crema),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: CoffeeColors.foam,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              alignment: Alignment.center,
                              child: Text(c.product.emoji,
                                  style: const TextStyle(fontSize: 28)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(c.product.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: CoffeeColors.espresso)),
                                  Text(
                                      '${c.product.brand} • ${c.product.unit}',
                                      style: const TextStyle(
                                          color: CoffeeColors.cocoa,
                                          fontSize: 11)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        '₺${unit.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                            color: CoffeeColors.accent,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14),
                                      ),
                                      const SizedBox(width: 6),
                                      if (c.product.cheapestStore != null)
                                        Container(
                                          padding: const EdgeInsets
                                              .symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: CoffeeColors.espresso,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                              c.product.cheapestStore!,
                                              style: const TextStyle(
                                                  color:
                                                      CoffeeColors.cream,
                                                  fontSize: 9,
                                                  fontWeight:
                                                      FontWeight.w700)),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('₺${lineTotal.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: CoffeeColors.espresso,
                                        fontSize: 14)),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    _QtyBtn(
                                      icon: Icons.remove,
                                      onTap: () => state.changeQty(
                                          c.product.id, -1),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                      child: Text('${c.quantity}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              color:
                                                  CoffeeColors.espresso)),
                                    ),
                                    _QtyBtn(
                                      icon: Icons.add,
                                      onTap: () => state.changeQty(
                                          c.product.id, 1),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  _RedeemCard(state: state),
                  const SizedBox(height: 12),
                  _SummaryCard(state: state),
                ],
              ),
            ),
          if (items.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: CoffeeColors.espresso,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Toplam',
                            style: TextStyle(
                                color: CoffeeColors.latte, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text('₺${state.cartTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                                color: CoffeeColors.cream,
                                fontSize: 22,
                                fontWeight: FontWeight.w800)),
                        Text(
                          '+${state.pointsEarnedForCart} puan kazanacaksın',
                          style: const TextStyle(
                            color: CoffeeColors.caramel,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      await state.checkout();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Sipariş tamamlandı, puanlar hesabına eklendi')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CoffeeColors.caramel,
                      foregroundColor: CoffeeColors.espresso,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Öde',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _RedeemCard extends StatelessWidget {
  const _RedeemCard({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final available = state.points;
    final maxRedeem = available;
    final selected = state.pointsToRedeem.toDouble();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CoffeeColors.crema),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star, color: CoffeeColors.caramel, size: 18),
              const SizedBox(width: 6),
              const Expanded(
                child: Text('Puan kullan',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: CoffeeColors.espresso)),
              ),
              Text('$available puan',
                  style: const TextStyle(color: CoffeeColors.cocoa)),
            ],
          ),
          if (maxRedeem > 0) ...[
            Slider(
              value: selected.clamp(0, maxRedeem.toDouble()),
              min: 0,
              max: maxRedeem.toDouble(),
              divisions: maxRedeem > 0 ? maxRedeem : 1,
              label: '${state.pointsToRedeem} puan',
              onChanged: (v) => state.setRedeemPoints(v.round()),
              activeColor: CoffeeColors.caramel,
            ),
            Text(
              '${state.pointsToRedeem} puan = ₺${state.redeemDiscount.toStringAsFixed(2)} indirim',
              style: const TextStyle(
                  color: CoffeeColors.cocoa, fontSize: 12),
            ),
          ] else
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('Fiyat ekleyerek puan kazan',
                  style: TextStyle(
                      color: CoffeeColors.cocoa, fontSize: 12)),
            ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CoffeeColors.foam,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          _row('Ara Toplam', '₺${state.cartSubtotal.toStringAsFixed(2)}'),
          const SizedBox(height: 6),
          _row(
            'Tasarrufun',
            '-₺${state.cartSavings.toStringAsFixed(2)}',
            color: const Color(0xFF2E7D32),
          ),
          const SizedBox(height: 6),
          _row(
            'Teslimat',
            state.deliveryFee == 0
                ? 'Ücretsiz'
                : '₺${state.deliveryFee.toStringAsFixed(2)}',
          ),
          if (state.pointsToRedeem > 0) ...[
            const SizedBox(height: 6),
            _row(
              'Puan İndirimi',
              '-₺${state.redeemDiscount.toStringAsFixed(2)}',
              color: CoffeeColors.accent,
            ),
          ],
          const Divider(height: 20),
          _row(
            'Toplam',
            '₺${state.cartTotal.toStringAsFixed(2)}',
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false, Color? color}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
      color: color ?? CoffeeColors.espresso,
      fontSize: bold ? 15 : 13,
    );
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: TextStyle(
                color: color ?? CoffeeColors.cocoa,
                fontSize: bold ? 15 : 13,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              )),
        ),
        Text(value, style: style),
      ],
    );
  }
}

class _QtyBtn extends StatelessWidget {
  const _QtyBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: CoffeeColors.foam,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: CoffeeColors.darkRoast),
      ),
    );
  }
}
