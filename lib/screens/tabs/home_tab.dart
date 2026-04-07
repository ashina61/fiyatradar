import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/product_card.dart';
import '../product_detail_screen.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final trending = state.products.take(4).toList();
    final recent = state.products.reversed.take(6).toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: CoffeeColors.espresso,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.coffee,
                    color: CoffeeColors.cream, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Merhaba ☕',
                        style: TextStyle(
                            color: CoffeeColors.cocoa, fontSize: 13)),
                    Text('FiyatRadar',
                        style: TextStyle(
                            color: CoffeeColors.espresso,
                            fontSize: 22,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              _PointsPill(points: state.points),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none,
                    color: CoffeeColors.darkRoast),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _BannerCarousel(banners: state.banners),
          const SizedBox(height: 24),
          _SectionHeader(title: 'Öne Çıkan Fırsatlar', onMore: () {}),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.74,
            ),
            itemCount: trending.length,
            itemBuilder: (context, i) {
              final p = trending[i];
              return ProductCard(
                product: p,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductDetailScreen(product: p),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: 'Son Eklenenler', onMore: () {}),
          const SizedBox(height: 12),
          ...recent.map((p) => _RecentTile(product: p)),
          if (state.products.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('Ürünler yükleniyor...',
                    style: TextStyle(color: CoffeeColors.cocoa)),
              ),
            ),
        ],
      ),
    );
  }
}

class _PointsPill extends StatelessWidget {
  const _PointsPill({required this.points});
  final int points;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: CoffeeColors.caramel,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 14, color: CoffeeColors.espresso),
          const SizedBox(width: 4),
          Text('$points',
              style: const TextStyle(
                  color: CoffeeColors.espresso,
                  fontWeight: FontWeight.w800,
                  fontSize: 13)),
        ],
      ),
    );
  }
}

class _BannerCarousel extends StatefulWidget {
  const _BannerCarousel({required this.banners});
  final List<AppBanner> banners;

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  final _ctrl = PageController(viewportFraction: 0.92);
  int _idx = 0;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banners = widget.banners;
    if (banners.isEmpty) {
      return Container(
        height: 150,
        decoration: BoxDecoration(
          color: CoffeeColors.foam,
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.center,
        child: const Text('Bannerlar yükleniyor...',
            style: TextStyle(color: CoffeeColors.cocoa)),
      );
    }
    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _ctrl,
            onPageChanged: (i) => setState(() => _idx = i),
            itemCount: banners.length,
            itemBuilder: (context, i) {
              final b = banners[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: i.isEven
                          ? const [
                              CoffeeColors.espresso,
                              CoffeeColors.mocha,
                            ]
                          : const [
                              CoffeeColors.mocha,
                              CoffeeColors.darkRoast,
                            ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        b.title,
                        style: const TextStyle(
                          color: CoffeeColors.cream,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              b.subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: CoffeeColors.latte,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: CoffeeColors.caramel,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(b.actionLabel,
                                style: const TextStyle(
                                  color: CoffeeColors.espresso,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                )),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(banners.length, (i) {
            final active = i == _idx;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color:
                    active ? CoffeeColors.espresso : CoffeeColors.crema,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _RecentTile extends StatelessWidget {
  const _RecentTile({required this.product});
  final Product product;
  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final isFav = state.isFavorite(product.id);
    final changePct = product.priceChangePct;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: CoffeeColors.crema),
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: CoffeeColors.foam,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(product.emoji,
                        style: const TextStyle(fontSize: 28)),
                  ),
                  if (changePct != null)
                    Positioned(
                      left: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: changePct < 0
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFFC62828),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          changePct < 0
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: CoffeeColors.espresso)),
                    Text('${product.brand} • ${product.category}',
                        style: const TextStyle(
                            color: CoffeeColors.cocoa, fontSize: 12)),
                    if (changePct != null)
                      Text(
                        '${changePct < 0 ? "▼" : "▲"} ${changePct.abs().toStringAsFixed(1)}% son değişim',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: changePct < 0
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFFC62828),
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                product.lowestPrice == null
                    ? '-'
                    : '₺${product.lowestPrice!.toStringAsFixed(2)}',
                style: const TextStyle(
                    color: CoffeeColors.accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 16),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: () => state.toggleFavorite(product.id),
                customBorder: const CircleBorder(),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    color: isFav
                        ? CoffeeColors.accent
                        : CoffeeColors.darkRoast,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onMore});
  final String title;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: CoffeeColors.espresso)),
        ),
        TextButton(
          onPressed: onMore,
          child: const Text('Tümü',
              style: TextStyle(color: CoffeeColors.caramel)),
        ),
      ],
    );
  }
}
