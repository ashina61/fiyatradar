import 'dart:ui';

import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/design.dart';
import '../main_screen.dart';
import '../product_detail_screen.dart';

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
        quantity: item.quantity,
      ));
    }
  }
  return _MixedBasket(total: total, allocations: allocs);
}

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

enum _ComparisonScenario {
  noCoverage,
  singleStore,
  multiStore,
  mixedOnly,
  partialData,
}

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
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: CoffeeColors.espresso,
                          letterSpacing: -0.7,
                        ),
                      ),
                      Text(
                        'Akıllı sepet optimizasyonu',
                        style: TextStyle(color: CoffeeColors.cocoa, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                if (items.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: CoffeeColors.espresso.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: CoffeeColors.crema),
                    ),
                    child: Text(
                      '$totalQty ürün',
                      style: const TextStyle(
                        color: CoffeeColors.darkRoast,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _confirmClear(context, state),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: CoffeeColors.danger.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: CoffeeColors.danger.withOpacity(0.2)),
                      ),
                      child: const Icon(Icons.delete_outline, size: 18, color: CoffeeColors.danger),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? _EmptyState(products: state.products)
                : _ComparisonBody(items: items),
          ),
        ],
      ),
    );
  }

  void _confirmClear(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Sepeti Temizle',
          style: TextStyle(fontWeight: FontWeight.w800, color: CoffeeColors.espresso),
        ),
        content: const Text(
          'Tüm ürünler sepetten kaldırılacak.',
          style: TextStyle(color: CoffeeColors.cocoa),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal', style: TextStyle(color: CoffeeColors.cocoa)),
          ),
          ElevatedButton(
            onPressed: () {
              state.clearCart();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: CoffeeColors.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Temizle', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    final suggestions = [...products]
      ..sort((a, b) {
        DateTime aDate = DateTime.fromMillisecondsSinceEpoch(0);
        DateTime bDate = DateTime.fromMillisecondsSinceEpoch(0);
        if (a.priceHistory.isNotEmpty) {
          aDate = ([...a.priceHistory]..sort((x, y) => y.date.compareTo(x.date))).first.date;
        }
        if (b.priceHistory.isNotEmpty) {
          bDate = ([...b.priceHistory]..sort((x, y) => y.date.compareTo(x.date))).first.date;
        }
        return bDate.compareTo(aDate);
      });
    final latestSuggestions = suggestions.take(3).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [CoffeeColors.espresso, CoffeeColors.darkRoast],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: CoffeeColors.espresso.withOpacity(0.28),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const EyebrowLabel('KARŞILAŞTIRMAYA BAŞLA'),
              const SizedBox(height: 12),
              const Text(
                'Sepetine ürün ekle,\nFiyatRadar en avantajlı senaryoyu çıkarsın.',
                style: TextStyle(
                  color: CoffeeColors.cream,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tek market sonucu varsa net gör, yoksa karma kombinasyonu ürün bazında değerlendir.',
                style: TextStyle(color: CoffeeColors.latte, fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 1)),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: CoffeeColors.caramel,
                  foregroundColor: CoffeeColors.espresso,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.explore_outlined, size: 18),
                label: const Text(
                  'Keşfet’ten ürün ekle',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        if (latestSuggestions.isNotEmpty) ...[
          const SizedBox(height: 14),
          const _SectionLabel(
            title: 'Son Eklenenlerden Öneriler',
            subtitle: 'Karşılaştırmaya hızlı başlamak için ürün seç',
          ),
          const SizedBox(height: 8),
          ...latestSuggestions.map(
            (product) => _SuggestionRow(product: product),
          ),
        ],
      ],
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CoffeeColors.crema),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: CoffeeColors.foam,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(product.emoji, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: CoffeeColors.espresso,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Text(
                  product.lowestPrice != null
                      ? 'En düşük: ₺${product.lowestPrice!.toStringAsFixed(2)}'
                      : 'Henüz fiyat verisi yok',
                  style: const TextStyle(color: CoffeeColors.cocoa, fontSize: 11),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => state.addToCart(product),
            style: TextButton.styleFrom(
              foregroundColor: CoffeeColors.darkRoast,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            child: const Text('Ekle', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class _ComparisonBody extends StatelessWidget {
  const _ComparisonBody({required this.items});
  final List<CartItem> items;

  @override
  Widget build(BuildContext context) {
    final storeTotals = storeBasketTotals(items);
    final mixed = mixedBasket(items);
    final winner = storeTotals.isNotEmpty ? storeTotals.first : null;
    final worst = storeTotals.isNotEmpty ? storeTotals.last : null;
    final savingsVsWorst = (winner != null && worst != null && worst.store != winner.store)
        ? worst.total - winner.total
        : null;
    final scenario = _resolveScenario(storeTotals: storeTotals, mixed: mixed, items: items);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
      children: [
        _TopSummaryCard(
          scenario: scenario,
          winner: winner,
          mixed: mixed,
          itemCount: items.fold(0, (s, c) => s + c.quantity),
          distinctProductCount: items.length,
          savingsVsWorst: savingsVsWorst,
        ),
        const SizedBox(height: 16),
        const _SectionLabel(
          title: 'Market Karşılaştırma',
          subtitle: 'Uygunluk ve toplam fiyat görünümü',
        ),
        const SizedBox(height: 8),
        if (storeTotals.isNotEmpty)
          _StoreRankingList(storeTotals: storeTotals, worstTotal: worst?.total)
        else
          _MarketFallbackCard(scenario: scenario, mixed: mixed),
        const SizedBox(height: 18),
        const _SectionLabel(
          title: 'Ürün Bazında Dağılım',
          subtitle: 'Her üründe en iyi market ve fiyat',
        ),
        const SizedBox(height: 8),
        ...items.map((c) => _ItemCompareRow(item: c)),
        const SizedBox(height: 18),
        const _SectionLabel(
          title: 'Sepet',
          subtitle: 'Adet düzenle, ürünü çıkar',
        ),
        const SizedBox(height: 8),
        ...items.map((c) => _BasketItemRow(item: c)),
      ],
    );
  }

  _ComparisonScenario _resolveScenario({
    required List<_StoreTotal> storeTotals,
    required _MixedBasket mixed,
    required List<CartItem> items,
  }) {
    if (storeTotals.isEmpty && mixed.allocations.isEmpty) {
      return _ComparisonScenario.noCoverage;
    }
    if (storeTotals.length == 1) {
      return _ComparisonScenario.singleStore;
    }
    if (storeTotals.length > 1) {
      final allCoveredByMixed = mixed.allocations.length == items.length;
      return allCoveredByMixed ? _ComparisonScenario.multiStore : _ComparisonScenario.partialData;
    }
    if (mixed.allocations.length == items.length) {
      return _ComparisonScenario.mixedOnly;
    }
    return _ComparisonScenario.partialData;
  }
}

class _TopSummaryCard extends StatelessWidget {
  const _TopSummaryCard({
    required this.scenario,
    required this.winner,
    required this.mixed,
    required this.itemCount,
    required this.distinctProductCount,
    required this.savingsVsWorst,
  });

  final _ComparisonScenario scenario;
  final _StoreTotal? winner;
  final _MixedBasket mixed;
  final int itemCount;
  final int distinctProductCount;
  final double? savingsVsWorst;

  @override
  Widget build(BuildContext context) {
    final bool isSingleStore = scenario == _ComparisonScenario.singleStore || scenario == _ComparisonScenario.multiStore;
    final bool isMixedHero = scenario == _ComparisonScenario.mixedOnly;
    final heroTitle = switch (scenario) {
      _ComparisonScenario.singleStore => 'Tek markette en iyi sonuç',
      _ComparisonScenario.multiStore => 'En avantajlı market bulundu',
      _ComparisonScenario.mixedOnly => 'Karma kombinasyon en iyi seçenek',
      _ComparisonScenario.partialData => 'Kısmi fiyat verisiyle özet',
      _ComparisonScenario.noCoverage => 'Kıyas için yeterli veri yok',
    };

    final heroTotal = isMixedHero ? mixed.total : winner?.total;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [CoffeeColors.espresso, CoffeeColors.darkRoast],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const EyebrowLabel('TOPLAM KARAR YÜZEYİ'),
              const Spacer(),
              _StateBadge(label: _scenarioChip(scenario)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            heroTitle,
            style: const TextStyle(
              color: CoffeeColors.cream,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${distinctProductCount} ürün · $itemCount adet hesaplandı',
            style: const TextStyle(color: CoffeeColors.latte, fontSize: 12),
          ),
          const SizedBox(height: 14),
          if (heroTotal != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₺${heroTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: CoffeeColors.cream,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 6),
                const Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Text('toplam', style: TextStyle(color: CoffeeColors.latte, fontSize: 11)),
                ),
              ],
            )
          else
            const Text(
              'Fiyat geçmişi olan ürün ekleyerek karşılaştırmayı başlatabilirsin.',
              style: TextStyle(color: CoffeeColors.latte, fontSize: 12),
            ),
          if (isSingleStore && winner != null) ...[
            const SizedBox(height: 10),
            Text(
              'Önerilen market: ${winner!.store}',
              style: const TextStyle(color: CoffeeColors.caramel, fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ],
          if (savingsVsWorst != null && savingsVsWorst! > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: CoffeeColors.success.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: CoffeeColors.success.withOpacity(0.35)),
              ),
              child: Text(
                'En pahalı seçeneğe göre ₺${savingsVsWorst!.toStringAsFixed(2)} avantaj',
                style: const TextStyle(color: Color(0xFFCDE3B8), fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _scenarioChip(_ComparisonScenario scenario) {
    return switch (scenario) {
      _ComparisonScenario.singleStore => 'TEK MARKET',
      _ComparisonScenario.multiStore => 'MARKET KIYASI',
      _ComparisonScenario.mixedOnly => 'KARMA SONUÇ',
      _ComparisonScenario.partialData => 'KISMİ VERİ',
      _ComparisonScenario.noCoverage => 'VERİ YETERSİZ',
    };
  }
}

class _StateBadge extends StatelessWidget {
  const _StateBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: CoffeeColors.caramel,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _MarketFallbackCard extends StatelessWidget {
  const _MarketFallbackCard({required this.scenario, required this.mixed});

  final _ComparisonScenario scenario;
  final _MixedBasket mixed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CoffeeColors.crema),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                scenario == _ComparisonScenario.noCoverage ? Icons.info_outline : Icons.hub_outlined,
                color: CoffeeColors.caramel,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                scenario == _ComparisonScenario.noCoverage
                    ? 'Ürün var ama kıyas yapılamıyor'
                    : 'Ortak market yok, karma kombinasyon hazır',
                style: const TextStyle(
                  color: CoffeeColors.espresso,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            scenario == _ComparisonScenario.noCoverage
                ? 'Sepetteki ürünlerde geçerli fiyat verisi olmayan kayıtlar var. Yeni fiyat ekleyerek karşılaştırmayı güçlendirebilirsin.'
                : 'Tüm ürünleri tek markette bulamadık. Ürün bazında en düşük fiyatları birleştirerek toplam ₺${mixed.total.toStringAsFixed(2)} sonucu elde edildi.',
            style: const TextStyle(color: CoffeeColors.cocoa, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _StoreRankingList extends StatelessWidget {
  const _StoreRankingList({required this.storeTotals, required this.worstTotal});

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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CoffeeColors.crema),
        boxShadow: FR.softShadow,
      ),
      child: Column(
        children: List.generate(storeTotals.length, (i) {
          final st = storeTotals[i];
          final isWinner = i == 0;
          final isLast = i == storeTotals.length - 1;
          final barFill = isWinner ? 0.14 : 0.14 + ((st.total - minTotal) / range) * 0.86;
          final diff = isWinner ? null : st.total - minTotal;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: isWinner ? CoffeeColors.caramel.withOpacity(0.07) : null,
              border: !isLast ? const Border(bottom: BorderSide(color: CoffeeColors.crema)) : null,
              borderRadius: isWinner
                  ? const BorderRadius.vertical(top: Radius.circular(18))
                  : isLast
                      ? const BorderRadius.vertical(bottom: Radius.circular(18))
                      : null,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: isWinner ? CoffeeColors.caramel : CoffeeColors.cocoa,
                      fontSize: isWinner ? 17 : 12,
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
                          Expanded(
                            child: Text(
                              st.store,
                              style: TextStyle(
                                fontWeight: isWinner ? FontWeight.w800 : FontWeight.w700,
                                color: CoffeeColors.espresso,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (isWinner)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: CoffeeColors.caramel,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'EN UCUZ',
                                style: TextStyle(
                                  color: CoffeeColors.espresso,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (diff != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '+₺${diff.toStringAsFixed(2)} fark',
                          style: const TextStyle(
                            color: CoffeeColors.danger,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: barFill,
                          minHeight: 5,
                          backgroundColor: CoffeeColors.foam,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isWinner ? CoffeeColors.caramel : CoffeeColors.crema,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '₺${st.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: CoffeeColors.espresso,
                    fontSize: 15,
                    fontFeatures: [FontFeature.tabularFigures()],
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

class _ItemCompareRow extends StatelessWidget {
  const _ItemCompareRow({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final prices = _bestPricePerStore(item.product);
    final sorted = prices.entries.toList()..sort((a, b) => a.value.compareTo(b.value));
    final cheapest = sorted.isNotEmpty ? sorted.first : null;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductDetailScreen(product: item.product)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: CoffeeColors.crema),
          boxShadow: FR.softShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: CoffeeColors.foam,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(item.product.emoji, style: const TextStyle(fontSize: 18)),
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
                      fontWeight: FontWeight.w800,
                      color: CoffeeColors.espresso,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    cheapest == null
                        ? 'Fiyat verisi yok'
                        : '${cheapest.key} · ₺${cheapest.value.toStringAsFixed(2)} en iyi fiyat',
                    style: const TextStyle(color: CoffeeColors.cocoa, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (sorted.length > 1)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: CoffeeColors.foam,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: CoffeeColors.crema),
                ),
                child: Text(
                  '${sorted.length} market',
                  style: const TextStyle(
                    color: CoffeeColors.darkRoast,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BasketItemRow extends StatelessWidget {
  const _BasketItemRow({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CoffeeColors.crema),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: CoffeeColors.foam,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(item.product.emoji, style: const TextStyle(fontSize: 17)),
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
                    fontSize: 13,
                  ),
                ),
                Text(
                  item.product.lowestPrice != null
                      ? 'Referans: ₺${item.product.lowestPrice!.toStringAsFixed(2)}'
                      : 'Referans fiyat yok',
                  style: const TextStyle(color: CoffeeColors.cocoa, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: CoffeeColors.foam,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CoffeeColors.crema),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _QtyBtn(icon: Icons.remove, onTap: () => state.changeQty(item.product.id, -1)),
                SizedBox(
                  width: 28,
                  child: Text(
                    '${item.quantity}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: CoffeeColors.espresso,
                      fontSize: 13,
                    ),
                  ),
                ),
                _QtyBtn(icon: Icons.add, onTap: () => state.changeQty(item.product.id, 1)),
              ],
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => state.removeFromCart(item.product.id),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: CoffeeColors.danger.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.close, size: 15, color: CoffeeColors.danger),
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
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 28,
        height: 30,
        child: Icon(icon, size: 14, color: CoffeeColors.darkRoast),
      ),
    );
  }
}

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
            style: const TextStyle(color: CoffeeColors.cocoa, fontSize: 12),
          ),
        ],
      ],
    );
  }
}
