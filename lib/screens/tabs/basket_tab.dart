import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../../widgets/prototype_ui.dart';

class BasketTab extends StatelessWidget {
  const BasketTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final items = state.cart;
    return SafeArea(
      child: Column(
        children: [
          const ProtoTopBar(title: 'Karşılaştırma'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: ProtoColors.tan.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(ProtoRadius.xl),
                    border: Border.all(color: ProtoColors.tan.withOpacity(0.3)),
                  ),
                  child: Column(children: const [
                    Text('EN İYİ KOMBİNASYON', style: TextStyle(fontSize: 11, color: ProtoColors.textSubtle, fontWeight: FontWeight.w600)),
                    SizedBox(height: 8),
                    Text('₺3.847', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900)),
                  ]),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: protoSurface(radius: ProtoRadius.lg),
                  child: Row(children: const [
                    Expanded(child: _Toggle('En İyi Karışık', true)),
                    Expanded(child: _Toggle('Tek Platform', false)),
                  ]),
                ),
                const SizedBox(height: 16),
                const ProtoSectionHeader('Platform Karşılaştırması'),
                const SizedBox(height: 10),
                if (items.isEmpty)
                  const ProtoCard(child: Text('Sepet boş. Keşfet ekranından ürün ekleyin.')),
                ...items.map((item) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: protoSurface(),
                      child: Column(children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: ProtoColors.surfaceAlt,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                          ),
                          child: Row(children: [
                            Text(item.product.emoji, style: const TextStyle(fontSize: 22)),
                            const SizedBox(width: 10),
                            Expanded(child: Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.w700))),
                            Text('₺${(item.product.lowestPrice ?? 0).toStringAsFixed(0)}', style: const TextStyle(color: ProtoColors.success, fontWeight: FontWeight.w700)),
                          ]),
                        ),
                        ...['A101', 'BİM', 'Migros'].asMap().entries.map((e) {
                          final best = e.key == 0;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            color: best ? ProtoColors.success.withOpacity(0.08) : null,
                            child: Row(children: [
                              CircleAvatar(radius: 12, backgroundColor: ProtoColors.surfaceElevated, child: Text(e.value[0], style: const TextStyle(fontSize: 11, color: ProtoColors.tan))),
                              const SizedBox(width: 8),
                              Expanded(child: Text(e.value, style: const TextStyle(color: ProtoColors.textSecondary))),
                              Text('₺${((item.product.lowestPrice ?? 0) + e.key * 10).toStringAsFixed(0)}'),
                            ]),
                          );
                        }),
                      ]),
                    )),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle(this.t, this.a);
  final String t;
  final bool a;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: a ? ProtoColors.tan : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: a ? ProtoColors.bgPrimary : ProtoColors.textSecondary)),
    );
  }
}
