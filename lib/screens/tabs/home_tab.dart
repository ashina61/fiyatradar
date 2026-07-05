import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../state/app_state.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import '../banner_page_screen.dart';
import '../main_screen.dart';
import '../notifications_screen.dart';
import '../product_detail_screen.dart';
import '../widgets/product_visual.dart';
import '../widgets/region_picker_sheet.dart';
import '../widgets/profile_avatar.dart';

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
          const SizedBox(height: FRSpace.l),
          // Sayfanın tek baskın bloğu: koyu espresso hero. Bölge seçimi de
          // ayrı bir kart yerine hero içinde kompakt bir chip olarak yaşar —
          // "açık gövde + tek koyu premium vurgu" kontrast modeli.
          FRFadeSlideIn(
            delay: nextDelay(),
            child: _RadarHero(
              state: state,
              hasRegion: hasRegion,
              onInspect: () => MainScreen.switchTab(context, 1),
            ),
          ),
          const SizedBox(height: FRSpace.m),
          // Kapsam seçimi: kart kabuğu olmadan sessiz bir chip satırı.
          // Feed'in hangi bölgeye baktığını kontrol eder.
          FRFadeSlideIn(
            delay: nextDelay(),
            child: _ScopeChipsRow(state: state, hasRegion: hasRegion),
          ),
          const SizedBox(height: FRSpace.m),
          // Günlük seri — retention kancası, ama hero ile yarışmayan tek
          // satırlık sakin bir utility row. Mevcut gamification verisiyle
          // çalışır, backend değişikliği yok.
          FRFadeSlideIn(delay: nextDelay(), child: _DailyStreakRow(state: state)),
          if (state.banners.isNotEmpty) ...[
            const SizedBox(height: FRSpace.xxl),
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
          const SizedBox(height: FRSpace.xxl),
          FRFadeSlideIn(
            delay: nextDelay(),
            child: FRSectionHead(
              eyebrow: 'BU HAFTA',
              title: 'Fiyatı düşenler',
              action: TextButton(
                onPressed: () => MainScreen.switchTab(context, 1),
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
                          onFavorite: () {
                            frHaptic();
                            state.toggleFavorite(p.id);
                          },
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
            const SizedBox(height: FRSpace.xxl),
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
          const SizedBox(height: FRSpace.xxl),
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
              child: _FeedEmptyState(state: state),
            )
          else
            // Feed rows skip the per-row fade animation — each instance
            // spawns its own AnimationController + delayed timer, and
            // stacking them on every list rebuild was visibly hitching the
            // home tab on cold scrolls.
            //
            // Pro değilse her 4 ürün başına bir banner reklam yerleştir;
            // Pro kullanıcıda hiç reklam render edilmez (FRInlineBannerAd
            // isPremium=true ile SizedBox.shrink döner).
            for (var i = 0; i < feedItems.length; i++) ...[
              _FeedRow(
                product: feedItems[i],
                latest: state.homeScopedEntryForProduct(feedItems[i].id),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(
                          product: feedItems[i])),
                ),
              ),
              if (!state.premium.isActive &&
                  i > 0 &&
                  (i + 1) % 4 == 0 &&
                  i != feedItems.length - 1) ...[
                const SizedBox(height: 12),
                FRInlineBannerAd(isPremium: state.premium.isActive),
                const SizedBox(height: 12),
              ],
            ],
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
    final firstName = state.displayName.split(' ').first.trim();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        InkWell(
          onTap: () => MainScreen.switchTab(context, 4),
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
            clipBehavior: Clip.antiAlias,
            child: ProfileAvatarImage(
              imageUrl: state.profileImageUrl,
              displayName: state.displayName,
              size: 52,
              radius: 16,
              cacheWidth: 156,
              initialStyle: frDisplay(20, FontWeight.w800, color: FR.onGold),
              onImageError: (url) => state.clearCachedProfileImageUrl(
                failedUrl: url,
              ),
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      firstName.isEmpty ? 'Anasayfa' : firstName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: frDisplay(28, FontWeight.w700, height: 1.05),
                    ),
                  ),
                  if (state.premium.isActive) ...[
                    const SizedBox(width: 8),
                    const FRProBadge(compact: false),
                  ],
                ],
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

// ─── Bölge seçimi (hero chip + boş durum ortak kullanır) ─────────────────────

Future<void> _pickRegion(BuildContext context, AppState state) async {
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

// ─── Kapsam chip satırı (kart kabuğu yok — sessiz kontrol) ───────────────────

/// Feed kapsamını seçen çıplak chip satırı. Eski hali koca bir "bölge kartı"
/// içinde yaşıyordu; kart kabuğu, ayraç ve BÖLGE etiketi kaldırıldı — bölge
/// bilgisi artık hero içindeki chip'te. 44px: chip dikey padding'i +
/// descender'lar için gereken yükseklik.
class _ScopeChipsRow extends StatelessWidget {
  const _ScopeChipsRow({required this.state, required this.hasRegion});
  final AppState state;
  final bool hasRegion;

  @override
  Widget build(BuildContext context) {
    final scope = state.activeHomeScope;
    return SizedBox(
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
              onTap: () => state.setHomePriceScope(HomePriceScope.online)),
          FRFilterChip('Türkiye geneli',
              active: scope == HomePriceScope.turkeyWide,
              onTap: () =>
                  state.setHomePriceScope(HomePriceScope.turkeyWide)),
        ],
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

class _BannerCarouselState extends State<_BannerCarousel>
    with SingleTickerProviderStateMixin {
  // Auto-rotate so featured editorial content cycles without forcing the
  // user to swipe. 6s/page sits between "noticed" and "patient" for casual
  // browsing. Drag input pauses the timer; we restart it after 4s of idle.
  static const _autoInterval = Duration(seconds: 6);
  static const _resumeIdle = Duration(seconds: 4);
  static const _cardHeight = 168.0;

  final PageController _ctrl = PageController(viewportFraction: .9);
  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: _autoInterval,
  );
  Timer? _autoTimer;
  Timer? _resumeTimer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    if (widget.banners.length > 1) _startAuto();
  }

  @override
  void didUpdateWidget(covariant _BannerCarousel old) {
    super.didUpdateWidget(old);
    if (widget.banners.length != old.banners.length) {
      if (_page >= widget.banners.length) _page = 0;
      if (widget.banners.length > 1) {
        _startAuto();
      } else {
        _stopAuto();
      }
    }
  }

  void _startAuto() {
    _stopAuto();
    if (!mounted || widget.banners.length <= 1) return;
    _progress
      ..reset()
      ..forward();
    _autoTimer = Timer.periodic(_autoInterval, (_) {
      if (!mounted || !_ctrl.hasClients) return;
      final next = (_page + 1) % widget.banners.length;
      _ctrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _stopAuto() {
    _autoTimer?.cancel();
    _autoTimer = null;
    _progress.stop();
  }

  void _pauseAndScheduleResume() {
    _stopAuto();
    _resumeTimer?.cancel();
    _resumeTimer = Timer(_resumeIdle, () {
      if (mounted) _startAuto();
    });
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _resumeTimer?.cancel();
    _progress.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banners = widget.banners;
    if (banners.isEmpty) return const SizedBox.shrink();
    final multi = banners.length > 1;
    return Column(
      children: [
        SizedBox(
          height: _cardHeight,
          // ScrollStartNotification.dragDetails is non-null only for
          // user-initiated drags, so programmatic animateToPage calls
          // don't accidentally pause the auto-rotation timer.
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n is ScrollStartNotification && n.dragDetails != null) {
                _pauseAndScheduleResume();
              }
              return false;
            },
            child: PageView.builder(
              controller: _ctrl,
              itemCount: banners.length,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (i) {
                setState(() => _page = i);
                if (multi && _autoTimer != null) {
                  _progress
                    ..reset()
                    ..forward();
                }
              },
              itemBuilder: (_, i) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _BannerCard(
                    banner: banners[i],
                    index: i,
                    count: banners.length,
                  ),
                );
              },
            ),
          ),
        ),
        if (multi) ...[
          const SizedBox(height: 12),
          _BannerProgressBar(
            count: banners.length,
            active: _page,
            progress: _progress,
            onTap: (i) {
              _pauseAndScheduleResume();
              _ctrl.animateToPage(
                i,
                duration: const Duration(milliseconds: 380),
                curve: Curves.easeOutCubic,
              );
            },
          ),
        ],
      ],
    );
  }
}

class _BannerProgressBar extends StatelessWidget {
  const _BannerProgressBar({
    required this.count,
    required this.active,
    required this.progress,
    required this.onTap,
  });
  final int count;
  final int active;
  final AnimationController progress;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == active;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: InkWell(
            onTap: () => onTap(i),
            borderRadius: FRRad.all(999),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              width: isActive ? 28 : 8,
              height: 4,
              decoration: BoxDecoration(
                color: isActive ? FR.gold.withOpacity(.22) : FR.hairline,
                borderRadius: FRRad.all(999),
              ),
              clipBehavior: Clip.antiAlias,
              child: isActive
                  ? AnimatedBuilder(
                      animation: progress,
                      builder: (_, __) => Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: progress.value.clamp(0.0, 1.0),
                          child: Container(color: FR.gold),
                        ),
                      ),
                    )
                  : null,
            ),
          ),
        );
      }),
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({
    required this.banner,
    required this.index,
    required this.count,
  });
  final AppBanner banner;
  final int index;
  final int count;

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
    final hasImage = banner.hasImage;
    final subtitle = banner.subtitle.trim();
    final actionLabel =
        banner.actionLabel.trim().isEmpty ? 'Keşfet' : banner.actionLabel;

    // Title sits on top of the image so it always reads as light text on
    // a darkened bottom; on plain (image-less) cards it reverts to the
    // standard ink hierarchy.
    final Color titleColor =
        hasImage ? const Color(0xFFFBF6EE) : FR.ink;
    final Color subtitleColor = hasImage
        ? const Color(0xFFFBF6EE).withOpacity(.78)
        : FR.ink3;

    return Semantics(
      button: true,
      label: count > 1
          ? '${banner.title}. ${subtitle.isEmpty ? '' : '$subtitle. '}Banner ${index + 1} / $count'
          : '${banner.title}. ${subtitle.isEmpty ? '' : subtitle}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onTap(context),
          borderRadius: FRRad.all(FRRad.xxl),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: FR.surface,
              borderRadius: FRRad.all(FRRad.xxl),
              border: Border.all(color: FR.goldDeep.withOpacity(.22)),
              boxShadow: frShadow(blur: 18, y: 8, opacity: .12),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (hasImage)
                  Image.network(
                    banner.imageUrl!,
                    fit: BoxFit.cover,
                    // Card sits at ~88% viewport width; 900px gives a
                    // crisp render on retina without inflating the
                    // GPU cache.
                    cacheWidth: 900,
                    cacheHeight: 540,
                    filterQuality: FilterQuality.medium,
                    frameBuilder: frFadeFrameBuilder,
                    loadingBuilder: (_, child, prog) {
                      if (prog == null) return child;
                      return Container(color: FR.surfaceHi);
                    },
                    errorBuilder: (_, __, ___) => _BannerImageFallback(),
                  )
                else
                  const _BannerPlainBackdrop(),
                if (hasImage)
                  // Bottom-anchored gradient: keep imagery vivid up top,
                  // drop to a dark espresso wash where the text lives so
                  // the title stays legible regardless of subject matter.
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.0, 0.42, 1.0],
                          colors: [
                            Colors.transparent,
                            const Color(0xFF1A0F06).withOpacity(.38),
                            const Color(0xFF120B07).withOpacity(.92),
                          ],
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (count > 1)
                        Align(
                          alignment: Alignment.topRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: hasImage
                                  ? const Color(0xFF120B07).withOpacity(.45)
                                  : FR.surfaceHi,
                              borderRadius: FRRad.all(999),
                              border: Border.all(
                                color: hasImage
                                    ? Colors.white.withOpacity(.22)
                                    : FR.hairline,
                              ),
                            ),
                            child: Text(
                              '${index + 1} / $count',
                              style: frText(10, FontWeight.w800,
                                  color: hasImage
                                      ? const Color(0xFFFBF6EE)
                                      : FR.ink3,
                                  letter: .6),
                            ),
                          ),
                        ),
                      const Spacer(),
                      Text(
                        banner.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: frDisplay(18, FontWeight.w700,
                            color: titleColor, height: 1.18),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: frText(12, FontWeight.w600,
                              color: subtitleColor, height: 1.4),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.fromLTRB(13, 7, 11, 7),
                        decoration: BoxDecoration(
                          color: FR.gold,
                          borderRadius: FRRad.all(999),
                          boxShadow: frGoldGlow(opacity: hasImage ? .3 : .22),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              actionLabel,
                              style: frText(11.5, FontWeight.w800,
                                  color: FR.onGold, letter: .2),
                            ),
                            const SizedBox(width: 6),
                            Icon(Icons.arrow_forward_rounded,
                                size: 13, color: FR.onGold),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BannerPlainBackdrop extends StatelessWidget {
  const _BannerPlainBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [FR.surfaceHi, FR.surfaceLo],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        Positioned(
          right: -28,
          top: -22,
          child: Icon(Icons.campaign_rounded,
              size: 168, color: FR.gold.withOpacity(.09)),
        ),
      ],
    );
  }
}

class _BannerImageFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const _BannerPlainBackdrop(),
        Center(
          child: Icon(Icons.broken_image_outlined,
              color: FR.ink3, size: 32),
        ),
      ],
    );
  }
}

// ─── Radar hero (sayfanın tek baskın premium bloğu) ──────────────────────────

/// Her iki temada da koyu espresso yüzey: design-language.md'nin çekirdek
/// kontrast modeli "açık gövde + tek koyu premium vurgu". Bu yüzden renkler
/// aktif temadan değil doğrudan [FRPalette.dark]'tan gelir — açık temada
/// sayfanın krem gövdesi üzerinde imza bloğu olur, koyu temada zaten aynı
/// aileden bir elevated yüzey gibi oturur.
class _RadarHero extends StatelessWidget {
  const _RadarHero({
    required this.state,
    required this.hasRegion,
    required this.onInspect,
  });
  final AppState state;
  final bool hasRegion;
  final VoidCallback onInspect;

  static const FRPalette _d = FRPalette.dark;

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
      padding: const EdgeInsetsDirectional.all(FRSpace.xl),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_d.surfaceHi, _d.bgElev],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: FRRad.all(FRRad.xxl),
        border: Border.all(color: _d.hairline),
        boxShadow: frShadow(blur: 26, y: 14, opacity: FR.isDark ? .4 : .2),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -16,
            top: -10,
            child: Icon(Icons.radar_rounded,
                size: 156, color: _d.gold.withOpacity(.08)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _livePill(),
                  const SizedBox(width: FRSpace.s),
                  Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: _regionChip(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: FRSpace.l),
              Text(headline,
                  style: frDisplay(24, FontWeight.w700,
                      color: _d.ink, height: 1.15)),
              const SizedBox(height: FRSpace.s),
              Text(subtitle,
                  style: frText(12, FontWeight.w600, color: _d.ink2)),
              const SizedBox(height: FRSpace.l),
              Row(
                children: [
                  _heroStat('$fresh', 'YENİ VERİ · 24s'),
                  const SizedBox(width: FRSpace.s),
                  _heroStat('$verified', 'DOĞRULANDI'),
                  const SizedBox(width: FRSpace.s),
                  _heroStat(trust == 0 ? '—' : '%$trust', 'GÜVEN'),
                ],
              ),
              const SizedBox(height: FRSpace.l),
              _heroCta(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _livePill() {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
          horizontal: FRSpace.s + 1, vertical: FRSpace.xs),
      decoration: BoxDecoration(
        color: _d.good.withOpacity(.16),
        borderRadius: FRRad.all(FRRad.pill),
        border: Border.all(color: _d.good.withOpacity(.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FRLiveDot(color: _d.good),
          const SizedBox(width: 6),
          Text('RADAR AKTİF',
              style: frText(9.5, FontWeight.w800,
                  color: _d.good, letter: 1.3)),
        ],
      ),
    );
  }

  /// Bölge bağlamı hero içinde yaşar — ayrı bir kart yerine sağ üstte
  /// dokunulabilir bir chip. Tık → bölge seçici sheet.
  Widget _regionChip(BuildContext context) {
    final city = (state.cityName ?? '').trim();
    final district = (state.districtName ?? '').trim();
    return InkWell(
      onTap: () => _pickRegion(context, state),
      borderRadius: FRRad.all(FRRad.pill),
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(
            horizontal: FRSpace.m, vertical: 6),
        decoration: BoxDecoration(
          color: _d.bg.withOpacity(.4),
          borderRadius: FRRad.all(FRRad.pill),
          border: Border.all(color: _d.hairline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.place_outlined, size: 13, color: _d.gold),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                hasRegion ? '$district / $city' : 'Bölge seç',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: frText(11, FontWeight.w800, color: _d.ink2),
              ),
            ),
            const SizedBox(width: FRSpace.xs),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 14, color: _d.ink3),
          ],
        ),
      ),
    );
  }

  Widget _heroStat(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(
            vertical: FRSpace.s + 2, horizontal: FRSpace.s + 2),
        decoration: BoxDecoration(
          color: _d.bg.withOpacity(.4),
          borderRadius: FRRad.all(FRRad.m),
          border: Border.all(color: _d.hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: frPrice(18, color: _d.gold)),
            Text(label,
                style: frText(9, FontWeight.w800,
                    color: _d.ink3, letter: 1.2)),
          ],
        ),
      ),
    );
  }

  /// Koyu yüzey üzerinde altın dolgulu birincil CTA — [FRCta] aktif temanın
  /// altınını kullandığı için (açık temada koyu bakır) burada sabit espresso
  /// paletiyle yerel bir kapsül çiziyoruz.
  Widget _heroCta() {
    return InkWell(
      onTap: () {
        frHaptic();
        onInspect();
      },
      borderRadius: FRRad.all(FRRad.pill),
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _d.gold,
          borderRadius: FRRad.all(FRRad.pill),
          boxShadow: [
            BoxShadow(
              color: _d.gold.withOpacity(.28),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Radarı incele',
                style: frText(14, FontWeight.w800, color: _d.onGold)),
            const SizedBox(width: FRSpace.s),
            Icon(Icons.arrow_forward_rounded, size: 18, color: _d.onGold),
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
              MainScreen.switchTab(context, 1);
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
                            cacheHeight: 480,
                            filterQuality: FilterQuality.medium,
                            frameBuilder: frFadeFrameBuilder,
                            errorBuilder: (_, __, ___) =>
                                _trendCardVisualFallback(product),
                          )
                        : _trendCardVisualFallback(product),
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
                      // Fiyat altın değil mürekkep: altın sadece vurgu rengi,
                      // her kartta tekrar edince değerini yitiriyordu.
                      FRPriceText(product.lowestPrice, size: 22),
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

Widget _trendCardVisualFallback(Product product) {
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [FR.surfaceHi, FR.surfaceLo],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: ProductVisual(
      product: product,
      iconSize: 48,
      padIllustration: true,
    ),
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
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: FR.surfaceHi,
                borderRadius: FRRad.all(12),
                border: Border.all(color: FR.hairline),
              ),
              clipBehavior: Clip.antiAlias,
              child: ProductVisual(
                product: product,
                cacheWidth: 192,
                padIllustration: false,
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
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      FRStoreBadge(latest?.store ?? '—'),
                      if (latestEntry != null)
                        FRFreshChip(date: latestEntry.date)
                      else
                        Text('fiyat yok',
                            style:
                                frText(11, FontWeight.w700, color: FR.ink3)),
                      if (latestEntry != null)
                        FRVerifyBadge.status(
                          status: statusToString(latestEntry.status),
                          trustPercent: latestEntry.trustPercent,
                          dense: true,
                        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 20), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
      decoration: frSurface(radius: FRRad.l),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.radar_rounded, size: 26, color: FR.ink3),
          const SizedBox(height: 8),
          Text(text,
              textAlign: TextAlign.center,
              style: frText(12.5, FontWeight.w600, color: FR.ink3)),
        ],
      ),
    );
  }
}

/// Topluluk akışı boşken gösterilen profesyonel boş durum: ikon + başlık +
/// açıklama + iki aksiyon (fiyat ekle / bölge değiştir). Gri/kuru kutu yerine
/// kullanıcıyı ilk katkıya veya bölge seçimine yönlendirir.
class _FeedEmptyState extends StatelessWidget {
  const _FeedEmptyState({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: frSurface(radius: FRRad.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: FR.gold.withOpacity(.14),
                borderRadius: FRRad.all(18),
                border: Border.all(color: FR.gold.withOpacity(.4)),
              ),
              child: Icon(Icons.radar_rounded, color: FR.gold, size: 28),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Bu bölgede henüz yeterli fiyat yok',
            textAlign: TextAlign.center,
            style: frText(15, FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'İlk fiyatı sen ekleyerek bölgenin fiyat radarını başlatabilirsin.',
            textAlign: TextAlign.center,
            style: frText(12.5, FontWeight.w600, color: FR.ink3, height: 1.5),
          ),
          const SizedBox(height: 16),
          FRCta(
            label: 'Fiyat ekle',
            icon: Icons.add_rounded,
            onTap: () => MainScreen.switchTab(context, 2),
          ),
          const SizedBox(height: 10),
          FRCta(
            label: 'Bölge değiştir',
            icon: Icons.place_outlined,
            filled: false,
            onTap: () => _pickRegion(context, state),
          ),
        ],
      ),
    );
  }
}

// ─── Günlük seri (streak) — sakin utility row ────────────────────────────────
//
// Retention kancası: mevcut seriyi, bugünkü katkı durumunu ve sıradaki seri
// rozetine (3/7/30 gün) ilerlemeyi gösterir. Tamamı mevcut gamification
// snapshot'ından beslenir; ek Firestore okuması veya backend değişikliği yok.
// Eski hali altın çerçeveli, altın CTA'lı büyük bir karttı ve hero ile
// yarışıyordu — artık satırın tamamı dokunulabilir tek bir utility row.

class _DailyStreakRow extends StatelessWidget {
  const _DailyStreakRow({required this.state});
  final AppState state;

  bool get _contributedToday {
    final last = state.gamification.lastContributionDay;
    if (last == null) return false;
    final now = DateTime.now().toUtc();
    final today = DateTime.utc(now.year, now.month, now.day);
    final lastDay = DateTime.utc(last.year, last.month, last.day);
    return today.difference(lastDay).inDays == 0;
  }

  /// Sıradaki seri rozeti eşiği (3 → 7 → 30). Hepsi geçildiyse null.
  int? _nextStreakTarget(int streak) {
    for (final t in const [3, 7, 30]) {
      if (streak < t) return t;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = state.isGuestUser;
    final g = state.gamification;
    final streak = g.streakActive ? g.currentStreak : 0;
    final doneToday = _contributedToday;

    final String title;
    final String body;
    final int ctaTabIndex;
    if (isGuest) {
      title = 'Seri toplamaya başla';
      body = 'Hesap aç, her fiyat katkısı +10 PT olsun.';
      ctaTabIndex = 4; // Profil sekmesi — kayıt/upgrade CTA'sı orada.
    } else if (doneToday) {
      title = '$streak günlük seri';
      body = 'Bugünkü katkın tamam — yarın da paylaş, seri büyüsün.';
      ctaTabIndex = 2;
    } else if (streak > 0) {
      title = '$streak günlük serin risk altında';
      body = 'Bugün 1 fiyat paylaş, serini koru.';
      ctaTabIndex = 2;
    } else {
      title = 'Bugün serini başlat';
      body = 'İlk fiyatını paylaş — +10 PT.';
      ctaTabIndex = 2;
    }

    final target = isGuest ? null : _nextStreakTarget(streak);
    final progress =
        target == null ? 1.0 : (streak / target).clamp(0.0, 1.0).toDouble();

    return FRCard(
      radius: FRRad.l,
      padding: const EdgeInsetsDirectional.all(FRSpace.m),
      onTap: () {
        frHaptic();
        MainScreen.switchTab(context, ctaTabIndex);
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: FR.gold.withOpacity(.12),
              border: Border.all(color: FR.gold.withOpacity(.3)),
            ),
            child: Text(
              doneToday || streak > 0 ? '🔥' : '✨',
              style: const TextStyle(fontSize: 17),
            ),
          ),
          const SizedBox(width: FRSpace.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: frText(13.5, FontWeight.w800)),
                    ),
                    if (target != null) ...[
                      const SizedBox(width: FRSpace.s),
                      Text('$streak/$target gün',
                          style: frText(10.5, FontWeight.w800,
                              color: FR.ink3)),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: frText(11.5, FontWeight.w600, color: FR.ink3),
                ),
                if (target != null) ...[
                  const SizedBox(height: FRSpace.s),
                  ClipRRect(
                    borderRadius: FRRad.all(FRRad.pill),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      backgroundColor: FR.hairlineSoft,
                      valueColor: AlwaysStoppedAnimation<Color>(FR.gold),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: FRSpace.s),
          Icon(Icons.chevron_right_rounded, size: 20, color: FR.ink3),
        ],
      ),
    );
  }
}
