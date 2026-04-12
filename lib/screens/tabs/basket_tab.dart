import 'package:flutter/material.dart';

import '../../widgets/prototype_ui.dart';

class BasketTab extends StatelessWidget {
  const BasketTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 16, 24, 12),
            child: Row(children: [
              Icon(Icons.arrow_back, size: 20),
              SizedBox(width: 12),
              Expanded(child: Text('Karşılaştırma', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
              SizedBox(width: 36),
            ]),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: FRRadii.xl,
                    border: Border.all(color: ProtoColors.tan.withOpacity(0.25)),
                    gradient: LinearGradient(colors: [ProtoColors.tan.withOpacity(0.08), ProtoColors.tan.withOpacity(0.02)]),
                  ),
                  child: const Column(children: [
                    Text('EN İYİ KOMBİNASYON', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ProtoColors.textSubtle)),
                    SizedBox(height: 8),
                    Text('₺3.847', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900)),
                    SizedBox(height: 12),
                    _SavingBadge(),
                    SizedBox(height: 8),
                    Text('3 platformdan 5 ürün', style: TextStyle(fontSize: 11, color: ProtoColors.textSubtle)),
                  ]),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  padding: const EdgeInsets.all(4),
                  decoration: protoSurface(radius: ProtoRadius.lg),
                  child: Row(children: const [
                    Expanded(child: _Toggle('En İyi Karışık', true, Icons.layers)),
                    Expanded(child: _Toggle('Tek Platform', false, Icons.store)),
                  ]),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text('↔ Platform Karşılaştırması', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: _Comparison(
                    icon: '🎧',
                    name: 'Sony WH-1000XM5',
                    price: '₺1.299',
                    rows: [
                      ('T', 'Trendyol', '₺1.299', 'En Ucuz', true),
                      ('H', 'Hepsiburada', '₺1.349', '+₺50', false),
                      ('A', 'Amazon', '₺1.399', '+₺100', false),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: _Comparison(
                    icon: '💪',
                    name: 'Protein Tozu',
                    price: '₺749',
                    rows: [
                      ('T', 'Trendyol', '₺749', 'En Ucuz', true),
                      ('H', 'Hepsiburada', '₺769', '+₺20', false),
                      ('A', 'Amazon', '₺799', '+₺50', false),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: ProtoColors.border),
                            shape: RoundedRectangleBorder(borderRadius: FRRadii.lg),
                          ),
                          icon: const Icon(Icons.share),
                          label: const Text('Listeyi Paylaş', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Fiyatlar platformlarda değişebilir. Son fiyatları platformda kontrol edin.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 10, color: ProtoColors.textSubtle, height: 1.45),
                      )
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _SavingBadge extends StatelessWidget {
  const _SavingBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: ProtoColors.success.withOpacity(0.12),
        border: Border.all(color: ProtoColors.success.withOpacity(0.3)),
        borderRadius: FRRadii.pill,
      ),
      child: const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.arrow_downward, size: 14, color: ProtoColors.success),
        SizedBox(width: 6),
        Text('₺452 tasarruf (%12)', style: TextStyle(fontSize: 12, color: ProtoColors.success, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle(this.t, this.a, this.icon);
  final String t;
  final bool a;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: BoxDecoration(color: a ? ProtoColors.tan : Colors.transparent, borderRadius: FRRadii.md),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 14, color: a ? ProtoColors.bgPrimary : ProtoColors.textSecondary),
        const SizedBox(width: 6),
        Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: a ? ProtoColors.bgPrimary : ProtoColors.textSecondary)),
      ]),
    );
  }
}

class _Comparison extends StatelessWidget {
  const _Comparison({required this.icon, required this.name, required this.price, required this.rows});
  final String icon;
  final String name;
  final String price;
  final List<(String, String, String, String, bool)> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: protoSurface(),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: const BoxDecoration(color: ProtoColors.surfaceAlt, borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
          child: Row(children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: ProtoColors.surfaceElevated, borderRadius: FRRadii.md), alignment: Alignment.center, child: Text(icon)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)), const Text('Adet: 1', style: TextStyle(fontSize: 10, color: ProtoColors.textSubtle))])),
            Text(price, style: const TextStyle(color: ProtoColors.success, fontSize: 16, fontWeight: FontWeight.w700)),
          ]),
        ),
        ...rows.map(
          (r) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: r.$5 ? ProtoColors.success.withOpacity(0.06) : null,
              border: Border(bottom: BorderSide(color: ProtoColors.borderLight)),
            ),
            child: Row(children: [
              Container(width: 28, height: 28, alignment: Alignment.center, decoration: BoxDecoration(color: ProtoColors.surfaceElevated, borderRadius: FRRadii.sm), child: Text(r.$1, style: const TextStyle(fontSize: 12, color: ProtoColors.tan, fontWeight: FontWeight.w700))),
              const SizedBox(width: 10),
              Expanded(child: Text(r.$2, style: const TextStyle(fontSize: 13, color: ProtoColors.textSecondary))),
              Text(r.$3, style: TextStyle(fontSize: 15, color: r.$5 ? ProtoColors.success : ProtoColors.textPrimary, fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: r.$5 ? ProtoColors.success.withOpacity(0.12) : Colors.transparent,
                  borderRadius: FRRadii.sm,
                ),
                child: Text(r.$4, style: TextStyle(fontSize: 9, color: r.$5 ? ProtoColors.success : ProtoColors.danger, fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
