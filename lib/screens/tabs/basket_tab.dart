import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/price_reporting.dart';
import '../../models/product.dart';
import '../../services/ads_service.dart';
import '../../services/basket_pricing_service.dart';
import '../../state/app_state.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import '../main_screen.dart';
import '../paywall_screen.dart';
import '../widgets/region_picker_sheet.dart';

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
    final s = AppStrings.of(context);
    final cart = state.cart;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(FRSpace.xl, 14, FRSpace.xl, 0),
            child: FRPageHeader(
              overline: s.t('basket.overline'),
              title: s.t('basket.title'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Text(
              s.t('basket.description'),
              style: frText(13, FontWeight.w500, color: FR.ink3, height: 1.5),
            ),
          ),
          if (state.isGuestUser) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _GuestQuotaPill(
                remaining: state.guestBasketComputeRemaining,
                limit: AppState.guestBasketComputeLimit,
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: _Segmented(
              // Both tabs reflect the same physical cart, so the count must
              // match. Use the unique-product count (cart.length) on both
              // sides — that's what each tab actually renders.
              labels: [s.t('basket.tab.mine'), s.t('basket.tab.compare')],
              counts: [cart.length, cart.length],
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
                  // priceHistory.length is the total number of price entries,
                  // not the number of distinct stores — counting unique store
                  // names matches the user's expectation.
                  () {
                    final uniqueStores = item.product.priceHistory
                        .map((e) => e.store.trim().toLowerCase())
                        .where((s) => s.isNotEmpty)
                        .toSet()
                        .length;
                    return '$uniqueStores mağaza · ${item.product.brand}';
                  }(),
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
            // "Alt toplam" yerine "Tahmini toplam" — bu satır kasa fiyatı
            // değil, bölgesel topluluk fiyatlarından üretilmiş bir tahmin.
            _line('Tahmini toplam',
                '₺${state.cartSubtotal.toStringAsFixed(2)}'),
            const SizedBox(height: 4),
            _line('Tahmini tasarruf', '₺${state.cartSavings.toStringAsFixed(2)}',
                hl: FR.good),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Bölgesel topluluk fiyatlarına göre tahmin · kasa fiyatı garanti değildir.',
                style: frText(10.5, FontWeight.w600,
                    color: FR.ink3, height: 1.4),
              ),
            ),
            // Pro değilse reklamsız CTA görünür; Pro ise no-op (SizedBox).
            FRAdSlot(
              isPremium: state.premium.isActive,
              onUpgradeTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PaywallScreen()),
              ),
            ),
            const SizedBox(height: 6),
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
  Future<BasketPricingResult>? _future;
  int _cartSignature = -1;

  @override
  void initState() {
    super.initState();
    _maybeRefresh();
  }

  @override
  void didUpdateWidget(covariant _ComparePanel old) {
    super.didUpdateWidget(old);
    _maybeRefresh();
  }

  int _signatureFor(AppState state) {
    var sig = 0;
    for (final c in state.cart) {
      sig = sig * 31 + c.product.id.hashCode;
      sig = sig * 31 + c.quantity;
    }
    sig = sig * 31 + (state.cityName ?? '').hashCode;
    sig = sig * 31 + (state.districtName ?? '').hashCode;
    return sig;
  }

  void _maybeRefresh() {
    final sig = _signatureFor(widget.state);
    if (sig == _cartSignature && _future != null) return;
    // Misafir kullanıcı kotası dolduysa hesap yapma — UI overlay
    // gösterip kullanıcıyı üye olmaya yönlendiriyor.
    if (widget.state.guestBasketExhausted) {
      _cartSignature = sig;
      _future = null;
      return;
    }
    _cartSignature = sig;
    final future = widget.state.calculateRegionalBasketPricing();
    _future = future;
    // Hesap başarılı bittiyse: misafir sayacı bir artır, Pro değilse
    // interstitial reklam dene (cooldown'lu).
    future.then((_) {
      if (widget.state.isGuestUser) {
        widget.state.recordGuestBasketCompute();
      }
      if (!widget.state.premium.isActive) {
        AdsService.instance.maybeShowInterstitial();
      }
    });
  }

  void _recalc() {
    if (widget.state.guestBasketExhausted) {
      setState(() {});
      return;
    }
    setState(() {
      _cartSignature = _signatureFor(widget.state);
      final future = widget.state.calculateRegionalBasketPricing();
      _future = future;
      future.then((_) {
        if (widget.state.isGuestUser) {
          widget.state.recordGuestBasketCompute();
        }
        if (!widget.state.premium.isActive) {
          AdsService.instance.maybeShowInterstitial();
        }
      });
    });
  }

  Future<void> _pickRegion(AppState state) async {
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Bölge güncellendi: ${result.city} / ${result.district}')),
      );
      _recalc();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bölge güncellenemedi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    if (state.cart.isEmpty) return _EmptyCart();

    final hasRegion = (state.cityName ?? '').trim().isNotEmpty &&
        (state.districtName ?? '').trim().isNotEmpty;
    if (!hasRegion) {
      return _CompareNoRegion(onPick: () => _pickRegion(state));
    }

    // Misafir kullanıcı sepet hesap kotasını tüketti — paywall benzeri
    // ekrana yönlendir, hesap yapma. Üye olduktan sonra sayaç sıfırlanmaz
    // (cihaz başına); ama gerçek hesap kullanıcıda limit zaten yok.
    if (state.guestBasketExhausted) {
      return _GuestLimitReached();
    }

    return FutureBuilder<BasketPricingResult>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const _CompareLoading();
        }
        final result = snap.data!;
        final singles = result.singleMarketEstimates;
        if (singles.isEmpty) {
          return _CompareEmptyData(
            city: state.cityName!.trim(),
            district: state.districtName!.trim(),
            onAddPrice: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 2)),
            ),
            onPickRegion: () => _pickRegion(state),
          );
        }

        final mixed = result.cheapestMixed;
        final smart = result.smartSuggestion;
        final winner = singles.first;
        final worstTotal = singles.last.estimatedTotal;
        final saving = (worstTotal - winner.estimatedTotal).clamp(0, double.infinity);
        final mixedSavingVsWinner =
            mixed == null ? 0.0 : (winner.estimatedTotal - mixed.estimatedTotal);

        return ListView(
          padding: EdgeInsets.fromLTRB(20, 14, 20, frBottomScrollPadding(context)),
          children: [
            _CompareRegionRow(
              city: state.cityName!.trim(),
              district: state.districtName!.trim(),
              onChange: () => _pickRegion(state),
            ),
            const SizedBox(height: 14),
            _CompareWinnerCard(
              estimate: winner,
              savingsVsWorst: saving.toDouble(),
              totalChains: singles.length,
              region: '${state.districtName} / ${state.cityName}',
              onAddMissing: () => _routeToAddMissing(context, winner, state),
            ),
            const SizedBox(height: 16),
            if (mixed != null && mixedSavingVsWinner > 0) ...[
              if (state.premium.isActive)
                _CompareMixedCard(
                  mixed: mixed,
                  saving: mixedSavingVsWinner,
                  bestSingle: winner.chainName,
                )
              else
                const _CompareMixedLockedCard(),
              const SizedBox(height: 16),
            ],
            FRSectionHead(
              eyebrow: 'TEK MARKET SIRALAMASI',
              title: 'Tahmini toplamlar',
              action: TextButton.icon(
                onPressed: _recalc,
                icon: Icon(Icons.refresh_rounded, size: 14, color: FR.goldDeep),
                label: Text(
                  'Yenile',
                  style: frText(12, FontWeight.w800, color: FR.goldDeep),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: const Size(0, 30),
                ),
              ),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < singles.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SingleStoreCard(
                  estimate: singles[i],
                  state: state,
                  rank: i + 1,
                  isWinner: i == 0,
                ),
              ),
            // Akıllı sepet önerisi — Pro özelliği. Pro değilse upsell kartı
            // gösteriyoruz ki kullanıcı sebebini görsün; aksi halde
            // kullanıcı "öneri niye yok?" diye düşünür.
            if (smart != null) ...[
              const SizedBox(height: 6),
              if (state.premium.isActive)
                _CompareInsightBanner(message: smart.message)
              else
                _ProUpsellBanner(
                  title: 'Akıllı sepet önerisi',
                  body:
                      'Pro üyeler için sepetin nasıl bölünmesi gerektiğine dair akıllı öneri. Yükselt ve hangi marketleri gezeceğini saniyede gör.',
                ),
            ],
          ],
        );
      },
    );
  }

  void _routeToAddMissing(
    BuildContext context,
    BasketStoreEstimate estimate,
    AppState state,
  ) {
    if (estimate.missingProductIds.isEmpty) return;
    // Queue every missing product for sequential add-price consumption so
    // the user can fill the gap for the whole chain in one sitting.
    state.queueAddPricePreset(
      productIds: estimate.missingProductIds,
      chainName: estimate.chainName,
    );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 2)),
    );
  }
}

// ─── Region indicator at the top of the compare result panel ────────────────

class _CompareRegionRow extends StatelessWidget {
  const _CompareRegionRow({
    required this.city,
    required this.district,
    required this.onChange,
  });
  final String city;
  final String district;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onChange,
      borderRadius: FRRad.all(FRRad.l),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        decoration: frSurface(radius: FRRad.l),
        child: Row(
          children: [
            Icon(Icons.place_outlined, size: 18, color: FR.gold),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('KARŞILAŞTIRMA BÖLGESİ',
                      style: frOverline(color: FR.ink3, size: 9.5)),
                  const SizedBox(height: 2),
                  Text('$district / $city',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: frText(13.5, FontWeight.w800)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: FR.gold.withOpacity(.14),
                borderRadius: FRRad.all(999),
                border: Border.all(color: FR.gold.withOpacity(.4)),
              ),
              child: Text('Değiştir',
                  style: frText(11.5, FontWeight.w800, color: FR.gold)),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompareNoRegion extends StatelessWidget {
  const _CompareNoRegion({required this.onPick});
  final VoidCallback onPick;

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
                  colors: [FR.surfaceHi, FR.surfaceLo],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: FRRad.all(28),
                border: Border.all(color: FR.hairline),
              ),
              child: Icon(Icons.location_on_outlined, color: FR.gold, size: 40),
            ),
            const SizedBox(height: 16),
            Text('Bölgeni seç', style: frDisplay(22, FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              'Karşılaştırma için il ve ilçe gerekli — bölgendeki marketlerden gelen fiyatları kullanırız.',
              textAlign: TextAlign.center,
              style: frText(13, FontWeight.w600, color: FR.ink3, height: 1.5),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: 240,
              child: FRCta(
                label: 'İl / ilçe seç',
                icon: Icons.map_outlined,
                onTap: onPick,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Misafir kullanıcılara üst panelde kalan sepet karşılaştırma kotasını
/// gösteren küçük altın çubuk. Kalan azaldıkça uyarı tonuna geçer.
class _GuestQuotaPill extends StatelessWidget {
  const _GuestQuotaPill({required this.remaining, required this.limit});
  final int remaining;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final low = remaining <= 1;
    final color = low ? FR.warn : FR.gold;
    return InkWell(
      onTap: () => Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 4)),
      ),
      borderRadius: FRRad.all(FRRad.m),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: color.withOpacity(.10),
          borderRadius: FRRad.all(FRRad.m),
          border: Border.all(color: color.withOpacity(.35)),
        ),
        child: Row(
          children: [
            Icon(Icons.person_outline_rounded, size: 15, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                s.f('basket.guest.pill', {
                  'remaining': remaining,
                  'limit': limit,
                }),
                style: frText(11.5, FontWeight.w800, color: color),
              ),
            ),
            Icon(Icons.arrow_forward_rounded, size: 14, color: color),
          ],
        ),
      ),
    );
  }
}

/// Misafir kullanıcı sepet karşılaştırma kotasını tükettiğinde gösterilen
/// "üye ol ya da Pro al" ekranı. Anonymous kullanıcı için soft-paywall
/// gibi davranıyor; hesabı olan kullanıcılar bu ekrana hiç düşmez.
class _GuestLimitReached extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
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
                  colors: [FR.goldHi, FR.goldDeep],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: FRRad.all(28),
                boxShadow: frGoldGlow(opacity: .28),
              ),
              child: Icon(Icons.lock_outline_rounded,
                  color: FR.onGold, size: 40),
            ),
            const SizedBox(height: 16),
            Text(s.t('basket.guest.limitTitle'),
                style: frDisplay(22, FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              s.t('basket.guest.limitBody'),
              textAlign: TextAlign.center,
              style: frText(13, FontWeight.w600, color: FR.ink3, height: 1.5),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: 260,
              child: FRCta(
                label: s.t('basket.guest.signupCta'),
                icon: Icons.person_add_alt_1_rounded,
                onTap: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 4)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: 260,
              child: FRCta(
                label: s.t('basket.guest.proCta'),
                icon: Icons.workspace_premium_rounded,
                filled: false,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PaywallScreen()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompareLoading extends StatelessWidget {
  const _CompareLoading();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 14, 20, frBottomScrollPadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Region picker bar yer tutucusu.
          const FRSkeleton(height: 56, radius: 16),
          const SizedBox(height: 14),
          // Winner card hero yer tutucusu.
          const FRSkeleton(height: 220, radius: 28),
          const SizedBox(height: 16),
          // Mixed öneri kartı.
          const FRSkeleton(height: 130, radius: 22),
          const SizedBox(height: 22),
          // Tek market sıralaması (3 kart).
          const FRSkeletonList(count: 3, itemHeight: 100, radius: 16),
          const SizedBox(height: 14),
          Center(
            child: Text(
              'Bölgesel fiyatlar hesaplanıyor…',
              style: frText(12, FontWeight.w700, color: FR.ink3),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompareEmptyData extends StatelessWidget {
  const _CompareEmptyData({
    required this.city,
    required this.district,
    required this.onAddPrice,
    required this.onPickRegion,
  });
  final String city;
  final String district;
  final VoidCallback onAddPrice;
  final VoidCallback onPickRegion;

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
                  colors: [FR.surfaceHi, FR.surfaceLo],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: FRRad.all(28),
                border: Border.all(color: FR.hairline),
              ),
              child: Icon(Icons.insights_rounded, color: FR.gold, size: 40),
            ),
            const SizedBox(height: 16),
            Text('Henüz veri yok', style: frDisplay(22, FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              '$district / $city için sepet karşılaştırması yapacak kadar bildirilen fiyat bulamadık. İlk fiyatları sen ekleyebilirsin.',
              textAlign: TextAlign.center,
              style: frText(13, FontWeight.w600, color: FR.ink3, height: 1.5),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: 240,
              child: FRCta(
                label: 'Fiyat ekle',
                icon: Icons.add_rounded,
                onTap: onAddPrice,
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: onPickRegion,
              icon: Icon(Icons.map_outlined, size: 14, color: FR.goldDeep),
              label: Text('Bölgeyi değiştir',
                  style: frText(12, FontWeight.w800, color: FR.goldDeep)),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompareWinnerCard extends StatelessWidget {
  const _CompareWinnerCard({
    required this.estimate,
    required this.savingsVsWorst,
    required this.totalChains,
    required this.region,
    required this.onAddMissing,
  });
  final BasketStoreEstimate estimate;
  final double savingsVsWorst;
  final int totalChains;
  final String region;
  final VoidCallback onAddMissing;

  @override
  Widget build(BuildContext context) {
    final coverage = estimate.foundItemCount /
        ((estimate.foundItemCount + estimate.missingItemCount).clamp(1, 9999));
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
            top: -16,
            child: Icon(Icons.workspace_premium_rounded,
                size: 140, color: FR.gold.withOpacity(.07)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: FR.gold.withOpacity(.16),
                      borderRadius: FRRad.all(999),
                      border: Border.all(color: FR.gold.withOpacity(.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.workspace_premium_rounded,
                            size: 12, color: FR.gold),
                        const SizedBox(width: 6),
                        Text('EN İYİ SEÇENEK',
                            style: frText(10, FontWeight.w800,
                                color: FR.gold, letter: 1.2)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text('$totalChains market',
                      style: frText(11, FontWeight.w800, color: FR.ink3)),
                ],
              ),
              const SizedBox(height: 14),
              Text(estimate.chainName,
                  style: frDisplay(26, FontWeight.w700, height: 1.1)),
              const SizedBox(height: 4),
              Text(region,
                  style: frText(12, FontWeight.w700, color: FR.ink3)),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FRPriceText(estimate.estimatedTotal, size: 36, color: FR.gold),
                  const SizedBox(width: 10),
                  if (savingsVsWorst > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: FR.good.withOpacity(.16),
                          borderRadius: FRRad.all(999),
                          border: Border.all(color: FR.good.withOpacity(.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.trending_down_rounded,
                                size: 12, color: FR.good),
                            const SizedBox(width: 4),
                            Text(
                              '₺${savingsVsWorst.toStringAsFixed(0)} avantaj',
                              style: frText(11, FontWeight.w800, color: FR.good),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              _coverageBar(coverage.toDouble(), estimate),
              // Düşük kapsama uyarısı: kullanıcı %30 coverage'lı bir
              // marketin "EN İYİ SEÇENEK" olduğunu sanmasın.
              if (coverage < 0.7) ...[
                const SizedBox(height: 10),
                _warnRow(
                  icon: Icons.info_outline_rounded,
                  text: 'Bu marketin sepet kapsaması düşük — ${(coverage * 100).round()}% '
                      'ürün için fiyat var. Tutar yanıltıcı olabilir.',
                ),
              ],
              // Bayat fiyat uyarısı: en eski bildirim 30+ gün ise sinyal ver.
              if (estimate.isStale) ...[
                const SizedBox(height: 8),
                _warnRow(
                  icon: Icons.schedule_rounded,
                  text: 'En eski fiyat ${estimate.oldestPriceAgeDays} gün önce '
                      'bildirilmiş — gerçek raf fiyatı değişmiş olabilir.',
                ),
              ],
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetaPill(
                    icon: Icons.shield_outlined,
                    label: 'Güven · ${confidenceLabelTr(estimate.confidence)}',
                  ),
                  _MetaPill(
                    icon: Icons.bolt_rounded,
                    label: _sourceTr(estimate.usedPriceSource),
                  ),
                ],
              ),
              if (estimate.missingItemCount > 0) ...[
                const SizedBox(height: 14),
                FRCta(
                  label: 'Eksik fiyatları ekle',
                  icon: Icons.add_rounded,
                  filled: false,
                  onTap: onAddMissing,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _warnRow({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: FR.warn.withOpacity(.10),
        borderRadius: FRRad.all(10),
        border: Border.all(color: FR.warn.withOpacity(.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 13, color: FR.warn),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: frText(11, FontWeight.w700,
                    color: FR.ink2, height: 1.4)),
          ),
        ],
      ),
    );
  }

  Widget _coverageBar(double coverage, BasketStoreEstimate e) {
    final pct = (coverage * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('KAPSAMA', style: frOverline(color: FR.ink3, size: 9.5)),
            const Spacer(),
            Text('$pct% · ${e.foundItemCount}/${e.foundItemCount + e.missingItemCount} ürün',
                style: frText(11, FontWeight.w800, color: FR.ink2)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: FRRad.all(999),
          child: Stack(
            children: [
              Container(height: 6, color: FR.bgElev),
              FractionallySizedBox(
                widthFactor: coverage.clamp(0.0, 1.0),
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [FR.goldHi, FR.goldDeep]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompareMixedCard extends StatelessWidget {
  const _CompareMixedCard({
    required this.mixed,
    required this.saving,
    required this.bestSingle,
  });
  final BasketMixedEstimate mixed;
  final double saving;
  final String bestSingle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FR.surface,
        borderRadius: FRRad.all(FRRad.xl),
        border: Border.all(color: FR.good.withOpacity(.45)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: FR.good.withOpacity(.16),
              borderRadius: FRRad.all(14),
              border: Border.all(color: FR.good.withOpacity(.35)),
            ),
            child: Icon(Icons.alt_route_rounded, color: FR.good, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('KARMA SEPET', style: frOverline(color: FR.good, size: 9.5)),
                const SizedBox(height: 3),
                Text(
                  '${mixed.marketCount} markete bölünce ₺${saving.toStringAsFixed(0)} kazanç',
                  style: frText(13.5, FontWeight.w800, height: 1.3),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tahmini toplam ₺${mixed.estimatedTotal.toStringAsFixed(2)} · '
                  '${mixed.coveredItemCount}/${mixed.totalItemCount} ürün fiyatlandı',
                  style: frText(11.5, FontWeight.w700, color: FR.ink3, height: 1.3),
                ),
                if (mixed.hasMissingItems) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${mixed.missingProductIds.length} ürün için bölgesel fiyat yok; toplam eksik ürünlerden dolayı düşük görünebilir.',
                    style: frText(11, FontWeight.w800, color: FR.warn, height: 1.35),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Free kullanıcıya Mixed sepet kartının kilitli önizlemesi. Gerçek
/// dağılım sonuçları (market sayısı, kazanç, kapsama) Pro pitch'inin
/// ana satış metni; Free kullanıcıya leak ederse paywall kıymetsiz
/// kalır. Bu kart sayısal sonuçları gizler, sadece "ne kazanırsın"
/// hissini verir ve tıklanınca paywall'a götürür.
class _CompareMixedLockedCard extends StatelessWidget {
  const _CompareMixedLockedCard();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PaywallScreen()),
      ),
      borderRadius: FRRad.all(FRRad.xl),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [FR.goldHi.withOpacity(.16), FR.goldDeep.withOpacity(.06)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: FRRad.all(FRRad.xl),
          border: Border.all(color: FR.goldDeep.withOpacity(.45)),
          boxShadow: frGoldGlow(opacity: .14),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: FR.gold.withOpacity(.18),
                borderRadius: FRRad.all(14),
                border: Border.all(color: FR.gold.withOpacity(.45)),
              ),
              child: Icon(Icons.lock_outline_rounded, color: FR.gold, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('AKILLI DAĞILIM',
                          style: frOverline(color: FR.gold, size: 9.5)),
                      const SizedBox(width: 6),
                      const FRProBadge(compact: true),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sepetini birden fazla markete bölerek ortalama %15-25 tasarruf et.',
                    style: frText(13, FontWeight.w800, height: 1.35),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pro\'ya geç ve hangi marketten ne alacağını saniyede gör.',
                    style: frText(11.5, FontWeight.w700,
                        color: FR.ink3, height: 1.35),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded, size: 18, color: FR.gold),
          ],
        ),
      ),
    );
  }
}

/// Pro'ya yükseltme CTA'sı — akıllı sepet gibi Pro feature'larında non-Pro
/// kullanıcılara gösterilir. Tap → Paywall.
class _ProUpsellBanner extends StatelessWidget {
  const _ProUpsellBanner({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PaywallScreen()),
      ),
      borderRadius: FRRad.all(FRRad.l),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [FR.goldHi.withOpacity(.18), FR.goldDeep.withOpacity(.08)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: FRRad.all(FRRad.l),
          border: Border.all(color: FR.goldDeep.withOpacity(.4)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.workspace_premium_rounded, size: 20, color: FR.gold),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title,
                          style: frText(13, FontWeight.w800, color: FR.ink)),
                      const SizedBox(width: 6),
                      const FRProBadge(compact: true),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(body,
                      style: frText(12, FontWeight.w700,
                          color: FR.ink2, height: 1.45)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_rounded, size: 16, color: FR.gold),
          ],
        ),
      ),
    );
  }
}

class _CompareInsightBanner extends StatelessWidget {
  const _CompareInsightBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FR.bgElev,
        borderRadius: FRRad.all(FRRad.l),
        border: Border.all(color: FR.hairlineSoft),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline_rounded, size: 18, color: FR.goldDeep),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: frText(12, FontWeight.w700, color: FR.ink2, height: 1.5)),
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: FR.bgElev,
        borderRadius: FRRad.all(999),
        border: Border.all(color: FR.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: FR.ink2),
          const SizedBox(width: 5),
          Text(label, style: frText(10.5, FontWeight.w800, color: FR.ink2)),
        ],
      ),
    );
  }
}

String _sourceTr(String raw) {
  switch (raw) {
    case 'trustedPrice':
      return 'Güvenilir fiyat';
    case 'latestPrice':
      return 'Son bildirilen';
    case 'avgPrice':
      return 'Ortalama';
    case 'minPrice':
      return 'En düşük';
    default:
      return 'Veri yok';
  }
}

/// Single-market estimate row in the compare panel. Shows the chain, total,
/// rank, coverage indicator and an action to add missing prices.
class _SingleStoreCard extends StatelessWidget {
  const _SingleStoreCard({
    required this.estimate,
    required this.state,
    required this.rank,
    required this.isWinner,
  });

  final BasketStoreEstimate estimate;
  final AppState state;
  final int rank;
  final bool isWinner;

  void _addMissingPrices(BuildContext context) {
    if (estimate.missingProductIds.isEmpty) return;
    final firstId = estimate.missingProductIds.first;
    state.setAddPricePreset(
      productId: firstId,
      chainName: estimate.chainName,
    );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = estimate.foundItemCount + estimate.missingItemCount;
    final coverage = total == 0 ? 0.0 : estimate.foundItemCount / total;
    // Show every missing product name so the user can see exactly which
    // items aren't being included in this market's estimate — capping at
    // 2 made it look like only 1–2 products were ever being compared.
    final missing = estimate.missingProductIds
        .map((id) => state.findById(id)?.name)
        .whereType<String>()
        .toList();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FR.surface,
        borderRadius: FRRad.all(FRRad.l),
        border: Border.all(
          color: isWinner ? FR.gold.withOpacity(.55) : FR.hairline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isWinner ? FR.gold : FR.bgElev,
                  borderRadius: FRRad.all(10),
                  border: Border.all(
                      color: isWinner ? FR.gold : FR.hairline),
                ),
                child: Text(
                  '$rank',
                  style: frText(12, FontWeight.w800,
                      color: isWinner ? FR.onGold : FR.ink2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(estimate.chainName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: frText(13.5, FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(
                      '${estimate.foundItemCount}/$total ürün · ${confidenceLabelTr(estimate.confidence)} · ${_sourceTr(estimate.usedPriceSource)}',
                      style: frText(10.5, FontWeight.w700, color: FR.ink3),
                    ),
                  ],
                ),
              ),
              FRPriceText(estimate.estimatedTotal,
                  size: 17, color: isWinner ? FR.gold : FR.ink),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: FRRad.all(999),
            child: Stack(
              children: [
                Container(height: 5, color: FR.bgElev),
                FractionallySizedBox(
                  widthFactor: coverage.clamp(0.0, 1.0),
                  child: Container(
                    height: 5,
                    color: isWinner ? FR.gold : FR.goldDeep.withOpacity(.55),
                  ),
                ),
              ],
            ),
          ),
          if (missing.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.error_outline_rounded, size: 13, color: FR.warn),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Eksik · ${missing.join(', ')}',
                    style: frText(11, FontWeight.w700, color: FR.ink3),
                  ),
                ),
                TextButton(
                  onPressed: () => _addMissingPrices(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 28),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text('Ekle',
                      style: frText(11, FontWeight.w800, color: FR.goldDeep)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

