import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/design.dart';
import '../product_detail_screen.dart';

// ─── Comparison logic helpers ─────────────────────────────────────────────────

/// Best (lowest) price per store for a given product, using full price history.
Map<String, double> _bestPricePerStore(Product product) {
  final Map<String, double> best = {};
  for (final e in product.priceHistory) {
    if (!best.containsKey(e.store) || e.price < best[e.store]!) {
      best[e.store] = e.price;
    }
  }
  return best;
}

/// Returns all stores that carry every item in the basket, with their totals.
/// Sorted cheapest first.
List<_StoreTotal> storeBasketTotals(List<CartItem> items) {
  if (items.isEmpty) return [];

  // Collect union of all stores
  final Set<String> allStores = {};
  for (final item in items) {
    allStores.addAll(_bestPricePerStore(item.product).keys);
  }

  final List<_StoreTotal> results = [];
  for (final store in allStores) {
    double total = 0;
    bool coversAll = true;
    for (final item in items) {
      final prices = _bestPricePerStore(item.product);
      if (!prices.containsKey(store)) {
        coversAll = false;
        break;
      }
      total += prices[store]! * item.quantity;
    }
    if (coversAll) {
      results.add(_StoreTotal(store: store, total: total));
    }
  }

  results.sort((a, b) => a.total.compareTo(b.total));
  return results;
}

/// Mixed basket: for each item, take its cheapest available store.
/// Returns total and per-item allocation.
_MixedBasket mixedBasket(List<CartItem> items) {
  double total = 0;
  final allocs = <_ItemAllocation>[];
  for (final item in items) {
    final lowest = item.product.lowestPrice;
    final store = item.product.cheapestStore;
    if (lowest != null && store != null) {
      total += lowest * item.quantity;
      allocs.add(_ItemAllocation(
          product: item.product,
          store: store,
          unitPrice: lowest,
          quantity: item.quantity));
    }
  }
  return _MixedBasket(total: total, allocations: allocs);
}

// ─── Data classes ─────────────────────────────────────────────────────────────

class _StoreTotal {
  final String store;
  final double total;
  const _StoreTotal({required this.store, required this.total});
}

class _MixedBasket {
  final double total;
  final List<_ItemAllocation> allocations;
  const _MixedBasket({required this.total, required this.allocations});
}

class _ItemAllocation {
  final Product product;
  final String store;
  final double unitPrice;
  final int quantity;
  const _ItemAllocation({
    required this.product,
    required this.store,
    required this.unitPrice,
    required this.quantity,
  });
}

// ─── Main screen ──────────────────────────────────────────────────────────────

class BasketTab extends StatelessWidget {
  const BasketTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final items = state.cart;

    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Karşılaştır',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: CoffeeColors.espresso,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'En ucuz marketi bul',
                        style: TextStyle(
                            color: CoffeeColors.cocoa, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                if (items.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: CoffeeColors.foam,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${items.fold(0, (s, c) => s + c.quantity)} ürün',
                      style: const TextStyle(
                          color: CoffeeColors.darkRoast,
                          fontWeight: FontWeight.w700,
                          fontSize: 13),
                    ),
                  ),
                if (items.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => state.clearCart(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: CoffeeColors.foam,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.delete_outline,
                          size: 18, color: CoffeeColors.cocoa),
                    ),
                  ),
                ],
              ],
            ),
          ),

          Expanded(
            child: items.isEmpty ? _EmptyState() : _ComparisonBody(items: items),
          ),
        ],
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
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
            ),
            alignment: Alignment.center,
            child: const Text('⚖️', style: TextStyle(fontSize: 36)),
          ),
          const SizedBox(height: 16),
          const Text(
            'Karşılaştırmak için ürün ekle',
            style: TextStyle(
              color: CoffeeColors.espresso,
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Ürün detayından "Karşılaştırmaya Ekle"\nbutonuna bas',
            textAlign: TextAlign.center,
            style: TextStyle(color: CoffeeColors.cocoa, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─── Comparison body ──────────────────────────────────────────────────────────

class _ComparisonBody extends StatelessWidget {
  const _ComparisonBody({required this.items});
  final List<CartItem> items;

  @override
  Widget build(BuildContext context) {
    final storeTotals = storeBasketTotals(items);
    final mixed = mixedBasket(items);
    final winner = storeTotals.isNotEmpty ? storeTotals.first : null;
    final worst = storeTotals.isNotEmpty ? storeTotals.last : null;
    final savingsVsWorst =
        (winner != null && worst != null && worst != winner)
            ? worst.total - winner.total
            : null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      children: [
        // ── Winner card (dominant block) ─────────────────────────
        if (winner != null)
          _WinnerCard(
            winner: winner,
            savings: savingsVsWorst,
            itemCount: items.fold(0, (s, c) => s + c.quantity),
          )
        else
          _NoComparisonCard(),

        const SizedBox(height: 16),

        // ── Store ranking ────────────────────────────────────────
        if (storeTotals.isNotEmpty) ...[
          _SectionLabel('Market Sıralaması'),
          const SizedBox(height: 10),
          _StoreRankingList(
              storeTotals: storeTotals, worstTotal: worst?.total),
          const SizedBox(height: 20),
        ],

        // ── Mixed basket ─────────────────────────────────────────
        if (mixed.allocations.isNotEmpty && mixed.allocations.length > 1) ...[
          _SectionLabel('En İyi Kombinasyon'),
          const SizedBox(height: 6),
          const Text(
            'Her ürün kendi en ucuz marketinden alınırsa',
            style: TextStyle(color: CoffeeColors.cocoa, fontSize: 12),
          ),
          const SizedBox(height: 10),
          _MixedBasketCard(mixed: mixed),
          const SizedBox(height: 20),
        ],

        // ── Per-item breakdown ────────────────────────────────────
        _SectionLabel('Ürün Bazında En Ucuz'),
        const SizedBox(height: 10),
        ...items.map((c) => _ItemCompareRow(item: c)),
        const SizedBox(height: 20),

        // ── Manage basket ─────────────────────────────────────────
        _SectionLabel('Sepetteki Ürünler'),
        const SizedBox(height: 10),
        ...items.map((c) => _BasketItemRow(item: c)),
      ],
    );
  }
}

// ─── Winner card ─────────────────────────────────────────────────────────────

class _WinnerCard extends StatelessWidget {
  const _WinnerCard({
    required this.winner,
    required this.savings,
    required this.itemCount,
  });

  final _StoreTotal winner;
  final double? savings;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [CoffeeColors.espresso, CoffeeColors.darkRoast],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: CoffeeColors.espresso.withOpacity(0.30),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const EyebrowLabel('EN UCUZ SEÇENEK'),
              const Spacer(),
              LiveDot(color: CoffeeColors.caramel),
              const SizedBox(width: 6),
              const Text(
                'CANLI HESAPLAMA',
                style: TextStyle(
                  color: CoffeeColors.caramel,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      winner.store,
                      style: const TextStyle(
                        color: CoffeeColors.cream,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$itemCount ürün için toplam',
                      style: const TextStyle(
                          color: CoffeeColors.latte, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Text(
                '₺${winner.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: CoffeeColors.cream,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (savings != null && savings! > 0) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.22),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color:
                            const Color(0xFF2E7D32).withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.savings_outlined,
                          color: Color(0xFFB7D49A), size: 14),
                      const SizedBox(width: 6),
                      Text(
                        '₺${savings!.toStringAsFixed(2)} tasarruf',
                        style: const TextStyle(
                          color: Color(0xFFB7D49A),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: CoffeeColors.caramel.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: CoffeeColors.caramel.withOpacity(0.45),
                    ),
                  ),
                  child: Text(
                    '~%${((savings! / (savings! + winner.total)) * 100).toStringAsFixed(0)} avantaj',
                    style: const TextStyle(
                      color: CoffeeColors.caramel,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── No comparison card ───────────────────────────────────────────────────────

class _NoComparisonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CoffeeColors.foam,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CoffeeColors.crema),
      ),
      child: const Column(
        children: [
          Icon(Icons.info_outline, color: CoffeeColors.cocoa, size: 28),
          SizedBox(height: 10),
          Text(
            'Karşılaştırma yapılamıyor',
            style: TextStyle(
                fontWeight: FontWeight.w700, color: CoffeeColors.espresso),
          ),
          SizedBox(height: 4),
          Text(
            'Sepetteki ürünlerin tüm marketlerde fiyatı olmayabilir. Daha fazla fiyat eklenmesini bekle.',
            textAlign: TextAlign.center,
            style: TextStyle(color: CoffeeColors.cocoa, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ─── Store ranking list ───────────────────────────────────────────────────────

class _StoreRankingList extends StatelessWidget {
  const _StoreRankingList(
      {required this.storeTotals, required this.worstTotal});

  final List<_StoreTotal> storeTotals;
  final double? worstTotal;

  @override
  Widget build(BuildContext context) {
    final maxTotal = worstTotal ?? storeTotals.last.total;
    final minTotal = storeTotals.first.total;
    final range = (maxTotal - minTotal).clamp(0.01, double.infinity);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CoffeeColors.crema),
      ),
      child: Column(
        children: List.generate(storeTotals.length, (i) {
          final st = storeTotals[i];
          final isWinner = i == 0;
          final barWidth = (st.total - minTotal) / range;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              border: i < storeTotals.length - 1
                  ? const Border(
                      bottom: BorderSide(color: CoffeeColors.crema))
                  : null,
            ),
            child: Row(
              children: [
                // Rank
                SizedBox(
                  width: 24,
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: isWinner
                          ? CoffeeColors.caramel
                          : CoffeeColors.cocoa,
                      fontSize: isWinner ? 15 : 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Store name + bar
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            st.store,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: isWinner
                                  ? CoffeeColors.espresso
                                  : CoffeeColors.darkRoast,
                              fontSize: 14,
                            ),
                          ),
                          if (isWinner) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: CoffeeColors.caramel,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'En ucuz',
                                style: TextStyle(
                                    color: CoffeeColors.espresso,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: isWinner ? 0.12 : 0.12 + barWidth * 0.88,
                          minHeight: 5,
                          backgroundColor: CoffeeColors.foam,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isWinner
                                ? CoffeeColors.caramel
                                : CoffeeColors.crema,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Total
                Text(
                  '₺${st.total.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: isWinner
                        ? CoffeeColors.accent
                        : CoffeeColors.espresso,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ─── Mixed basket card ────────────────────────────────────────────────────────

class _MixedBasketCard extends StatelessWidget {
  const _MixedBasketCard({required this.mixed});
  final _MixedBasket mixed;

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
        children: [
          ...mixed.allocations.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text(a.product.emoji,
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        a.product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: CoffeeColors.espresso,
                            fontWeight: FontWeight.w600,
                            fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: CoffeeColors.foam,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: CoffeeColors.crema),
                      ),
                      child: Text(
                        a.store,
                        style: const TextStyle(
                            color: CoffeeColors.darkRoast,
                            fontSize: 10,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '₺${(a.unitPrice * a.quantity).toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: CoffeeColors.espresso,
                          fontSize: 13),
                    ),
                  ],
                ),
              )),
          const Divider(height: 16),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Karma Toplam',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: CoffeeColors.espresso),
                ),
              ),
              Text(
                '₺${mixed.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: CoffeeColors.accent,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Per-item compare row ─────────────────────────────────────────────────────

class _ItemCompareRow extends StatelessWidget {
  const _ItemCompareRow({required this.item});
  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final prices = _bestPricePerStore(item.product);
    final sorted = prices.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final cheapest = sorted.isNotEmpty ? sorted.first : null;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(product: item.product),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CoffeeColors.crema),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: CoffeeColors.foam,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child:
                  Text(item.product.emoji, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: CoffeeColors.espresso,
                    fontSize: 13),
              ),
            ),
            if (cheapest != null) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: CoffeeColors.espresso,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  cheapest.key,
                  style: const TextStyle(
                      color: CoffeeColors.cream,
                      fontSize: 10,
                      fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '₺${cheapest.value.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: CoffeeColors.accent,
                    fontSize: 14),
              ),
            ] else
              const Text('–',
                  style: TextStyle(color: CoffeeColors.cocoa)),
          ],
        ),
      ),
    );
  }
}

// ─── Basket item row (manage) ─────────────────────────────────────────────────

class _BasketItemRow extends StatelessWidget {
  const _BasketItemRow({required this.item});
  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: CoffeeColors.foam,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CoffeeColors.crema),
      ),
      child: Row(
        children: [
          Text(item.product.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: CoffeeColors.espresso,
                  fontSize: 13),
            ),
          ),
          // Qty controls
          _QtyBtn(
            icon: Icons.remove,
            onTap: () => state.changeQty(item.product.id, -1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '${item.quantity}',
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: CoffeeColors.espresso,
                  fontSize: 14),
            ),
          ),
          _QtyBtn(
            icon: Icons.add,
            onTap: () => state.changeQty(item.product.id, 1),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => state.removeFromCart(item.product.id),
            child: const Icon(Icons.close,
                size: 18, color: CoffeeColors.cocoa),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: CoffeeColors.crema),
        ),
        child: Icon(icon, size: 16, color: CoffeeColors.darkRoast),
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
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: CoffeeColors.espresso,
      ),
    );
  }
}
