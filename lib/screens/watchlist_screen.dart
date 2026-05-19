import 'package:flutter/material.dart';

import '../models/product.dart';
import '../state/app_state.dart';
import '../ui/components.dart';
import '../ui/tokens.dart';
import 'product_detail_screen.dart';
import 'widgets/product_visual.dart';

/// Birleşik takip paneli: kullanıcı favorileri + fiyat alarmları tek
/// ekranda görür. Eskiden Favoriler ve Alarmlarım profil listesinde iki
/// ayrı satırdı — kafa karıştırıcı ("favori mi, alarm mı?"). Artık tek
/// "Takiplerim" girişi var, içeride iki tab.
///
/// Her iki sekme de `_ProductWatchRow`'ı paylaşıyor, ama trailing chip
/// farklı: favori → kalp, alarm → hedef fiyat.
class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  late int _tab;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab.clamp(0, 1);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final favs = state.products.where((p) => state.isFavorite(p.id)).toList();
    final alerts = state.productAlerts.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      backgroundColor: FR.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(children: [
                FRIconChip(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => Navigator.pop(context),
                ),
              ]),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: FRPageHeader(
                overline: 'RADAR TAKVİMİN',
                title: 'Takiplerim',
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _Segmented(
                labels: const ['Favoriler', 'Alarmlar'],
                counts: [favs.length, alerts.length],
                index: _tab,
                onChange: (i) => setState(() => _tab = i),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: _tab == 0
                  ? _FavoritesPanel(favs: favs, state: state)
                  : _AlertsPanel(alerts: alerts, state: state),
            ),
          ],
        ),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
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

class _FavoritesPanel extends StatelessWidget {
  const _FavoritesPanel({required this.favs, required this.state});
  final List<Product> favs;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    if (favs.isEmpty) {
      return _empty(
        icon: Icons.favorite_outline_rounded,
        title: 'Henüz favori yok',
        body: 'Bir ürünü keşfet ve kalp simgesine dokun. '
            'Favori ürünlerin bölgendeki fiyatları burada listelenir.',
      );
    }
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(20, 4, 20, frBottomScrollPadding(context)),
      itemCount: favs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final p = favs[i];
        return _Row(
          product: p,
          subtitle: '${p.brand} · ${p.unit}',
          trailing: InkWell(
            onTap: () => state.toggleFavorite(p.id),
            borderRadius: FRRad.all(999),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(Icons.favorite_rounded, color: FR.bad, size: 19),
            ),
          ),
        );
      },
    );
  }
}

class _AlertsPanel extends StatelessWidget {
  const _AlertsPanel({required this.alerts, required this.state});
  final List<ProductAlert> alerts;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) {
      return _empty(
        icon: Icons.notifications_off_outlined,
        title: 'Alarm kurulmamış',
        body: 'Ürün detayından hedef fiyat belirle. Ürün hedefin altına '
            'düştüğünde radarın sana haber versin.',
      );
    }
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(20, 4, 20, frBottomScrollPadding(context)),
      itemCount: alerts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final a = alerts[i];
        final p = state.findById(a.productId);
        if (p == null) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: frSurface(radius: FRRad.l),
            child: Row(children: [
              Icon(Icons.help_outline_rounded, color: FR.ink3, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Silinmiş ürün için alarm · hedef ₺${a.targetPrice.toStringAsFixed(2)}',
                  style: frText(12, FontWeight.w700, color: FR.ink3),
                ),
              ),
            ]),
          );
        }
        return _Row(
          product: p,
          subtitle:
              'Hedef ₺${a.targetPrice.toStringAsFixed(2)} · şu an ${p.lowestPrice == null ? "—" : "₺${p.lowestPrice!.toStringAsFixed(2)}"}',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: FR.gold.withOpacity(.14),
              borderRadius: FRRad.all(999),
              border: Border.all(color: FR.gold.withOpacity(.4)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.notifications_active_rounded,
                  size: 11, color: FR.gold),
              const SizedBox(width: 4),
              Text('AKTİF',
                  style:
                      frText(9.5, FontWeight.w800, color: FR.gold, letter: 1)),
            ]),
          ),
        );
      },
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.product,
    required this.subtitle,
    required this.trailing,
  });
  final Product product;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product)),
      ),
      borderRadius: FRRad.all(FRRad.l),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: frSurface(radius: FRRad.l),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: FR.surfaceHi,
              borderRadius: FRRad.all(12),
              border: Border.all(color: FR.hairline),
            ),
            child: ClipRRect(
              borderRadius: FRRad.all(12),
              child: ProductVisual(
                product: product,
                iconSize: 22,
                padIllustration: false,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: frText(13.5, FontWeight.w800)),
                const SizedBox(height: 2),
                Text(subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: frText(11.5, FontWeight.w700, color: FR.ink3)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ]),
      ),
    );
  }
}

Widget _empty({
  required IconData icon,
  required String title,
  required String body,
}) {
  return Padding(
    padding: const EdgeInsets.all(24),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 38, color: FR.gold),
          const SizedBox(height: 14),
          Text(title, style: frDisplay(20, FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: frText(12.5, FontWeight.w600, color: FR.ink3, height: 1.5),
          ),
        ],
      ),
    ),
  );
}
