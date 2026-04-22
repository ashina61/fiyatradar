import 'package:flutter/material.dart';

import '../ui/components.dart';
import '../ui/tokens.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int tab = 0;
  static const tabs = [
    'Panel',
    'Ürünler',
    'Talepler',
    'Fiyatlar',
    'Raporlar',
    'Banner',
    'Kullanıcılar',
    'Moderasyon',
    'Ayarlar',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FR.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  FRIconChip(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: FR.gold.withOpacity(.14),
                      borderRadius: FRRad.all(999),
                      border: Border.all(color: FR.goldDeep.withOpacity(.45)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const FRLiveDot(),
                        const SizedBox(width: 6),
                        Text('KONTROL CANLI',
                            style: frOverline(color: FR.gold, size: 9.5)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: FRPageHeader(
                overline: 'FİYATRADAR KONTROL MERKEZİ',
                title: 'Admin',
                italicTail: ' konsolu',
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 42,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: tabs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => _TabChip(
                  label: tabs[i],
                  active: tab == i,
                  onTap: () => setState(() => tab = i),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                children: [_buildTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab() {
    switch (tab) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _StatGrid(),
            const SizedBox(height: 18),
            const FRSectionHead(eyebrow: 'CANLI', title: 'Son aktivite'),
            const SizedBox(height: 10),
            _rowList(const [
              _Row(
                title: 'iPhone 15 Pro Max · MediaMarkt',
                subtitle: 'merve_k · 72.999 ₺ · 2 saat önce',
                icon: Icons.price_change_rounded,
                withActions: true,
              ),
              _Row(
                title: 'Yeni kullanıcı kaydı',
                subtitle: 'ayse_b · Kadıköy · 18 dakika önce',
                icon: Icons.person_add_alt_1_rounded,
                withActions: false,
              ),
              _Row(
                title: 'Kurukahveci M.E. 250g · CarrefourSA',
                subtitle: 'can_t · 189 ₺ · 36 dakika önce',
                icon: Icons.local_offer_rounded,
                withActions: true,
              ),
            ]),
          ],
        );
      case 1:
        return _rowList(const [
          _Row(
            title: 'iPhone 15 Pro Max 256GB',
            subtitle: '3 fiyat · 12 doğrulama',
            icon: Icons.smartphone_rounded,
            withActions: true,
          ),
          _Row(
            title: 'Samsung QLED 55" Q80C',
            subtitle: '2 fiyat · 8 doğrulama',
            icon: Icons.tv_rounded,
            withActions: true,
          ),
          _Row(
            title: 'Kurukahveci M.E. 250g',
            subtitle: '8 fiyat · 34 doğrulama',
            icon: Icons.coffee_rounded,
            withActions: true,
          ),
        ]);
      case 2:
        return _rowList(const [
          _Row(
            title: 'Samsung Galaxy S24 Ultra 512GB',
            subtitle: 'Bekleyen ürün talebi',
            icon: Icons.pending_actions_rounded,
            withActions: true,
          ),
          _Row(
            title: 'Dyson V15 Detect Absolute',
            subtitle: 'Bekleyen ürün talebi',
            icon: Icons.pending_actions_rounded,
            withActions: true,
          ),
          _Row(
            title: 'Lavazza Qualità Rossa 1kg',
            subtitle: 'Bekleyen ürün talebi',
            icon: Icons.pending_actions_rounded,
            withActions: true,
          ),
        ]);
      case 3:
        return _rowList(const [
          _Row(
            title: 'iPhone 15 Pro Max · MediaMarkt',
            subtitle: 'merve_k · 72.999 ₺',
            icon: Icons.receipt_long_rounded,
            withActions: true,
          ),
          _Row(
            title: 'Nike Air Force 1 · Sport Point',
            subtitle: 'emre_s · 3.499 ₺',
            icon: Icons.receipt_long_rounded,
            withActions: true,
          ),
          _Row(
            title: 'Bosch Serie 6 Bulaşık · Teknosa',
            subtitle: 'ece_a · 18.499 ₺',
            icon: Icons.receipt_long_rounded,
            withActions: true,
          ),
        ]);
      case 4:
        return _rowList(const [
          _Row(
            title: 'Şüpheli fiyat bildirimi',
            subtitle: '3 kullanıcı bildirdi · Samsung QLED',
            icon: Icons.report_gmailerrorred_rounded,
            withActions: true,
          ),
          _Row(
            title: 'Spam kullanıcı şüphesi',
            subtitle: 'kullanıcı_x · 48 saatte 156 fiyat',
            icon: Icons.report_gmailerrorred_rounded,
            withActions: true,
          ),
        ]);
      case 5:
        return _rowList(const [
          _Row(
            title: 'Ana banner aktif',
            subtitle: 'Haftanın fırsatları · 14 gün',
            icon: Icons.view_carousel_rounded,
            withActions: false,
          ),
          _Row(
            title: 'Kampanya kartı',
            subtitle: 'Doğrulanmış düşüşler · canlı',
            icon: Icons.campaign_rounded,
            withActions: false,
          ),
        ]);
      case 6:
        return _rowList(const [
          _Row(
            title: 'merve_k',
            subtitle: '2.450 PT · Güven %96 · 84 katkı',
            icon: Icons.person_rounded,
            withActions: false,
          ),
          _Row(
            title: 'emre_s',
            subtitle: '3.840 PT · Güven %94 · 127 katkı',
            icon: Icons.person_rounded,
            withActions: false,
          ),
          _Row(
            title: 'ece_a',
            subtitle: '1.620 PT · Güven %91 · 58 katkı',
            icon: Icons.person_rounded,
            withActions: false,
          ),
        ]);
      case 7:
        return _rowList(const [
          _Row(
            title: 'Şüpheli fiyat bildirimi',
            subtitle: '3 kullanıcı raporladı',
            icon: Icons.shield_outlined,
            withActions: true,
          ),
          _Row(
            title: 'Spam kullanıcı',
            subtitle: 'İnceleme bekliyor',
            icon: Icons.gpp_maybe_outlined,
            withActions: true,
          ),
        ]);
      default:
        return _rowList(const [
          _Row(
            title: 'Günlük onay limiti',
            subtitle: '500 fiyat / gün',
            icon: Icons.tune_rounded,
            withActions: false,
          ),
          _Row(
            title: 'Toplu bildirim saati',
            subtitle: '19:00 · Türkiye saati',
            icon: Icons.schedule_rounded,
            withActions: false,
          ),
          _Row(
            title: 'Doğrulama eşiği',
            subtitle: '3 kullanıcı onayı',
            icon: Icons.verified_rounded,
            withActions: false,
          ),
        ]);
    }
  }

  Widget _rowList(List<_Row> rows) {
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          rows[i],
          if (i < rows.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: FRRad.all(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: active ? FR.gold : FR.surface,
          borderRadius: FRRad.all(999),
          border: Border.all(color: active ? FR.gold : FR.hairline),
        ),
        child: Text(
          label,
          style: frText(12, FontWeight.w800,
              color: active ? FR.bg : FR.ink2, letter: .2),
        ),
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: const [
            Expanded(
                child: _StatCard(
                    value: '247',
                    label: 'BUGÜN ONAY',
                    delta: '+18%',
                    deltaGood: true)),
            SizedBox(width: 10),
            Expanded(
                child: _StatCard(
                    value: '12',
                    label: 'BEKLEYEN',
                    delta: 'acil',
                    deltaGood: false)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: const [
            Expanded(
                child: _StatCard(
                    value: '3.8K',
                    label: 'AKTİF KULLANICI',
                    delta: '+4%',
                    deltaGood: true)),
            SizedBox(width: 10),
            Expanded(
                child: _StatCard(
                    value: '%94',
                    label: 'GÜVEN SKORU',
                    delta: '+2',
                    deltaGood: true)),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.delta,
    required this.deltaGood,
  });
  final String value;
  final String label;
  final String delta;
  final bool deltaGood;

  @override
  Widget build(BuildContext context) {
    final deltaColor = deltaGood ? FR.good : FR.warn;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [FR.surfaceHi, FR.surfaceLo],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: FRRad.all(FRRad.l),
        border: Border.all(color: FR.goldDeep.withOpacity(.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: frOverline(color: FR.ink3, size: 9.5)),
          const SizedBox(height: 10),
          Text(value, style: frDisplay(28, FontWeight.w700)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: deltaColor.withOpacity(.14),
              borderRadius: FRRad.all(999),
              border: Border.all(color: deltaColor.withOpacity(.35)),
            ),
            child: Text(delta,
                style: frText(10.5, FontWeight.w800, color: deltaColor)),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.withActions,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final bool withActions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FR.surface,
        borderRadius: FRRad.all(FRRad.l),
        border: Border.all(color: FR.hairline),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: FR.surfaceHi,
              borderRadius: FRRad.all(12),
              border: Border.all(color: FR.hairline),
            ),
            child: Icon(icon, size: 17, color: FR.gold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: frText(13, FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: frText(11, FontWeight.w600, color: FR.ink3),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (withActions) ...[
            const SizedBox(width: 8),
            _ActBtn(icon: Icons.check_rounded, color: FR.good),
            const SizedBox(width: 6),
            _ActBtn(icon: Icons.close_rounded, color: FR.bad),
          ] else
            const Icon(Icons.chevron_right_rounded, color: FR.ink3),
        ],
      ),
    );
  }
}

class _ActBtn extends StatelessWidget {
  const _ActBtn({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withOpacity(.14),
        borderRadius: FRRad.all(10),
        border: Border.all(color: color.withOpacity(.4)),
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }
}
