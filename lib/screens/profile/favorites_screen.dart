import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/design.dart';
import '../product_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final favProducts = state.products
        .where((p) => state.isFavorite(p.id))
        .toList();

    return Scaffold(
      backgroundColor: CoffeeColors.cream,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Kayıtlı Ürünler'),
            if (favProducts.isNotEmpty)
              Text(
                '${favProducts.length} ürün',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: CoffeeColors.cocoa),
              ),
          ],
        ),
      ),
      body: favProducts.isEmpty
          ? _EmptyFavorites()
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
              itemCount: favProducts.length,
              itemBuilder: (context, i) {
                final p = favProducts[i];
                return _FavoriteRow(product: p);
              },
            ),
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: CoffeeColors.foam,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: CoffeeColors.crema),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.bookmark_outline,
                color: CoffeeColors.caramel, size: 36),
          ),
          const SizedBox(height: 16),
          const Text(
            'Henüz kayıtlı ürün yok',
            style: TextStyle(
                color: CoffeeColors.espresso,
                fontSize: 17,
                fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Ürün detayında kalp ikonuna basarak\nürünleri buraya ekleyebilirsin',
            textAlign: TextAlign.center,
            style: TextStyle(color: CoffeeColors.cocoa, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _FavoriteRow extends StatelessWidget {
  const _FavoriteRow({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final price = product.lowestPrice;
    final store = product.cheapestStore;
    final changePct = product.priceChangePct;

    DateTime? latest;
    if (product.priceHistory.isNotEmpty) {
      final sorted = [...product.priceHistory]
        ..sort((a, b) => b.date.compareTo(a.date));
      latest = sorted.first.date;
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: CoffeeColors.crema),
          boxShadow: FR.softShadow,
        ),
        child: Row(
          children: [
            // Emoji
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [CoffeeColors.foam, CoffeeColors.crema],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(product.emoji,
                  style: const TextStyle(fontSize: 26)),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: CoffeeColors.espresso,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (changePct != null)
                        TrendPill(pct: changePct, dense: true),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        product.brand,
                        style: const TextStyle(
                            color: CoffeeColors.cocoa,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                      if (store != null) ...[
                        const Text(' · ',
                            style: TextStyle(
                                color: CoffeeColors.crema,
                                fontSize: 12)),
                        StoreBadge(store, dark: false),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      PriceText(price, size: 16),
                      const Spacer(),
                      FreshnessChip(date: latest),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Unfavorite
            GestureDetector(
              onTap: () => state.toggleFavorite(product.id),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CoffeeColors.accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.favorite_rounded,
                    color: CoffeeColors.accent, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
