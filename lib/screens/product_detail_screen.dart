import 'package:flutter/material.dart';

import '../models/product.dart';
import 'main_screen.dart';
import '../state/app_state.dart';
import '../widgets/prototype_ui.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key, required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final isFav = state.isFavorite(product.id);
    return Scaffold(
      appBar: AppBar(title: const Text('Ürün Detayı')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: FRInsets.pageBody,
              children: [
                Container(
                  padding: FRInsets.card22,
                  decoration: protoSurface(radius: ProtoRadius.xxl),
                  child: Column(children: [
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [ProtoColors.surface, ProtoColors.surfaceAlt]),
                        borderRadius: FRRadii.xxl,
                      ),
                      alignment: Alignment.center,
                      child: Text(product.emoji, style: const TextStyle(fontSize: 70)),
                    ),
                    const SizedBox(height: 12),
                    Text(product.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(product.brand, style: const TextStyle(color: ProtoColors.textSubtle)),
                  ]),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: FRInsets.cardXl,
                  decoration: BoxDecoration(
                    color: ProtoColors.surfaceAlt,
                    borderRadius: FRRadii.all(18),
                    border: Border.all(color: ProtoColors.tan.withOpacity(0.3)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('EN İYİ FİYAT', style: TextStyle(fontSize: 11, color: ProtoColors.textSubtle)),
                    const SizedBox(height: 6),
                    Text('₺${(product.lowestPrice ?? 0).toStringAsFixed(2)}', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: ProtoColors.tan)),
                    Text(product.cheapestStore ?? '-', style: const TextStyle(color: ProtoColors.textSecondary)),
                  ]),
                ),
                const SizedBox(height: 14),
                const ProtoCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Güven Analizi', style: TextStyle(fontWeight: FontWeight.w700)),
                    SizedBox(height: 8),
                    Text('94% Güvenilir • Topluluk onayı güçlü', style: TextStyle(fontSize: 12, color: ProtoColors.textSecondary)),
                  ]),
                ),
                const SizedBox(height: 12),
                const ProtoCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Fiyat Doğrulama', style: TextStyle(fontWeight: FontWeight.w700)),
                    SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: _VoteBtn('Doğru', ProtoColors.success)),
                      SizedBox(width: 8),
                      Expanded(child: _VoteBtn('Yanlış', ProtoColors.danger)),
                    ])
                  ]),
                ),
              ],
            ),
          ),
          Container(
            padding: FRInsets.pageFooter,
            child: Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => state.toggleFavorite(product.id),
                  icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
                  label: const Text('Listeye Ekle'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 2)),
                  ),
                  style: FilledButton.styleFrom(backgroundColor: ProtoColors.tan, foregroundColor: ProtoColors.bgPrimary),
                  icon: const Icon(Icons.add),
                  label: const Text('Fiyat Ekle'),
                ),
              ),
            ]),
          )
        ],
      ),
    );
  }
}

class _VoteBtn extends StatelessWidget {
  const _VoteBtn(this.t, this.c);
  final String t;
  final Color c;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(color: c.withOpacity(0.14), borderRadius: FRRadii.md, border: Border.all(color: c.withOpacity(0.4))),
      alignment: Alignment.center,
      child: Text(t, style: TextStyle(color: c, fontWeight: FontWeight.w700)),
    );
  }
}
