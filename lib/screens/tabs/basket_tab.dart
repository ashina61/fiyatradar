import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../state/app_state.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import '../main_screen.dart';

class BasketTab extends StatefulWidget {
  const BasketTab({super.key});

  @override
  State<BasketTab> createState() => _BasketTabState();
}

class _BasketTabState extends State<BasketTab> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final cart = state.cart;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: FRPageHeader(
              overline: 'TOPLUCA SORGULA',
              title: 'Sepet',
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Text(
              'Ürünleri ekle — hangi marketin hangi kombinasyonda en ucuz olduğunu gör.',
              style: frText(13, FontWeight.w500, color: FR.ink3, height: 1.5),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: _Segmented(
              labels: const ['Sepetim', 'Karşılaştır'],
              counts: [state.cartItemCount, cart.isEmpty ? 0 : state.cart.length],
              index: _tab,
              onChange: (i) => setState(() => _tab = i),
            ),
          ),
          Expanded(
            child: _tab == 0
                ? _CartPanel(state: state, onCompare: () => setState(() => _tab = 1))
                : _ComparePanel(state: state),
          ),
        ],
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  const _Segmented({
    required this.labels,
    required this.counts,
    required this.index,
    required this.onChange,
  });
  final List<String> labels;
  final List<int> counts;
  final int index;
  final ValueChanged<int> onChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: FR.surface,
        borderRadius: FRRad.all(FRRad.m),
        border: Border.all(color: FR.hairline),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: InkWell(
                onTap: () => onChange(i),
                borderRadius: FRRad.all(10),
                child: Container(
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: index == i ? FR.gold : Colors.transparent,
                    borderRadius: FRRad.all(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        labels[i],
                        style: frText(12.5, FontWeight.w800,
                            color: index == i ? FR.bg : FR.ink2),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: index == i
                              ? FR.surface.withOpacity(FR.isDark ? .24 : .82)
                              : FR.bgElev,
                          borderRadius: FRRad.all(8),
                        ),
                        child: Text('${counts[i]}',
                            style: frText(10, FontWeight.w800,
                                color: index == i ? FR.bg : FR.ink3)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CartPanel extends StatelessWidget {
  const _CartPanel({required this.state, required this.onCompare});
  final AppState state;
  final VoidCallback onCompare;

  @override
  Widget build(BuildContext context) {
    final cart = state.cart;
    if (cart.isEmpty) {
      return _EmptyCart();
    }
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.fromLTRB(
              20,
              14,
              20,
              frScrollPaddingWithFooter(context),
            ),
            itemCount: cart.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _CartRow(item: cart[i], state: state),
          ),
        ),
        _CartFooter(state: state, onCompare: onCompare),
      ],
    );
  }
}

class _EmptyCart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 24, 20, frBottomScrollPadding(context)),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [FR.surface, FR.surfaceLo],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: FRRad.all(28),
                border: Border.all(color: FR.hairline),
              ),
              child: Icon(Icons.shopping_basket_outlined, color: FR.gold, size: 40),
            ),
            const SizedBox(height: 16),
            Text('Sepetin boş', style: frDisplay(22, FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              'Ürün ekle, hangi markette en ucuz olduğunu radar senin için bulsun.',
              textAlign: TextAlign.center,
              style: frText(13, FontWeight.w600, color: FR.ink3, height: 1.5),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: 220,
              child: FRCta(
                label: 'Ürün keşfet',
                icon: Icons.radar_rounded,
                onTap: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 1)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartRow extends StatelessWidget {
  const _CartRow({required this.item, required this.state});
  final CartItem item;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: frSurface(radius: FRRad.l),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: FR.surfaceHi,
              borderRadius: FRRad.all(12),
              border: Border.all(color: FR.hairline),
            ),
            alignment: Alignment.center,
            child: Text(item.product.emoji, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: frText(13.5, FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                  '${item.product.priceHistory.length} mağaza · ${item.product.brand}',
                  style: frText(11.5, FontWeight.w600, color: FR.ink3),
                ),
                const SizedBox(height: 4),
                FRPriceText(item.product.lowestPrice, size: 15, color: FR.gold),
              ],
            ),
          ),
          _QtyStepper(
            qty: item.quantity,
            onDec: () => state.changeQty(item.product.id, -1),
            onInc: () => state.changeQty(item.product.id, 1),
            onRemove: () => state.removeFromCart(item.product.id),
          ),
        ],
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  const _QtyStepper({
    required this.qty,
    required this.onDec,
    required this.onInc,
    required this.onRemove,
  });
  final int qty;
  final VoidCallback onDec;
  final VoidCallback onInc;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: FR.bgElev,
        borderRadius: FRRad.all(10),
        border: Border.all(color: FR.hairline),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          _btn(Icons.remove_rounded, qty <= 1 ? onRemove : onDec),
          SizedBox(
            width: 26,
            child: Text('$qty',
                textAlign: TextAlign.center,
                style: frText(13.5, FontWeight.w800)),
          ),
          _btn(Icons.add_rounded, onInc),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, VoidCallback? onTap) => InkWell(
        onTap: onTap,
        borderRadius: FRRad.all(8),
        child: Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          child: Icon(icon, color: FR.ink2, size: 16),
        ),
      );
}

class _CartFooter extends StatelessWidget {
  const _CartFooter({required this.state, required this.onCompare});
  final AppState state;
  final VoidCallback onCompare;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: true,
      minimum: EdgeInsets.only(
        bottom: frStickyFooterBottomPadding(context),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
        decoration: BoxDecoration(
          color: FR.bgElev,
          border: Border(top: BorderSide(color: FR.hairline)),
        ),
        child: Column(
          children: [
            _line('Alt toplam', '₺${state.cartSubtotal.toStringAsFixed(2)}'),
            const SizedBox(height: 4),
            _line('Tahmini tasarruf', '₺${state.cartSavings.toStringAsFixed(2)}',
                hl: FR.good),
            const SizedBox(height: 12),
            FRCta(
              label: 'En ucuz sepeti bul',
              icon: Icons.bolt_rounded,
              onTap: onCompare,
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(String l, String v, {Color? hl}) => Row(
        children: [
          Expanded(
            child: Text(l, style: frText(12.5, FontWeight.w700, color: FR.ink3)),
          ),
          Text(v, style: frPrice(14, color: hl ?? FR.ink)),
        ],
      );
}

class _ComparePanel extends StatefulWidget {
  const _ComparePanel({required this.state});
  final AppState state;

  @override
  State<_ComparePanel> createState() => _ComparePanelState();
}

class _ComparePanelState extends State<_ComparePanel> {
  String _cacheKey = '';
  List<_StoreGroup> _cachedGroups = const [];

  List<_StoreGroup> _groups(AppState state) {
    final key = state.cart
        .map((c) {
          final p = c.product;
          final histSig = p.priceHistory
              .map((e) => '${e.store}:${e.price}')
              .join('|');
          return '${p.id}:${c.quantity}:$histSig';
        })
        .join('||');
    if (key == _cacheKey) return _cachedGroups;
    _cacheKey = key;
    _cachedGroups = _computeStoreGroups(state);
    return _cachedGroups;
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final cart = state.cart;
    if (cart.isEmpty) {
      return _EmptyCart();
    }
    final groups = _groups(state);
    final best = groups.isEmpty ? null : groups.first;

    return ListView(
      padding: EdgeInsets.fromLTRB(20, 14, 20, frBottomScrollPadding(context)),
      children: [
        if (best != null)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [FR.surfaceHi, FR.surfaceLo],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: FRRad.all(24),
              border: Border.all(color: FR.goldDeep.withOpacity(.4)),
              boxShadow: [BoxShadow(color: FR.gold.withOpacity(.12), blurRadius: 32)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('EN UCUZ KOMBİNASYON', style: frOverline()),
                const SizedBox(height: 10),
                Text(best.store, style: frDisplay(28, FontWeight.w700)),
                const SizedBox(height: 4),
                Text('${best.items} ürün · ${best.covered}/${cart.length} eşleşti',
                    style: frText(12, FontWeight.w600, color: FR.ink3)),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FRPriceText(best.total, size: 38, color: FR.gold),
                    const SizedBox(width: 12),
                    if (state.cartSavings > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: FR.good.withOpacity(.14),
                            borderRadius: FRRad.all(999),
                            border: Border.all(color: FR.good.withOpacity(.35)),
                          ),
                          child: Text(
                              '-₺${state.cartSavings.toStringAsFixed(0)}',
                              style: frText(12, FontWeight.w800, color: FR.good)),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),
        const FRSectionHead(eyebrow: 'DİĞER MARKETLER', title: 'Zincir karşılaştırması'),
        const SizedBox(height: 12),
        for (final g in groups.skip(1).take(4))
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: frSurface(radius: FRRad.l),
              child: Row(
                children: [
                  FRStoreBadge(g.store),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${g.covered}/${cart.length} ürün eşleşti',
                            style: frText(12.5, FontWeight.w800)),
                        Text('${g.items} fiyat noktası',
                            style: frText(11, FontWeight.w600, color: FR.ink3)),
                      ],
                    ),
                  ),
                  FRPriceText(g.total, size: 16, color: FR.ink),
                ],
              ),
            ),
          ),
        const SizedBox(height: 20),
        const FRSectionHead(eyebrow: 'ÜRÜN BAZLI', title: 'Sepet dağılımı'),
        const SizedBox(height: 12),
        for (final c in cart)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: frSurface(radius: FRRad.l),
              child: Row(
                children: [
                  Text(c.product.emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${c.product.name} × ${c.quantity}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: frText(13, FontWeight.w800)),
                        Text(c.product.cheapestStore ?? '—',
                            style: frText(11.5, FontWeight.w700, color: FR.ink3)),
                      ],
                    ),
                  ),
                  FRPriceText(
                    (c.product.lowestPrice ?? 0) * c.quantity,
                    size: 15,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  static List<_StoreGroup> _computeStoreGroups(AppState state) {
    final storeCount = <String, int>{};
    final storeTotal = <String, double>{};
    final storeItems = <String, int>{};
    for (final c in state.cart) {
      for (final e in c.product.priceHistory) {
        storeItems[e.store] = (storeItems[e.store] ?? 0) + 1;
      }
      // For each store with a price for this product, add its cheapest entry
      final byStore = <String, double>{};
      for (final e in c.product.priceHistory) {
        final cur = byStore[e.store];
        if (cur == null || e.price < cur) byStore[e.store] = e.price;
      }
      byStore.forEach((store, price) {
        storeTotal[store] = (storeTotal[store] ?? 0) + price * c.quantity;
        storeCount[store] = (storeCount[store] ?? 0) + 1;
      });
    }
    final groups = storeTotal.entries
        .map((e) => _StoreGroup(
              store: e.key,
              total: e.value,
              covered: storeCount[e.key] ?? 0,
              items: storeItems[e.key] ?? 0,
            ))
        .toList();
    groups.sort((a, b) {
      final covCmp = b.covered.compareTo(a.covered);
      if (covCmp != 0) return covCmp;
      return a.total.compareTo(b.total);
    });
    return groups;
  }
}

class _StoreGroup {
  final String store;
  final double total;
  final int covered;
  final int items;
  _StoreGroup({
    required this.store,
    required this.total,
    required this.covered,
    required this.items,
  });
}
