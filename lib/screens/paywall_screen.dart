import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../services/premium_service.dart';
import '../state/app_state.dart';
import '../ui/components.dart';
import '../ui/tokens.dart';

/// FiyatRadar Pro paywall ekranı.
///
/// Akış:
///   1. PremiumService.availableProducts üzerinden aylık + yıllık fiyatları
///      göster (yerel para birimi otomatik). Play Console'da SKU yoksa
///      hard-coded fallback fiyat GÖSTERİLMEZ — bunun yerine skeleton
///      veya hata state'i çıkar (sahte fiyat göstermek kullanıcıyı
///      yanıltır).
///   2. Subscribe → in_app_purchase → Play Billing → purchaseStream →
///      PremiumService.enqueueForServerVerification → Cloud Function
///      doğrular → users/{uid}.isPremium = true.
///   3. AppState premium.isActive true olduğunda paywall otomatik
///      "Tebrikler" durumuna geçer.
///
/// Premium feature listesi: Akıllı sepet önerisi, geçmiş fiyat grafikleri,
/// sınırsız akıllı alarm, reklamsız deneyim, Pro rozeti + erken erişim.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _purchasing = false;
  String _selectedSku = PremiumService.yearlySku;

  bool get _isYearly => _selectedSku == PremiumService.yearlySku;

  @override
  void initState() {
    super.initState();
    // Eğer init() henüz çağrılmadıysa veya retry gerekiyorsa, paywall
    // açıldığında ürünleri tekrar yükle.
    final svc = PremiumService.instance;
    if (!svc.productsQueried && !svc.loadingProducts) {
      unawaited(svc.reloadProducts());
    }
  }

  Future<void> _purchase(ProductDetails p) async {
    debugPrint('🟢 PAYWALL TAP: _purchase(${p.id}) at ${DateTime.now()}');
    if (_purchasing) return;
    setState(() => _purchasing = true);
    try {
      final ok = await PremiumService.instance.purchase(p);
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Satın alma başlatılamadı. Play Store hesabını kontrol et.'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Doğrulanıyor… birkaç saniye sürebilir.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  Future<void> _onCtaTap() async {
    debugPrint('🟢 PAYWALL TAP: cta (Pro\'ya geç) at ${DateTime.now()}');
    final svc = PremiumService.instance;
    if (!svc.hasPurchasableProducts) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(svc.productsError ??
              'Mağaza bağlantısı hazır değil. Birkaç dakika sonra tekrar dene.'),
        ),
      );
      return;
    }
    final selected = svc.availableProducts.firstWhere(
      (p) => p.id == _selectedSku,
      orElse: () => svc.availableProducts.first,
    );
    await _purchase(selected);
  }

  Future<void> _restore() async {
    debugPrint('🟢 PAYWALL TAP: restore at ${DateTime.now()}');
    final svc = PremiumService.instance;
    // Mağaza bağlantısı kurulamadıysa kullanıcıya görünür feedback ver —
    // sessizce no-op olmasın (kullanıcı "buton dead" sanır).
    if (!svc.available) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(svc.productsError ??
              'Mağaza bağlantısı yok. Play Store hesabını kontrol et.'),
        ),
      );
      return;
    }
    try {
      await svc.restore();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Geri yükleme başlatıldı. Birkaç saniye bekle.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Geri yükleme hatası: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final premium = state.premium;
    final svc = PremiumService.instance;

    return Scaffold(
      backgroundColor: FR.bg,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: svc,
          builder: (context, _) {
            if (kDebugMode) {
              debugPrint(
                  'Paywall build: loading=${svc.loadingProducts} queried=${svc.productsQueried} '
                  'available=${svc.available} products=${svc.availableProducts.map((p) => "${p.id}=${p.price}").toList()} '
                  'error=${svc.productsError}');
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(children: [
                    FRIconChip(
                      icon: Icons.arrow_back_rounded,
                      onTap: () {
                        debugPrint(
                            '🟢 PAYWALL TAP: back at ${DateTime.now()}');
                        Navigator.pop(context);
                      },
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _restore,
                      child: Text('Restore',
                          style: frText(12, FontWeight.w800,
                              color: FR.gold)),
                    ),
                  ]),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
                    children: [
                      if (kDebugMode) ...[
                        _DebugStatePanel(svc: svc),
                        const SizedBox(height: 14),
                      ],
                      _Hero(active: premium.isActive),
                      if (premium.isActive) ...[
                        const SizedBox(height: 20),
                        _ActiveCard(premium: premium),
                      ] else ...[
                        const SizedBox(height: 24),
                        const _BenefitList(),
                        const SizedBox(height: 24),
                        _PlanToggle(
                          selectedSku: _selectedSku,
                          monthly: svc.monthlyProduct,
                          yearly: svc.yearlyProduct,
                          loading: svc.loadingProducts,
                          onSelect: (sku) =>
                              setState(() => _selectedSku = sku),
                        ),
                        if (svc.productsQueried &&
                            !svc.loadingProducts &&
                            !svc.hasPurchasableProducts) ...[
                          const SizedBox(height: 14),
                          _ProductsLoadError(
                            message: svc.productsError ??
                                'Mağaza bağlantısı şu an kullanılamıyor.',
                            onRetry: () {
                              debugPrint(
                                  '🟢 PAYWALL TAP: products retry at ${DateTime.now()}');
                              unawaited(svc.reloadProducts());
                            },
                          ),
                        ],
                        const SizedBox(height: 18),
                        FRCta(
                          label: _ctaLabel(svc),
                          icon: Icons.workspace_premium_rounded,
                          // TEMP debug, revert before merge: CTA'yı her durumda
                          // aktif tut ki disable mantığı bug'lı mı yoksa daha
                          // derin bir tap-eating overlay mi var anlayalım.
                          // _onCtaTap içindeki guard yine snackbar gösterecek.
                          onTap: _onCtaTap,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _isYearly
                              ? '7 gün sonra yıllık abonelik başlar. İstediğin zaman Play Store\'dan iptal edebilirsin.'
                              : 'Aboneliğin Play Store\'da yönetilir. İstediğin zaman iptal edebilirsin.',
                          textAlign: TextAlign.center,
                          style: frText(11, FontWeight.w600,
                              color: FR.ink3, height: 1.5),
                        ),
                        if (kDebugMode) ...[
                          const SizedBox(height: 24),
                          _DebugFakePurchase(state: state),
                        ],
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _ctaLabel(PremiumService svc) {
    if (_purchasing) return 'İşleniyor…';
    if (svc.loadingProducts) return 'Yükleniyor…';
    if (!svc.hasPurchasableProducts) return 'Mağaza hazır değil';
    return _isYearly ? '7 gün ücretsiz başla' : 'Pro\'ya geç';
  }

  bool _ctaEnabled(PremiumService svc) {
    if (_purchasing) return false;
    if (svc.loadingProducts) return false;
    if (!svc.hasPurchasableProducts) return false;
    return true;
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [FR.surfaceHi, FR.surfaceLo],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: FRRad.all(FRRad.xxl),
        border: Border.all(color: FR.goldDeep.withOpacity(.45)),
        boxShadow: frGoldGlow(opacity: .14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!active) ...[
            const _FreeTrialBadge(),
            const SizedBox(height: 14),
          ],
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [FR.goldHi, FR.goldDeep],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: FRRad.all(18),
            ),
            child: Icon(Icons.workspace_premium_rounded,
                color: FR.onGold, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            active ? 'FiyatRadar Pro · aktif' : 'FiyatRadar Pro',
            style: frDisplay(28, FontWeight.w800, height: 1.1),
          ),
          const SizedBox(height: 6),
          Text(
            active
                ? 'Premium özelliklerin senin için açık.'
                : 'Bölgenin gerçek fiyat zekâsı, derinlemesine.',
            style: frText(13, FontWeight.w600, color: FR.ink2, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _FreeTrialBadge extends StatelessWidget {
  const _FreeTrialBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: FR.gold.withOpacity(.16),
        borderRadius: FRRad.all(999),
        border: Border.all(color: FR.gold.withOpacity(.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_rounded, size: 14, color: FR.gold),
          const SizedBox(width: 6),
          Text('7 gün ücretsiz dene',
              style: frText(11, FontWeight.w800,
                  color: FR.gold, letter: 0.4)),
        ],
      ),
    );
  }
}

class _ActiveCard extends StatelessWidget {
  const _ActiveCard({required this.premium});
  final PremiumStatus premium;

  @override
  Widget build(BuildContext context) {
    final remaining = premium.remaining;
    final daysLeft = remaining?.inDays;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: frSurface(radius: FRRad.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.verified_rounded, color: FR.good, size: 18),
            const SizedBox(width: 8),
            Text(premium.planLabel,
                style: frText(14, FontWeight.w800, color: FR.good)),
          ]),
          const SizedBox(height: 10),
          if (daysLeft != null)
            Text('Yenileme: $daysLeft gün',
                style: frText(12, FontWeight.w700, color: FR.ink3))
          else
            Text('Aktif abonelik',
                style: frText(12, FontWeight.w700, color: FR.ink3)),
          const SizedBox(height: 12),
          Text(
            'Premium özellikler: akıllı sepet önerisi, geçmiş fiyat grafikleri, '
            'sınırsız akıllı alarm, reklamsız deneyim, Pro rozeti + erken erişim.',
            style: frText(12, FontWeight.w600,
                color: FR.ink2, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _BenefitList extends StatelessWidget {
  const _BenefitList();

  @override
  Widget build(BuildContext context) {
    const items = [
      (
        '🧠',
        'Akıllı sepet önerisi',
        'Sepetini birden fazla markete bölerek ortalama %15-25 tasarruf et.'
      ),
      (
        '📊',
        'Geçmiş fiyat grafikleri',
        '12 aya kadar fiyat geçmişi ve trend analizi.'
      ),
      (
        '🔔',
        'Sınırsız akıllı alarm',
        'Sınırsız ürün takibi + özel eşik (%X düşüş, Y₺ altı).'
      ),
      (
        '🚫',
        'Reklamsız deneyim',
        'Tüm bannerlar ve geçiş reklamları kapatılır.'
      ),
      (
        '⭐',
        'Pro rozeti + erken erişim',
        'Leaderboard\'da Pro etiketi, yeni özelliklere ilk erişim.'
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (it) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 32,
                    child: Text(it.$1,
                        style: const TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(it.$2,
                            style: frText(13, FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(it.$3,
                            style: frText(11.5, FontWeight.w600,
                                color: FR.ink3, height: 1.45)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

/// İki segmentli plan toggle'ı. Fiyatlar Play Console / App Store
/// Connect'ten gelen `ProductDetails.price` üzerinden lokalize gelir
/// (örn. "₺49,99", "$4.99", "€4,99"). Ürün henüz yüklenmediyse skeleton
/// gösterilir — sahte hard-coded fiyat KOYULMAZ.
class _PlanToggle extends StatelessWidget {
  const _PlanToggle({
    required this.selectedSku,
    required this.monthly,
    required this.yearly,
    required this.loading,
    required this.onSelect,
  });
  final String selectedSku;
  final ProductDetails? monthly;
  final ProductDetails? yearly;
  final bool loading;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: FR.surface,
        borderRadius: FRRad.all(FRRad.xl),
        border: Border.all(color: FR.hairline),
      ),
      child: Row(
        children: [
          Expanded(
            child: _PlanSegment(
              selected: selectedSku == PremiumService.monthlySku,
              title: 'Aylık',
              price: monthly?.price,
              loading: loading && monthly == null,
              subtitle: 'Her ay yenilenir',
              onTap: () {
                debugPrint(
                    '🟢 PAYWALL TAP: plan=monthly at ${DateTime.now()}');
                onSelect(PremiumService.monthlySku);
              },
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _PlanSegment(
              selected: selectedSku == PremiumService.yearlySku,
              title: 'Yıllık',
              price: yearly?.price,
              loading: loading && yearly == null,
              subtitle: '7 gün ücretsiz',
              badge: '%50 tasarruf',
              onTap: () {
                debugPrint(
                    '🟢 PAYWALL TAP: plan=yearly at ${DateTime.now()}');
                onSelect(PremiumService.yearlySku);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanSegment extends StatelessWidget {
  const _PlanSegment({
    required this.selected,
    required this.title,
    required this.price,
    required this.loading,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });
  final bool selected;
  final String title;

  /// `ProductDetails.price` (lokalize). `null` ise loading skeleton veya
  /// "—" placeholder gösterilir; sahte hard-coded fiyat KULLANILMAZ.
  final String? price;
  final bool loading;
  final String subtitle;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: FRRad.all(FRRad.l),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
        decoration: BoxDecoration(
          color: selected ? FR.gold.withOpacity(.14) : Colors.transparent,
          borderRadius: FRRad.all(FRRad.l),
          border: Border.all(
            color: selected ? FR.gold : Colors.transparent,
            width: selected ? 1.4 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(title,
                  style: frText(13.5, FontWeight.w800,
                      color: selected ? FR.ink : FR.ink2)),
              const Spacer(),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: FR.gold.withOpacity(.22),
                    borderRadius: FRRad.all(999),
                    border: Border.all(color: FR.gold.withOpacity(.5)),
                  ),
                  child: Text(badge!,
                      style: frText(9, FontWeight.w800,
                          color: FR.gold, letter: 0.6)),
                ),
            ]),
            const SizedBox(height: 8),
            if (price != null)
              Text(price!,
                  style:
                      frPrice(20, color: selected ? FR.gold : FR.ink))
            else if (loading)
              const FRSkeleton(width: 84, height: 22, radius: 6)
            else
              Text('—',
                  style: frPrice(20,
                      color: selected
                          ? FR.gold.withOpacity(.6)
                          : FR.ink3)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: frText(10.5, FontWeight.w600, color: FR.ink3)),
          ],
        ),
      ),
    );
  }
}

/// Debug-only fake purchase paneli. Release build'de tamamen render
/// edilmez (`kDebugMode` guard). In-memory `AppState.setMockPremium`
/// çağırır — Firestore'a yazılmaz, app restart'ında premium durumu
/// kaybolur. Cloud Function tabanlı gerçek doğrulama akışını bypass
/// etmek için sadece UI / gating testleri amacıyla kullanılır.
class _DebugFakePurchase extends StatelessWidget {
  const _DebugFakePurchase({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-09-30
      decoration: BoxDecoration(
        color: FR.surface,
        borderRadius: FRRad.all(FRRad.m),
        border: Border.all(color: FR.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('🧪', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            Text('DEBUG · in-memory test',
                style: frText(11, FontWeight.w800,
                    color: FR.ink2, letter: 0.4)),
          ]),
          const SizedBox(height: 4),
          Text(
            'Sadece debug build\'de görünür. Premium durumu hafızada açılır, '
            'Firestore\'a yazılmaz, uygulama restart\'ında kaybolur.',
            style: frText(10.5, FontWeight.w600,
                color: FR.ink3, height: 1.4),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _DebugButton(
                  label: 'Fake Pro · 1 ay',
                  onTap: () => _grant(
                    context,
                    duration: const Duration(days: 30),
                    plan: PremiumService.monthlySku,
                    label: 'Aylık',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DebugButton(
                  label: 'Fake Pro · 1 yıl',
                  onTap: () => _grant(
                    context,
                    duration: const Duration(days: 365),
                    plan: PremiumService.yearlySku,
                    label: 'Yıllık',
                  ),
                ),
              ),
            ],
          ),
          if (state.premium.isActive) ...[
            const SizedBox(height: 8),
            _DebugButton(
              label: 'Fake Pro kapat',
              onTap: () {
                debugPrint(
                    '🟢 PAYWALL TAP: debug fake-pro OFF at ${DateTime.now()}');
                state.setMockPremium(active: false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('🧪 Fake Pro kapatıldı (in-memory).')),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  void _grant(
    BuildContext context, {
    required Duration duration,
    required String plan,
    required String label,
  }) {
    debugPrint(
        '🟢 PAYWALL TAP: debug fake-pro ON plan=$plan at ${DateTime.now()}');
    state.setMockPremium(
      active: true,
      until: DateTime.now().add(duration),
      plan: plan,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('🧪 Fake Pro · $label açıldı (in-memory).')),
    );
  }
}

class _DebugButton extends StatelessWidget {
  const _DebugButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: FRRad.all(FRRad.m),
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: FR.bg,
          borderRadius: FRRad.all(FRRad.m),
          border: Border.all(color: FR.hairline),
        ),
        child: Text(label,
            style: frText(12, FontWeight.w800, color: FR.ink)),
      ),
    );
  }
}

/// Debug-only canlı state paneli. Paywall ekranındaki "buton dead" şüphelerini
/// hızla doğrulamak için PremiumService'in mevcut yükleme/error/SKU
/// snapshot'ını ekranın tepesinde gösterir. Release build'de hiç render
/// edilmez (kDebugMode guard).
class _DebugStatePanel extends StatelessWidget {
  const _DebugStatePanel({required this.svc});
  final PremiumService svc;

  @override
  Widget build(BuildContext context) {
    final monthly = svc.monthlyProduct?.price;
    final yearly = svc.yearlyProduct?.price;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: FR.surfaceLo,
        borderRadius: FRRad.all(FRRad.m),
        border: Border.all(color: FR.gold.withOpacity(.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🧪 DEBUG · paywall live state',
              style: frText(10, FontWeight.w800,
                  color: FR.gold, letter: 0.4)),
          const SizedBox(height: 6),
          Text('available: ${svc.available}',
              style: frText(11, FontWeight.w600, color: FR.ink2)),
          Text('loading: ${svc.loadingProducts}',
              style: frText(11, FontWeight.w600, color: FR.ink2)),
          Text('queried: ${svc.productsQueried}',
              style: frText(11, FontWeight.w600, color: FR.ink2)),
          Text('hasProducts: ${svc.hasPurchasableProducts}',
              style: frText(11, FontWeight.w600, color: FR.ink2)),
          Text('monthly: ${monthly ?? "null"}',
              style: frText(11, FontWeight.w600, color: FR.ink2)),
          Text('yearly: ${yearly ?? "null"}',
              style: frText(11, FontWeight.w600, color: FR.ink2)),
          Text('error: ${svc.productsError ?? "none"}',
              style: frText(11, FontWeight.w600, color: FR.ink2)),
        ],
      ),
    );
  }
}

/// Ürün listesi yüklenemediğinde gösterilen uyarı + retry kartı. Mağaza
/// mevcut değilse veya SKU'lar Play Console'da yayında değilse buraya
/// düşülür.
class _ProductsLoadError extends StatelessWidget {
  const _ProductsLoadError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FR.warn.withOpacity(.10),
        borderRadius: FRRad.all(FRRad.m),
        border: Border.all(color: FR.warn.withOpacity(.35)),
      ),
      child: Row(children: [
        Icon(Icons.info_outline_rounded, color: FR.warn, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: frText(11.5, FontWeight.w700,
                color: FR.ink2, height: 1.45),
          ),
        ),
        const SizedBox(width: 10),
        TextButton(
          onPressed: onRetry,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            minimumSize: const Size(0, 32),
          ),
          child: Text('Tekrar dene',
              style: frText(12, FontWeight.w800, color: FR.gold)),
        ),
      ]),
    );
  }
}

