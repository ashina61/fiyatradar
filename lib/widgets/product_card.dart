import 'package:flutter/material.dart';
import '../models/product.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'design.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  DateTime? get _latestDate {
    if (product.priceHistory.isEmpty) return null;
    final s = [...product.priceHistory]
      ..sort((a, b) => b.date.compareTo(a.date));
    return s.first.date;
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final price = product.lowestPrice;
    final store = product.cheapestStore;
    final changePct = product.priceChangePct;
    final isFav = state.isFavorite(product.id);
    final entries = product.priceHistory.length;
    final stores = product.priceHistory.map((e) => e.store).toSet().length;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(FR.radiusXl),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(FR.radiusXl),
          border: Border.all(color: CoffeeColors.crema),
          boxShadow: FR.softShadow,
        ),
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 88,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [CoffeeColors.foam, CoffeeColors.crema],
                    ),
                    borderRadius: BorderRadius.circular(FR.radiusM),
                  ),
                  alignment: Alignment.center,
                  child: Text(product.emoji,
                      style: const TextStyle(fontSize: 44)),
                ),
                if (changePct != null)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: TrendPill(pct: changePct, dense: true),
                  ),
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
                          size: 16,
                          color: isFav
                              ? CoffeeColors.accent
                              : CoffeeColors.darkRoast,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: FreshnessChip(date: _latestDate),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: CoffeeColors.espresso,
                fontSize: 14,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 1),
            Row(
              children: [
                Flexible(
                  child: Text(
                    product.brand,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: CoffeeColors.cocoa,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Text(' · ',
                    style: TextStyle(color: CoffeeColors.crema, fontSize: 11)),
                Text(
                  product.unit,
                  style: const TextStyle(
                    color: CoffeeColors.cocoa,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, color: CoffeeColors.crema),
            const SizedBox(height: 8),
            if (price != null)
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'EN İYİ',
                        style: TextStyle(
                          color: CoffeeColors.cocoa,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                      PriceText(value: price, size: 17),
                    ],
                  ),
                  const Spacer(),
                  if (store != null) StoreBadge(store),
                ],
              )
            else
              const Text(
                'Henüz fiyat yok',
                style: TextStyle(color: CoffeeColors.cocoa, fontSize: 12),
              ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.people_alt_outlined,
                    size: 11, color: CoffeeColors.cocoa),
                const SizedBox(width: 4),
                Text(
                  '$entries kayıt · $stores market',
                  style: const TextStyle(
                    color: CoffeeColors.cocoa,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
