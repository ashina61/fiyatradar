import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../state/app_state.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import '../main_screen.dart';
import '../notifications_screen.dart';
import '../product_detail_screen.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final products = state.products;

    // "Düşenler" = price dropped (pct < 0), sorted by biggest drop.
    final droppers = [...products]
      ..sort((a, b) {
        final ap = a.priceChangePct ?? 0;
        final bp = b.priceChangePct ?? 0;
        return ap.compareTo(bp);
      });
    final topDrops = droppers.where((p) => (p.priceChangePct ?? 0) < 0).take(3).toList();
    // Live feed = most recently contributed prices.
    final feed = [...products]
      ..sort((a, b) {
        final ad = a.priceHistory.isEmpty
            ? DateTime(0)
            : a.priceHistory.last.date;
        final bd = b.priceHistory.isEmpty
            ? DateTime(0)
            : b.priceHistory.last.date;
        return bd.compareTo(ad);
      });
    final feedItems = feed.take(4).toList();

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: EdgeInsets.fromLTRB(20, 10, 20, frBottomScrollPadding(context)),
        children: [
          _Greet(state: state),
          const SizedBox(height: 18),
          _LocationStrip(),
          const SizedBox(height: 18),
          _RadarHero(
            state: state,
            onInspect: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 1)),
            ),
          ),
          const SizedBox(height: 26),
          FRSectionHead(
            eyebrow: 'FİLTRE',
            title: 'Kategoriler',
          ),
          const SizedBox(height: 12),
          _CategoryStrip(categories: state.categories),
          const SizedBox(height: 26),
          FRSectionHead(
            eyebrow: 'BU HAFTA',
            title: 'Fiyatı düşenler',
            action: TextButton(
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 1)),
              ),
              child: Text('Tümü', style: frText(12, FontWeight.w800, color: FR.goldDeep)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 302,
            child: topDrops.isEmpty
                ? _EmptyBlock(height: 302, text: 'Bu hafta fiyat düşüşü henüz yok.')
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: topDrops.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) {
                      final p = topDrops[i];
                      return _TrendCard(
                        product: p,
                        isFavorite: state.isFavorite(p.id),
                        onFavorite: () => state.toggleFavorite(p.id),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p)),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 26),
          FRSectionHead(
            eyebrow: 'TOPLULUK AKIŞI',
            title: 'Canlı fiyat akışı',
            action: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FRLiveDot(),
                const SizedBox(width: 6),
                Text('canlı', style: frText(11, FontWeight.w800, color: FR.good)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (feedItems.isEmpty)
            _EmptyBlock(height: 120, text: 'Topluluktan fiyat gelince burada görünür.')
          else
            ...feedItems.map(
              (p) => _FeedRow(
                product: p,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Greet header ────────────────────────────────────────────────────────────

class _Greet extends StatelessWidget {
  const _Greet({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greet = hour < 6
        ? 'İyi geceler'
        : hour < 12
            ? 'Günaydın'
            : hour < 18
                ? 'İyi günler'
                : 'İyi akşamlar';
    return Row(
      children: [
        Expanded(
          child: InkWell(
            borderRadius: FRRad.all(18),
            onTap: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 4)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [FR.goldHi, FR.goldDeep]),
                    borderRadius: FRRad.all(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    (state.displayName.isEmpty ? 'FR' : state.displayName[0].toUpperCase()),
                    style: frDisplay(18, FontWeight.w800, color: FR.bg),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(greet.toUpperCase(),
                          style: frOverline(color: FR.ink3, size: 9.5)),
                      const SizedBox(height: 2),
                      Text(
                        state.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: frDisplay(19, FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        FRIconChip(
          icon: Icons.notifications_none_rounded,
          badge: state.unreadNotificationCount,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          ),
        ),
      ],
    );
  }
}

class _LocationStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: frSurface(radius: FRRad.l),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: FR.gold.withOpacity(.12),
              borderRadius: FRRad.all(12),
              border: Border.all(color: FR.gold.withOpacity(.3)),
            ),
            child: Icon(Icons.my_location_rounded, color: FR.gold, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('BÖLGE (VARSAYILAN)', style: frOverline(color: FR.ink3, size: 9.5)),
                const SizedBox(height: 2),
                Text('Tüm Türkiye', style: frText(14, FontWeight.w800)),
                Text('Konum iznini açarsan radar daraltılır',
                    style: frText(11.5, FontWeight.w600, color: FR.ink3)),
              ],
            ),
          ),
          Icon(Icons.tune_rounded, color: FR.ink3, size: 20),
        ],
      ),
    );
  }
}

class _RadarHero extends StatelessWidget {
  const _RadarHero({required this.state, required this.onInspect});
  final AppState state;
  final VoidCallback onInspect;

  @override
  Widget build(BuildContext context) {
    final drop = state.weeklyDropPct;
    final fresh = state.freshContributionCountLast24h;
    final trust = state.catalogTrustPercent;
    final verified = state.aggregateVerifiedCount;
    final hasSignal = fresh > 0 || verified > 0 || drop < 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [FR.surfaceHi, FR.surfaceLo],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: FRRad.all(24),
        border: Border.all(color: FR.goldDeep.withOpacity(.35)),
        boxShadow: [
          BoxShadow(color: FR.gold.withOpacity(.12), blurRadius: 40, offset: const Offset(0, 8)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Icon(Icons.radar_rounded, size: 160, color: FR.gold.withOpacity(.08)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: FR.good.withOpacity(.16),
                      borderRadius: FRRad.all(999),
                      border: Border.all(color: FR.good.withOpacity(.35)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FRLiveDot(),
                        const SizedBox(width: 6),
                        Text('RADAR AKTİF',
                            style: frText(9.5, FontWeight.w800, color: FR.good, letter: 1.3)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (state.unreadNotificationCount > 0)
                    Text('${state.unreadNotificationCount} yeni sinyal',
                        style: frText(11, FontWeight.w800, color: FR.gold)),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                hasSignal
                    ? (drop < -0.01
                        ? 'Bu hafta %${drop.abs().toStringAsFixed(drop.abs() < 10 ? 1 : 0)}\nfiyat düşüşü saptandı'
                        : 'Radar son 24 saatte\n$fresh yeni veri işledi')
                    : 'Radar beklemede.\nİlk fiyatı sen ekle.',
                style: frDisplay(24, FontWeight.w700, height: 1.15),
              ),
              const SizedBox(height: 8),
              Text(
                hasSignal
                    ? '${state.products.length} ürün · $verified topluluk doğrulaması · %$trust güven'
                    : 'Ürün ekle, topluluk doğrulasın.',
                style: frText(12, FontWeight.w600, color: FR.ink3),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _heroStat('$fresh', 'YENİ VERİ · 24s'),
                  const SizedBox(width: 10),
                  _heroStat('$verified', 'DOĞRULANDI'),
                  const SizedBox(width: 10),
                  _heroStat(trust == 0 ? '—' : '%$trust', 'GÜVEN'),
                ],
              ),
              const SizedBox(height: 16),
              FRCta(label: 'Radarı incele', icon: Icons.arrow_forward_rounded, onTap: onInspect),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: FR.bg.withOpacity(.5),
          borderRadius: FRRad.all(12),
          border: Border.all(color: FR.hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: frPrice(18, color: FR.gold)),
            Text(label, style: frText(9, FontWeight.w800, color: FR.ink3, letter: 1.2)),
          ],
        ),
      ),
    );
  }
}

class _CategoryStrip extends StatelessWidget {
  const _CategoryStrip({required this.categories});
  final List<String> categories;

  static const _icons = <String, IconData>{
    'Tümü': Icons.grid_view_rounded,
    'Kahvaltılık': Icons.egg_outlined,
    'Meyve & Sebze': Icons.local_florist_outlined,
    'İçecek': Icons.local_cafe_outlined,
    'Atıştırmalık': Icons.cookie_outlined,
    'Süt Ürünleri': Icons.icecream_outlined,
    'Temizlik': Icons.cleaning_services_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (_, i) {
          final c = categories[i];
          final icon = _icons[c] ?? Icons.local_offer_outlined;
          return FRFilterChip(
            c,
            active: i == 0,
            leading: Icon(icon, size: 14, color: i == 0 ? FR.bg : FR.ink2),
          );
        },
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({
    required this.product,
    required this.isFavorite,
    required this.onFavorite,
    required this.onTap,
  });
  final Product product;
  final bool isFavorite;
  final VoidCallback onFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pct = product.priceChangePct;
    final trust = product.aggregateTrustPercent;
    return InkWell(
      onTap: onTap,
      borderRadius: FRRad.all(FRRad.xl),
      child: Container(
        width: 218,
        decoration: frSurface(radius: FRRad.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 136,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [FR.surfaceHi, FR.surfaceLo],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(FRRad.xl)),
                  ),
                  child: Center(child: Text(product.emoji, style: const TextStyle(fontSize: 66))),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: FRStoreBadge(product.cheapestStore ?? '—'),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: InkWell(
                    onTap: onFavorite,
                    borderRadius: FRRad.all(999),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: FR.bg.withOpacity(.65),
                        shape: BoxShape.circle,
                        border: Border.all(color: FR.hairline),
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                        size: 15,
                        color: isFavorite ? FR.bad : FR.ink2,
                      ),
                    ),
                  ),
                ),
                if (pct != null)
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: FRTrendPill(pct: pct, dense: true),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.category.toUpperCase(),
                      style: frOverline(color: FR.ink3, size: 9.5)),
                  const SizedBox(height: 4),
                  Text(product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: frText(13.5, FontWeight.w800)),
                  Text(product.brand,
                      style: frText(11.5, FontWeight.w600, color: FR.ink3)),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      FRPriceText(product.lowestPrice, size: 22, color: FR.gold),
                      const Spacer(),
                      Text(product.unit,
                          style: frText(11, FontWeight.w700, color: FR.ink3)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (product.verifiedCount > 0)
                    FRVerifyBadge(
                      label: '${product.verifiedCount} doğrulandı',
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedRow extends StatelessWidget {
  const _FeedRow({required this.product, required this.onTap});
  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final latest = product.priceHistory.isEmpty
        ? null
        : product.priceHistory.last;
    final pct = product.priceChangePct;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: FRCard(
        radius: FRRad.l,
        onTap: onTap,
        padding: const EdgeInsets.all(12),
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
              child: Text(product.emoji, style: const TextStyle(fontSize: 22)),
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
                  Row(
                    children: [
                      FRStoreBadge(latest?.store ?? '—'),
                      const SizedBox(width: 6),
                      if (latest != null)
                        FRFreshChip(date: latest.date)
                      else
                        Text('fiyat yok',
                            style: frText(11, FontWeight.w700, color: FR.ink3)),
                      if (latest != null) ...[
                        const SizedBox(width: 6),
                        FRVerifyBadge.status(
                          status: statusToString(latest.status),
                          trustPercent: latest.trustPercent,
                          dense: true,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FRPriceText(product.lowestPrice, size: 16, color: FR.ink),
                if (pct != null) ...[
                  const SizedBox(height: 4),
                  FRTrendPill(pct: pct, dense: true),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  const _EmptyBlock({required this.height, required this.text});
  final double height;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      alignment: Alignment.center,
      decoration: frSurface(radius: FRRad.l),
      child: Text(text, style: frText(12.5, FontWeight.w600, color: FR.ink3)),
    );
  }
}
