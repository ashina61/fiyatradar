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
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: CoffeeColors.foam,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('${items.length} ürün',
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
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final c = items[i];
                  final unit = c.product.lowestPrice ?? 0;
                  return Container(
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.product.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: CoffeeColors.espresso)),
                              Text('₺${unit.toStringAsFixed(2)} / adet',
                                  style: const TextStyle(
                                      color: CoffeeColors.cocoa,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            _QtyBtn(
                              icon: Icons.remove,
                              onTap: () =>
                                  state.changeQty(c.product.id, -1),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8),
                              child: Text('${c.quantity}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: CoffeeColors.espresso)),
                            ),
                            _QtyBtn(
                              icon: Icons.add,
                              onTap: () =>
                                  state.changeQty(c.product.id, 1),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tahmini Toplam',
                            style: TextStyle(
                                color: CoffeeColors.latte, fontSize: 12)),
                        SizedBox(height: 4),
                      ],
                    ),
                  ),
                  Text('₺${state.cartTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: CoffeeColors.cream,
                          fontSize: 22,
                          fontWeight: FontWeight.w800)),
                ],
              ),
            ),
        ],
      ),
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
