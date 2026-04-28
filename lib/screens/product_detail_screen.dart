import 'package:flutter/material.dart';

import '../models/price_reporting.dart';
import '../models/product.dart';
import '../state/app_state.dart';
import '../ui/components.dart';
import '../ui/tokens.dart';
import 'main_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.product});
  final Product product;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late List<PriceEntry> _sorted;
  late List<PriceEntry> _stores;
  late PriceEntry? _best;

  @override
  void initState() {
    super.initState();
    _recomputeDerived();
  }

  @override
  void didUpdateWidget(covariant ProductDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldP = oldWidget.product;
    final next = widget.product;
    final oldHistorySignature = oldP.priceHistory
        .map((e) =>
            '${e.id}:${e.price}:${e.upvotes}:${e.downvotes}:${e.trustWeightedScore}:${e.status.name}:${e.date.millisecondsSinceEpoch}')
        .join('|');
    final nextHistorySignature = next.priceHistory
        .map((e) =>
            '${e.id}:${e.price}:${e.upvotes}:${e.downvotes}:${e.trustWeightedScore}:${e.status.name}:${e.date.millisecondsSinceEpoch}')
        .join('|');
    if (oldP.id != next.id ||
        oldHistorySignature != nextHistorySignature) {
      _recomputeDerived();
    }
  }

  void _recomputeDerived() {
    final product = widget.product;
    _sorted = [...product.priceHistory]..sort((a, b) => b.date.compareTo(a.date));
    _best = product.bestValueEntry;

    final perStore = <String, PriceEntry>{};
    for (final e in product.validEntries) {
      final cur = perStore[e.store];
      if (cur == null) {
        perStore[e.store] = e;
        continue;
      }
      final curVerified = cur.status == PriceStatus.communityVerified;
      final eVerified = e.status == PriceStatus.communityVerified;
      if (eVerified && !curVerified) {
        perStore[e.store] = e;
      } else if (eVerified == curVerified && e.price < cur.price) {
        perStore[e.store] = e;
      }
    }
    _stores = perStore.values.toList()
      ..sort((a, b) {
        final av = a.status == PriceStatus.communityVerified ? 0 : 1;
        final bv = b.status == PriceStatus.communityVerified ? 0 : 1;
        if (av != bv) return av - bv;
        return a.price.compareTo(b.price);
      });
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final state = AppStateScope.of(context);
    final isFav = state.isFavorite(product.id);
    final alert = state.alertForProduct(product.id);

    return Scaffold(
      backgroundColor: FR.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Top nav
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
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
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
                children: [
                  // Hero image
                  Container(
                    height: 220,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [FR.surfaceHi, FR.surfaceLo],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: FRRad.all(24),
                      border: Border.all(color: FR.hairline),
                    ),
                    child: Stack(
                      children: [
                        if (product.imageUrl != null &&
                            product.imageUrl!.isNotEmpty)
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: FRRad.all(24),
                              child: Image.network(
                                product.imageUrl!,
                                fit: BoxFit.cover,
                                cacheWidth: 1200,
                                filterQuality: FilterQuality.medium,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Text(product.emoji,
                                      style: const TextStyle(fontSize: 108)),
                                ),
                              ),
                            ),
                          )
                        else
                          Center(
                            child: Text(product.emoji,
                                style: const TextStyle(fontSize: 108)),
                          ),
                        Positioned(
                          top: 14,
                          left: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
                            decoration: BoxDecoration(
                              color: FR.gold.withOpacity(.16),
                              borderRadius: FRRad.all(999),
                              border: Border.all(color: FR.gold.withOpacity(.35)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified_rounded, color: FR.gold, size: 13),
                                const SizedBox(width: 5),
                                Text('Katalog onaylı',
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
                  _RegionalPriceSections(product: product, state: state, legacyBest: _best),
                  const SizedBox(height: 18),
                  if (product.validEntries.length >= 2)
                    _PriceHistoryCard(product: product),
                  if (product.validEntries.length >= 2) const SizedBox(height: 18),
                  const FRSectionHead(eyebrow: 'MARKETLER', title: 'Mağaza karşılaştırması'),
                  const SizedBox(height: 12),
                  if (_stores.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
                      child: Text('Bu ürün için henüz fiyat yok.',
                          style: frText(12.5, FontWeight.w600, color: FR.ink3)),
                    )
                  else
                    ..._stores.map((e) {
                      final cheapest = product.lowestPrice ?? e.price;
                      final delta = e.price - cheapest;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
                        child: _StoreRow(
                          store: e.store,
                          entry: e,
                          isBest: _best != null && e.id == _best!.id,
                          delta: delta,
                          cheapestPrice: cheapest,
                        ),
                      );
                    }),
                  const SizedBox(height: 20),
                  const FRSectionHead(
                      eyebrow: 'TOPLULUK DOĞRULAMASI',
                      title: 'Son katkılar'),
                  const SizedBox(height: 6),
                  Text(
                    'Oy ver, topluluğun güveni şekillendir. Kendi girdiğine ya da aynı girdiye tekrar oy veremezsin.',
                    style: frText(11.5, FontWeight.w600, color: FR.ink3, height: 1.5),
                  ),
                  const SizedBox(height: 10),
                  if (_sorted.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
                      child: Text('Henüz katkı yok — ilk fiyatı sen ekle.',
                          style: frText(12, FontWeight.w600, color: FR.ink3)),
                    )
                  else
                    ..._sorted.take(6).map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 10), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
                          child: _ContributionRow(
                            product: product,
                            entry: e,
                            state: state,
                          ),
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
        backgroundColor: FR.surface,
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
              decoration: InputDecoration(
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


class _RegionalPriceSections extends StatelessWidget {
  const _RegionalPriceSections({
    required this.product,
    required this.state,
    required this.legacyBest,
  });

  final Product product;
  final AppState state;
  final PriceEntry? legacyBest;

  @override
  Widget build(BuildContext context) {
    final city = (state.cityName ?? '').trim();
    final district = (state.districtName ?? '').trim();
    final hasRegion = city.isNotEmpty && district.isNotEmpty;
    if (!hasRegion) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: frSurface(radius: FRRad.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('BÖLGENDE BİLDİRİLEN FİYATLAR', style: frOverline()),
            const SizedBox(height: 8),
            Text('Bölgesel fiyatları görmek için önce il ve ilçe seç.',
                style: frText(12, FontWeight.w600, color: FR.ink3)),
          ],
        ),
      );
    }

    return StreamBuilder<List<PriceGroupModel>>(
      stream: state.watchRegionalPriceGroups(
        productId: product.id,
        city: city,
        district: district,
      ),
      builder: (context, snap) {
        final groups = snap.data ?? const <PriceGroupModel>[];
        if (groups.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: frSurface(radius: FRRad.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('BÖLGENDE BİLDİRİLEN FİYATLAR', style: frOverline()),
                const SizedBox(height: 8),
                Text(
                  legacyBest == null
                      ? '$district / $city için henüz bildirilen fiyat yok.'
                      : '$district / $city için grup yok, son topluluk fiyatı: ₺${legacyBest!.price.toStringAsFixed(2)}',
                  style: frText(12, FontWeight.w600, color: FR.ink3),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: frSurface(radius: FRRad.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('BÖLGENDE BİLDİRİLEN FİYATLAR', style: frOverline()),
              const SizedBox(height: 8),
              Text('$district / $city bölgesi', style: frText(12, FontWeight.w700, color: FR.ink3)),
              const SizedBox(height: 12),
              ...groups.take(4).map((g) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _RegionalGroupCard(group: g, product: product),
                  )),
            ],
          ),
        );
      },
    );
  }
}

class _RegionalGroupCard extends StatelessWidget {
  const _RegionalGroupCard({required this.group, required this.product});

  final PriceGroupModel group;
  final Product product;

  String _relative(DateTime? date) {
    if (date == null) return 'Tarih yok';
    final days = DateTime.now().difference(date).inDays;
    if (days <= 0) return 'Bugün bildirildi';
    if (days == 1) return 'Dün bildirildi';
    return '$days gün önce';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FR.surfaceHi,
        borderRadius: FRRad.all(12),
        border: Border.all(color: FR.hairline),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(group.displayTitle, style: frText(12.5, FontWeight.w800)),
        const SizedBox(height: 4),
        FRPriceText(group.preferredPrice ?? group.latestPrice, size: 18, color: FR.gold),
        const SizedBox(height: 4),
        Text(
          '${_relative(group.lastReportedAt)} · ${group.reportCount} bildirim · ${group.verifiedCount} doğrulama · Güven: ${group.confidence}',
          style: frText(11, FontWeight.w600, color: FR.ink3),
        ),
        Text(priceReportSourceTypeLabelTr(group.sourceType),
            style: frText(11, FontWeight.w700, color: FR.goldDeep)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _TinyAction(
            label: 'Ben de gördüm',
            onTap: () async {
              final state = AppStateScope.of(context);
              try {
                await state.verifyRegionalPriceSeen(
                  productId: product.id,
                  chainId: group.chainId,
                  price: group.preferredPrice ?? group.latestPrice ?? 0,
                  city: group.cityName,
                  district: group.districtName,
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Doğrulaman kaydedildi.')),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$e')),
                );
              }
            },
          ),
          _TinyAction(
            label: 'Farklı fiyat bildir',
            onTap: () {
              final state = AppStateScope.of(context);
              state.setAddPricePreset(
                productId: product.id,
                chainId: group.chainId,
                chainName: group.chainName,
              );
              state.updateRegionSettings(
                cityName: group.cityName,
                districtName: group.districtName,
              );
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 2)),
              );
            },
          ),
          _TinyAction(
            label: 'Sepete ekle',
            onTap: () => AppStateScope.of(context).addToCart(product),
          ),
        ]),
      ]),
    );
  }
}

class _TinyAction extends StatelessWidget {
  const _TinyAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: FRRad.all(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: FR.bgElev,
          borderRadius: FRRad.all(999),
          border: Border.all(color: FR.hairline),
        ),
        child: Text(label, style: frText(10.5, FontWeight.w700, color: FR.ink2)),
      ),
    );
  }
}

class _PriceHistoryCard extends StatelessWidget {
  const _PriceHistoryCard({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final sorted = [...product.validEntries]
      ..sort((a, b) => a.date.compareTo(b.date));
    final values = sorted.map((e) => e.price).toList();
    final high = values.reduce((a, b) => a > b ? a : b);
    final low = values.reduce((a, b) => a < b ? a : b);
    return Container(
      padding: const EdgeInsets.all(18), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
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
    required this.entry,
    required this.isBest,
    required this.delta,
    required this.cheapestPrice,
  });
  final String store;
  final PriceEntry entry;
  final bool isBest;
  final double delta;
  final double cheapestPrice;

  @override
  Widget build(BuildContext context) {
    final verified = entry.status == PriceStatus.communityVerified;
    final pct = cheapestPrice <= 0 ? 0.0 : (delta / cheapestPrice) * 100.0;
    final isCheapest = delta.abs() < 0.005;
    return Container(
      padding: const EdgeInsets.all(14), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
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
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    FRFreshChip(date: entry.date),
                    FRVerifyBadge.status(
                      status: statusToString(entry.status),
                      trustPercent: entry.trustPercent,
                      dense: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FRPriceText(
                entry.price,
                size: 18,
                color: verified || isBest ? FR.gold : FR.ink,
              ),
              const SizedBox(height: 4),
              _DeltaPill(delta: delta, pct: pct, isCheapest: isCheapest),
            ],
          ),
        ],
      ),
    );
  }
}

/// Compact pill that summarises how much pricier (or cheaper) a store is
/// compared to the lowest tracked price. Renders "en ucuz" when the store
/// holds the cheapest price.
class _DeltaPill extends StatelessWidget {
  const _DeltaPill({
    required this.delta,
    required this.pct,
    required this.isCheapest,
  });
  final double delta;
  final double pct;
  final bool isCheapest;

  @override
  Widget build(BuildContext context) {
    if (isCheapest) {
      final c = FR.good;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
        decoration: BoxDecoration(
          color: c.withOpacity(.14),
          borderRadius: FRRad.all(999),
          border: Border.all(color: c.withOpacity(.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bolt_rounded, size: 11, color: c),
            const SizedBox(width: 4),
            Text('en ucuz', style: frText(10, FontWeight.w800, color: c)),
          ],
        ),
      );
    }
    final more = delta > 0;
    final c = more ? FR.bad : FR.good;
    final pctText = pct.abs() < 0.5
        ? pct.abs().toStringAsFixed(1)
        : pct.abs().toStringAsFixed(pct.abs() < 10 ? 1 : 0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
      decoration: BoxDecoration(
        color: c.withOpacity(.12),
        borderRadius: FRRad.all(999),
        border: Border.all(color: c.withOpacity(.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            more ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: 11,
            color: c,
          ),
          const SizedBox(width: 4),
          Text(
            '${more ? '+' : '-'}₺${delta.abs().toStringAsFixed(delta.abs() < 10 ? 2 : 0)} · %$pctText',
            style: frText(10, FontWeight.w800, color: c),
          ),
        ],
      ),
    );
  }
}

class _ContributionRow extends StatefulWidget {
  const _ContributionRow({
    required this.product,
    required this.entry,
    required this.state,
  });
  final Product product;
  final PriceEntry entry;
  final AppState state;

  @override
  State<_ContributionRow> createState() => _ContributionRowState();
}

class _ContributionRowState extends State<_ContributionRow> {
  bool _busy = false;

  Future<void> _report() async {
    final ctrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FR.surface,
        title: Text('Fiyatı raporla', style: frDisplay(20, FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Kısa not (opsiyonel)',
            hintStyle: frText(12, FontWeight.w600, color: FR.ink3),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('İptal', style: frText(12.5, FontWeight.w800, color: FR.ink3)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: Text('Raporla', style: frText(12.5, FontWeight.w800, color: FR.gold)),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (reason == null) return;
    try {
      await widget.state.reportPriceEntry(
        product: widget.product,
        entry: widget.entry,
        reason: reason,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fiyat raporu iletildi.')),
      );
    } on StateError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rapor gönderilemedi, tekrar dene.')),
      );
    }
  }

  Future<void> _cast(VoteKind kind) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.state.voteOnPrice(
        product: widget.product,
        entry: widget.entry,
        kind: kind,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(kind == VoteKind.up
              ? 'Oyunu kaydettik · +1 PT'
              : 'Yanlış olarak işaretlendi · +1 PT'),
        ),
      );
    } on StateError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Oy gönderilemedi, tekrar dene.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final state = widget.state;
    final initial = entry.reportedBy.isEmpty
        ? 'T'
        : entry.reportedBy[0].toUpperCase();
    final uid = state.user?.uid ?? '';
    final myVote = entry.voteOf(uid);
    final disabledReason = state.canVoteOn(widget.product, entry);

    return Container(
      padding: const EdgeInsets.all(14), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
      decoration: frSurface(radius: FRRad.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(entry.reportedBy,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: frText(13, FontWeight.w800)),
                        ),
                        const SizedBox(width: 6),
                        FRVerifyBadge.status(
                          status: statusToString(entry.status),
                          trustPercent: entry.trustPercent,
                          dense: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
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
              const SizedBox(width: 6),
              IconButton(
                onPressed: _busy ? null : _report,
                icon: Icon(Icons.flag_outlined, size: 18, color: FR.ink3),
                tooltip: 'Raporla',
              ),
            ],
          ),
          if (entry.note.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              entry.note,
              style: frText(12, FontWeight.w600, color: FR.ink2, height: 1.4),
            ),
          ],
          const SizedBox(height: 10),
          FRVoteBar(up: entry.upvotes, down: entry.downvotes),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  _subtitle(entry, disabledReason, myVote),
                  style: frText(10.5, FontWeight.w700, color: FR.ink3, height: 1.4),
                ),
              ),
              const SizedBox(width: 10),
              if (_busy)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: FR.gold),
                )
              else
                FRVoteButtons(
                  currentVote: myVote,
                  disabledReason: disabledReason,
                  onUp: () => _cast(VoteKind.up),
                  onDown: () => _cast(VoteKind.down),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _subtitle(PriceEntry e, String? disabledReason, String? myVote) {
    if (disabledReason != null) return disabledReason;
    if (myVote != null) {
      return 'Oyun: ${myVote == 'up' ? 'doğru' : 'yanlış'} · ${e.verifiedByCount} onay · ${e.rejectedByCount} itiraz';
    }
    return '${e.verifiedByCount} onay · ${e.rejectedByCount} itiraz';
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
    final safe = MediaQuery.of(context).viewPadding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + safe), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
      decoration: BoxDecoration(
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
                gradient: LinearGradient(colors: [FR.goldHi, FR.goldDeep]),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: FR.gold.withOpacity(.3), blurRadius: 18)],
              ),
              child: Icon(Icons.add_rounded, color: FR.onGold, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}
