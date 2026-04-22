import 'package:flutter/material.dart';

import '../models/product.dart';
import '../state/app_state.dart';
import '../ui/components.dart';
import '../ui/tokens.dart';
import 'main_screen.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key, required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final isFav = state.isFavorite(product.id);
    final alert = state.alertForProduct(product.id);
    final sorted = [...product.priceHistory]..sort((a, b) => b.date.compareTo(a.date));
    final latest = sorted.isEmpty ? null : sorted.first;

    // Store aggregates (cheapest entry per store)
    final perStore = <String, PriceEntry>{};
    for (final e in product.priceHistory) {
      final cur = perStore[e.store];
      if (cur == null || e.price < cur.price) perStore[e.store] = e;
    }
    final stores = perStore.values.toList()..sort((a, b) => a.price.compareTo(b.price));

    return Scaffold(
      backgroundColor: FR.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Top nav
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  FRIconChip(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => Navigator.pop(context)),
                  const Spacer(),
                  FRIconChip(
                    icon: isFav ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                    active: isFav,
                    onTap: () => state.toggleFavorite(product.id),
                  ),
                  const SizedBox(width: 8),
                  FRIconChip(icon: Icons.share_outlined, onTap: () {}),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 120),
                children: [
                  // Hero image
                  Container(
                    height: 220,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [FR.surfaceHi, FR.surfaceLo],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: FRRad.all(24),
                      border: Border.all(color: FR.hairline),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(product.emoji, style: const TextStyle(fontSize: 108)),
                        ),
                        Positioned(
                          top: 14,
                          left: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: FR.gold.withOpacity(.16),
                              borderRadius: FRRad.all(999),
                              border: Border.all(color: FR.gold.withOpacity(.35)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.verified_rounded, color: FR.gold, size: 13),
                                const SizedBox(width: 5),
                                Text('Admin onaylı',
                                    style: frText(10.5, FontWeight.w800, color: FR.gold)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text('${product.category.toUpperCase()} · ${product.brand.toUpperCase()}',
                      style: frOverline(color: FR.ink3)),
                  const SizedBox(height: 4),
                  Text(product.name,
                      style: frDisplay(28, FontWeight.w700, height: 1.1)),
                  Text(product.unit,
                      style: frText(13, FontWeight.w600, color: FR.ink3)),
                  const SizedBox(height: 18),
                  _BestPriceCard(
                    price: product.lowestPrice,
                    store: product.cheapestStore,
                    pct: product.priceChangePct,
                    latest: latest,
                  ),
                  const SizedBox(height: 18),
                  if (product.priceHistory.length >= 2) _PriceHistoryCard(product: product),
                  if (product.priceHistory.length >= 2) const SizedBox(height: 18),
                  FRSectionHead(eyebrow: 'MARKETLER', title: 'Mağaza karşılaştırması'),
                  const SizedBox(height: 12),
                  if (stores.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text('Bu ürün için henüz fiyat yok.',
                          style: frText(12.5, FontWeight.w600, color: FR.ink3)),
                    )
                  else
                    ...stores.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _StoreRow(
                            store: e.store,
                            price: e.price,
                            when: e.date,
                            isBest: e.store == product.cheapestStore,
                          ),
                        )),
                  const SizedBox(height: 20),
                  FRSectionHead(eyebrow: 'SON KATKILAR', title: 'Topluluk akışı'),
                  const SizedBox(height: 12),
                  ...sorted.take(4).map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ContributionRow(entry: e),
                      )),
                ],
              ),
            ),
            _Actions(
              isAlertActive: alert != null,
              onAlert: () => _openAlert(context, state, product, alert?.targetPrice),
              onAdd: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 2)),
              ),
              onCart: () => state.addToCart(product),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAlert(
    BuildContext context,
    AppState state,
    Product product,
    double? current,
  ) async {
    final ctrl = TextEditingController(
      text: current?.toStringAsFixed(2) ?? (product.lowestPrice ?? 0).toStringAsFixed(2),
    );
    final res = await showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Fiyat alarmı', style: frDisplay(20, FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ürün bu fiyata indiğinde seni uyaralım.',
                style: frText(12.5, FontWeight.w600, color: FR.ink3)),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: frPrice(20),
              cursorColor: FR.gold,
              decoration: const InputDecoration(
                prefixText: '₺ ',
                prefixStyle: TextStyle(color: FR.gold, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal', style: frText(13, FontWeight.w800, color: FR.ink3)),
          ),
          TextButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text.replaceAll(',', '.'));
              if (v != null && v > 0) Navigator.pop(context, v);
            },
            child: Text('Kaydet',
                style: frText(13, FontWeight.w800, color: FR.gold)),
          ),
        ],
      ),
    );
    if (res != null) {
      await state.setProductAlert(productId: product.id, targetPrice: res);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Alarm ayarlandı: ₺${res.toStringAsFixed(2)}')),
      );
    }
  }
}

class _BestPriceCard extends StatelessWidget {
  const _BestPriceCard({
    required this.price,
    required this.store,
    required this.pct,
    required this.latest,
  });
  final double? price;
  final String? store;
  final double? pct;
  final PriceEntry? latest;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [FR.surfaceHi, FR.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: FRRad.all(22),
        border: Border.all(color: FR.goldDeep.withOpacity(.4)),
        boxShadow: [BoxShadow(color: FR.gold.withOpacity(.1), blurRadius: 28)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('BÖLGENDEKİ EN İYİ FİYAT', style: frOverline()),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FRPriceText(price, size: 44, color: FR.ink),
              const SizedBox(width: 12),
              if (pct != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: FRTrendPill(pct: pct!),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (store != null) FRStoreBadge(store!, filled: true),
              const SizedBox(width: 8),
              if (latest != null) FRFreshChip(date: latest!.date),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriceHistoryCard extends StatelessWidget {
  const _PriceHistoryCard({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final sorted = [...product.priceHistory]..sort((a, b) => a.date.compareTo(b.date));
    final values = sorted.map((e) => e.price).toList();
    final high = values.reduce((a, b) => a > b ? a : b);
    final low = values.reduce((a, b) => a < b ? a : b);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: frSurface(radius: FRRad.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('SON 30 GÜN', style: frOverline()),
              const Spacer(),
              Text('${values.length} veri noktası',
                  style: frText(11, FontWeight.w700, color: FR.ink3)),
            ],
          ),
          const SizedBox(height: 12),
          FRSparkline(values: values, height: 64),
          const SizedBox(height: 10),
          Row(
            children: [
              _hl('EN DÜŞÜK', '₺${low.toStringAsFixed(2)}', FR.good),
              const SizedBox(width: 10),
              _hl('EN YÜKSEK', '₺${high.toStringAsFixed(2)}', FR.bad),
              const SizedBox(width: 10),
              _hl('FARK', '₺${(high - low).toStringAsFixed(2)}', FR.gold),
            ],
          ),
        ],
      ),
    );
  }

  Widget _hl(String l, String v, Color c) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: FR.bgElev,
            borderRadius: FRRad.all(10),
            border: Border.all(color: FR.hairline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l, style: frOverline(color: FR.ink3, size: 9)),
              const SizedBox(height: 2),
              Text(v, style: frPrice(14, color: c)),
            ],
          ),
        ),
      );
}

class _StoreRow extends StatelessWidget {
  const _StoreRow({
    required this.store,
    required this.price,
    required this.when,
    required this.isBest,
  });
  final String store;
  final double price;
  final DateTime when;
  final bool isBest;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FR.surface,
        borderRadius: FRRad.all(FRRad.l),
        border: Border.all(color: isBest ? FR.gold.withOpacity(.55) : FR.hairline),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isBest ? FR.gold.withOpacity(.15) : FR.surfaceHi,
              borderRadius: FRRad.all(12),
              border: Border.all(color: isBest ? FR.gold : FR.hairline),
            ),
            alignment: Alignment.center,
            child: Text(
              store.substring(0, store.length > 2 ? 2 : store.length).toUpperCase(),
              style: frText(13, FontWeight.w800, color: isBest ? FR.gold : FR.ink2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(store, style: frText(13.5, FontWeight.w800)),
                    if (isBest) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.bolt_rounded, color: FR.gold, size: 14),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                FRFreshChip(date: when),
              ],
            ),
          ),
          FRPriceText(price, size: 18, color: isBest ? FR.gold : FR.ink),
        ],
      ),
    );
  }
}

class _ContributionRow extends StatelessWidget {
  const _ContributionRow({required this.entry});
  final PriceEntry entry;

  @override
  Widget build(BuildContext context) {
    final initial = entry.reportedBy.isEmpty
        ? 'T'
        : entry.reportedBy[0].toUpperCase();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: frSurface(radius: FRRad.l),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: FR.surfaceHi,
              borderRadius: FRRad.all(12),
              border: Border.all(color: FR.hairline),
            ),
            alignment: Alignment.center,
            child: Text(initial,
                style: frText(14, FontWeight.w800, color: FR.gold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.reportedBy,
                    style: frText(13, FontWeight.w800)),
                Row(
                  children: [
                    FRStoreBadge(entry.store),
                    const SizedBox(width: 6),
                    FRFreshChip(date: entry.date),
                  ],
                ),
              ],
            ),
          ),
          FRPriceText(entry.price, size: 15),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.isAlertActive,
    required this.onAlert,
    required this.onAdd,
    required this.onCart,
  });
  final bool isAlertActive;
  final VoidCallback onAlert;
  final VoidCallback onAdd;
  final VoidCallback onCart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: const BoxDecoration(
        color: FR.bgElev,
        border: Border(top: BorderSide(color: FR.hairline)),
      ),
      child: Row(
        children: [
          Expanded(
            child: FRCta(
              label: isAlertActive ? 'Alarm aktif' : 'Alarm kur',
              icon: isAlertActive
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_none_rounded,
              filled: false,
              onTap: onAlert,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FRCta(
              label: 'Sepete ekle',
              icon: Icons.shopping_basket_outlined,
              onTap: onCart,
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: onAdd,
            borderRadius: FRRad.all(999),
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [FR.goldHi, FR.goldDeep]),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: FR.gold.withOpacity(.3), blurRadius: 18)],
              ),
              child: const Icon(Icons.add_rounded, color: FR.bg, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}
