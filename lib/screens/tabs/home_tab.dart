import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../state/app_state.dart';
import '../../widgets/prototype_ui.dart';
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
    final bannerItems = state.banners.isNotEmpty
        ? state.banners
            .asMap()
            .entries
            .map(
              (entry) => _HomeBannerData(
                tag: entry.value.actionLabel,
                title: entry.value.title,
                desc: entry.value.subtitle,
                colors: _bannerPalette(entry.key),
              ),
            )
            .toList()
        : const [
            _HomeBannerData(
              tag: '🔥 Fırsat',
              title: 'Haftanın Fırsatları',
              desc: 'En çok düşen fiyatları keşfet',
              colors: [Color(0xFF8B6914), Color(0xFFB8956A)],
            ),
            _HomeBannerData(
              tag: '✅ Güvenilir',
              title: 'Doğrulanmış Düşüşler',
              desc: 'Topluluk tarafından onaylananlar',
              colors: [Color(0xFF4A6B5A), Color(0xFF6B8A7A)],
            ),
            _HomeBannerData(
              tag: '⭐ Popüler',
              title: 'Popüler Ürünler',
              desc: 'Bu hafta en çok arananlar',
              colors: [Color(0xFF6B4A8A), Color(0xFF8A6BAA)],
            ),
          ];

    return SafeArea(
      child: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: FRInsets.pageTopBar,
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 4)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [ProtoColors.tan, ProtoColors.tanDark]),
                                borderRadius: FRRadii.pill,
                                border: Border.all(color: ProtoColors.tan.withOpacity(0.3), width: 2),
                              ),
                              alignment: Alignment.center,
                              child: const Text('FK', style: TextStyle(fontWeight: FontWeight.w800, color: ProtoColors.bgPrimary)),
                            ),
                            const SizedBox(width: 10),
                            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('Merhaba,', style: TextStyle(fontSize: 10, color: ProtoColors.textSubtle, fontWeight: FontWeight.w500)),
                              Text('Adem', style: TextStyle(fontSize: 14, color: ProtoColors.textPrimary, fontWeight: FontWeight.w700)),
                            ]),
                          ],
                        ),
                      ),
                    ),
                    NotificationButton(
                      badge: state.unreadNotificationCount,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen())),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: ProtoColors.tan,
                          borderRadius: FRRadii.pill,
                          border: Border.all(color: ProtoColors.tan),
                        ),
                        child: const Icon(Icons.settings, color: ProtoColors.bgPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              ProtoSearchField(
                hint: 'Ürün, market veya kategori ara...',
                onTap: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 1)),
                ),
              ),
              SizedBox(
                height: 38,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  scrollDirection: Axis.horizontal,
                  children: const [
                    _Chip('Tümü', Icons.grid_view_rounded, true),
                    _Chip('Elektronik', Icons.laptop, false),
                    _Chip('Gıda', Icons.restaurant, false),
                    _Chip('Bakım', Icons.spa, false),
                    _Chip('Ev', Icons.home, false),
                    _Chip('Spor', Icons.fitness_center, false),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: FRRadii.xl,
                  gradient: const LinearGradient(colors: [ProtoColors.flashStart, ProtoColors.flashEnd]),
                ),
                child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('⚡ FLASH DEAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                  SizedBox(height: 4),
                  Text('Sony WH-1000XM5', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      _Timer('02', 'Saat'),
                      SizedBox(width: 8),
                      _Timer('45', 'Dk'),
                      SizedBox(width: 8),
                      _Timer('30', 'Sn'),
                    ],
                  ),
                ]),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 100),
                  children: [
                    _HomeBannerSection(bannerItems: bannerItems),
                    const SizedBox(height: 14),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text('✨ Senin İçin Öneriler', style: TextStyle(color: ProtoColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                    const SizedBox(height: 10),
                    const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: _Suggestion('🎧', 'Sony WH-1000XM5', 'Son aradığın üründe ₺200 düşüş!', '₺1.299', ProtoColors.purple)),
                    const SizedBox(height: 8),
                    const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: _Suggestion('☕', 'Lavazza Kahve', 'Sık satın aldığın kategoride fırsat', '₺329', ProtoColors.success)),
                    const SizedBox(height: 16),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Expanded(child: Text('🔥 Canlı Fiyatlar', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
                          Text('Tümü', style: TextStyle(color: ProtoColors.tan, fontWeight: FontWeight.w600, fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    GridView.builder(
                      itemCount: products.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.70,
                      ),
                      itemBuilder: (_, i) {
                        final p = products[i];
                        return _ProductCard(
                          product: p,
                          isFavorite: state.isFavorite(p.id),
                          onFavoriteTap: () => state.toggleFavorite(p.id),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p))),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            right: 24,
            bottom: 86,
            child: InkWell(
              onTap: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 2)),
              ),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: FRRadii.pill,
                  gradient: const LinearGradient(colors: [ProtoColors.tan, ProtoColors.tanLight]),
                  boxShadow: [
                    BoxShadow(color: ProtoColors.tan.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: const Icon(Icons.add, color: ProtoColors.bgPrimary, size: 28),
              ),
            ),
          ),
          Positioned(
            top: 104,
            right: 20,
            child: Container(
              width: 220,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: FRRadii.lg,
                gradient: const LinearGradient(colors: [ProtoColors.success, Color(0xFF6B8A6B)]),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 12)],
              ),
              child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Icon(Icons.arrow_downward, size: 14, color: Colors.white), SizedBox(width: 8), Text('Fiyat Düştü!', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white))]),
                SizedBox(height: 4),
                Text('Sony WH-1000XM5', style: TextStyle(fontSize: 11, color: Colors.white)),
                Text('₺1.299 TL   ₺1.499', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

List<Color> _bannerPalette(int index) {
  const palettes = [
    [Color(0xFF8B6914), Color(0xFFB8956A)],
    [Color(0xFF4A6B5A), Color(0xFF6B8A7A)],
    [Color(0xFF6B4A8A), Color(0xFF8A6BAA)],
  ];
  return palettes[index % palettes.length];
}

class _Chip extends StatelessWidget {
  const _Chip(this.text, this.icon, this.active);
  final String text;
  final IconData icon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: active ? ProtoColors.tan : ProtoColors.surface,
        borderRadius: FRRadii.pill,
        border: Border.all(color: active ? ProtoColors.tan : ProtoColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: active ? ProtoColors.bgPrimary : ProtoColors.textSecondary),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: active ? ProtoColors.bgPrimary : ProtoColors.textSecondary)),
        ],
      ),
    );
  }
}

class _HomeBannerData {
  const _HomeBannerData({
    required this.tag,
    required this.title,
    required this.desc,
    required this.colors,
  });

  final String tag;
  final String title;
  final String desc;
  final List<Color> colors;
}

class _HomeBannerSection extends StatefulWidget {
  const _HomeBannerSection({required this.bannerItems});

  final List<_HomeBannerData> bannerItems;

  @override
  State<_HomeBannerSection> createState() => _HomeBannerSectionState();
}

class _HomeBannerSectionState extends State<_HomeBannerSection> {
  late final PageController _pageController;
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1);
  }

  @override
  void didUpdateWidget(covariant _HomeBannerSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_activeIndex >= widget.bannerItems.length && widget.bannerItems.isNotEmpty) {
      setState(() => _activeIndex = widget.bannerItems.length - 1);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 156,
      child: Column(
        children: [
          SizedBox(
            height: 138,
            child: PageView.builder(
              controller: _pageController,
              padEnds: false,
              itemCount: widget.bannerItems.length,
              onPageChanged: (index) => setState(() => _activeIndex = index),
              itemBuilder: (_, i) {
                return Padding(
                  padding: EdgeInsetsDirectional.only(
                    start: i == 0 ? 24 : 0,
                    end: i == widget.bannerItems.length - 1 ? 24 : 12,
                    bottom: 8,
                  ),
                  child: _Banner(
                    data: widget.bannerItems[i],
                    width: MediaQuery.of(context).size.width - 48,
                  ),
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < widget.bannerItems.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                _Dot(i == _activeIndex),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.data, required this.width});
  final _HomeBannerData data;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 130,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: data.colors),
        borderRadius: FRRadii.xl,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white.withOpacity(0.08), Colors.transparent],
                  stops: const [0, 0.6],
                ),
                borderRadius: FRRadii.xl,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: FRRadii.pill,
                ),
                child: Text(
                  data.tag,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(data.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 4),
                Text(data.desc, style: const TextStyle(fontSize: 12, color: Color.fromRGBO(255, 255, 255, 0.8))),
              ]),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.isFavorite,
    required this.onFavoriteTap,
    required this.onTap,
  });

  final Product product;
  final bool isFavorite;
  final VoidCallback onFavoriteTap;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final change = product.priceChangePct;
    final isDown = (change ?? 0) <= 0;
    final price = product.lowestPrice ?? product.latestPrice ?? 0;
    final cheapestStore = product.cheapestStore ?? '-';
    final lastReporter = product.priceHistory.isNotEmpty ? product.priceHistory.last.reportedBy : 'Sen';

    return InkWell(
      borderRadius: FRRadii.xl,
      onTap: onTap,
      child: Container(
        decoration: protoSurface(),
        child: Column(
          children: [
            Container(
              height: 100,
              width: double.infinity,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                gradient: LinearGradient(colors: [ProtoColors.surfaceAlt, ProtoColors.surfaceElevated]),
              ),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Text(product.emoji, style: const TextStyle(fontSize: 36)),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        borderRadius: FRRadii.sm,
                        color: (isDown ? ProtoColors.success : ProtoColors.danger).withOpacity(0.12),
                        border: Border.all(
                          color: (isDown ? ProtoColors.success : ProtoColors.danger).withOpacity(0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(isDown ? Icons.south : Icons.north, size: 10, color: isDown ? ProtoColors.success : ProtoColors.danger),
                          const SizedBox(width: 3),
                          Text(
                            '${(change ?? 0).abs().toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isDown ? ProtoColors.success : ProtoColors.danger,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: InkWell(
                      onTap: onFavoriteTap,
                      borderRadius: FRRadii.pill,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(isFavorite ? 0.7 : 0.5),
                        ),
                        child: Icon(
                          isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          size: 14,
                          color: isFavorite ? ProtoColors.danger : const Color.fromRGBO(255, 255, 255, 0.6),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                      color: ProtoColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '₺${price.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ProtoColors.tan),
                        ),
                        const TextSpan(
                          text: 'TL',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color.fromRGBO(175, 163, 152, 0.7)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.storefront, size: 8, color: ProtoColors.textSubtle),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        cheapestStore,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 9, color: ProtoColors.textSubtle),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.person, size: 8, color: ProtoColors.textSubtle),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(text: 'Ekleyen: ', style: TextStyle(fontSize: 9, color: ProtoColors.textSubtle)),
                            TextSpan(
                              text: lastReporter,
                              style: const TextStyle(fontSize: 9, color: ProtoColors.tan, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Suggestion extends StatelessWidget {
  const _Suggestion(this.icon, this.name, this.reason, this.price, this.tone);
  final String icon;
  final String name;
  final String reason;
  final String price;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return ProtoCard(
      child: Row(children: [
        Container(width: 42, height: 42, decoration: BoxDecoration(color: tone.withOpacity(0.12), borderRadius: FRRadii.md), alignment: Alignment.center, child: Text(icon)),
        const SizedBox(width: 10),
        Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          Text(reason, style: const TextStyle(fontSize: 10, color: ProtoColors.textSubtle)),
        ])),
        RichText(
          text: TextSpan(children: [
            TextSpan(text: price, style: const TextStyle(color: ProtoColors.tan, fontWeight: FontWeight.w800, fontSize: 15)),
            const TextSpan(text: 'TL', style: TextStyle(color: ProtoColors.textSubtle, fontSize: 10, fontWeight: FontWeight.w600)),
          ]),
        ),
      ]),
    );
  }
}

class _Timer extends StatelessWidget {
  const _Timer(this.value, this.label);
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.22), borderRadius: FRRadii.md),
      child: Column(children: [
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 9)),
      ]),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot(this.active);
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: active ? 18 : 6,
      height: 6,
      decoration: BoxDecoration(
        color: active ? ProtoColors.tan : ProtoColors.surfaceElevated,
        borderRadius: BorderRadius.circular(active ? 3 : 99),
        border: Border.all(color: active ? ProtoColors.tan : ProtoColors.border),
      ),
    );
  }
}
