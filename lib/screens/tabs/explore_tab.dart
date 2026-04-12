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
  final TextEditingController _ctrl = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final filtered = state.products.where((e) => e.name.toLowerCase().contains(_q.toLowerCase())).toList();

    return SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 16, 24, 12),
            child: Row(children: [
              Icon(Icons.arrow_back, size: 20),
              SizedBox(width: 12),
              Expanded(child: Text('Ara', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
              SizedBox(width: 36),
            ]),
          ),
          Container(
            margin: FRInsets.searchWrap,
            padding: FRInsets.searchContent,
            decoration: protoSurface(),
            child: Row(
              children: [
                const Icon(Icons.search, color: ProtoColors.tan),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    onChanged: (v) => setState(() => _q = v),
                    style: const TextStyle(color: ProtoColors.textPrimary),
                    decoration: const InputDecoration.collapsed(
                      hintText: 'Ürün, marka, platform',
                      hintStyle: TextStyle(color: ProtoColors.textSubtle),
                    ),
                  ),
                ),
                if (_q.isNotEmpty)
                  InkWell(
                    onTap: () {
                      _ctrl.clear();
                      setState(() => _q = '');
                    },
                    child: const Icon(Icons.close, color: ProtoColors.textSubtle, size: 18),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: 34,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              scrollDirection: Axis.horizontal,
              children: const [_Fx('Tümü', true), _Fx('Elektronik', false), _Fx('Gıda', false), _Fx('Bakım', false)],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 10),
            child: Row(children: [
              Text('${filtered.length}', style: const TextStyle(fontSize: 12, color: ProtoColors.tan, fontWeight: FontWeight.w700)),
              const Text(' sonuç', style: TextStyle(fontSize: 12, color: ProtoColors.textSubtle)),
            ]),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 95),
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
                          Text(p.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text('${p.brand} • ${p.category}', style: const TextStyle(fontSize: 11, color: ProtoColors.textSubtle)),
                          const SizedBox(height: 4),
                          const Text('2 dk önce güncellendi', style: TextStyle(fontSize: 10, color: ProtoColors.textSubtle)),
                        ]),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('₺${(p.lowestPrice ?? 0).toStringAsFixed(0)}', style: const TextStyle(fontSize: 15, color: ProtoColors.tan, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          const Text('-12%', style: TextStyle(fontSize: 10, color: ProtoColors.success, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ]),
                  ),
                );
              },
            ),
          ),
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
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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
