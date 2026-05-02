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
    if (oldP.id != next.id || oldHistorySignature != nextHistorySignature) {
      _recomputeDerived();
    }
  }

  void _recomputeDerived() {
    final product = widget.product;
    _sorted = [...product.priceHistory]
      ..sort((a, b) => b.date.compareTo(a.date));
    _best = product.bestValueEntry;
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
            _DetailTopBar(
              isFav: isFav,
              onBack: () => Navigator.pop(context),
              onFav: () => state.toggleFavorite(product.id),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
                children: [
                  _DetailTitleBlock(product: product),
                  const SizedBox(height: 16),
                  _DetailHero(product: product),
                  const SizedBox(height: 20),
                  _DetailHeadlinePrice(product: product, state: state),
                  const SizedBox(height: 24),
                  _RegionalPriceSections(
                      product: product, state: state, legacyBest: _best),
                  if (product.validEntries.length >= 2) ...[
                    const SizedBox(height: 24),
                    const FRSectionHead(
                        eyebrow: 'FİYAT GEÇMİŞİ',
                        title: 'Son 30 gün'),
                    const SizedBox(height: 12),
                    _PriceHistoryCard(product: product),
                  ],
                  const SizedBox(height: 24),
                  const FRSectionHead(
                      eyebrow: 'TOPLULUK DOĞRULAMASI',
                      title: 'Son katkılar'),
                  const SizedBox(height: 6),
                  Text(
                    'Oy ver, topluluğun güveni şekillendir. Kendi girdiğine ya da aynı girdiye tekrar oy veremezsin.',
                    style: frText(11.5, FontWeight.w600,
                        color: FR.ink3, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  if (_sorted.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: frSurface(radius: FRRad.l),
                      child: Text(
                        'Henüz katkı yok — ilk fiyatı sen ekle.',
                        style: frText(12.5, FontWeight.w600, color: FR.ink3),
                      ),
                    )
                  else
                    ..._sorted.take(6).map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
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
              alertTarget: alert?.targetPrice,
              onAlert: () =>
                  _openAlert(context, state, product, alert?.targetPrice),
              onAdd: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                    builder: (_) => const MainScreen(initialIndex: 2)),
              ),
              onCart: () {
                state.addToCart(product);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${product.name} sepete eklendi.')),
                );
              },
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
      text: current?.toStringAsFixed(2) ??
          (product.lowestPrice ?? 0).toStringAsFixed(2),
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
                prefixStyle:
                    TextStyle(color: FR.gold, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal',
                style: frText(13, FontWeight.w800, color: FR.ink3)),
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

// ─── Top bar ─────────────────────────────────────────────────────────────────

class _DetailTopBar extends StatelessWidget {
  const _DetailTopBar({
    required this.isFav,
    required this.onBack,
    required this.onFav,
  });
  final bool isFav;
  final VoidCallback onBack;
  final VoidCallback onFav;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          FRIconChip(icon: Icons.arrow_back_rounded, onTap: onBack),
          const Spacer(),
          FRIconChip(
            icon: isFav
                ? Icons.favorite_rounded
                : Icons.favorite_outline_rounded,
            active: isFav,
            onTap: onFav,
          ),
        ],
      ),
    );
  }
}

// ─── Title block (page entry rhythm: eyebrow + page title) ──────────────────

class _DetailTitleBlock extends StatelessWidget {
  const _DetailTitleBlock({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${product.category.toUpperCase()} · ${product.brand.toUpperCase()}',
          style: frOverline(color: FR.ink3),
        ),
        const SizedBox(height: 6),
        Text(product.name,
            style: frDisplay(28, FontWeight.w700, height: 1.1)),
        const SizedBox(height: 6),
        Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: FR.gold.withOpacity(.14),
                borderRadius: FRRad.all(999),
                border: Border.all(color: FR.gold.withOpacity(.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_rounded, color: FR.gold, size: 12),
                  const SizedBox(width: 5),
                  Text('Katalog onaylı',
                      style: frText(10.5, FontWeight.w800, color: FR.gold)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(product.unit,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: frText(12.5, FontWeight.w700, color: FR.ink3)),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Hero image (clean Soft Surface, no competing gold border) ───────────────

class _DetailHero extends StatelessWidget {
  const _DetailHero({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final hasImage =
        product.imageUrl != null && product.imageUrl!.isNotEmpty;
    return Container(
      height: 220,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [FR.surfaceHi, FR.surfaceLo],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: FRRad.all(FRRad.xxl),
        border: Border.all(color: FR.hairline),
      ),
      child: hasImage
          ? Image.network(
              product.imageUrl!,
              fit: BoxFit.cover,
              cacheWidth: 1200,
              filterQuality: FilterQuality.medium,
              errorBuilder: (_, __, ___) => Center(
                child: Text(product.emoji,
                    style: const TextStyle(fontSize: 108)),
              ),
            )
          : Center(
              child: Text(product.emoji,
                  style: const TextStyle(fontSize: 108)),
            ),
    );
  }
}

// ─── Headline price (the single dominant emphasis block) ─────────────────────

class _DetailHeadlinePrice extends StatelessWidget {
  const _DetailHeadlinePrice({required this.product, required this.state});
  final Product product;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final lowest = product.lowestPrice;
    final pct = product.priceChangePct;
    final store = product.cheapestStore;
    final verified = product.verifiedCount;
    final trust = product.aggregateTrustPercent;
    final dataPoints = product.validEntries.length;

    if (lowest == null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: frSurface(radius: FRRad.xl),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: FR.bgElev,
                borderRadius: FRRad.all(14),
                border: Border.all(color: FR.hairline),
              ),
              child: Icon(Icons.timer_outlined, color: FR.ink3, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Fiyat bekleniyor',
                      style: frText(14, FontWeight.w800, color: FR.ink)),
                  const SizedBox(height: 2),
                  Text('Topluluktan ilk fiyatı sen ekleyebilirsin.',
                      style:
                          frText(11.5, FontWeight.w600, color: FR.ink3)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [FR.surfaceHi, FR.surfaceLo],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: FRRad.all(FRRad.xxl),
        border: Border.all(color: FR.goldDeep.withOpacity(.4)),
        boxShadow: frGoldGlow(opacity: .14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TOPLULUKTAN EN İYİ FİYAT', style: frOverline()),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FRPriceText(lowest, size: 38, color: FR.gold),
              const SizedBox(width: 10),
              if (pct != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: FRTrendPill(pct: pct),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (store != null) FRStoreBadge(store, filled: true),
              if (verified > 0)
                FRVerifyBadge(
                  label: '$verified doğrulandı',
                  tone: FRVerifyTone.good,
                  trustPercent: trust,
                  dense: true,
                )
              else
                FRVerifyBadge(
                  label: trust >= 50 ? 'İncelemede' : 'Yeni',
                  tone: FRVerifyTone.neutral,
                  trustPercent: trust,
                  dense: true,
                ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: FR.bgElev,
                  borderRadius: FRRad.all(999),
                  border: Border.all(color: FR.hairline),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bar_chart_rounded, size: 12, color: FR.ink2),
                    const SizedBox(width: 4),
                    Text('$dataPoints veri noktası',
                        style: frText(10.5, FontWeight.w800, color: FR.ink2)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Regional price sections ────────────────────────────────────────────────

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
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FRSectionHead(
              eyebrow: 'BÖLGENDEKİ FİYATLAR',
              title: 'Önce bölgeni belirt'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: frSurface(radius: FRRad.l),
            child: Row(
              children: [
                Icon(Icons.location_on_outlined, color: FR.ink3, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Bölgesel fiyatları görmek için anasayfadan il ve ilçe seç.',
                    style: frText(12, FontWeight.w600,
                        color: FR.ink3, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
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
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FRSectionHead(
                eyebrow: 'BÖLGENDEKİ FİYATLAR',
                title: '$district / $city',
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: frSurface(radius: FRRad.l),
                child: Text(
                  legacyBest == null
                      ? '$district / $city için henüz bildirilen fiyat yok.'
                      : '$district / $city için grup yok, son topluluk fiyatı: ₺${legacyBest!.price.toStringAsFixed(2)}',
                  style: frText(12, FontWeight.w600,
                      color: FR.ink3, height: 1.4),
                ),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FRSectionHead(
              eyebrow: 'BÖLGENDEKİ FİYATLAR',
              title: '$district / $city',
              action: Text(
                '${groups.length} market',
                style: frText(11, FontWeight.w800, color: FR.ink3),
              ),
            ),
            const SizedBox(height: 12),
            ...groups.take(4).map((g) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _RegionalGroupCard(group: g, product: product),
                )),
          ],
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
      padding: const EdgeInsets.all(14),
      decoration: frSurface(radius: FRRad.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.chainName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: frText(13.5, FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(
                      '${group.districtName} / ${group.cityName}',
                      style: frText(11, FontWeight.w700, color: FR.ink3),
                    ),
                  ],
                ),
              ),
              FRPriceText(
                group.preferredPrice ?? group.latestPrice,
                size: 18,
                color: FR.gold,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _MetaPill(
                icon: Icons.schedule_rounded,
                label: _relative(group.lastReportedAt),
              ),
              _MetaPill(
                icon: Icons.shield_outlined,
                label: confidenceLabelTr(group.confidence),
              ),
              _MetaPill(
                icon: Icons.people_outline_rounded,
                label: '${group.reportCount} bildirim',
              ),
              if (group.verifiedCount > 0)
                _MetaPill(
                  icon: Icons.verified_rounded,
                  label: '${group.verifiedCount} doğrulama',
                  tone: FR.good,
                ),
              if (group.hasPhotoEvidence)
                _MetaPill(
                  icon: Icons.photo_camera_rounded,
                  label: '${group.photoReportCount} fotoğraflı',
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TinyAction(
                  icon: Icons.thumb_up_alt_outlined,
                  label: 'Ben de gördüm',
                  onTap: () async {
                    final state = AppStateScope.of(context);
                    try {
                      await state.verifyRegionalPriceSeen(
                        productId: product.id,
                        chainId: group.chainId,
                        price: group.preferredPrice ??
                            group.latestPrice ??
                            0,
                        city: group.cityName,
                        district: group.districtName,
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Doğrulaman kaydedildi.')),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$e')),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TinyAction(
                  icon: Icons.edit_outlined,
                  label: 'Farklı fiyat',
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
                      MaterialPageRoute(
                          builder: (_) =>
                              const MainScreen(initialIndex: 2)),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label, this.tone});
  final IconData icon;
  final String label;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final c = tone ?? FR.ink2;
    final bg = tone == null ? FR.bgElev : tone!.withOpacity(.12);
    final border = tone == null ? FR.hairline : tone!.withOpacity(.35);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: FRRad.all(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: c),
          const SizedBox(width: 4),
          Text(label, style: frText(10.5, FontWeight.w800, color: c)),
        ],
      ),
    );
  }
}

class _TinyAction extends StatelessWidget {
  const _TinyAction({
    required this.label,
    required this.onTap,
    this.icon,
  });

  final String label;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: FRRad.all(12),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: FR.bgElev,
          borderRadius: FRRad.all(12),
          border: Border.all(color: FR.hairline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: FR.ink2),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: frText(11, FontWeight.w800, color: FR.ink2),
              ),
            ),
          ],
        ),
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
      padding: const EdgeInsets.all(18),
      decoration: frSurface(radius: FRRad.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${values.length} veri noktası',
                  style: frText(11, FontWeight.w800, color: FR.ink3)),
              const Spacer(),
              Text('FARK · ₺${(high - low).toStringAsFixed(2)}',
                  style: frText(11, FontWeight.w800,
                      color: FR.goldDeep, letter: .8)),
            ],
          ),
          const SizedBox(height: 12),
          FRSparkline(values: values, height: 64),
          const SizedBox(height: 12),
          Row(
            children: [
              _hl('EN DÜŞÜK', '₺${low.toStringAsFixed(2)}', FR.good),
              const SizedBox(width: 10),
              _hl('EN YÜKSEK', '₺${high.toStringAsFixed(2)}', FR.bad),
              const SizedBox(width: 10),
              _hl('ORTALAMA',
                  '₺${(values.reduce((a, b) => a + b) / values.length).toStringAsFixed(2)}',
                  FR.gold),
            ],
          ),
        ],
      ),
    );
  }

  Widget _hl(String l, String v, Color c) => Expanded(
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
            child: Text('İptal',
                style: frText(12.5, FontWeight.w800, color: FR.ink3)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: Text('Raporla',
                style: frText(12.5, FontWeight.w800, color: FR.gold)),
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
    final initial =
        entry.reportedBy.isEmpty ? 'T' : entry.reportedBy[0].toUpperCase();
    final uid = state.user?.uid ?? '';
    final myVote = entry.voteOf(uid);
    final disabledReason = state.canVoteOn(widget.product, entry);

    return Container(
      padding: const EdgeInsets.all(14),
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
                  style: frText(10.5, FontWeight.w700,
                      color: FR.ink3, height: 1.4),
                ),
              ),
              const SizedBox(width: 10),
              if (_busy)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: FR.gold),
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

// ─── Sticky bottom actions ───────────────────────────────────────────────────

class _Actions extends StatelessWidget {
  const _Actions({
    required this.isAlertActive,
    required this.alertTarget,
    required this.onAlert,
    required this.onAdd,
    required this.onCart,
  });
  final bool isAlertActive;
  final double? alertTarget;
  final VoidCallback onAlert;
  final VoidCallback onAdd;
  final VoidCallback onCart;

  @override
  Widget build(BuildContext context) {
    final safe = MediaQuery.of(context).viewPadding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + safe),
      decoration: BoxDecoration(
        color: FR.bgElev,
        border: Border(top: BorderSide(color: FR.hairline)),
      ),
      child: Row(
        children: [
          _SquareIconAction(
            icon: isAlertActive
                ? Icons.notifications_active_rounded
                : Icons.notifications_none_rounded,
            label: isAlertActive
                ? '₺${alertTarget!.toStringAsFixed(0)}'
                : null,
            active: isAlertActive,
            onTap: onAlert,
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
          _SquareIconAction(
            icon: Icons.add_rounded,
            active: false,
            filled: true,
            onTap: onAdd,
          ),
        ],
      ),
    );
  }
}

class _SquareIconAction extends StatelessWidget {
  const _SquareIconAction({
    required this.icon,
    required this.onTap,
    this.label,
    this.active = false,
    this.filled = false,
  });
  final IconData icon;
  final String? label;
  final bool active;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = filled
        ? FR.gold
        : active
            ? FR.gold.withOpacity(.14)
            : FR.surface;
    final border = filled
        ? FR.gold
        : active
            ? FR.gold.withOpacity(.55)
            : FR.hairline;
    final fg = filled ? FR.onGold : (active ? FR.gold : FR.ink2);
    return InkWell(
      onTap: onTap,
      borderRadius: FRRad.all(16),
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: FRRad.all(16),
          border: Border.all(color: border),
          boxShadow: filled ? frGoldGlow(opacity: .22) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: fg),
            if (label != null) ...[
              const SizedBox(width: 6),
              Text(label!,
                  style: frText(12, FontWeight.w800, color: fg)),
            ],
          ],
        ),
      ),
    );
  }
}
