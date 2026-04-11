import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../../widgets/prototype_ui.dart';
import '../product_detail_screen.dart';

class ExploreTab extends StatefulWidget {
  const ExploreTab({super.key});

  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final filtered = state.products.where((e) => e.name.toLowerCase().contains(_q.toLowerCase())).toList();

    return SafeArea(
      child: Column(
        children: [
          const ProtoTopBar(title: 'Ara'),
          ProtoSearchField(hint: 'Ürün, marka, platform', onChanged: (v) => setState(() => _q = v)),
          SizedBox(
            height: 34,
            child: ListView(
              padding: FRInsets.horizontalPage,
              scrollDirection: Axis.horizontal,
              children: const [_Fx('Tümü', true), _Fx('Elektronik', false), _Fx('Gıda', false), _Fx('Bakım', false)],
            ),
          ),
          Padding(
            padding: FRInsets.pageHeader,
            child: Row(
              children: [
                Text('${filtered.length}', style: const TextStyle(color: ProtoColors.tan, fontWeight: FontWeight.w700)),
                const Text(' sonuç', style: TextStyle(color: ProtoColors.textSubtle, fontSize: 12)),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: FRInsets.page,
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final p = filtered[i];
                return InkWell(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p))),
                  child: ProtoCard(
                    child: Row(children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(color: ProtoColors.surfaceAlt, borderRadius: FRRadii.md),
                        alignment: Alignment.center,
                        child: Text(p.emoji, style: const TextStyle(fontSize: 24)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text(p.brand, style: const TextStyle(color: ProtoColors.textSubtle, fontSize: 11)),
                        ]),
                      ),
                      Text('₺${(p.lowestPrice ?? 0).toStringAsFixed(0)}', style: const TextStyle(color: ProtoColors.tan, fontWeight: FontWeight.w800)),
                    ]),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

class _Fx extends StatelessWidget {
  const _Fx(this.t, this.a);
  final String t;
  final bool a;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: FRInsets.rightGapS,
      padding: FRInsets.horizontalM,
      decoration: BoxDecoration(
        color: a ? ProtoColors.tan : ProtoColors.surface,
        borderRadius: FRRadii.pill,
        border: Border.all(color: a ? ProtoColors.tan : ProtoColors.border),
      ),
      alignment: Alignment.center,
      child: Text(t, style: TextStyle(fontSize: 12, color: a ? ProtoColors.bgPrimary : ProtoColors.textSecondary, fontWeight: FontWeight.w600)),
    );
  }
}
