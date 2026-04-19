import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../../widgets/executive_ui.dart';
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
          const _PageHeader(
            overline: 'Radardaki ürünler',
            title: 'Keşfet',
            subtitle: 'Binlerce ürün, gerçek kullanıcıların eklediği güncel fiyatlarla.',
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(20, 22, 20, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            height: 54,
            decoration: execCard(radius: 20),
            child: Row(children: [
              const Icon(Icons.search, color: ExecColors.ink3),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  onChanged: (v) => setState(() => _q = v),
                  decoration: InputDecoration(
                    hintText: 'Ürün, marka veya mağaza ara…',
                    hintStyle: manrope(13, FontWeight.w600, color: ExecColors.ink4),
                    border: InputBorder.none,
                  ),
                ),
              ),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: ExecColors.bgSoft, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.tune_rounded, size: 18, color: ExecColors.ink3),
              )
            ]),
          ),
          SizedBox(
            height: 46,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              scrollDirection: Axis.horizontal,
              children: const [
                _Chip('Hepsi', true),
                _Chip('Popüler', false),
                _Chip('Ucuzlayanlar', false),
                _Chip('Yeni', false),
                _Chip('Yakınımda', false),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
              itemCount: filtered.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.66,
              ),
              itemBuilder: (_, i) {
                final p = filtered[i];
                return InkWell(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p))),
                  child: Container(
                    decoration: execCard(radius: 22),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(
                        height: 122,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF0EBE1),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                        ),
                        child: Stack(children: [
                          Center(child: Text(p.emoji, style: const TextStyle(fontSize: 44))),
                          Positioned(
                            right: 10,
                            top: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: ExecColors.successSoft, borderRadius: ExecRadii.pill),
                              child: Text('↓ %8', style: manrope(10, FontWeight.w800, color: ExecColors.success)),
                            ),
                          ),
                        ]),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(p.category.toUpperCase(), style: manrope(10, FontWeight.w800, color: ExecColors.ink3, letterSpacing: 1.2)),
                          const SizedBox(height: 4),
                          Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: manrope(13, FontWeight.w800)),
                          const SizedBox(height: 6),
                          Text('${(p.lowestPrice ?? 0).toStringAsFixed(0)} ₺', style: fraunces(24, FontWeight.w700)),
                          Text('${p.brand} · 2s', style: manrope(11, FontWeight.w600, color: ExecColors.ink3)),
                        ]),
                      )
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

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.overline, required this.title, required this.subtitle});
  final String overline;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(overline.toUpperCase(), style: manrope(10, FontWeight.w800, color: ExecColors.goldDeep, letterSpacing: 2.2)),
        const SizedBox(height: 6),
        Text(title, style: fraunces(44, FontWeight.w700)),
        const SizedBox(height: 4),
        Text(subtitle, style: manrope(13, FontWeight.w600, color: ExecColors.ink3)),
      ]),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.t, this.a);
  final String t;
  final bool a;
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: a ? ExecColors.espresso : ExecColors.surface,
          borderRadius: ExecRadii.pill,
          border: Border.all(color: a ? ExecColors.gold : ExecColors.bgDeep),
        ),
        child: Text(t, style: manrope(12, FontWeight.w700, color: a ? ExecColors.gold : ExecColors.ink2)),
      );
}
