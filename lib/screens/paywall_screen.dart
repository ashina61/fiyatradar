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
///      paywall yine hard-coded fiyatlarla render edilir — RevenueCat
///      entegrasyonu eklendiğinde fiyatlar mağazadan dinamik çekilecek.
///   2. Subscribe → in_app_purchase → Play Billing → purchaseStream →
///      PremiumService.enqueueForServerVerification → Cloud Function
///      doğrular → users/{uid}.isPremium = true.
///   3. AppState premium.isActive true olduğunda paywall otomatik
///      "Tebrikler" durumuna geçer (StreamBuilder ile).
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

  Future<void> _purchase(ProductDetails p) async {
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
    final svc = PremiumService.instance;
    if (!svc.available || svc.availableProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
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
    try {
      await PremiumService.instance.restore();
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
    final available = PremiumService.instance.available;

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
                const Spacer(),
                TextButton(
                  onPressed: _restore,
                  child: Text('Restore',
                      style:
                          frText(12, FontWeight.w800, color: FR.gold)),
                ),
              ]),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
                children: [
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
                      onSelect: (sku) =>
                          setState(() => _selectedSku = sku),
                    ),
                    if (!available) ...[
                      const SizedBox(height: 14),
                      _StoreUnavailable(),
                    ],
                    const SizedBox(height: 18),
                    FRCta(
                      label: _purchasing
                          ? 'İşleniyor…'
                          : (_isYearly
                              ? '7 gün ücretsiz başla'
                              : 'Pro\'ya geç'),
                      icon: Icons.workspace_premium_rounded,
                      onTap: _purchasing ? null : _onCtaTap,
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

/// İki segmentli plan toggle'ı. Fiyatlar şimdilik hard-coded —
/// RevenueCat entegrasyonu eklendiğinde dinamik fiyat çekme buraya
/// bağlanacak (PremiumService.availableProducts üzerinden).
class _PlanToggle extends StatelessWidget {
  const _PlanToggle({
    required this.selectedSku,
    required this.onSelect,
  });
  final String selectedSku;
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
              price: '49,99₺',
              subtitle: 'Her ay yenilenir',
              onTap: () => onSelect(PremiumService.monthlySku),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _PlanSegment(
              selected: selectedSku == PremiumService.yearlySku,
              title: 'Yıllık',
              price: '299,99₺',
              subtitle: '7 gün ücretsiz',
              badge: '%50 tasarruf',
              onTap: () => onSelect(PremiumService.yearlySku),
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
    required this.subtitle,
    required this.onTap,
    this.badge,
  });
  final bool selected;
  final String title;
  final String price;
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
            Text(price,
                style:
                    frPrice(20, color: selected ? FR.gold : FR.ink)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: frText(10.5, FontWeight.w600, color: FR.ink3)),
          ],
        ),
      ),
    );
  }
}

class _StoreUnavailable extends StatelessWidget {
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
            'Mağaza bağlantısı şu an kullanılamıyor. '
            'Play Store hesabını kontrol et veya birkaç dakika sonra tekrar dene.',
            style: frText(11.5, FontWeight.w700,
                color: FR.ink2, height: 1.45),
          ),
        ),
      ]),
    );
  }
}
