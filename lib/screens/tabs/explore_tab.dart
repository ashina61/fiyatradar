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
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final products = state.products.where((p) => p.name.toLowerCase().contains(_query.toLowerCase())).toList();

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Radardaki ürünler'.toUpperCase(), style: manrope(10, FontWeight.w800, color: ExecColors.goldDeep, letterSpacing: 2.2)), const SizedBox(height: 6), Text('Keşfet', style: fraunces(44, FontWeight.w700)), const SizedBox(height: 4), Text('Binlerce ürün, gerçek kullanıcıların eklediği güncel fiyatlarla.', style: manrope(13, FontWeight.w600, color: ExecColors.ink3))]),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(20, 22, 20, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            height: 54,
            decoration: execCard(radius: 20),
            child: Row(children: [const Icon(Icons.search_rounded, color: ExecColors.ink3), const SizedBox(width: 10), Expanded(child: TextField(controller: _controller, onChanged: (v) => setState(() => _query = v), decoration: InputDecoration(border: InputBorder.none, hintText: 'Ürün, marka veya mağaza ara…', hintStyle: manrope(13, FontWeight.w600, color: ExecColors.ink4)))), Container(width: 34, height: 34, decoration: BoxDecoration(color: ExecColors.bgSoft, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.tune_rounded, size: 18, color: ExecColors.ink3))]),
          ),
          SizedBox(
            height: 46,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              scrollDirection: Axis.horizontal,
              children: const [_FilterChip('Hepsi', true), _FilterChip('Popüler', false), _FilterChip('Ucuzlayanlar', false), _FilterChip('Yeni', false), _FilterChip('Yakınımda', false)],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 120),
              itemCount: products.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: .68),
              itemBuilder: (_, i) {
                final p = products[i];
                final fav = state.isFavorite(p.id);
                return InkWell(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p))),
                  child: Container(
                    decoration: execCard(radius: 22),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(
                        height: 118,
                        decoration: const BoxDecoration(color: Color(0xFFF0EBE1), borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
                        child: Stack(children: [Center(child: Text(p.emoji, style: const TextStyle(fontSize: 44))), Positioned(right: 8, top: 8, child: InkWell(onTap: () => state.toggleFavorite(p.id), child: Icon(fav ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: fav ? ExecColors.danger : ExecColors.ink3))), Positioned(left: 8, bottom: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: ExecColors.successSoft, borderRadius: BorderRadius.circular(99)), child: Text('↓ %8', style: manrope(10, FontWeight.w800, color: ExecColors.success))))]),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(p.category.toUpperCase(), style: manrope(10, FontWeight.w800, color: ExecColors.ink3, letterSpacing: 1.2)), const SizedBox(height: 4), Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: manrope(12, FontWeight.w800)), const SizedBox(height: 6), Text('${(p.lowestPrice ?? 0).toStringAsFixed(0)} ₺', style: fraunces(22, FontWeight.w700)), Text('${p.brand} · 2s', style: manrope(11, FontWeight.w600, color: ExecColors.ink3))]),
                      )
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

class _FilterChip extends StatelessWidget {
  const _FilterChip(this.label, this.active);
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: active ? ExecColors.espresso : ExecColors.surface, borderRadius: ExecRadii.pill, border: Border.all(color: active ? ExecColors.gold : ExecColors.bgDeep)),
        child: Text(label, style: manrope(12, FontWeight.w700, color: active ? ExecColors.gold : ExecColors.ink2)),
      );
}
