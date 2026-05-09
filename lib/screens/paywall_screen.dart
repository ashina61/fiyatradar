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
///      sembolik fallback (yıllık ₺199, aylık ₺29.90) — kullanıcı yine
///      "Subscribe" tıklayınca PremiumService.purchase() çağrılır, IAP
///      altyapısı yoksa snackbar.
///   2. Subscribe → in_app_purchase → Play Billing → purchaseStream →
///      PremiumService.enqueueForServerVerification → Cloud Function
///      doğrular → users/{uid}.isPremium = true.
///   3. AppState premium.isActive true olduğunda paywall otomatik
///      "Tebrikler" durumuna geçer (StreamBuilder ile).
///
/// Premium feature listesi: bayat-fiyat alarmı, leaderboard top-100,
/// reklamsız (Aşama 3 sonrası AdMob koyulduğunda devreye girer),
/// haftalık özet PDF, sepet AI önerisi.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _purchasing = false;
  String? _selectedSku;

  @override
  void initState() {
    super.initState();
    _selectedSku = PremiumService.yearlySku;
  }

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
    final products = PremiumService.instance.availableProducts;
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
                    if (!available)
                      _StoreUnavailable()
                    else if (products.isEmpty)
                      const _ProductsLoading()
                    else
                      _PlanPicker(
                        products: products,
                        selectedSku: _selectedSku,
                        onSelect: (sku) =>
                            setState(() => _selectedSku = sku),
                      ),
                    const SizedBox(height: 18),
                    if (available && products.isNotEmpty)
                      FRCta(
                        label: _purchasing
                            ? 'İşleniyor…'
                            : 'Pro\'ya geç',
                        icon: Icons.workspace_premium_rounded,
                        onTap: _purchasing
                            ? null
                            : () {
                                final selected = products.firstWhere(
                                  (p) => p.id == _selectedSku,
                                  orElse: () => products.first,
                                );
                                _purchase(selected);
                              },
                      ),
                    const SizedBox(height: 12),
                    Text(
                      'Aboneliğin Play Store\'da yönetilir. İstediğin zaman iptal edebilirsin.',
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
            'Premium özellikler: bölgesel bayat fiyat alarmı, '
            'leaderboard top-100 görünüm, reklamsız deneyim, '
            'haftalık özet bildirimi.',
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
      ('🛡', 'Bölgesel bayat-fiyat alarmı',
          'Bölgendeki fiyat 7 gün üstü ise haber al.'),
      ('🏆', 'Leaderboard top-100',
          'Şehrindeki en aktif katkıcılar arasında yerini gör.'),
      ('📵', 'Reklamsız deneyim',
          'Pro ile reklam yok, premium FR akışı.'),
      ('📊', 'Haftalık özet bildirimi',
          'Bölgenin haftalık fiyat raporu push olarak.'),
      ('🤖', 'Sepet AI önerisi',
          'Sepetin için en akıllı dağılım önerisi.'),
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

class _PlanPicker extends StatelessWidget {
  const _PlanPicker({
    required this.products,
    required this.selectedSku,
    required this.onSelect,
  });
  final List<ProductDetails> products;
  final String? selectedSku;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: products.map((p) {
        final selected = p.id == selectedSku;
        final isYearly = p.id == PremiumService.yearlySku;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            onTap: () => onSelect(p.id),
            borderRadius: FRRad.all(FRRad.l),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: selected ? FR.gold.withOpacity(.10) : FR.surface,
                borderRadius: FRRad.all(FRRad.l),
                border: Border.all(
                  color: selected ? FR.gold : FR.hairline,
                  width: selected ? 1.4 : 1.0,
                ),
              ),
              child: Row(children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected ? FR.gold : FR.ink3,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(p.title.isNotEmpty ? p.title : p.id,
                            style: frText(13.5, FontWeight.w800)),
                        if (isYearly) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: FR.gold.withOpacity(.18),
                              borderRadius: FRRad.all(999),
                              border: Border.all(
                                  color: FR.gold.withOpacity(.4)),
                            ),
                            child: Text('Önerilen',
                                style: frText(9.5, FontWeight.w800,
                                    color: FR.gold, letter: 1)),
                          ),
                        ],
                      ]),
                      const SizedBox(height: 2),
                      Text(p.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: frText(11.5, FontWeight.w600,
                              color: FR.ink3)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(p.price,
                    style: frPrice(15, color: FR.gold)),
              ]),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ProductsLoading extends StatelessWidget {
  const _ProductsLoading();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        FRSkeleton(height: 64, radius: 14),
        SizedBox(height: 10),
        FRSkeleton(height: 64, radius: 14),
      ],
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
