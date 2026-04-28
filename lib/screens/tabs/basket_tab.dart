import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../services/basket_pricing_service.dart';
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
  int _previousTab = 0;

  void _setTab(int next) {
    if (next == _tab) return;
    setState(() {
      _previousTab = _tab;
      _tab = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final cart = state.cart;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsetsDirectional.fromSTEB(FRSpace.xl, 14, FRSpace.xl, 0),
            child: FRPageHeader(
              overline: 'TOPLUCA SORGULA',
              title: 'Sepet',
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Text(
              'Bölgende bildirilen fiyatlara göre tahmini sepet planını karşılaştır.',
              style: frText(13, FontWeight.w500, color: FR.ink3, height: 1.5),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: _Segmented(
              labels: const ['Sepetim', 'Karşılaştır'],
              counts: [state.cartItemCount, cart.isEmpty ? 0 : state.cart.length],
              index: _tab,
              onChange: _setTab,
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 360),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                final isIncoming = child.key == ValueKey(_tab);
                final fromLeft = _tab > _previousTab;
                final begin = isIncoming
                    ? Offset(fromLeft ? 0.08 : -0.08, 0)
                    : Offset(fromLeft ? -0.04 : 0.04, 0);
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: begin,
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey(_tab),
                child: _tab == 0
                    ? _CartPanel(state: state, onCompare: () => _setTab(1))
                    : _ComparePanel(state: state),
              ),
            ),
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
                            color: index == i ? FR.onGold : FR.ink2),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: index == i
                              ? FR.onGold.withOpacity(.18)
                              : FR.bgElev,
                          borderRadius: FRRad.all(8),
                        ),
                        child: Text('${counts[i]}',
                            style: frText(10, FontWeight.w800,
                                color: index == i ? FR.onGold : FR.ink3)),
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
              'Ürün ekle, bölgesel fiyat gruplarına göre tahmini sepet toplamlarını gör.',
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
              label: 'Tahmini sepeti karşılaştır',
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
  late Future<BasketPricingResult> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.state.calculateRegionalBasketPricing();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    if (state.cart.isEmpty) return _EmptyCart();

    return FutureBuilder<BasketPricingResult>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final result = snap.data!;
        final singles = result.singleMarketEstimates;
        final mixed = result.cheapestMixed;
        final smart = result.smartSuggestion;
        return ListView(
          padding: EdgeInsets.fromLTRB(20, 14, 20, frBottomScrollPadding(context)),
          children: [
            const FRSectionHead(eyebrow: 'TEK MARKET', title: 'Tahmini toplamlar'),
            const SizedBox(height: 12),
            ...singles.take(5).map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: frSurface(radius: FRRad.l),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.chainName, style: frText(13, FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text('Tahmini toplam: ₺${s.estimatedTotal.toStringAsFixed(2)}',
                              style: frText(12, FontWeight.w700, color: FR.goldDeep)),
                          Text(
                            'Bulunan: ${s.foundItemCount} · Eksik: ${s.missingItemCount} · Güven: ${s.confidence} · Kaynak: ${s.usedPriceSource}',
                            style: frText(10.5, FontWeight.w600, color: FR.ink3),
                          ),
                          if (s.missingProductIds.isNotEmpty)
                            Text(
                              'Eksik ürün id: ${s.missingProductIds.join(', ')}',
                              style: frText(10.5, FontWeight.w600, color: FR.warn),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
            const SizedBox(height: 16),
            const FRSectionHead(eyebrow: 'KARMA SEPET', title: 'En ucuz tahmini karışım'),
            const SizedBox(height: 12),
            if (mixed == null)
              Text('Karma hesap için yeterli bölgesel fiyat yok.',
                  style: frText(12, FontWeight.w600, color: FR.ink3))
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: frSurface(radius: FRRad.l),
                child: Text(
                  'Tahmini toplam: ₺${mixed.estimatedTotal.toStringAsFixed(2)} · ${mixed.marketCount} market gerekiyor',
                  style: frText(12.5, FontWeight.w700),
                ),
              ),
            const SizedBox(height: 16),
            const FRSectionHead(eyebrow: 'ÖNERİ', title: 'En mantıklı seçenek'),
            const SizedBox(height: 12),
            if (smart == null)
              Text('Karşılaştırma için yeterli veri yok.',
                  style: frText(12, FontWeight.w600, color: FR.ink3))
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: frSurface(radius: FRRad.l),
                child: Text(smart.message, style: frText(12, FontWeight.w700)),
              ),
          ],
        );
      },
    );
  }
}

class _BestCombinationCard extends StatelessWidget {
  const _BestCombinationCard({
    required this.best,
    required this.cartSize,
    required this.savings,
  });
  final _StoreGroup best;
  final int cartSize;
  final double savings;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: FRRad.all(28),
        border: Border.all(color: FR.goldDeep.withOpacity(.55), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: FR.gold.withOpacity(.18),
            blurRadius: 36,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: FR.shadowTone.withOpacity(.45),
            blurRadius: 22,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Layered premium gradient — espresso into deep gold light.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    FR.surfaceHi,
                    FR.surfaceLo,
                    FR.bgElev,
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            right: -40,
            top: -50,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    FR.gold.withOpacity(.22),
                    FR.gold.withOpacity(.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: -18,
            top: -18,
            child: Icon(
              Icons.workspace_premium_rounded,
              size: 180,
              color: FR.gold.withOpacity(.07),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: FR.bg.withOpacity(.35),
                        borderRadius: FRRad.all(999),
                        border: Border.all(color: FR.hairline),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const FRLiveDot(size: 6),
                          const SizedBox(width: 5),
                          Text('canlı hesaplama',
                              style: frText(9.5, FontWeight.w800,
                                  color: FR.ink3, letter: .6)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('EN UCUZ KOMBİNASYON',
                    style: frOverline(color: FR.gold, size: 10)),
                const SizedBox(height: 8),
                ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (rect) => LinearGradient(
                    colors: [FR.goldHi, FR.gold, FR.goldDeep],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(rect),
                  child: Text(
                    best.store,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: frDisplay(34, FontWeight.w700, height: 1.05),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${best.items} fiyat noktası tarandı · '
                  '${best.covered}/$cartSize ürün eşleşti',
                  style: frText(12, FontWeight.w600, color: FR.ink3),
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TOPLAM',
                            style: frOverline(color: FR.ink3, size: 9)),
                        const SizedBox(height: 4),
                        FRPriceText(best.total, size: 42, color: FR.gold),
                      ],
                    ),
                    const Spacer(),
                    if (savings > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              FR.good.withOpacity(.22),
                              FR.good.withOpacity(.10),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: FRRad.all(999),
                          border: Border.all(color: FR.good.withOpacity(.45)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.savings_rounded,
                                color: FR.good, size: 14),
                            const SizedBox(width: 6),
                            Text('-₺${savings.toStringAsFixed(0)} tasarruf',
                                style: frText(12, FontWeight.w800,
                                    color: FR.good)),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompareRow extends StatelessWidget {
  const _CompareRow({
    required this.group,
    required this.cartSize,
    required this.bestTotal,
    required this.bestStore,
  });
  final _StoreGroup group;
  final int cartSize;
  final double bestTotal;
  final String bestStore;

  @override
  Widget build(BuildContext context) {
    final delta = group.total - bestTotal;
    final pct = bestTotal <= 0 ? 0.0 : ((delta / bestTotal) * 100.0).abs();
    final more = delta > 0.005;
    final coverColor = group.covered >= cartSize ? FR.good : FR.warn;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: frSurface(radius: FRRad.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FRStoreBadge(group.store),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${group.covered}/$cartSize ürün eşleşti',
                        style: frText(12.5, FontWeight.w800)),
                    Text(
                      group.covered < cartSize
                          ? '${cartSize - group.covered} ürün için fiyat yok'
                          : '${group.items} fiyat noktası tarandı',
                      style: frText(11, FontWeight.w600, color: coverColor),
                    ),
                  ],
                ),
              ),
              FRPriceText(group.total, size: 16, color: FR.ink),
            ],
          ),
          const SizedBox(height: 10),
          if (more)
            _MoreExpensive(delta: delta, pct: pct, vsStore: bestStore)
          else
            const _SamePriceTag(),
        ],
      ),
    );
  }
}

class _MoreExpensive extends StatelessWidget {
  const _MoreExpensive({
    required this.delta,
    required this.pct,
    required this.vsStore,
  });
  final double delta;
  final double pct;
  final String vsStore;

  @override
  Widget build(BuildContext context) {
    final c = FR.bad;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: c.withOpacity(.10),
        borderRadius: FRRad.all(10),
        border: Border.all(color: c.withOpacity(.28)),
      ),
      child: Row(
        children: [
          Icon(Icons.arrow_upward_rounded, size: 14, color: c),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '${vsStore.isEmpty ? 'En ucuz seçeneğe' : '$vsStore\'e'} göre +₺${delta.toStringAsFixed(delta < 10 ? 2 : 0)} '
              '(%${pct.toStringAsFixed(pct < 10 ? 1 : 0)}) daha pahalı',
              style: frText(11, FontWeight.w800, color: c),
            ),
          ),
        ],
      ),
    );
  }
}

class _SamePriceTag extends StatelessWidget {
  const _SamePriceTag();

  @override
  Widget build(BuildContext context) {
    final c = FR.good;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: c.withOpacity(.10),
        borderRadius: FRRad.all(10),
        border: Border.all(color: c.withOpacity(.28)),
      ),
      child: Row(
        children: [
          Icon(Icons.bolt_rounded, size: 14, color: c),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'En ucuz kombinasyona eşit fiyat',
              style: frText(11, FontWeight.w800, color: c),
            ),
          ),
        ],
      ),
    );
  }
}

List<_StoreGroup> _computeStoreGroups(AppState state) {
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
