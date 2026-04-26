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
    final topDrops = state.homeTopDrops;
    final feedItems = state.homeFeed;

    var step = 0;
    Duration nextDelay() => Duration(milliseconds: 60 * step++);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: EdgeInsets.fromLTRB(20, 10, 20, frBottomScrollPadding(context)),
        children: [
          FRFadeSlideIn(delay: nextDelay(), child: _Greet(state: state)),
          const SizedBox(height: 18),
          FRFadeSlideIn(delay: nextDelay(), child: _LocationStrip(state: state)),
          const SizedBox(height: 18),
          if (state.banners.isNotEmpty) ...[
            FRFadeSlideIn(
              delay: nextDelay(),
              child: _BannerCarousel(banners: state.banners),
            ),
            const SizedBox(height: 18),
          ],
          FRFadeSlideIn(
            delay: nextDelay(),
            child: _RadarHero(
              state: state,
              onInspect: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 1)),
              ),
            ),
          ),
          const SizedBox(height: 26),
          FRFadeSlideIn(
            delay: nextDelay(),
            child: const FRSectionHead(
              eyebrow: 'FİLTRE',
              title: 'Kategoriler',
            ),
          ),
          const SizedBox(height: 12),
          FRFadeSlideIn(
            delay: nextDelay(),
            child: _CategoryStrip(categories: state.categories),
          ),
          const SizedBox(height: 26),
          FRFadeSlideIn(
            delay: nextDelay(),
            child: FRSectionHead(
              eyebrow: 'BU HAFTA',
              title: 'Fiyatı düşenler',
              action: TextButton(
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 1)),
                ),
                child: Text('Tümü', style: frText(12, FontWeight.w800, color: FR.goldDeep)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FRFadeSlideIn(
            delay: nextDelay(),
            child: SizedBox(
              height: 302,
              child: topDrops.isEmpty
                  ? const _EmptyBlock(height: 302, text: 'Bu hafta fiyat düşüşü henüz yok.')
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
          ),
          const SizedBox(height: 26),
          FRFadeSlideIn(
            delay: nextDelay(),
            child: FRSectionHead(
              eyebrow: 'TOPLULUK AKIŞI',
              title: 'Canlı fiyat akışı',
              action: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const FRLiveDot(),
                  const SizedBox(width: 6),
                  Text('canlı', style: frText(11, FontWeight.w800, color: FR.good)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (feedItems.isEmpty)
            FRFadeSlideIn(
              delay: nextDelay(),
              child: const _EmptyBlock(
                height: 120,
                text: 'Topluluktan fiyat gelince burada görünür.',
              ),
            )
          else
            ...feedItems.map(
              (p) => FRFadeSlideIn(
                delay: nextDelay(),
                child: _FeedRow(
                  product: p,
                  latest: state.latestEntryForProduct(p.id),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Greet header ────────────────────────────────────────────────────────────

class _BannerCarousel extends StatefulWidget {
  const _BannerCarousel({required this.banners});
  final List<AppBanner> banners;

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  final PageController _ctrl = PageController(viewportFraction: .92);
  int _page = 0;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banners = widget.banners;
    if (banners.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        SizedBox(
          height: 132,
          child: PageView.builder(
            controller: _ctrl,
            itemCount: banners.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) {
              final b = banners[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [FR.surfaceHi, FR.surfaceLo],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: FRRad.all(20),
                    border: Border.all(color: FR.goldDeep.withOpacity(.3)),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              b.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: frDisplay(15, FontWeight.w700, height: 1.2),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              b.subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: frText(11.5, FontWeight.w600,
                                  color: FR.ink3, height: 1.4),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: FR.gold.withOpacity(.16),
                                borderRadius: FRRad.all(999),
                                border:
                                    Border.all(color: FR.gold.withOpacity(.4)),
                              ),
                              child: Text(
                                b.actionLabel,
                                style: frText(10.5, FontWeight.w800,
                                    color: FR.gold, letter: .4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 64,
                        height: 64,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: FR.gold.withOpacity(.12),
                          shape: BoxShape.circle,
                          border: Border.all(color: FR.gold.withOpacity(.3)),
                        ),
                        child: Icon(Icons.campaign_rounded,
                            color: FR.gold, size: 28),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (banners.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(banners.length, (i) {
              final active = i == _page;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active ? FR.gold : FR.hairline,
                  borderRadius: FRRad.all(999),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

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
                    style: frDisplay(18, FontWeight.w800, color: FR.onGold),
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

/// 81 il of Türkiye, in alphabetical order. Used by the home location picker.
const List<String> kTurkishCities = [
  'Adana', 'Adıyaman', 'Afyonkarahisar', 'Ağrı', 'Aksaray', 'Amasya', 'Ankara',
  'Antalya', 'Ardahan', 'Artvin', 'Aydın', 'Balıkesir', 'Bartın', 'Batman',
  'Bayburt', 'Bilecik', 'Bingöl', 'Bitlis', 'Bolu', 'Burdur', 'Bursa',
  'Çanakkale', 'Çankırı', 'Çorum', 'Denizli', 'Diyarbakır', 'Düzce', 'Edirne',
  'Elazığ', 'Erzincan', 'Erzurum', 'Eskişehir', 'Gaziantep', 'Giresun',
  'Gümüşhane', 'Hakkari', 'Hatay', 'Iğdır', 'Isparta', 'İstanbul', 'İzmir',
  'Kahramanmaraş', 'Karabük', 'Karaman', 'Kars', 'Kastamonu', 'Kayseri',
  'Kilis', 'Kırıkkale', 'Kırklareli', 'Kırşehir', 'Kocaeli', 'Konya', 'Kütahya',
  'Malatya', 'Manisa', 'Mardin', 'Mersin', 'Muğla', 'Muş', 'Nevşehir', 'Niğde',
  'Ordu', 'Osmaniye', 'Rize', 'Sakarya', 'Samsun', 'Şanlıurfa', 'Siirt', 'Sinop',
  'Şırnak', 'Sivas', 'Tekirdağ', 'Tokat', 'Trabzon', 'Tunceli', 'Uşak', 'Van',
  'Yalova', 'Yozgat', 'Zonguldak',
];

class _LocationStrip extends StatefulWidget {
  const _LocationStrip({required this.state});
  final AppState state;

  @override
  State<_LocationStrip> createState() => _LocationStripState();
}

class _LocationStripState extends State<_LocationStrip> {
  Future<void> _editRegion() async {
    final initialCity = widget.state.cityName?.trim();
    final districtCtrl = TextEditingController(
      text: widget.state.districtName ?? '',
    );
    String? selectedCity = (initialCity != null && initialCity.isNotEmpty)
        ? (kTurkishCities.contains(initialCity) ? initialCity : null)
        : null;
    var saving = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: FR.bgElev,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(FRRad.xl)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            Future<void> save() async {
              final city = selectedCity?.trim() ?? '';
              if (city.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lütfen listeden bir şehir seç.')),
                );
                return;
              }
              setSheetState(() => saving = true);
              try {
                await widget.state.updateRegionSettings(
                  cityName: city,
                  districtName: districtCtrl.text,
                );
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (_) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bölge güncellenemedi.')),
                );
              } finally {
                if (ctx.mounted) setSheetState(() => saving = false);
              }
            }

            final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
            return Padding(
              padding: EdgeInsets.fromLTRB(18, 18, 18, bottomInset + 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bölge tercihi', style: frDisplay(18, FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(
                    'Anasayfa bölgeni kaydeder. Listeden şehrini seç ve istersen ilçeni gir.',
                    style: frText(12, FontWeight.w600, color: FR.ink3),
                  ),
                  const SizedBox(height: 14),
                  Text('Şehir',
                      style: frText(11.5, FontWeight.w800,
                          color: FR.ink3, letter: .4)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: FR.surface,
                      borderRadius: FRRad.all(FRRad.m),
                      border: Border.all(color: FR.hairline),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: selectedCity,
                        hint: Text(
                          'Şehir seç',
                          style: frText(13, FontWeight.w600, color: FR.ink3),
                        ),
                        icon: Icon(Icons.expand_more_rounded, color: FR.ink3),
                        dropdownColor: FR.surface,
                        style: frText(14, FontWeight.w700),
                        items: [
                          for (final c in kTurkishCities)
                            DropdownMenuItem<String>(
                              value: c,
                              child: Text(c, style: frText(14, FontWeight.w700)),
                            ),
                        ],
                        onChanged: saving
                            ? null
                            : (v) => setSheetState(() => selectedCity = v),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: districtCtrl,
                    style: frText(14, FontWeight.w700),
                    cursorColor: FR.gold,
                    decoration: const InputDecoration(
                      labelText: 'İlçe (opsiyonel)',
                      hintText: 'Örn: Kadıköy',
                    ),
                  ),
                  const SizedBox(height: 16),
                  FRCta(
                    label: saving ? 'Kaydediliyor…' : 'Bölgeyi kaydet',
                    icon: Icons.check_rounded,
                    onTap: saving ? null : save,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    districtCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final city = widget.state.cityName;
    final district = widget.state.districtName;
    final hasRegion = city != null && city.isNotEmpty;
    final title = hasRegion
        ? (district != null && district.isNotEmpty ? '$city · $district' : city)
        : 'Şehir seç';
    return InkWell(
      onTap: _editRegion,
      borderRadius: FRRad.all(FRRad.l),
      child: Container(
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
                  Text(
                    hasRegion ? 'BÖLGE' : 'BÖLGE (VARSAYILAN)',
                    style: frOverline(color: FR.ink3, size: 9.5),
                  ),
                  const SizedBox(height: 2),
                  Text(title, style: frText(14, FontWeight.w800)),
                  Text('Listeden şehir seç, ilçeni iste varsa gir',
                      style: frText(11.5, FontWeight.w600, color: FR.ink3)),
                ],
              ),
            ),
            Icon(Icons.expand_more_rounded, color: FR.ink3, size: 22),
          ],
        ),
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
                        const FRLiveDot(),
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
          color: FR.surface.withOpacity(FR.isDark ? .34 : .88),
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
    if (categories.isEmpty) {
      return SizedBox(
        height: 42,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Kategoriler yükleniyor…',
            style: frText(12, FontWeight.w600, color: FR.ink3),
          ),
        ),
      );
    }
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
                        color: FR.surface.withOpacity(FR.isDark ? .62 : .9),
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
  const _FeedRow({
    required this.product,
    required this.latest,
    required this.onTap,
  });
  final Product product;
  final PriceEntry? latest;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pct = product.priceChangePct;
    final latestEntry = latest;
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
                      if (latestEntry != null)
                        FRFreshChip(date: latestEntry.date)
                      else
                        Text('fiyat yok',
                            style: frText(11, FontWeight.w700, color: FR.ink3)),
                      if (latestEntry != null) ...[
                        const SizedBox(width: 6),
                        FRVerifyBadge.status(
                          status: statusToString(latestEntry.status),
                          trustPercent: latestEntry.trustPercent,
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
