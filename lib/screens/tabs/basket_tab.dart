import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/design.dart';
import '../product_detail_screen.dart';

// ─── Comparison logic ─────────────────────────────────────────────────────────

Map<String, double> _bestPricePerStore(Product product) {
  final Map<String, double> best = {};
  for (final e in product.priceHistory) {
    if (!best.containsKey(e.store) || e.price < best[e.store]!) {
      best[e.store] = e.price;
    }
  }
  return best;
}

List<_StoreTotal> storeBasketTotals(List<CartItem> items) {
  if (items.isEmpty) return [];
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
    if (coversAll) results.add(_StoreTotal(store: store, total: total));
  }
  results.sort((a, b) => a.total.compareTo(b.total));
  return results;
}

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

// ─── Main tab ─────────────────────────────────────────────────────────────────

class BasketTab extends StatelessWidget {
  const BasketTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final items = state.cart;
    final totalQty = items.fold(0, (s, c) => s + c.quantity);

    return SafeArea(
      child: Column(
        children: [
          // ── Header ───────────────────────────────────────────────
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
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: CoffeeColors.espresso,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'En avantajlı marketi bul',
                        style: TextStyle(
                            color: CoffeeColors.cocoa, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                if (items.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: CoffeeColors.foam,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: CoffeeColors.crema),
                    ),
                    child: Text(
                      '$totalQty ürün',
                      style: const TextStyle(
                          color: CoffeeColors.darkRoast,
                          fontWeight: FontWeight.w700,
                          fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => state.clearCart(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: CoffeeColors.foam,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: CoffeeColors.crema),
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
            child: items.isEmpty
                ? const _EmptyState()
                : _ComparisonBody(items: items),
          ),
        ],
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: CoffeeColors.foam,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: CoffeeColors.crema),
              ),
              alignment: Alignment.center,
              child: const Text('⚖️',
                  style: TextStyle(fontSize: 40)),
            ),
            const SizedBox(height: 18),
            const Text(
              'Karşılaştırmak için\nürün ekle',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: CoffeeColors.espresso,
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: -0.3,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ürün detay ekranındaki "Karşılaştırmaya Ekle" butonuna bas.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: CoffeeColors.cocoa, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: CoffeeColors.crema),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tips_and_updates_outlined,
                      color: CoffeeColors.caramel, size: 16),
                  SizedBox(width: 8),
                  Text(
                    "İpucu: Keşfet'ten ürün ara ve ekle",
                    style: TextStyle(
                      color: CoffeeColors.darkRoast,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
        (winner != null && worst != null && worst.store != winner.store)
            ? worst.total - winner.total
            : null;
    final savingsPct = (savingsVsWorst != null && worst!.total > 0)
        ? (savingsVsWorst / worst.total * 100)
        : null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      children: [
        // ── Winner card ──────────────────────────────────────────
        if (winner != null)
          _WinnerCard(
            winner: winner,
            savings: savingsVsWorst,
            savingsPct: savingsPct,
            itemCount: items.fold(0, (s, c) => s + c.quantity),
          )
        else
          const _NoComparisonCard(),

        const SizedBox(height: 16),

        // ── Store ranking ────────────────────────────────────────
        if (storeTotals.isNotEmpty) ...[
          _SectionLabel(
            title: 'Market Sıralaması',
            subtitle: 'Tüm ürünleri karşılayan marketler',
          ),
          const SizedBox(height: 10),
          _StoreRankingList(
              storeTotals: storeTotals, worstTotal: worst?.total),
          const SizedBox(height: 20),
        ],

        // ── Mixed basket ─────────────────────────────────────────
        if (mixed.allocations.length > 1) ...[
          _SectionLabel(
            title: 'En İyi Kombinasyon',
            subtitle:
                'Her ürün kendi en ucuz marketinden → toplam',
          ),
          const SizedBox(height: 10),
          _MixedBasketCard(mixed: mixed),
          const SizedBox(height: 20),
        ],

        // ── Per-item breakdown ────────────────────────────────────
        _SectionLabel(
          title: 'Ürün Bazında En Ucuz',
          subtitle: 'Her ürün için en iyi market',
        ),
        const SizedBox(height: 10),
        ...items.map((c) => _ItemCompareRow(item: c)),
        const SizedBox(height: 20),

        // ── Basket items ──────────────────────────────────────────
        _SectionLabel(
          title: 'Sepetteki Ürünler',
          subtitle: 'Miktar düzenle veya çıkar',
        ),
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
    required this.savingsPct,
    required this.itemCount,
  });

  final _StoreTotal winner;
  final double? savings;
  final double? savingsPct;
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
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: CoffeeColors.espresso.withOpacity(0.30),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label row
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
          const SizedBox(height: 18),

          // Store name + total
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
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 5),
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
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),

          // Savings badges
          if (savings != null && savings! > 0.005) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                // Savings amount
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFF2E7D32).withOpacity(0.22),
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
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (savingsPct != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: CoffeeColors.caramel.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: CoffeeColors.caramel.withOpacity(0.4),
                      ),
                    ),
                    child: Text(
                      '%${savingsPct!.toStringAsFixed(0)} avantaj',
                      style: const TextStyle(
                        color: CoffeeColors.caramel,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
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
  const _NoComparisonCard();

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
          Icon(Icons.info_outline, color: CoffeeColors.caramel, size: 28),
          SizedBox(height: 10),
          Text(
            'Karşılaştırma yapılamıyor',
            style: TextStyle(
                fontWeight: FontWeight.w800,
                color: CoffeeColors.espresso,
                fontSize: 15),
          ),
          SizedBox(height: 4),
          Text(
            'Sepetteki ürünlerin tümünde fiyat bulunan ortak bir market yok. Daha fazla fiyat eklenmesini bekle.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: CoffeeColors.cocoa, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }
}

// ─── Store ranking ────────────────────────────────────────────────────────────

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
        boxShadow: FR.softShadow,
      ),
      child: Column(
        children: List.generate(storeTotals.length, (i) {
          final st = storeTotals[i];
          final isWinner = i == 0;
          final barFill = isWinner
              ? 0.12
              : 0.12 + ((st.total - minTotal) / range) * 0.88;

          return Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: i < storeTotals.length - 1
                  ? const Border(
                      bottom:
                          BorderSide(color: CoffeeColors.crema))
                  : null,
              borderRadius: i == 0
                  ? const BorderRadius.vertical(
                      top: Radius.circular(20))
                  : i == storeTotals.length - 1
                      ? const BorderRadius.vertical(
                          bottom: Radius.circular(20))
                      : null,
            ),
            child: Row(
              children: [
                // Rank
                SizedBox(
                  width: 22,
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: isWinner
                          ? CoffeeColors.caramel
                          : CoffeeColors.cocoa,
                      fontSize: isWinner ? 16 : 13,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            st.store,
                            style: TextStyle(
                              fontWeight: isWinner
                                  ? FontWeight.w800
                                  : FontWeight.w700,
                              color: CoffeeColors.espresso,
                              fontSize: 14,
                            ),
                          ),
                          if (isWinner) ...[
                            const SizedBox(width: 7),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: CoffeeColors.caramel,
                                borderRadius:
                                    BorderRadius.circular(6),
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
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: barFill,
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
                const SizedBox(width: 14),
                Text(
                  '₺${st.total.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: isWinner
                        ? CoffeeColors.accent
                        : CoffeeColors.espresso,
                    fontSize: 15,
                    fontFeatures: const [FontFeature.tabularFigures()],
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
        boxShadow: FR.softShadow,
      ),
      child: Column(
        children: [
          ...mixed.allocations.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Row(
                  children: [
                    Text(a.product.emoji,
                        style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        a.product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: CoffeeColors.espresso,
                            fontWeight: FontWeight.w700,
                            fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 8),
                    StoreBadge(a.store, dark: true),
                    const SizedBox(width: 10),
                    Text(
                      '₺${(a.unitPrice * a.quantity).toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: CoffeeColors.espresso,
                          fontSize: 13,
                          fontFeatures: [
                            FontFeature.tabularFigures()
                          ]),
                    ),
                  ],
                ),
              )),
          const Divider(height: 16, color: CoffeeColors.crema),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Karma Toplam',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: CoffeeColors.espresso,
                      fontSize: 14),
                ),
              ),
              Text(
                '₺${mixed.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: CoffeeColors.accent,
                  fontSize: 18,
                  fontFeatures: [FontFeature.tabularFigures()],
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CoffeeColors.crema),
          boxShadow: FR.softShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: CoffeeColors.foam,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(item.product.emoji,
                  style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: CoffeeColors.espresso,
                        fontSize: 13),
                  ),
                  if (sorted.length > 1)
                    Text(
                      '${sorted.length} market karşılaştırıldı',
                      style: const TextStyle(
                          color: CoffeeColors.cocoa, fontSize: 11),
                    ),
                ],
              ),
            ),
            if (cheapest != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: CoffeeColors.espresso,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  cheapest.key,
                  style: const TextStyle(
                      color: CoffeeColors.cream,
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '₺${cheapest.value.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: CoffeeColors.accent,
                    fontSize: 15,
                    fontFeatures: [FontFeature.tabularFigures()]),
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

// ─── Basket item row ──────────────────────────────────────────────────────────

class _BasketItemRow extends StatelessWidget {
  const _BasketItemRow({required this.item});
  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: CoffeeColors.foam,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CoffeeColors.crema),
      ),
      child: Row(
        children: [
          Text(item.product.emoji,
              style: const TextStyle(fontSize: 22)),
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
          // Qty controls
          _QtyBtn(
            icon: Icons.remove,
            onTap: () => state.changeQty(item.product.id, -1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '${item.quantity}',
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: CoffeeColors.espresso,
                  fontSize: 15),
            ),
          ),
          _QtyBtn(
            icon: Icons.add,
            onTap: () => state.changeQty(item.product.id, 1),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => state.removeFromCart(item.product.id),
            child: Container(
              padding: const EdgeInsets.all(4),
              child: const Icon(Icons.close,
                  size: 17, color: CoffeeColors.cocoa),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: CoffeeColors.crema),
        ),
        child: Icon(icon, size: 16, color: CoffeeColors.darkRoast),
      ),
    );
  }
}

// ─── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: CoffeeColors.espresso,
            letterSpacing: -0.2,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: const TextStyle(
                color: CoffeeColors.cocoa, fontSize: 12),
          ),
        ],
      ],
    );
  }
}
