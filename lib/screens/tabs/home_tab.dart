import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../state/app_state.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import '../banner_page_screen.dart';
import '../main_screen.dart';
import '../notifications_screen.dart';
import '../product_detail_screen.dart';
import '../widgets/region_picker_sheet.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final topDrops = state.homeTopDrops;
    final scopedProductIds = state.homeScopedProductIds;
    final feedItems = scopedProductIds
        .map(state.findById)
        .whereType<Product>()
        .take(6)
        .toList();
    final hasRegion = (state.cityName ?? '').trim().isNotEmpty &&
        (state.districtName ?? '').trim().isNotEmpty;

    var step = 0;
    Duration nextDelay() => Duration(milliseconds: 60 * step++);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: EdgeInsets.fromLTRB(20, 14, 20, frBottomScrollPadding(context)),
        children: [
          FRFadeSlideIn(delay: nextDelay(), child: _HomeHeader(state: state)),
          const SizedBox(height: 18),
          FRFadeSlideIn(
            delay: nextDelay(),
            child: _RadarHero(
              state: state,
              onInspect: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                    builder: (_) => const MainScreen(initialIndex: 1)),
              ),
            ),
          ),
          const SizedBox(height: 14),
          FRFadeSlideIn(
            delay: nextDelay(),
            child: _RegionScopeCard(state: state, hasRegion: hasRegion),
          ),
          const SizedBox(height: 14),
          FRFadeSlideIn(delay: nextDelay(), child: const _QuickAddRow()),
          if (state.banners.isNotEmpty) ...[
            const SizedBox(height: 24),
            FRFadeSlideIn(
              delay: nextDelay(),
              child: const FRSectionHead(
                eyebrow: 'EDİTÖR SEÇİMLERİ',
                title: 'Bu hafta öne çıkan',
              ),
            ),
            const SizedBox(height: 12),
            FRFadeSlideIn(
              delay: nextDelay(),
              child: _BannerCarousel(banners: state.banners),
            ),
          ],
          const SizedBox(height: 26),
          FRFadeSlideIn(
            delay: nextDelay(),
            child: FRSectionHead(
              eyebrow: 'BU HAFTA',
              title: 'Fiyatı düşenler',
              action: TextButton(
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                      builder: (_) => const MainScreen(initialIndex: 1)),
                ),
                child: Text('Tümü',
                    style: frText(12, FontWeight.w800, color: FR.goldDeep)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FRFadeSlideIn(
            delay: nextDelay(),
            child: SizedBox(
              height: 302,
              child: topDrops.isEmpty
                  ? const _EmptyBlock(
                      height: 302, text: 'Bu hafta fiyat düşüşü henüz yok.')
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
                            MaterialPageRoute(
                                builder: (_) =>
                                    ProductDetailScreen(product: p)),
                          ),
                        );
                      },
                    ),
            ),
          ),
          if (state.categories.isNotEmpty) ...[
            const SizedBox(height: 26),
            FRFadeSlideIn(
              delay: nextDelay(),
              child: const FRSectionHead(
                eyebrow: 'KEŞFET',
                title: 'Kategoriler',
              ),
            ),
            const SizedBox(height: 12),
            FRFadeSlideIn(
              delay: nextDelay(),
              child: _CategoryStrip(categories: state.categories),
            ),
          ],
          const SizedBox(height: 26),
          FRFadeSlideIn(
            delay: nextDelay(),
            child: FRSectionHead(
              eyebrow: 'TOPLULUK AKIŞI',
              title: state.homeScopeTitle,
              action: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const FRLiveDot(),
                  const SizedBox(width: 6),
                  Text('canlı',
                      style: frText(11, FontWeight.w800, color: FR.good)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          FRFadeSlideIn(
            delay: nextDelay(),
            child: Text(
              state.homeScopeSubtitle,
              style: frText(12, FontWeight.w600, color: FR.ink3, height: 1.4),
            ),
          ),
          const SizedBox(height: 12),
          if (feedItems.isEmpty)
            FRFadeSlideIn(
              delay: nextDelay(),
              child: _EmptyBlock(
                height: 120,
                text: state.homeScopeEmptyMessage,
              ),
            )
          else
            // Feed rows skip the per-row fade animation — each instance
            // spawns its own AnimationController + delayed timer, and
            // stacking them on every list rebuild was visibly hitching the
            // home tab on cold scrolls.
            ...feedItems.map(
              (p) => _FeedRow(
                product: p,
                latest: state.homeScopedEntryForProduct(p.id),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(product: p)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Page entry: greeting + bell, follows the FRPageHeader rhythm ────────────

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.state});
  final AppState state;

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 5) return 'İyi geceler';
    if (hour < 11) return 'Günaydın';
    if (hour < 17) return 'İyi günler';
    if (hour < 22) return 'İyi akşamlar';
    return 'İyi geceler';
  }

  @override
  Widget build(BuildContext context) {
    final firstName =
        state.displayName.split(' ').first.trim();
    final initial = state.displayName.isEmpty
        ? 'FR'
        : state.displayName[0].toUpperCase();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        InkWell(
          onTap: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(
                builder: (_) => const MainScreen(initialIndex: 4)),
          ),
          borderRadius: FRRad.all(16),
          child: Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [FR.goldHi, FR.goldDeep]),
              borderRadius: FRRad.all(16),
              boxShadow: frGoldGlow(opacity: .18),
            ),
            child: Text(
              initial,
              style: frDisplay(20, FontWeight.w800, color: FR.onGold),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${_greeting().toUpperCase()} · RADAR',
                  style: frOverline(color: FR.ink3, size: 9.5)),
              const SizedBox(height: 4),
              Text(
                firstName.isEmpty ? 'Anasayfa' : firstName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: frDisplay(28, FontWeight.w700, height: 1.05),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
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

// ─── Region scope row (Utility Row card style) ───────────────────────────────

class _RegionScopeCard extends StatelessWidget {
  const _RegionScopeCard({required this.state, required this.hasRegion});
  final AppState state;
  final bool hasRegion;

  Future<void> _openPicker(BuildContext context) async {
    final result = await showRegionPickerSheet(
      context,
      initialCity: state.cityName,
      initialDistrict: state.districtName,
    );
    if (result == null) return;
    try {
      await state.updateRegionSettings(
        cityName: result.city,
        districtName: result.district,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Bölge güncellendi: ${result.city} / ${result.district}')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bölge güncellenemedi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final city = (state.cityName ?? '').trim();
    final district = (state.districtName ?? '').trim();
    final scope = state.activeHomeScope;

    return Container(
      decoration: frSurface(radius: FRRad.l),
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _openPicker(context),
            borderRadius: FRRad.all(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.place_outlined, size: 18, color: FR.gold),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('BÖLGE',
                            style: frOverline(color: FR.ink3, size: 9.5)),
                        const SizedBox(height: 2),
                        Text(
                          hasRegion
                              ? '$district / $city'
                              : 'İl ve ilçe seçilmedi',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: frText(14.5, FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: FR.gold.withOpacity(.14),
                      borderRadius: FRRad.all(999),
                      border: Border.all(color: FR.gold.withOpacity(.4)),
                    ),
                    child: Text(
                      hasRegion ? 'Değiştir' : 'Seç',
                      style: frText(11.5, FontWeight.w800, color: FR.gold),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(height: 1, color: FR.hairlineSoft),
          const SizedBox(height: 10),
          // Filter chips were clipped at the previous 36px height — the
          // chip's vertical padding (10+10) plus glyph height pushed past
          // the box and the bottom of "Türkiye geneli" descenders went
          // missing. Bump to 44 to give descenders room and add a soft
          // bounce scroll physics so the user can reach the last chip.
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: [
                FRFilterChip('Yakınımda',
                    active: scope == HomePriceScope.nearby,
                    onTap: hasRegion
                        ? () => state.setHomePriceScope(HomePriceScope.nearby)
                        : null),
                FRFilterChip('Şehrimde',
                    active: scope == HomePriceScope.city,
                    onTap: hasRegion
                        ? () => state.setHomePriceScope(HomePriceScope.city)
                        : null),
                FRFilterChip('Online',
                    active: scope == HomePriceScope.online,
                    onTap: () =>
                        state.setHomePriceScope(HomePriceScope.online)),
                FRFilterChip('Türkiye geneli',
                    active: scope == HomePriceScope.turkeyWide,
                    onTap: () =>
                        state.setHomePriceScope(HomePriceScope.turkeyWide)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quick add price (Utility Row, low intensity) ────────────────────────────

class _QuickAddRow extends StatelessWidget {
  const _QuickAddRow();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: FRRad.all(FRRad.l),
      onTap: () => Navigator.of(context).pushReplacement(
        MaterialPageRoute(
            builder: (_) => const MainScreen(initialIndex: 2)),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
        decoration: frSurface(radius: FRRad.l),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: FR.gold.withOpacity(.14),
                borderRadius: FRRad.all(11),
                border: Border.all(color: FR.gold.withOpacity(.4)),
              ),
              child: Icon(Icons.add_rounded, color: FR.gold, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Fiyat gördün mü?',
                      style: frText(13.5, FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text('20 saniyede ekle, bölgendeki kullanıcılar görsün.',
                      style: frText(11.5, FontWeight.w600, color: FR.ink3)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: FR.ink3),
          ],
        ),
      ),
    );
  }
}

// ─── Banner carousel ─────────────────────────────────────────────────────────

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
                child: _BannerCard(banner: b),
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

class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.banner});
  final AppBanner banner;

  void _onTap(BuildContext context) {
    final state = AppStateScope.read(context);
    if (banner.actionType == 'route' && banner.actionTarget.trim().isNotEmpty) {
      runBannerRoute(context, state, banner.actionTarget);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BannerPageScreen(banner: banner)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _onTap(context),
      borderRadius: FRRad.all(20),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: FR.surface,
          borderRadius: FRRad.all(20),
          border: Border.all(color: FR.hairline),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (banner.hasImage)
              Image.network(
                banner.imageUrl!,
                fit: BoxFit.cover,
                // Banner card is ~92% viewport width; 800px decoded width
                // gives crisp results on retina without needlessly
                // decoding 1200px frames into the GPU cache.
                cacheWidth: 800,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            if (banner.hasImage)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      FR.bg.withOpacity(.55),
                      FR.bg.withOpacity(.86),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          banner.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: frDisplay(15, FontWeight.w700, height: 1.2),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          banner.subtitle,
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
                            border: Border.all(color: FR.gold.withOpacity(.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                banner.actionLabel,
                                style: frText(10.5, FontWeight.w800,
                                    color: FR.gold, letter: .4),
                              ),
                              const SizedBox(width: 6),
                              Icon(Icons.arrow_forward_rounded,
                                  size: 12, color: FR.gold),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!banner.hasImage) ...[
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Radar hero (the dominant premium block of the page) ────────────────────

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

    final headline = hasSignal
        ? (drop < -0.01
            ? 'Bu hafta %${drop.abs().toStringAsFixed(drop.abs() < 10 ? 1 : 0)} fiyat düşüşü'
            : 'Son 24 saatte $fresh yeni veri')
        : 'Radar beklemede.\nİlk fiyatı sen ekle.';

    final subtitle = hasSignal
        ? '${state.products.length} ürün · $verified topluluk doğrulaması · %$trust güven'
        : 'Ürün ekle, topluluk doğrulasın.';

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
      child: Stack(
        children: [
          Positioned(
            right: -16,
            top: -10,
            child: Icon(Icons.radar_rounded,
                size: 156, color: FR.gold.withOpacity(.07)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 4),
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
                            style: frText(9.5, FontWeight.w800,
                                color: FR.good, letter: 1.3)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (state.unreadNotificationCount > 0)
                    Text('${state.unreadNotificationCount} yeni sinyal',
                        style:
                            frText(11, FontWeight.w800, color: FR.gold)),
                ],
              ),
              const SizedBox(height: 14),
              Text('RADAR ÖZETİ',
                  style: frOverline(color: FR.ink3, size: 9.5)),
              const SizedBox(height: 4),
              Text(headline,
                  style: frDisplay(24, FontWeight.w700, height: 1.15)),
              const SizedBox(height: 8),
              Text(subtitle,
                  style: frText(12, FontWeight.w600, color: FR.ink3)),
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
              FRCta(
                  label: 'Radarı incele',
                  icon: Icons.arrow_forward_rounded,
                  onTap: onInspect),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String value, String label) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: FR.surface.withOpacity(FR.isDark ? .34 : .88),
          borderRadius: FRRad.all(12),
          border: Border.all(color: FR.hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: frPrice(18, color: FR.gold)),
            Text(label,
                style:
                    frText(9, FontWeight.w800, color: FR.ink3, letter: 1.2)),
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
            leading: Icon(icon, size: 14, color: FR.ink2),
            onTap: () {
              final state = AppStateScope.read(context);
              state.setExplorePresetCategory(c);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => const MainScreen(initialIndex: 1),
                ),
              );
            },
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
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(FRRad.xl),
                  ),
                  child: SizedBox(
                    height: 136,
                    width: double.infinity,
                    child: product.imageUrl != null &&
                            product.imageUrl!.isNotEmpty
                        ? Image.network(
                            product.imageUrl!,
                            fit: BoxFit.cover,
                            cacheWidth: 480,
                            filterQuality: FilterQuality.medium,
                            errorBuilder: (_, __, ___) =>
                                _trendCardEmojiFallback(product.emoji),
                          )
                        : _trendCardEmojiFallback(product.emoji),
                  ),
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
                        isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_outline_rounded,
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
                      FRPriceText(product.lowestPrice,
                          size: 22, color: FR.gold),
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

Widget _trendCardEmojiFallback(String emoji) {
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [FR.surfaceHi, FR.surfaceLo],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Center(child: Text(emoji, style: const TextStyle(fontSize: 66))),
  );
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
    final regionLabel = latestEntry == null
        ? null
        : () {
            final city = (latestEntry.city ?? '').trim();
            final district = (latestEntry.district ?? '').trim();
            if (city.isEmpty || district.isEmpty) return null;
            return '$district / $city';
          }();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: FRCard(
        radius: FRRad.l,
        onTap: onTap,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            FRProductThumb(
              emoji: product.emoji,
              imageUrl: product.imageUrl,
              size: 48,
              radius: 12,
              cacheWidth: 192,
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
                            style:
                                frText(11, FontWeight.w700, color: FR.ink3)),
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
                  if (regionLabel != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      regionLabel,
                      style: frText(10.5, FontWeight.w700, color: FR.ink3),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FRPriceText(latestEntry?.price ?? product.lowestPrice,
                    size: 16, color: FR.ink),
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
