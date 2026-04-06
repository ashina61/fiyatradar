import 'package:flutter/material.dart';
import '../models/product.dart';
import '../theme.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final price = product.lowestPrice;
    final store = product.cheapestStore;
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
            Container(
              height: 84,
              decoration: BoxDecoration(
                color: CoffeeColors.foam,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(product.emoji, style: const TextStyle(fontSize: 44)),
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
