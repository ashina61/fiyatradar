import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class FRColors {
  static const Color bgApp = Color(0xFFF5F3F0);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color studio = Color(0xFFEBE5DF);

  static const Color darkMain = Color(0xFF211510);
  static const Color darkSurface = Color(0xFF2D1E17);
  static const Color gold = Color(0xFFC29B78);

  static const Color textMain = Color(0xFF211510);
  static const Color textMuted = Color(0xFF948A82);

  static const Color success = Color(0xFF4CAF50);
  static const Color successBg = Color(0xFFE8F5E9);
  static const Color danger = Color(0xFFF44336);
  static const Color dangerBg = Color(0xFFFFEBEE);
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedCategoryIndex = 0;

  final List<HomeCategory> _categories = const [
    HomeCategory(label: 'Tümü', icon: Icons.grid_view_rounded),
    HomeCategory(label: 'Market', icon: Icons.shopping_cart_rounded),
    HomeCategory(label: 'Tekno', icon: Icons.laptop_mac_rounded),
    HomeCategory(label: 'Kozmetik', icon: Icons.face_retouching_natural_rounded),
  ];

  final RadarAnalysisData _analysisData = const RadarAnalysisData(
    brand: 'DR. OETKER',
    title: 'Ristorante Karışık Pizza 340g',
    avgPriceText: 'Ortalama: 110₺',
    imageUrl:
        'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?q=80&w=240&auto=format&fit=crop',
    rows: [
      AnalysisRow(market: 'A-101', priceText: '89,00₺', fill: 1.0, isBest: true),
      AnalysisRow(market: 'BİM', priceText: '95,00₺', fill: 0.85),
      AnalysisRow(market: 'Migros', priceText: '115,00₺', fill: 0.70),
    ],
  );

  final List<HardDropItem> _hardDrops = const [
    HardDropItem(
      brand: 'FERRERO',
      title: 'Nutella Fındık Kreması 400g',
      imageUrl:
          'https://images.unsplash.com/photo-1628840042765-356cda07504e?q=80&w=320&auto=format&fit=crop',
      dropPercent: 28,
      oldPriceText: '40,00₺',
      priceText: '36,00₺',
      market: 'Trendyol M.',
    ),
    HardDropItem(
      brand: 'SARIYER',
      title: 'Sarıyer Kola 330mL Kutu İçecek',
      imageUrl:
          'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?q=80&w=320&auto=format&fit=crop',
      dropPercent: 15,
      oldPriceText: '52,00₺',
      priceText: '45,00₺',
      market: 'Carrefour',
    ),
  ];

  final List<ScanItem> _latestScans = const [
    ScanItem(
      name: 'Komili Zeytinyağı 1L',
      detail: 'A-101 • Ahmet ekledi',
      priceText: '272,00₺',
      deltaText: '48₺ Ucuzladı',
      deltaType: PriceDeltaType.drop,
    ),
    ScanItem(
      name: 'Doğuş Çay 1Kg',
      detail: 'Migros • Sistem',
      priceText: '165,00₺',
      deltaText: '15₺ Zamlandı',
      deltaType: PriceDeltaType.rise,
    ),
    ScanItem(
      name: 'Osmancık Pirinç 2.5Kg',
      detail: 'BİM • Ceren ekledi',
      priceText: '95,00₺',
      deltaText: 'Fiyat Sabit',
      deltaType: PriceDeltaType.neutral,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: FRColors.bgApp,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _EliteHeader(topPadding: topPadding),
                const Positioned(
                  left: 24,
                  right: 24,
                  bottom: -24,
                  child: _FloatingSearchBar(),
                ),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 44)),
          SliverToBoxAdapter(child: _buildCategoriesSection()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
              child: const _MegaBannerCard(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
              child: _RadarAnalysisCard(data: _analysisData),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 36),
              child: _HardDropsSection(items: _hardDrops),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
              child: _LatestScansBlock(items: _latestScans),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return SizedBox(
      height: 98,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategoryIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategoryIndex = index),
            child: SizedBox(
              width: 74,
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: isSelected ? FRColors.darkMain : FRColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isSelected ? 0.16 : 0.05),
                          blurRadius: isSelected ? 20 : 12,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      category.icon,
                      color: isSelected ? FRColors.surface : FRColors.textMuted,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category.label,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: FRColors.textMain,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemCount: _categories.length,
      ),
    );
  }
}

class _EliteHeader extends StatelessWidget {
  const _EliteHeader({required this.topPadding});

  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, topPadding + 14, 24, 50),
      decoration: const BoxDecoration(
        color: FRColors.darkMain,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: FRColors.gold, width: 1.5),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl:
                          'https://images.unsplash.com/photo-1599566150163-29194dcaad36?q=80&w=100&auto=format&fit=crop',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hoş geldin,',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          color: FRColors.gold,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Adem Bayram',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          color: FRColors.surface,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              color: Colors.white.withOpacity(0.08),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.stars_rounded, color: FRColors.gold, size: 16),
                const SizedBox(width: 5),
                Text(
                  '20.506',
                  style: GoogleFonts.outfit(
                    color: FRColors.gold,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.white.withOpacity(0.05),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Center(
                  child: Icon(Icons.notifications_rounded, color: FRColors.surface, size: 20),
                ),
                Positioned(
                  right: 10,
                  top: 9,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(color: FRColors.danger, shape: BoxShape.circle),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingSearchBar extends StatelessWidget {
  const _FloatingSearchBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.only(left: 16, right: 6),
      decoration: BoxDecoration(
        color: FRColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: FRColors.textMuted, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Ürün, marka veya mağaza ara...',
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                color: FRColors.textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: FRColors.studio,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.qr_code_scanner_rounded, color: FRColors.darkMain, size: 21),
          ),
        ],
      ),
    );
  }
}

class _MegaBannerCard extends StatelessWidget {
  const _MegaBannerCard();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl:
                  'https://images.unsplash.com/photo-1542838132-92c53300491e?q=80&w=900&auto=format&fit=crop',
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    FRColors.darkMain.withOpacity(0.95),
                    FRColors.darkMain.withOpacity(0.10),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: FRColors.gold,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'HAFTANIN YILDIZI',
                      style: GoogleFonts.outfit(
                        color: FRColors.darkMain,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Temel Gıdada\nDev İndirim',
                    style: GoogleFonts.outfit(
                      color: FRColors.surface,
                      fontSize: 27,
                      height: 1.0,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
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

class _RadarAnalysisCard extends StatelessWidget {
  const _RadarAnalysisCard({required this.data});

  final RadarAnalysisData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FRColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: FRColors.darkMain.withOpacity(0.08),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Radar Analizi',
                  style: GoogleFonts.outfit(
                    color: FRColors.textMain,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: FRColors.dangerBg,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(color: FRColors.danger, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'CANLI',
                      style: GoogleFonts.outfit(
                        color: FRColors.danger,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 70,
                height: 70,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: FRColors.studio,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: CachedNetworkImage(imageUrl: data.imageUrl, fit: BoxFit.contain),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.brand,
                      style: GoogleFonts.outfit(
                        color: FRColors.gold,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      data.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        color: FRColors.textMain,
                        fontSize: 15,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.avgPriceText,
                      style: GoogleFonts.outfit(
                        color: FRColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Column(
            children: data.rows
                .map(
                  (row) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _AnalysisBarRow(row: row),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _AnalysisBarRow extends StatelessWidget {
  const _AnalysisBarRow({required this.row});

  final AnalysisRow row;

  @override
  Widget build(BuildContext context) {
    final fillColor = row.isBest ? FRColors.gold : FRColors.textMuted.withOpacity(0.50);
    final marketColor = row.isBest ? FRColors.gold : FRColors.textMuted;
    final priceColor = row.isBest ? FRColors.gold : FRColors.textMain;

    return Row(
      children: [
        SizedBox(
          width: 54,
          child: Text(
            row.market,
            style: GoogleFonts.outfit(
              color: marketColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: SizedBox(
              height: 8,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: FRColors.studio),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: row.fill,
                      child: Container(color: fillColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 62,
          child: Text(
            row.priceText,
            textAlign: TextAlign.right,
            style: GoogleFonts.outfit(
              color: priceColor,
              fontSize: row.isBest ? 14 : 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _HardDropsSection extends StatelessWidget {
  const _HardDropsSection({required this.items});

  final List<HardDropItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: FRColors.darkMain,
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Sert Düşüşler',
                    style: GoogleFonts.outfit(
                      color: FRColors.surface,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  'Tümünü Gör',
                  style: GoogleFonts.outfit(
                    color: FRColors.gold,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 278,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) => _HardDropCard(item: items[index]),
            ),
          ),
        ],
      ),
    );
  }
}

class _HardDropCard extends StatelessWidget {
  const _HardDropCard({required this.item});

  final HardDropItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FRColors.darkSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white.withOpacity(0.03),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: CachedNetworkImage(imageUrl: item.imageUrl, fit: BoxFit.contain),
                  ),
                ),
                Positioned(
                  left: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF69F0AE).withOpacity(0.14),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF69F0AE).withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.arrow_downward_rounded, color: Color(0xFF69F0AE), size: 12),
                        const SizedBox(width: 2),
                        Text(
                          '%${item.dropPercent}',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF69F0AE),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.brand,
                  style: GoogleFonts.outfit(
                    color: FRColors.gold,
                    fontSize: 10,
                    letterSpacing: 0.4,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: FRColors.surface,
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.oldPriceText,
                            style: GoogleFonts.outfit(
                              color: Colors.white.withOpacity(0.42),
                              fontSize: 10,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          Text(
                            item.priceText,
                            style: GoogleFonts.outfit(
                              color: FRColors.gold,
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: FRColors.gold,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.market,
                        style: GoogleFonts.outfit(
                          color: FRColors.darkMain,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LatestScansBlock extends StatelessWidget {
  const _LatestScansBlock({required this.items});

  final List<ScanItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Son Taramalar',
          style: GoogleFonts.outfit(
            color: FRColors.textMain,
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: FRColors.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: FRColors.darkMain.withOpacity(0.05),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: List.generate(items.length, (index) {
              final item = items[index];
              return _LatestScanRow(
                item: item,
                hasDivider: index < items.length - 1,
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _LatestScanRow extends StatelessWidget {
  const _LatestScanRow({required this.item, required this.hasDivider});

  final ScanItem item;
  final bool hasDivider;

  @override
  Widget build(BuildContext context) {
    final isDrop = item.deltaType == PriceDeltaType.drop;
    final isRise = item.deltaType == PriceDeltaType.rise;
    final iconBg = isDrop
        ? FRColors.successBg
        : isRise
            ? FRColors.dangerBg
            : FRColors.studio;
    final iconColor = isDrop
        ? FRColors.success
        : isRise
            ? FRColors.danger
            : FRColors.textMuted;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
                child: Icon(
                  isDrop
                      ? Icons.trending_down_rounded
                      : isRise
                          ? Icons.trending_up_rounded
                          : Icons.drag_handle_rounded,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        color: FRColors.textMain,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        color: FRColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    item.priceText,
                    style: GoogleFonts.outfit(
                      color: FRColors.darkMain,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  _TrendLabel(item: item),
                ],
              ),
            ],
          ),
        ),
        if (hasDivider)
          Divider(
            height: 1,
            thickness: 1,
            indent: 20,
            endIndent: 20,
            color: FRColors.darkMain.withOpacity(0.05),
          ),
      ],
    );
  }
}

class _TrendLabel extends StatelessWidget {
  const _TrendLabel({required this.item});

  final ScanItem item;

  @override
  Widget build(BuildContext context) {
    switch (item.deltaType) {
      case PriceDeltaType.drop:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.south_east_rounded, color: FRColors.success, size: 12),
            const SizedBox(width: 2),
            Text(
              item.deltaText,
              style: GoogleFonts.outfit(color: FRColors.success, fontSize: 10, fontWeight: FontWeight.w800),
            ),
          ],
        );
      case PriceDeltaType.rise:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.north_east_rounded, color: FRColors.danger, size: 12),
            const SizedBox(width: 2),
            Text(
              item.deltaText,
              style: GoogleFonts.outfit(color: FRColors.danger, fontSize: 10, fontWeight: FontWeight.w800),
            ),
          ],
        );
      case PriceDeltaType.neutral:
        return Text(
          item.deltaText,
          style: GoogleFonts.outfit(color: FRColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600),
        );
    }
  }
}

class HomeCategory {
  const HomeCategory({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class RadarAnalysisData {
  const RadarAnalysisData({
    required this.brand,
    required this.title,
    required this.avgPriceText,
    required this.imageUrl,
    required this.rows,
  });

  final String brand;
  final String title;
  final String avgPriceText;
  final String imageUrl;
  final List<AnalysisRow> rows;
}

class AnalysisRow {
  const AnalysisRow({
    required this.market,
    required this.priceText,
    required this.fill,
    this.isBest = false,
  });

  final String market;
  final String priceText;
  final double fill;
  final bool isBest;
}

class HardDropItem {
  const HardDropItem({
    required this.brand,
    required this.title,
    required this.imageUrl,
    required this.dropPercent,
    required this.oldPriceText,
    required this.priceText,
    required this.market,
  });

  final String brand;
  final String title;
  final String imageUrl;
  final int dropPercent;
  final String oldPriceText;
  final String priceText;
  final String market;
}

enum PriceDeltaType { drop, rise, neutral }

class ScanItem {
  const ScanItem({
    required this.name,
    required this.detail,
    required this.priceText,
    required this.deltaText,
    required this.deltaType,
  });

  final String name;
  final String detail;
  final String priceText;
  final String deltaText;
  final PriceDeltaType deltaType;
}
