import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/design.dart';
import '../notifications_screen.dart';
import '../product_detail_screen.dart';
import '../points_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  String _activeFilter = 'Hepsi';

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Günaydın';
    if (h < 18) return 'İyi günler';
    return 'İyi akşamlar';
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final products = state.products;

    final drops = products.where((p) {
      final c = p.priceChangePct;
      return c != null && c < 0;
    }).toList();
    final rises = products.where((p) {
      final c = p.priceChangePct;
      return c != null && c > 0;
    }).toList();

    List<Product> featured;
    if (_activeFilter == 'Düşenler') {
      featured = drops;
    } else if (_activeFilter == 'Yükselenler') {
      featured = rises;
    } else {
      featured = [...products]
        ..sort((a, b) {
          final ca = a.priceChangePct?.abs() ?? 0;
          final cb = b.priceChangePct?.abs() ?? 0;
          return cb.compareTo(ca);
        });
    }

    final storeCount = <String, int>{};
    for (final p in products) {
      final s = p.cheapestStore;
      if (s != null) storeCount[s] = (storeCount[s] ?? 0) + 1;
    }
    String? bestStore;
    if (storeCount.isNotEmpty) {
      bestStore = storeCount.entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;
    }

    final allEntries = <_RecentEntry>[];
    final contributors = <String>{};
    final allStores = <String>{};
    for (final p in products) {
      for (final e in p.priceHistory) {
        allEntries.add(_RecentEntry(product: p, entry: e));
        contributors.add(e.reportedBy);
        allStores.add(e.store);
      }
    }
    allEntries.sort((a, b) => b.entry.date.compareTo(a.entry.date));
    final recentTop = allEntries.take(5).toList();
    final last24h = allEntries
        .where((e) =>
            DateTime.now().difference(e.entry.date).inHours < 24)
        .length;

    final double dropRatio = products.isEmpty
        ? 0
        : drops.length / products.length;
    final String marketPulse = dropRatio > 0.4
        ? 'Piyasa düşüşte'
        : dropRatio > 0.2
            ? 'Karışık sinyal'
            : rises.length > drops.length
                ? 'Piyasa yükselişte'
                : 'Stabil seyir';

    final pulseColor = dropRatio > 0.4
        ? const Color(0xFF2E7D32)
        : dropRatio > 0.2
            ? CoffeeColors.caramel
            : rises.length > drops.length
                ? const Color(0xFFC62828)
                : CoffeeColors.cocoa;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          // ── Header ───────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        LiveDot(),
                        const SizedBox(width: 6),
                        Text(
                          _greeting,
                          style: const TextStyle(
                              color: CoffeeColors.cocoa,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'FiyatRadar',
                      style: TextStyle(
                          color: CoffeeColors.espresso,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8),
                    ),
                  ],
                ),
              ),
              _PointsPill(
                points: state.points,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PointsScreen()),
                ),
              ),
              const SizedBox(width: 8),
              _NotificationBell(hasNew: state.unreadNotificationCount > 0),
            ],
          ),
          const SizedBox(height: 16),

          // ── Radar hero ────────────────────────────────────────────
          _RadarHeroCard(
            dropCount: drops.length,
            riseCount: rises.length,
            last24h: last24h,
            bestStore: bestStore,
            sparkValues: _aggregateSpark(allEntries),
            totalProducts: products.length,
            marketPulse: marketPulse,
            pulseColor: pulseColor,
          ),
          const SizedBox(height: 10),

          // ── Signal strip ──────────────────────────────────────────
          _SignalStrip(
            products: products.length,
            stores: allStores.length,
            contributors: contributors.length,
          ),
          const SizedBox(height: 22),

          // ── Filter chips ──────────────────────────────────────────
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _FilterChip(
                  label: 'Hepsi',
                  count: products.length,
                  selected: _activeFilter == 'Hepsi',
                  selectedColor: CoffeeColors.espresso,
                  onTap: () => setState(() => _activeFilter = 'Hepsi'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Düşenler',
                  count: drops.length,
                  selected: _activeFilter == 'Düşenler',
                  selectedColor: const Color(0xFF2E7D32),
                  onTap: () => setState(() => _activeFilter = 'Düşenler'),
                  icon: Icons.trending_down,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Yükselenler',
                  count: rises.length,
                  selected: _activeFilter == 'Yükselenler',
                  selectedColor: const Color(0xFFC62828),
                  onTap: () => setState(() => _activeFilter = 'Yükselenler'),
                  icon: Icons.trending_up,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // ── Featured ──────────────────────────────────────────────
          SectionHeader(
            title: 'Öne Çıkanlar',
            subtitle: 'En hareketli ürünler',
            trailing: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Tümü →',
                style: TextStyle(
                    color: CoffeeColors.caramel,
                    fontSize: 13,
                    fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (featured.isEmpty)
            _EmptyBlock(
              text: _activeFilter == 'Düşenler'
                  ? 'Bugün fiyat düşüşü yok'
                  : _activeFilter == 'Yükselenler'
                      ? 'Bugün fiyat artışı yok'
                      : 'Ürünler yükleniyor…',
            )
          else
            SizedBox(
              height: 252,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: featured.take(8).length,
                itemBuilder: (context, i) {
                  final p = featured[i];
                  return _FeaturedCard(
                    product: p,
                    rank: i,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductDetailScreen(product: p),
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 28),

          // ── Recent entries ────────────────────────────────────────
          SectionHeader(
            title: 'Son Fiyat Eklemeleri',
            subtitle: last24h > 0
                ? '$last24h kayıt son 24 saatte'
                : 'Henüz bugün ekleme yok',
            trailing: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Akış →',
                style: TextStyle(
                    color: CoffeeColors.caramel,
                    fontSize: 13,
                    fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (recentTop.isEmpty)
            _EmptyBlock(text: 'Henüz fiyat eklenmemiş')
          else
            ...recentTop.asMap().entries.map(
                  (e) => _RecentEntryTile(entry: e.value, rank: e.key + 1),
                ),
        ],
      ),
    );
  }

  List<double> _aggregateSpark(List<_RecentEntry> entries) {
    if (entries.length < 4) return const [];
    final last = entries.take(14).toList().reversed.toList();
    return last.map((e) => e.entry.price).toList();
  }
}

class _RecentEntry {
  final Product product;
  final PriceEntry entry;
  const _RecentEntry({required this.product, required this.entry});
}

// ─── Filter chip ─────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
    this.icon,
  });
  final String label;
  final int count;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? selectedColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? selectedColor : CoffeeColors.crema),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: selectedColor.withOpacity(0.22),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14,
                  color: selected ? Colors.white : CoffeeColors.darkRoast),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : CoffeeColors.darkRoast,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withOpacity(0.22)
                    : CoffeeColors.foam,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: selected ? Colors.white : CoffeeColors.cocoa,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Points pill ─────────────────────────────────────────────────────────────

class _PointsPill extends StatelessWidget {
  const _PointsPill({required this.points, required this.onTap});
  final int points;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: CoffeeColors.espresso,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: CoffeeColors.caramel.withOpacity(0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded,
                  size: 13, color: CoffeeColors.caramel),
              const SizedBox(width: 5),
              Text(
                '$points',
                style: const TextStyle(
                    color: CoffeeColors.cream,
                    fontWeight: FontWeight.w800,
                    fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Notification bell ────────────────────────────────────────────────────────

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({this.hasNew = false});
  final bool hasNew;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: CoffeeColors.crema),
          ),
          child: IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationsScreen(),
                ),
              );
            },
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.notifications_none,
                color: CoffeeColors.darkRoast, size: 20),
          ),
        ),
        if (hasNew)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: CoffeeColors.accent,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Hero card ───────────────────────────────────────────────────────────────

class _RadarHeroCard extends StatelessWidget {
  const _RadarHeroCard({
    required this.dropCount,
    required this.riseCount,
    required this.last24h,
    required this.bestStore,
    required this.sparkValues,
    required this.totalProducts,
    required this.marketPulse,
    required this.pulseColor,
  });

  final int dropCount;
  final int riseCount;
  final int last24h;
  final String? bestStore;
  final List<double> sparkValues;
  final int totalProducts;
  final String marketPulse;
  final Color pulseColor;

  @override
  Widget build(BuildContext context) {
    final hasActivity = last24h > 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [CoffeeColors.espresso, CoffeeColors.darkRoast],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: CoffeeColors.espresso.withOpacity(0.28),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: label + live indicator
          Row(
            children: [
              const EyebrowLabel('KARAR PANELİ'),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.10)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LiveDot(color: CoffeeColors.caramel),
                    const SizedBox(width: 5),
                    const Text(
                      'CANLI',
                      style: TextStyle(
                        color: CoffeeColors.caramel,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Main row: numbers + sparkline
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Contextual number display
                    if (hasActivity) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$last24h',
                            style: const TextStyle(
                              color: CoffeeColors.cream,
                              fontSize: 48,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -2,
                              height: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'yeni kayıt',
                            style: TextStyle(
                              color: CoffeeColors.latte,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'son 24 saat',
                        style: TextStyle(
                            color: CoffeeColors.cocoa, fontSize: 11),
                      ),
                    ] else ...[
                      Text(
                        '$totalProducts',
                        style: const TextStyle(
                          color: CoffeeColors.cream,
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -2,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'ürün aktif takipte',
                        style: TextStyle(
                            color: CoffeeColors.latte, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 8),
                    // Market pulse badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: pulseColor.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: pulseColor.withOpacity(0.30)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.radio_button_checked,
                              size: 9, color: pulseColor),
                          const SizedBox(width: 5),
                          Text(
                            marketPulse,
                            style: TextStyle(
                              color: pulseColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (sparkValues.length >= 2)
                SizedBox(
                  width: 110,
                  child: Sparkline(
                    values: sparkValues,
                    height: 52,
                    color: CoffeeColors.caramel,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),

          // Stats row
          Row(
            children: [
              _HeroStat(
                label: 'düşen',
                value: '$dropCount',
                icon: Icons.trending_down,
                accent: const Color(0xFF8FB36A),
              ),
              const SizedBox(width: 8),
              _HeroStat(
                label: 'yükselen',
                value: '$riseCount',
                icon: Icons.trending_up,
                accent: const Color(0xFFE57B6F),
              ),
              const SizedBox(width: 8),
              _HeroStat(
                label: 'en ucuz market',
                value: bestStore ?? '–',
                icon: Icons.emoji_events_outlined,
                accent: CoffeeColors.caramel,
                highlight: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    this.highlight = false,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        decoration: BoxDecoration(
          color: highlight
              ? accent.withOpacity(0.16)
              : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: highlight
                ? accent.withOpacity(0.35)
                : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: accent, size: 13),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: highlight ? accent : CoffeeColors.cream,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: CoffeeColors.latte, fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Signal strip ────────────────────────────────────────────────────────────

class _SignalStrip extends StatelessWidget {
  const _SignalStrip({
    required this.products,
    required this.stores,
    required this.contributors,
  });
  final int products;
  final int stores;
  final int contributors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(FR.radiusL),
        border: Border.all(color: CoffeeColors.crema),
        boxShadow: FR.softShadow,
      ),
      child: Row(
        children: [
          _cell('$products', 'ürün', Icons.inventory_2_outlined),
          _vDivider(),
          _cell('$stores', 'market', Icons.storefront_outlined),
          _vDivider(),
          _cell('$contributors', 'katkıcı', Icons.people_alt_outlined),
        ],
      ),
    );
  }

  Widget _vDivider() =>
      Container(width: 1, height: 16, color: CoffeeColors.crema);

  Widget _cell(String value, String label, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 14, color: CoffeeColors.caramel),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: CoffeeColors.espresso,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: CoffeeColors.cocoa,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Featured card ───────────────────────────────────────────────────────────

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({
    required this.product,
    required this.onTap,
    required this.rank,
  });
  final Product product;
  final VoidCallback onTap;
  final int rank;

  DateTime? get _latest {
    if (product.priceHistory.isEmpty) return null;
    final s = [...product.priceHistory]
      ..sort((a, b) => b.date.compareTo(a.date));
    return s.first.date;
  }

  List<double> get _sparkValues {
    if (product.priceHistory.length < 3) return [];
    final sorted = [...product.priceHistory]
      ..sort((a, b) => a.date.compareTo(b.date));
    return sorted.map((e) => e.price).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final isFav = state.isFavorite(product.id);
    final changePct = product.priceChangePct;
    final lowest = product.lowestPrice;
    final stores = product.priceHistory.map((e) => e.store).toSet().length;
    final entries = product.priceHistory.length;
    final isHot = changePct != null && changePct < -5;
    final spark = _sparkValues;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 170,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(FR.radiusXl),
          border: Border.all(
            color: isHot
                ? CoffeeColors.caramel.withOpacity(0.4)
                : CoffeeColors.crema,
            width: isHot ? 1.5 : 1,
          ),
          boxShadow: FR.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area
            Stack(
              children: [
                Container(
                  height: 84,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isHot
                          ? [
                              CoffeeColors.caramel.withOpacity(0.15),
                              CoffeeColors.foam
                            ]
                          : [CoffeeColors.foam, CoffeeColors.crema],
                    ),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(FR.radiusXl)),
                  ),
                  alignment: Alignment.center,
                  child: Text(product.emoji,
                      style: const TextStyle(fontSize: 40)),
                ),
                // Rank indicator (top left, subtle)
                Positioned(
                  top: 8,
                  left: 10,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: rank == 0
                          ? CoffeeColors.caramel
                          : Colors.white.withOpacity(0.88),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: rank == 0
                              ? CoffeeColors.caramel
                              : CoffeeColors.crema),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${rank + 1}',
                      style: TextStyle(
                        color: rank == 0
                            ? CoffeeColors.espresso
                            : CoffeeColors.cocoa,
                        fontWeight: FontWeight.w800,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: () => state.toggleFavorite(product.id),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: CoffeeColors.espresso.withOpacity(0.08),
                            blurRadius: 6,
                          )
                        ],
                      ),
                      child: Icon(
                        isFav ? Icons.favorite_rounded : Icons.favorite_border,
                        color: isFav
                            ? CoffeeColors.accent
                            : CoffeeColors.darkRoast,
                        size: 14,
                      ),
                    ),
                  ),
                ),
                if (changePct != null)
                  Positioned(
                    bottom: 6,
                    left: 8,
                    child: TrendPill(pct: changePct, dense: true),
                  ),
              ],
            ),

            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: CoffeeColors.espresso,
                      fontSize: 13,
                      height: 1.25,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${product.brand} · ${product.unit}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: CoffeeColors.cocoa,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  // Sparkline (if available)
                  if (spark.length >= 3) ...[
                    const SizedBox(height: 8),
                    Sparkline(
                      values: spark,
                      height: 32,
                      color: changePct != null && changePct < 0
                          ? CoffeeColors.success
                          : CoffeeColors.caramel,
                    ),
                  ] else
                    const SizedBox(height: 10),

                  const Divider(height: 10, color: CoffeeColors.crema),

                  // Price row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'EN İYİ',
                            style: TextStyle(
                              color: CoffeeColors.cocoa,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                          PriceText(lowest, size: 16),
                        ],
                      ),
                      const Spacer(),
                      if (product.cheapestStore != null)
                        StoreBadge(product.cheapestStore!),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      FreshnessChip(date: _latest),
                      const Spacer(),
                      if (stores > 0)
                        Text(
                          '$stores market',
                          style: const TextStyle(
                            color: CoffeeColors.cocoa,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Recent entry tile ────────────────────────────────────────────────────────

class _RecentEntryTile extends StatelessWidget {
  const _RecentEntryTile({required this.entry, required this.rank});
  final _RecentEntry entry;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final isLow = entry.product.lowestPrice != null &&
        entry.entry.price <= entry.product.lowestPrice!;
    final changePct = entry.product.priceChangePct;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(product: entry.product),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(FR.radiusL),
          border: Border.all(
            color: isLow
                ? CoffeeColors.caramel.withOpacity(0.4)
                : CoffeeColors.crema,
            width: isLow ? 1.5 : 1,
          ),
          boxShadow: FR.softShadow,
        ),
        child: Row(
          children: [
            // Rank + emoji
            SizedBox(
              width: 48,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [CoffeeColors.foam, CoffeeColors.crema],
                      ),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    alignment: Alignment.center,
                    child: Text(entry.product.emoji,
                        style: const TextStyle(fontSize: 22)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: CoffeeColors.espresso,
                              fontSize: 13),
                        ),
                      ),
                      if (changePct != null)
                        TrendPill(pct: changePct, dense: true),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      StoreBadge(entry.entry.store, dark: false),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          entry.entry.reportedBy,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: CoffeeColors.cocoa,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                PriceText(
                  entry.entry.price,
                  size: 16,
                  color: isLow
                      ? CoffeeColors.success
                      : CoffeeColors.accent,
                ),
                const SizedBox(height: 4),
                FreshnessChip(date: entry.entry.date),
                if (isLow) ...[
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: CoffeeColors.success.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Text(
                      'en düşük',
                      style: TextStyle(
                        color: CoffeeColors.success,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  const _EmptyBlock({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(FR.radiusL),
        border: Border.all(color: CoffeeColors.crema),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: CoffeeColors.foam,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.radar_rounded,
                color: CoffeeColors.caramel, size: 24),
          ),
          const SizedBox(height: 10),
          Text(
            text,
            style: const TextStyle(
                color: CoffeeColors.cocoa,
                fontSize: 13,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
