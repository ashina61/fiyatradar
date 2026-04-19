import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../state/app_state.dart';
import '../../widgets/executive_ui.dart';
import '../admin_screen.dart';
import '../main_screen.dart';
import '../notifications_screen.dart';
import '../product_detail_screen.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final products = state.products.take(6).toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 110),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(children: [
              Expanded(
                child: InkWell(
                  onTap: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 4))),
                  child: Row(children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [ExecColors.espresso2, ExecColors.espresso]),
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                      alignment: Alignment.center,
                      child: Text('FR', style: fraunces(20, FontWeight.w800, color: ExecColors.gold)),
                    ),
                    const SizedBox(width: 12),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('İyi akşamlar', style: manrope(10, FontWeight.w800, color: ExecColors.goldDeep, letterSpacing: 1.4)),
                      Text('Merhaba, ${state.displayName}', style: fraunces(22, FontWeight.w600)),
                    ])
                  ]),
                ),
              ),
              _iconBtn(Icons.notifications_none_rounded, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                  dot: state.unreadNotificationCount > 0),
            ]),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            padding: const EdgeInsets.all(14),
            decoration: execCard(),
            child: Row(children: [
              Container(width: 38, height: 38, decoration: BoxDecoration(color: const Color(0x1FC9A063), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.my_location, color: ExecColors.goldDeep, size: 18)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('BÖLGENDEKİ FİYATLAR', style: manrope(10, FontWeight.w800, color: ExecColors.ink3, letterSpacing: 1.3)), Text('Kadıköy, İstanbul · 2,3 km yarıçap', style: manrope(13, FontWeight.w700))])),
              TextButton(onPressed: () {}, child: Text('Değiştir', style: manrope(12, FontWeight.w800, color: ExecColors.goldDeep)))
            ]),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            height: 170,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(colors: [ExecColors.espresso2, ExecColors.espresso]),
            ),
            child: Stack(children: [
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('HAFTANIN AVI', style: manrope(10, FontWeight.w800, color: ExecColors.gold, letterSpacing: 2)),
                  const SizedBox(height: 8),
                  Text('Kahve fiyatları\nbu hafta %14 düştü', style: fraunces(24, FontWeight.w700, color: ExecColors.onDark)),
                  const Spacer(),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: ExecColors.gold, borderRadius: ExecRadii.pill), child: Text('İncele', style: manrope(12, FontWeight.w800, color: ExecColors.espresso))),
                ]),
              ),
              Positioned(right: 16, top: 14, child: Text('☕', style: fraunces(74, FontWeight.w700, color: const Color(0x55C9A063)))),
            ]),
          ),
          _section('Kategoriler', 'FİLTRE'),
          SizedBox(
            height: 44,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              children: const [
                _Cat('Tümü', true),
                _Cat('Teknoloji', false),
                _Cat('Market', false),
                _Cat('Gıda', false),
                _Cat('Giyim', false),
              ],
            ),
          ),
          _section('Trend ürünler', 'BU HAFTA', action: TextButton(onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 1))), child: Text('Tümü', style: manrope(12, FontWeight.w800, color: ExecColors.goldDeep)))),
          SizedBox(
            height: 298,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _TrendCard(
                product: products[i],
                isFavorite: state.isFavorite(products[i].id),
                onFavorite: () => state.toggleFavorite(products[i].id),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: products[i]))),
              ),
            ),
          ),
          _section('Canlı akış', 'SON 30 DAKİKA'),
          ...products.take(3).map((p) => _FeedRow(p: p, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p))))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen())),
              style: ElevatedButton.styleFrom(backgroundColor: ExecColors.espresso, foregroundColor: ExecColors.gold, shape: RoundedRectangleBorder(borderRadius: ExecRadii.pill), padding: const EdgeInsets.symmetric(vertical: 16)),
              icon: const Icon(Icons.admin_panel_settings_outlined),
              label: Text('Admin Konsolu', style: manrope(15, FontWeight.w700, color: ExecColors.gold)),
            ),
          )
        ],
      ),
    );
  }

  static Widget _iconBtn(IconData icon, {required VoidCallback onTap, bool dot = false}) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Stack(children: [
          Container(width: 46, height: 46, decoration: execCard(radius: 14), child: Icon(icon, color: ExecColors.ink2)),
          if (dot) const Positioned(right: 10, top: 10, child: CircleAvatar(radius: 4, backgroundColor: ExecColors.gold)),
        ]),
      );

  static Widget _section(String title, String overline, {Widget? action}) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
        child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(overline, style: manrope(10, FontWeight.w800, color: ExecColors.goldDeep, letterSpacing: 1.8)), Text(title, style: fraunces(26, FontWeight.w700))])), if (action != null) action]),
      );
}

class _Cat extends StatelessWidget {
  const _Cat(this.label, this.active);
  final String label;
  final bool active;
  @override
  Widget build(BuildContext context) => Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: active ? ExecColors.espresso : ExecColors.surface,
        borderRadius: ExecRadii.pill,
        border: Border.all(color: active ? ExecColors.gold : ExecColors.bgDeep),
      ),
      child: Text(label, style: manrope(13, FontWeight.w700, color: active ? ExecColors.gold : ExecColors.ink)));
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.product, required this.isFavorite, required this.onFavorite, required this.onTap});
  final Product product;
  final bool isFavorite;
  final VoidCallback onFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 220,
        decoration: execCard(radius: 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            height: 136,
            decoration: const BoxDecoration(color: Color(0xFFF0EBE1), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            child: Stack(children: [
              Center(child: Text(product.emoji, style: const TextStyle(fontSize: 60))),
              Positioned(
                  right: 10,
                  top: 10,
                  child: InkWell(
                    onTap: onFavorite,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: ExecColors.danger, size: 18),
                    ),
                  )),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${product.category.toUpperCase()} · ${product.brand.toUpperCase()}', style: manrope(10, FontWeight.w800, color: ExecColors.ink3, letterSpacing: 1.1)),
              const SizedBox(height: 4),
              Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: manrope(14, FontWeight.w800)),
              const SizedBox(height: 8),
              RichText(text: TextSpan(text: (product.lowestPrice ?? 0).toStringAsFixed(0), style: fraunces(30, FontWeight.w700), children: [TextSpan(text: ' ₺', style: manrope(14, FontWeight.w700, color: ExecColors.goldDeep))])),
            ]),
          )
        ]),
      ),
    );
  }
}

class _FeedRow extends StatelessWidget {
  const _FeedRow({required this.p, required this.onTap});
  final Product p;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          padding: const EdgeInsets.all(12),
          decoration: execCard(radius: 18),
          child: Row(children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(color: ExecColors.bgSoft, borderRadius: BorderRadius.circular(12)), alignment: Alignment.center, child: Text(p.emoji, style: const TextStyle(fontSize: 24))),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(p.name, style: manrope(13, FontWeight.w800)), Text('Kadıköy · 2s önce', style: manrope(11, FontWeight.w600, color: ExecColors.ink3))])),
            Text('${(p.lowestPrice ?? 0).toStringAsFixed(0)} ₺', style: manrope(15, FontWeight.w800, color: ExecColors.goldDeep)),
          ]),
        ),
      );
