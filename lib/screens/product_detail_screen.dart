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
    final isFav = state.isFavorite(product.id);
    final history = [...product.priceHistory]
      ..sort((a, b) => b.date.compareTo(a.date));
    final lowest = product.lowestPrice;
    final latest = product.latestPrice;
    final changePct = product.priceChangePct;
    final hasDrop = changePct != null && changePct < 0;
    final hasRise = changePct != null && changePct > 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ürün Detayı'),
        actions: [
          IconButton(
            icon: Icon(
              isFav ? Icons.favorite_rounded : Icons.favorite_border,
              color: isFav ? CoffeeColors.accent : CoffeeColors.darkRoast,
            ),
            onPressed: () => state.toggleFavorite(product.id),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          // ── Product hero ─────────────────────────────────────────
          Container(
            height: 200,
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
            child: Text(product.emoji,
                style: const TextStyle(fontSize: 110)),
          ),
          const SizedBox(height: 18),

          // ── Name + meta ──────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: CoffeeColors.espresso,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(children: [
                      Text(product.brand,
                          style: const TextStyle(
                              color: CoffeeColors.cocoa,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                      const Text('  ·  ',
                          style: TextStyle(color: CoffeeColors.crema)),
                      Text(product.unit,
                          style: const TextStyle(
                              color: CoffeeColors.cocoa, fontSize: 13)),
                      const Text('  ·  ',
                          style: TextStyle(color: CoffeeColors.crema)),
                      Text(product.category,
                          style: const TextStyle(
                              color: CoffeeColors.cocoa, fontSize: 13)),
                    ]),
                  ],
                ),
              ),
              if (changePct != null)
                _TrendBadge(pct: changePct),
            ],
          ),
          const SizedBox(height: 18),

          // ── Best price block ─────────────────────────────────────
          if (lowest != null)
            _BestPriceBlock(
              lowest: lowest,
              store: product.cheapestStore ?? '–',
              entryCount: product.priceHistory.length,
            ),
          const SizedBox(height: 12),

          // ── Stat tiles ───────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'En Düşük',
                  value: lowest == null
                      ? '–'
                      : '₺${lowest.toStringAsFixed(2)}',
                  color: CoffeeColors.success,
                  icon: Icons.trending_down,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  label: 'Son Görülen',
                  value: latest == null
                      ? '–'
                      : '₺${latest.toStringAsFixed(2)}',
                  color: (hasDrop
                      ? CoffeeColors.success
                      : hasRise
                          ? CoffeeColors.danger
                          : CoffeeColors.accent),
                  icon: Icons.access_time_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Price history ────────────────────────────────────────
          const _SectionLabel('Fiyat Geçmişi'),
          const SizedBox(height: 12),
          if (history.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: CoffeeColors.foam,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Henüz fiyat eklenmemiş. İlk ekleyen sen ol!',
                style: TextStyle(color: CoffeeColors.cocoa, fontSize: 13),
              ),
            )
          else
            ...history.map((e) => _PriceTile(entry: e)),
          const SizedBox(height: 24),

          // ── Trust note ───────────────────────────────────────────
          if (history.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: CoffeeColors.foam,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: CoffeeColors.crema),
              ),
              child: Row(
                children: [
                  const Icon(Icons.people_outline,
                      color: CoffeeColors.cocoa, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${history.length} fiyat girişi · topluluk tarafından güncellendi',
                      style: const TextStyle(
                          color: CoffeeColors.cocoa, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),

          // ── Actions ──────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.notifications_none, size: 18),
                  label: const Text('Alarm Kur'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: CoffeeColors.espresso,
                    side:
                        const BorderSide(color: CoffeeColors.crema),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () {
                    state.addToCart(product);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Karşılaştırmaya eklendi'),
                        backgroundColor: CoffeeColors.darkRoast,
                        behavior: SnackBarBehavior.floating,
                        margin: EdgeInsets.fromLTRB(16, 0, 16, 80),
                      ),
                    );
                  },
                  icon: const Icon(Icons.balance_outlined, size: 18),
                  label: const Text('Karşılaştırmaya Ekle'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Best price block ─────────────────────────────────────────────────────────

class _BestPriceBlock extends StatelessWidget {
  const _BestPriceBlock({
    required this.lowest,
    required this.store,
    required this.entryCount,
  });

  final double lowest;
  final String store;
  final int entryCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [CoffeeColors.espresso, CoffeeColors.darkRoast],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'En Düşük Fiyat',
                  style: TextStyle(
                      color: CoffeeColors.latte, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  '₺${lowest.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: CoffeeColors.cream,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: CoffeeColors.caramel.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: CoffeeColors.caramel.withOpacity(0.4)),
                ),
                child: Text(
                  store,
                  style: const TextStyle(
                    color: CoffeeColors.caramel,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$entryCount kayıt',
                style: const TextStyle(
                    color: CoffeeColors.latte, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Trend badge ──────────────────────────────────────────────────────────────

class _TrendBadge extends StatelessWidget {
  const _TrendBadge({required this.pct});
  final double pct;

  @override
  Widget build(BuildContext context) {
    final drop = pct < 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (drop
                ? const Color(0xFF2E7D32)
                : const Color(0xFFC62828))
            .withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (drop ? const Color(0xFF2E7D32) : const Color(0xFFC62828))
              .withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            drop ? Icons.trending_down : Icons.trending_up,
            size: 14,
            color: drop ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
          ),
          const SizedBox(width: 4),
          Text(
            '${drop ? '' : '+'}${pct.toStringAsFixed(1)}%',
            style: TextStyle(
              color:
                  drop ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stat tile ────────────────────────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

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
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
                color: CoffeeColors.cocoa,
                fontSize: 11,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 20),
          ),
        ],
      ),
    );
  }
}

// ─── Price tile ───────────────────────────────────────────────────────────────

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
      margin: const EdgeInsets.only(bottom: 9),
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
            alignment: Alignment.center,
            child: const Icon(Icons.storefront_outlined,
                color: CoffeeColors.darkRoast, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.store,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: CoffeeColors.espresso,
                      fontSize: 14),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    // Contributor badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: CoffeeColors.foam,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: CoffeeColors.crema),
                      ),
                      child: Text(
                        entry.reportedBy,
                        style: const TextStyle(
                            color: CoffeeColors.darkRoast,
                            fontSize: 10,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _ago(entry.date),
                      style: const TextStyle(
                          color: CoffeeColors.cocoa, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '₺${entry.price.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: CoffeeColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: CoffeeColors.espresso,
      ),
    );
  }
}
