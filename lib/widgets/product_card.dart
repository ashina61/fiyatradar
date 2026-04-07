import 'package:flutter/material.dart';
import '../models/product.dart';
import '../state/app_state.dart';
import '../theme.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final price = product.lowestPrice;
    final store = product.cheapestStore;
    final changePct = product.priceChangePct;
    final isFav = state.isFavorite(product.id);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: CoffeeColors.crema),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 84,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: CoffeeColors.foam,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(product.emoji,
                      style: const TextStyle(fontSize: 44)),
                ),
                // Price-change badge (top-left)
                if (changePct != null)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: _ChangeBadge(pct: changePct),
                  ),
                // Favorite button (top-right)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 1,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => state.toggleFavorite(product.id),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          size: 18,
                          color: isFav
                              ? CoffeeColors.accent
                              : CoffeeColors.darkRoast,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: CoffeeColors.espresso,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              product.brand,
              style: const TextStyle(
                color: CoffeeColors.cocoa,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            if (price != null)
              Row(
                children: [
                  Text(
                    '₺${price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: CoffeeColors.accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  if (store != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: CoffeeColors.espresso,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        store,
                        style: const TextStyle(
                          color: CoffeeColors.cream,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              )
            else
              const Text(
                'Henüz fiyat yok',
                style: TextStyle(color: CoffeeColors.cocoa, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChangeBadge extends StatelessWidget {
  const _ChangeBadge({required this.pct});
  final double pct;

  @override
  Widget build(BuildContext context) {
    final isDown = pct < 0;
    final color = isDown ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
    final icon = isDown ? Icons.arrow_downward : Icons.arrow_upward;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 11),
          const SizedBox(width: 2),
          Text(
            '${pct.abs().toStringAsFixed(1)}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
