import 'package:flutter/material.dart';
import '../models/product.dart';
import '../state/app_state.dart';
import '../theme.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final history = [...product.priceHistory]
      ..sort((a, b) => b.date.compareTo(a.date));
    final lowest = product.lowestPrice;
    final latest = product.latestPrice;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ürün Detayı'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          Container(
            height: 220,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [CoffeeColors.foam, CoffeeColors.crema],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: CoffeeColors.crema),
            ),
            alignment: Alignment.center,
            child: Text(product.emoji, style: const TextStyle(fontSize: 120)),
          ),
          const SizedBox(height: 20),
          Text(
            product.name,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: CoffeeColors.espresso,
            ),
          ),
          const SizedBox(height: 4),
          Row(children: [
            Text(product.brand,
                style: const TextStyle(
                    color: CoffeeColors.cocoa,
                    fontWeight: FontWeight.w600)),
            const Text('  •  ',
                style: TextStyle(color: CoffeeColors.cocoa)),
            Text(product.unit,
                style: const TextStyle(color: CoffeeColors.cocoa)),
          ]),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'En Düşük',
                  value:
                      lowest == null ? '-' : '₺${lowest.toStringAsFixed(2)}',
                  color: CoffeeColors.success,
                  icon: Icons.trending_down,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  label: 'Son Görülen',
                  value:
                      latest == null ? '-' : '₺${latest.toStringAsFixed(2)}',
                  color: CoffeeColors.accent,
                  icon: Icons.access_time,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Fiyat Geçmişi',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: CoffeeColors.espresso)),
          const SizedBox(height: 12),
          if (history.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: CoffeeColors.crema),
              ),
              child: const Text(
                'Henüz fiyat eklenmemiş. İlk ekleyen sen ol!',
                style: TextStyle(color: CoffeeColors.cocoa),
              ),
            )
          else
            ...history.map((e) => _PriceTile(entry: e)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              state.addToCart(product);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Sepete eklendi'),
                    backgroundColor: CoffeeColors.darkRoast),
              );
            },
            icon: const Icon(Icons.shopping_basket_outlined),
            label: const Text('Sepete Ekle'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile(
      {required this.label,
      required this.value,
      required this.color,
      required this.icon});
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CoffeeColors.crema),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(
                  color: CoffeeColors.cocoa,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 20)),
        ],
      ),
    );
  }
}

class _PriceTile extends StatelessWidget {
  const _PriceTile({required this.entry});
  final PriceEntry entry;

  String _ago(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inDays > 0) return '${diff.inDays} gün önce';
    if (diff.inHours > 0) return '${diff.inHours} sa önce';
    return 'az önce';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CoffeeColors.crema),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: CoffeeColors.foam,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.storefront,
                color: CoffeeColors.darkRoast),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.store,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: CoffeeColors.espresso)),
                Text('${entry.reportedBy} • ${_ago(entry.date)}',
                    style: const TextStyle(
                        color: CoffeeColors.cocoa, fontSize: 12)),
              ],
            ),
          ),
          Text('₺${entry.price.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: CoffeeColors.accent)),
        ],
      ),
    );
  }
}
