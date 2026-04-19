import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../state/app_state.dart';
import '../../widgets/executive_ui.dart';
import '../main_screen.dart';
import '../notifications_screen.dart';
import '../product_detail_screen.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final trend = state.products.take(3).toList();
    final feed = state.products.skip(1).take(3).toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          _HomeGreet(state: state),
          const SizedBox(height: 14),
          _LocationStrip(onTap: () {}),
          const SizedBox(height: 16),
          _Banner(onInspect: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 1)))),
          const SizedBox(height: 22),
          _SectionHead(overline: 'Filtre', title: 'Kategoriler'),
          const SizedBox(height: 10),
          const SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [_Cat('Tümü', true), _Cat('Teknoloji', false), _Cat('Market', false), _Cat('Gıda', false), _Cat('Giyim', false), _Cat('Ev', false)]),
          ),
          const SizedBox(height: 24),
          _SectionHead(overline: 'Bu Hafta', title: 'Trend ürünler', onAll: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 1)))),
          const SizedBox(height: 10),
          SizedBox(
            height: 286,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: trend.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final p = trend[i];
                return _TrendCard(
                  product: p,
                  isFavorite: state.isFavorite(p.id),
                  onFavorite: () => state.toggleFavorite(p.id),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p))),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          _SectionHead(overline: 'Son 30 dakika', title: 'Canlı akış'),
          const SizedBox(height: 10),
          ...feed.map((p) => _FeedRow(product: p, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p))))),
        ],
      ),
    );
  }
}

class _HomeGreet extends StatelessWidget {
  const _HomeGreet({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 4))),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(gradient: LinearGradient(colors: [ExecColors.espresso2, ExecColors.espresso]), borderRadius: BorderRadius.all(Radius.circular(16))),
                  alignment: Alignment.center,
                  child: Text('FR', style: fraunces(20, FontWeight.w800, color: ExecColors.gold)),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('İyi akşamlar', style: manrope(10, FontWeight.w800, color: ExecColors.goldDeep, letterSpacing: 1.8)),
                    Text('Merhaba, ${state.displayName}', style: fraunces(22, FontWeight.w600)),
                  ],
                )
              ],
            ),
          ),
        ),
        InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              Container(width: 46, height: 46, decoration: execCard(radius: 14), child: const Icon(Icons.notifications_none_rounded, color: ExecColors.ink2)),
              if (state.unreadNotificationCount > 0) const Positioned(right: 10, top: 10, child: CircleAvatar(radius: 4, backgroundColor: ExecColors.gold)),
            ],
          ),
        ),
      ],
    );
  }
}

class _LocationStrip extends StatelessWidget {
  const _LocationStrip({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: execCard(radius: 20),
      child: Row(
        children: [
          Container(width: 38, height: 38, decoration: BoxDecoration(color: const Color(0x1FC9A063), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.my_location_rounded, size: 18, color: ExecColors.goldDeep)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Bölgendeki fiyatlar', style: manrope(10, FontWeight.w800, color: ExecColors.ink3, letterSpacing: 1.2)), Text('Kadıköy, İstanbul · 2,3 km yarıçap', style: manrope(13, FontWeight.w700))])),
          TextButton(onPressed: onTap, child: Text('Değiştir', style: manrope(12, FontWeight.w800, color: ExecColors.goldDeep))),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.onInspect});
  final VoidCallback onInspect;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(26), gradient: const LinearGradient(colors: [ExecColors.espresso2, ExecColors.espresso])),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('HAFTANIN AVI', style: manrope(10, FontWeight.w800, color: ExecColors.gold, letterSpacing: 2)),
              const SizedBox(height: 8),
              Text('Kahve fiyatları\nbu hafta %14 düştü', style: fraunces(24, FontWeight.w700, color: ExecColors.onDark)),
              Text('12 şehirden 347 yeni veri', style: manrope(12, FontWeight.w600, color: const Color(0xFFC9BCA6))),
              const Spacer(),
              SizedBox(height: 34, child: ElevatedButton(onPressed: onInspect, style: ElevatedButton.styleFrom(backgroundColor: ExecColors.gold, foregroundColor: ExecColors.espresso), child: Text('İncele', style: manrope(12, FontWeight.w800, color: ExecColors.espresso)))),
            ]),
          ),
          Positioned(right: 16, top: 10, child: Text('☕', style: fraunces(72, FontWeight.w700, color: const Color(0x55C9A063)))),
        ],
      ),
    );
  }
}

class _SectionHead extends StatelessWidget {
  const _SectionHead({required this.overline, required this.title, this.onAll});
  final String overline;
  final String title;
  final VoidCallback? onAll;

  @override
  Widget build(BuildContext context) {
    return Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(overline, style: manrope(10, FontWeight.w800, color: ExecColors.goldDeep, letterSpacing: 1.8)), Text(title, style: fraunces(24, FontWeight.w700))])), if (onAll != null) TextButton(onPressed: onAll, child: Text('Tümü', style: manrope(12, FontWeight.w800, color: ExecColors.goldDeep)))]);
  }
}

class _Cat extends StatelessWidget {
  const _Cat(this.label, this.active);
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
        decoration: execCard(radius: 22),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            height: 130,
            decoration: const BoxDecoration(color: Color(0xFFF0EBE1), borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
            child: Stack(children: [Center(child: Text(product.emoji, style: const TextStyle(fontSize: 54))), Positioned(right: 10, top: 10, child: InkWell(onTap: onFavorite, child: Icon(isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: ExecColors.danger)))]),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(product.category.toUpperCase(), style: manrope(10, FontWeight.w800, color: ExecColors.ink3, letterSpacing: 1.2)), const SizedBox(height: 4), Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: manrope(13, FontWeight.w800)), const SizedBox(height: 6), Text('${(product.lowestPrice ?? 0).toStringAsFixed(0)} ₺', style: fraunces(28, FontWeight.w700))]),
          )
        ]),
      ),
    );
  }
}

class _FeedRow extends StatelessWidget {
  const _FeedRow({required this.product, required this.onTap});
  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: execCard(radius: 18),
          child: Row(children: [Container(width: 44, height: 44, decoration: BoxDecoration(color: ExecColors.bgSoft, borderRadius: BorderRadius.circular(12)), alignment: Alignment.center, child: Text(product.emoji, style: const TextStyle(fontSize: 22))), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: manrope(13, FontWeight.w800)), Text('${product.brand} · Kadıköy', style: manrope(11, FontWeight.w600, color: ExecColors.ink3))])), Text('${(product.lowestPrice ?? 0).toStringAsFixed(0)} ₺', style: manrope(14, FontWeight.w800))]),
        ),
      );

}
