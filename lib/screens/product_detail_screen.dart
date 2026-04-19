import 'package:flutter/material.dart';

import '../models/product.dart';
import '../state/app_state.dart';
import '../widgets/executive_ui.dart';
import 'main_screen.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key, required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final isFav = state.isFavorite(product.id);
    final entries = product.priceHistory.reversed.take(3).toList();

    return Scaffold(
      backgroundColor: ExecColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Row(children: [_ic(Icons.arrow_back_rounded, onTap: () => Navigator.pop(context)), const Spacer(), _ic(Icons.notifications_none_rounded), const SizedBox(width: 8), _ic(isFav ? Icons.favorite_rounded : Icons.favorite_border, onTap: () => state.toggleFavorite(product.id), active: isFav), const SizedBox(width: 8), _ic(Icons.share_outlined)]),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
                children: [
                  Container(
                    height: 210,
                    decoration: BoxDecoration(borderRadius: ExecRadii.xl, gradient: const LinearGradient(colors: [ExecColors.espresso2, ExecColors.espresso])),
                    child: Stack(children: [Positioned(top: 12, left: 12, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: const Color(0x26C9A063), borderRadius: ExecRadii.pill), child: Text('Admin Onaylı', style: manrope(11, FontWeight.w800, color: ExecColors.gold))),), Center(child: Text(product.emoji, style: const TextStyle(fontSize: 90))),]),
                  ),
                  const SizedBox(height: 16),
                  Text('${product.category.toUpperCase()} · ${product.brand.toUpperCase()}', style: manrope(10, FontWeight.w800, color: ExecColors.ink3, letterSpacing: 1.8)),
                  const SizedBox(height: 4),
                  Text(product.name, style: fraunces(34, FontWeight.w700)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: execCard(radius: 20),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Bölgendeki En İyi Fiyat', style: manrope(10, FontWeight.w800, color: ExecColors.goldDeep, letterSpacing: 1.6)), const SizedBox(height: 8), Text('${(product.lowestPrice ?? 0).toStringAsFixed(0)} ₺', style: fraunces(38, FontWeight.w700)), Text('MediaMarkt · Kadıköy · 1,2 km', style: manrope(12, FontWeight.w600, color: ExecColors.ink3)), const SizedBox(height: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: ExecColors.successSoft, borderRadius: ExecRadii.pill), child: Text('↓ %8,2 · Son 30 gün', style: manrope(11, FontWeight.w800, color: ExecColors.success)))]),
                  ),
                  const SizedBox(height: 14),
                  Text('Kadıköy Bölgesi · Son 24 saat', style: manrope(11, FontWeight.w800, color: ExecColors.ink3, letterSpacing: 1.2)),
                  const SizedBox(height: 10),
                  ...entries.map((e) => _entry(e.reportedBy, e.store, e.price, '${DateTime.now().difference(e.date).inHours} saat önce')),
                ],
              ),
            ),
            Container(
              color: ExecColors.bg,
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Row(children: [Expanded(child: OutlinedButton.icon(onPressed: () {}, style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: ExecRadii.pill), side: const BorderSide(color: ExecColors.bgDeep), padding: const EdgeInsets.symmetric(vertical: 14)), icon: const Icon(Icons.notifications_none, color: ExecColors.ink2), label: Text('Alarm', style: manrope(13, FontWeight.w800, color: ExecColors.ink2)))), const SizedBox(width: 10), Expanded(child: ElevatedButton.icon(onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 2))), style: ElevatedButton.styleFrom(backgroundColor: ExecColors.espresso, foregroundColor: ExecColors.gold, shape: RoundedRectangleBorder(borderRadius: ExecRadii.pill), padding: const EdgeInsets.symmetric(vertical: 14)), icon: const Icon(Icons.add), label: Text('Fiyat Ekle', style: manrope(13, FontWeight.w800, color: ExecColors.gold))))]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _entry(String user, String store, double price, String time) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: execCard(radius: 18),
        child: Column(children: [Row(children: [CircleAvatar(radius: 13, backgroundColor: ExecColors.bgSoft, child: Text((user.isEmpty ? 'U' : user[0]).toUpperCase(), style: manrope(11, FontWeight.w800, color: ExecColors.goldDeep))), const SizedBox(width: 8), Expanded(child: Text(user.isEmpty ? 'kullanıcı' : user, style: manrope(12, FontWeight.w800))), Text(time, style: manrope(10, FontWeight.w700, color: ExecColors.ink4))]), const SizedBox(height: 8), Row(children: [Text(store, style: manrope(12, FontWeight.w700, color: ExecColors.ink2)), const Spacer(), Text('${price.toStringAsFixed(0)} ₺', style: manrope(18, FontWeight.w800, color: ExecColors.ink))]), const SizedBox(height: 8), Row(children: [Expanded(child: _vote('Doğru (47)', ExecColors.successSoft, ExecColors.success)), const SizedBox(width: 8), Expanded(child: _vote('Yanlış (2)', ExecColors.dangerSoft, ExecColors.danger)), _vote('🧭', const Color(0x26C9A063), ExecColors.goldDeep)])]),
      );

  Widget _vote(String t, Color bg, Color fg) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)), child: Text(t, style: manrope(11, FontWeight.w800, color: fg), textAlign: TextAlign.center));

  static Widget _ic(IconData icon, {VoidCallback? onTap, bool active = false}) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(width: 40, height: 40, decoration: BoxDecoration(color: active ? ExecColors.espresso : ExecColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: ExecColors.bgDeep)), child: Icon(icon, color: active ? ExecColors.gold : ExecColors.ink2, size: 18)),
      );
}
