import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/explore_provider.dart';
import '../../providers/notification_provider.dart';
import '../actual/actuals_screen.dart';
import '../add_price/add_price_screen.dart';
import '../notifications/notifications_screen.dart';
import '../product/product_detail_screen.dart';
import '../../features/cart_analysis/views/cart_analysis_screen.dart';
import 'personal_lists_screen.dart';

const _bg = Color(0xFFEDEAE3);
const _surface = Color(0xFFFAFAF8);
const _surface2 = Color(0xFFF5F3F0);
const _dk = Color(0xFF18100A);
const _dk2 = Color(0xFF261808);
const _tc = Color(0xFFBF9470);
const _t1 = Color(0xFF18100A);
const _t2 = Color(0xFF5E4A38);
const _t3 = Color(0xFFA0887A);
const _line = Color.fromRGBO(24, 16, 10, 0.08);
const _grn = Color(0xFF27A85A);
const _red = Color(0xFFE53935);

TextStyle _jakarta({
  double size = 14,
  FontWeight weight = FontWeight.w500,
  Color color = _t1,
  FontStyle? style,
  double? height,
  double? letterSpacing,
  TextDecoration? decoration,
}) {
  return GoogleFonts.plusJakartaSans(
    fontSize: size,
    fontWeight: weight,
    color: color,
    fontStyle: style,
    height: height,
    letterSpacing: letterSpacing,
    decoration: decoration,
  );
}

TextStyle _serif({
  double size = 20,
  Color color = _t1,
  double? height,
  double? letterSpacing,
}) {
  return GoogleFonts.dmSerifDisplay(
    fontSize: size,
    fontWeight: FontWeight.w400,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );
}

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final Set<String> _favorites = <String>{};
  final _marketFilters = const ['Tümü', 'A-101', 'BİM', 'Trendyol', 'ŞOK'];
  final _signalFilters = const ['Gerçek Düşüş', '24 Saatte', 'En Yakın'];

  String _selectedMarket = 'Tümü';
  String _selectedSignal = 'Gerçek Düşüş';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(exploreControllerProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    final allProducts = state.items;
    final products = _selectedMarket == 'Tümü'
        ? allProducts
        : allProducts.where((e) => e.storeName.toLowerCase() == _selectedMarket.toLowerCase()).toList();

    final locationLabel = (products.isNotEmpty ? products.first : allProducts.isNotEmpty ? allProducts.first : null)?.locationLabel;

    return Scaffold(
      backgroundColor: const Color(0xFFC8C4BC),
      body: SafeArea(
        bottom: false,
        child: Container(
          color: _bg,
          child: Column(
            children: [
              _Header(
                controller: _searchController,
                unreadCount: unreadCount,
                onLocationTap: () => _showLocationPeek(context, locationLabel),
                onNotifications: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _RadarSection(cards: _buildRadarCards(products.isNotEmpty ? products : allProducts)),
                        const SizedBox(height: 16),
                        _ActualLinkCard(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(builder: (_) => const ActualsScreen()),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _FilterChips(
                          items: _marketFilters,
                          selected: _selectedMarket,
                          marketDots: true,
                          onChanged: (v) => setState(() => _selectedMarket = v),
                        ),
                        const SizedBox(height: 16),
                        _FilterChips(
                          items: _signalFilters,
                          selected: _selectedSignal,
                          compact: true,
                          onChanged: (v) => setState(() => _selectedSignal = v),
                        ),
                        const SizedBox(height: 4),
                        Text('En Güçlü Sinyaller', style: _serif(size: 20, letterSpacing: -0.3)),
                        const SizedBox(height: 12),
                        if (state.loading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(child: CircularProgressIndicator(color: _tc)),
                          )
                        else if (products.isEmpty)
                          _emptySignals()
                        else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.58,
                            ),
                            itemCount: products.length,
                            itemBuilder: (context, i) {
                              final item = products[i];
                              return _ProductCard(
                                item: item,
                                isFavorite: _favorites.contains(item.product.id),
                                onFavorite: () {
                                  setState(() {
                                    if (!_favorites.add(item.product.id)) {
                                      _favorites.remove(item.product.id);
                                    }
                                  });
                                },
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => ProductDetailScreen(productId: item.product.id),
                                  ),
                                ),
                              );
                            },
                          ),
                        const SizedBox(height: 16),
                        const _PersonalListsSection(),
                        const SizedBox(height: 16),
                        _CategorySection(items: allProducts),
                        const SizedBox(height: 16),
                        _LiveRadarSection(items: allProducts),
                        const SizedBox(height: 16),
                        _QuickTools(
                          onCartCompare: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(builder: (_) => const CartAnalysisScreen()),
                          ),
                          onAlarm: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _FooterCta(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(builder: (_) => const AddPriceScreen()),
                          ),
                        ),
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLocationPeek(BuildContext context, String? label) {
    final location = (label == null || label.trim().isEmpty) ? 'Konum bulunamadı' : label;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        backgroundColor: _dk,
        margin: const EdgeInsets.fromLTRB(16, 0, 120, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Row(
          children: [
            const Icon(Icons.location_on_rounded, color: _tc, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                location,
                overflow: TextOverflow.ellipsis,
                style: _jakarta(size: 12, weight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptySignals() {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _line),
      ),
      padding: const EdgeInsets.all(16),
      child: Text(
        'Seçilen filtrede ürün yok.',
        style: _jakarta(size: 12, weight: FontWeight.w700, color: _t3),
      ),
    );
  }

  List<_RadarData> _buildRadarCards(List<ExploreFeedItem> items) {
    if (items.isEmpty) {
      return const [_RadarData(percent: 0, label: 'Veri bekleniyor', count: 0, hot: true)];
    }
    final grouped = <String, List<ExploreFeedItem>>{};
    for (final item in items) {
      final key = item.product.categories.isEmpty ? 'Diğer' : item.product.categories.first;
      grouped.putIfAbsent(key, () => <ExploreFeedItem>[]).add(item);
    }

    final list = grouped.entries
        .map(
          (entry) => _RadarData(
            percent: entry.value
                    .map((e) => e.priceChangePercent ?? -e.dropPercent)
                    .fold<double>(0, (a, b) => a + b) /
                entry.value.length,
            label: entry.key,
            count: entry.value.length,
          ),
        )
        .toList()
      ..sort((a, b) => a.percent.compareTo(b.percent));

    return list.take(3).toList().asMap().entries.map((e) {
      final v = e.value;
      return _RadarData(percent: v.percent, label: v.label, count: v.count, hot: e.key == 0);
    }).toList();
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.controller, required this.unreadCount, required this.onNotifications, required this.onLocationTap});

  final TextEditingController controller;
  final int unreadCount;
  final VoidCallback onNotifications;
  final VoidCallback onLocationTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _dk,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [BoxShadow(color: Color.fromRGBO(24, 16, 10, 0.15), blurRadius: 24, offset: Offset(0, 10))],
      ),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text('Keşfet.', style: _serif(size: 32, color: Colors.white, height: 1, letterSpacing: -0.5))),
              _HeaderButton(icon: Icons.location_on_outlined, onTap: onLocationTap),
              const SizedBox(width: 8),
              _HeaderButton(icon: Icons.notifications_none_rounded, badge: unreadCount > 0 ? '$unreadCount' : null, onTap: onNotifications),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 48,
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'Ürün, marka veya barkod ara...',
                hintStyle: _jakarta(size: 14, weight: FontWeight.w400, color: _t3, style: FontStyle.italic),
                prefixIcon: const Icon(Icons.search, size: 18, color: _t3),
                suffixIcon: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Container(
                    decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.qr_code_2_rounded, size: 16, color: _dk),
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.icon, required this.onTap, this.badge});

  final IconData icon;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color.fromRGBO(255, 255, 255, 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color.fromRGBO(191, 148, 112, 0.2)),
            ),
            child: Icon(icon, size: 18, color: _tc),
          ),
          if (badge != null)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _red,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: _dk, width: 2),
                ),
                child: Text(badge!, style: _jakarta(size: 10, weight: FontWeight.w900, color: Colors.white)),
              ),
            ),
        ],
      ),
    );
  }
}

class _RadarSection extends StatelessWidget {
  const _RadarSection({required this.cards});

  final List<_RadarData> cards;

  @override
  Widget build(BuildContext context) {
    return _SectionBox(
      child: Column(
        children: [
          _SectionHead(title: 'Radar Sıcaklığı', action: 'Tümünü Gör'),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.88,
            ),
            itemCount: cards.length,
            itemBuilder: (context, i) {
              final card = cards[i];
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: card.hot ? const Color.fromRGBO(191, 148, 112, 0.3) : _line),
                  gradient: card.hot
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color.fromRGBO(191, 148, 112, 0.15), Color.fromRGBO(191, 148, 112, 0.05)],
                        )
                      : null,
                  color: card.hot ? null : _surface2,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${card.percent > 0 ? '+' : ''}${card.percent.round()}%',
                      style: _serif(size: 22, color: card.hot ? _tc : _grn, height: 1),
                    ),
                    const SizedBox(height: 2),
                    Text(card.label, style: _jakarta(size: 11, weight: FontWeight.w800), textAlign: TextAlign.center),
                    const SizedBox(height: 2),
                    Text('${card.count} ürün', style: _jakarta(size: 10, weight: FontWeight.w600, color: _t3)),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ActualLinkCard extends StatelessWidget {
  const _ActualLinkCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(colors: [_dk, Color(0xFF2A1A0B)]),
          boxShadow: const [BoxShadow(color: Color.fromRGBO(24, 16, 10, 0.15), blurRadius: 30, offset: Offset(0, 10))],
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Aktüel Fırsatlar', style: _serif(size: 22, color: Colors.white, letterSpacing: -0.3)),
                  const SizedBox(height: 4),
                  Text('BİM, A-101 Canlı Stok Takibi', style: _jakarta(size: 12, color: const Color.fromRGBO(255, 255, 255, 0.6))),
                ],
              ),
            ),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color.fromRGBO(191, 148, 112, 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color.fromRGBO(191, 148, 112, 0.2)),
              ),
              child: const Icon(Icons.chevron_right_rounded, size: 20, color: _tc),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.items, required this.selected, required this.onChanged, this.compact = false, this.marketDots = false});

  final List<String> items;
  final String selected;
  final bool compact;
  final bool marketDots;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: compact ? 36 : 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final label = items[i];
          final active = label == selected;
          return GestureDetector(
            onTap: () => onChanged(label),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 16, vertical: compact ? 8 : 10),
              decoration: BoxDecoration(
                color: active ? _dk : _surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: active ? _dk : _line),
                boxShadow: [
                  BoxShadow(
                    color: active ? const Color.fromRGBO(24, 16, 10, 0.15) : const Color.fromRGBO(0, 0, 0, 0.02),
                    blurRadius: active ? 16 : 10,
                    offset: active ? const Offset(0, 6) : const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (marketDots) ...[
                    Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: _marketColor(label))),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: _jakarta(size: compact ? 11 : 12, weight: FontWeight.w800, color: active ? Colors.white : _t2),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.item, required this.isFavorite, required this.onFavorite, required this.onTap});

  final ExploreFeedItem item;
  final bool isFavorite;
  final VoidCallback onFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final changePercent = item.priceChangePercent;
    final old = (changePercent != null && changePercent < 0 && (100 + changePercent) > 0)
        ? item.displayPrice / (1 + (changePercent / 100))
        : null;
    final hasOld = old != null && old > item.displayPrice;
    final showOnline = item.isPrimaryOnlineCheapest;
    final distance = item.distanceLabel ?? '${100 + math.Random(item.product.id.hashCode).nextInt(500)}m';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _line),
          boxShadow: const [BoxShadow(color: Color.fromRGBO(24, 16, 10, 0.04), blurRadius: 20, offset: Offset(0, 8))],
        ),
        child: Column(
          children: [
            Container(
              height: 160,
              decoration: const BoxDecoration(
                color: Color(0xFFF8F4EE),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(bottom: BorderSide(color: _line)),
              ),
              padding: const EdgeInsets.all(8),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Image.network(
                      item.product.effectiveImage ?? '',
                      fit: BoxFit.contain,
                      width: 100,
                      height: 100,
                      errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_outlined, color: _t3),
                    ),
                  ),
                  Positioned(top: 4, left: 4, child: _badge(item)),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: onFavorite,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.08), blurRadius: 10, offset: Offset(0, 4))],
                        ),
                        child: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, size: 14, color: isFavorite ? _red : _t3),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.product.brand.toUpperCase(), style: _jakarta(size: 9, weight: FontWeight.w900, color: _tc, letterSpacing: 0.6)),
                    const SizedBox(height: 4),
                    Text(item.product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: _jakarta(size: 13, weight: FontWeight.w800, height: 1.3)),
                    const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${item.displayPrice.toStringAsFixed(2).replaceAll('.', ',')}₺', style: _serif(size: 22, height: 1)),
                        const SizedBox(width: 6),
                        if (hasOld)
                          Text(
                            '${old.toStringAsFixed(2).replaceAll('.', ',')}₺',
                            style: _jakarta(size: 12, weight: FontWeight.w600, color: _t3, decoration: TextDecoration.lineThrough),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: const BoxDecoration(
                color: Color.fromRGBO(255, 255, 255, 0.5),
                border: Border(top: BorderSide(color: Color.fromRGBO(24, 16, 10, 0.08), style: BorderStyle.solid)),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: _marketColor(item.storeName))),
                  const SizedBox(width: 4),
                  Expanded(child: Text(item.storeName, style: _jakarta(size: 10, weight: FontWeight.w800, color: _t2))),
                  const SizedBox(width: 4),
                  Icon(showOnline ? Icons.public : Icons.location_on_outlined, size: 10, color: _t3),
                  const SizedBox(width: 3),
                  Text(showOnline ? 'Online' : distance, style: _jakarta(size: 9, weight: FontWeight.w700, color: _t3)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(ExploreFeedItem item) {
    final dip = item.dropPercent <= -18;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: dip ? const Color.fromRGBO(191, 148, 112, 0.15) : const Color.fromRGBO(39, 168, 90, 0.15),
        border: Border.all(color: dip ? const Color.fromRGBO(191, 148, 112, 0.3) : const Color.fromRGBO(39, 168, 90, 0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        dip ? 'DİP FİYAT' : '%${item.dropPercent.abs().round()}',
        style: _jakarta(size: 9, weight: FontWeight.w900, color: dip ? _dk : _grn, letterSpacing: 0.5),
      ),
    );
  }
}

class _PersonalListsSection extends StatelessWidget {
  const _PersonalListsSection();

  @override
  Widget build(BuildContext context) {
    return _SectionBox(
      child: Column(
        children: [
          _SectionHead(
            title: 'Sana Özel Listeler',
            action: 'Tümü',
            onActionTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const PersonalListsScreen()),
            ),
          ),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('curated_lists')
                .orderBy('order')
                .limit(1)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _listCard(title: 'Liste yüklenemedi', subtitle: 'Lütfen daha sonra tekrar dene.', products: const []);
              }

              final docs = snapshot.data?.docs.where((doc) => doc.data()['isActive'] == true).toList() ?? const [];
              if (docs.isEmpty) {
                return _listCard(
                  title: 'Henüz özel liste yok',
                  subtitle: 'Admin panelinden yeni liste ekleyebilirsin.',
                  products: const [],
                );
              }

              final data = docs.first.data();
              final products = (data['products'] as List<dynamic>? ?? const <dynamic>[]).map((e) => e.toString()).toList();
              return GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const PersonalListsScreen()),
                ),
                child: _listCard(
                  title: (data['title'] as String? ?? 'Özel Liste').trim(),
                  subtitle: (data['subtitle'] as String? ?? 'Senin için hazırlandı').trim(),
                  products: products,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _listCard({required String title, required String subtitle, required List<String> products}) {
    final limited = products.take(5).toList();
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _line),
        boxShadow: const [BoxShadow(color: Color.fromRGBO(24, 16, 10, 0.03), blurRadius: 16, offset: Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(191, 148, 112, 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color.fromRGBO(191, 148, 112, 0.2)),
                ),
                child: const Icon(Icons.description_outlined, color: _tc, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: _jakarta(size: 15, weight: FontWeight.w800)),
                    Text(subtitle, style: _jakarta(size: 11, weight: FontWeight.w600, color: _t3)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color.fromRGBO(24, 16, 10, 0.08)),
          const SizedBox(height: 14),
          if (limited.isEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Bu liste henüz ürün içermiyor.', style: _jakarta(size: 11, weight: FontWeight.w600, color: _t3)),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: limited
                  .map(
                    (product) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _surface2,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _line),
                      ),
                      child: Text(product, style: _jakarta(size: 10, weight: FontWeight.w700, color: _t2)),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({required this.items});

  final List<ExploreFeedItem> items;

  @override
  Widget build(BuildContext context) {
    final categoryCounts = <String, int>{};
    for (final item in items) {
      final category = item.product.categories.isNotEmpty ? item.product.categories.first.trim() : 'Diğer';
      if (category.isEmpty) continue;
      categoryCounts.update(category, (value) => value + 1, ifAbsent: () => 1);
    }

    final sorted = categoryCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final labels = sorted.take(8).map((e) => e.key).toList();

    if (labels.isEmpty) {
      labels.addAll(const ['Diğer']);
    }

    return _SectionBox(
      child: Column(
        children: [
          const _SectionHead(title: 'Kategoriler'),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.75,
            ),
            itemCount: labels.length,
            itemBuilder: (context, i) => Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _line),
                    boxShadow: const [BoxShadow(color: Color.fromRGBO(24, 16, 10, 0.04), blurRadius: 12, offset: Offset(0, 4))],
                  ),
                  child: Icon(_iconForCategory(labels[i]), color: _tc, size: 22),
                ),
                const SizedBox(height: 8),
                Text(labels[i], style: _jakarta(size: 11, weight: FontWeight.w800, color: _t2), textAlign: TextAlign.center),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForCategory(String category) {
    final key = category.toLowerCase();
    if (key.contains('gıda') || key.contains('yiyecek')) return Icons.restaurant_menu;
    if (key.contains('içecek')) return Icons.local_drink_outlined;
    if (key.contains('temizlik') || key.contains('ev')) return Icons.cleaning_services_outlined;
    if (key.contains('bakım') || key.contains('kozmetik')) return Icons.spa_outlined;
    if (key.contains('teknoloji')) return Icons.devices_outlined;
    if (key.contains('giyim')) return Icons.checkroom_outlined;
    return Icons.category_outlined;
  }
}

class _LiveRadarSection extends StatelessWidget {
  const _LiveRadarSection({required this.items});

  final List<ExploreFeedItem> items;

  @override
  Widget build(BuildContext context) {
    final latest = [...items]..sort((a, b) => b.price.createdAt.compareTo(a.price.createdAt));
    final top = latest.take(4).toList();

    return _SectionBox(
      child: Column(
        children: [
          const _SectionHead(
            title: 'Canlı Radar Akışı 🔴',
          ),
          if (top.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('Henüz canlı fiyat akışı yok.', style: _jakarta(size: 12, weight: FontWeight.w700, color: _t3)),
            )
          else
            ...top.asMap().entries.map(
              (entry) {
                final item = entry.value;
                final showDivider = entry.key != top.length - 1;
                final subtitle = '${item.storeName} • ${_timeAgo(item.price.createdAt)}';
                return _contrib(
                  _avatarFromName(item.product.name),
                  item.product.name,
                  subtitle,
                  '${item.displayPrice.toStringAsFixed(0)}₺',
                  inverse: entry.key.isOdd,
                  showDivider: showDivider,
                );
              },
            ),
        ],
      ),
    );
  }

  String _avatarFromName(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'FR';
    if (parts.length == 1) return parts.first.substring(0, math.min(2, parts.first.length)).toUpperCase();
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'şimdi';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
    if (diff.inHours < 24) return '${diff.inHours} sa önce';
    return '${diff.inDays} gün önce';
  }

  Widget _contrib(String avatar, String title, String subtitle, String price, {bool inverse = false, bool showDivider = true}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: showDivider ? const Border(bottom: BorderSide(color: Color.fromRGBO(24, 16, 10, 0.08), style: BorderStyle.solid)) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: inverse ? _tc : _surface2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _line),
            ),
            alignment: Alignment.center,
            child: Text(avatar, style: _jakarta(size: 14, weight: FontWeight.w800, color: inverse ? _dk : _tc)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _jakarta(size: 13, weight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(subtitle, style: _jakarta(size: 11, weight: FontWeight.w600, color: _t3), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(price, style: _serif(size: 20)),
        ],
      ),
    );
  }
}

class _QuickTools extends StatelessWidget {
  const _QuickTools({required this.onCartCompare, required this.onAlarm});

  final VoidCallback onCartCompare;
  final VoidCallback onAlarm;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text('Hızlı Araçlar', style: _serif(size: 20, letterSpacing: -0.3)),
        ),
        _tool(
          dark: true,
          title: 'Sepet Kıyasla',
          subtitle: 'Marketleri karşılaştır',
          icon: Icons.shopping_cart_outlined,
          onTap: onCartCompare,
        ),
        const SizedBox(height: 12),
        _tool(
          title: 'Fiyat Alarmı Kur',
          subtitle: 'Düşünce bildirim al',
          icon: Icons.notifications_none_rounded,
          onTap: onAlarm,
        ),
      ],
    );
  }

  Widget _tool({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool dark = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: dark ? _dk : _surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: dark ? const Color.fromRGBO(191, 148, 112, 0.2) : _line),
          boxShadow: const [BoxShadow(color: Color.fromRGBO(24, 16, 10, 0.04), blurRadius: 16, offset: Offset(0, 4))],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: dark ? const Color.fromRGBO(191, 148, 112, 0.15) : _surface2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: dark ? const Color.fromRGBO(191, 148, 112, 0.2) : _line),
              ),
              child: Icon(icon, size: 22, color: _tc),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _jakarta(size: 15, weight: FontWeight.w800, color: dark ? Colors.white : _t1)),
                Text(
                  subtitle,
                  style: _jakarta(size: 11, weight: FontWeight.w600, color: dark ? const Color.fromRGBO(255, 255, 255, 0.6) : _t3),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterCta extends StatelessWidget {
  const _FooterCta({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(colors: [_dk, _dk2]),
        border: Border.all(color: const Color.fromRGBO(191, 148, 112, 0.3)),
        boxShadow: const [BoxShadow(color: Color.fromRGBO(24, 16, 10, 0.2), blurRadius: 30, offset: Offset(0, 10))],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color.fromRGBO(191, 148, 112, 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color.fromRGBO(191, 148, 112, 0.25)),
            ),
            child: const Icon(Icons.add_circle_outline, size: 26, color: _tc),
          ),
          const SizedBox(height: 14),
          Text('Fiyat Ekle, Puan Kazan', style: _jakarta(size: 20, weight: FontWeight.w800, color: Colors.white, letterSpacing: -0.3)),
          const SizedBox(height: 8),
          Text(
            'Raflardaki güncel fiyatları okut, Radar Puanları toplayarak Premium ödüllerin kilidini aç.',
            style: _jakarta(size: 11, weight: FontWeight.w500, color: const Color.fromRGBO(255, 255, 255, 0.6), height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                backgroundColor: _tc,
                foregroundColor: _dk,
              ),
              child: Text('Hemen Başla', style: _jakarta(size: 14, weight: FontWeight.w800, color: _dk)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionBox extends StatelessWidget {
  const _SectionBox({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _line),
        boxShadow: const [BoxShadow(color: Color.fromRGBO(24, 16, 10, 0.04), blurRadius: 20, offset: Offset(0, 8))],
      ),
      padding: const EdgeInsets.all(18),
      child: child,
    );
  }
}

class _SectionHead extends StatelessWidget {
  const _SectionHead({required this.title, this.action, this.onActionTap});

  final String title;
  final String? action;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(child: Text(title, style: _serif(size: 20, letterSpacing: -0.3))),
          if (action != null)
            GestureDetector(
              onTap: onActionTap,
              child: Text(action!, style: _jakarta(size: 12, weight: FontWeight.w800, color: _tc)),
            ),
        ],
      ),
    );
  }
}

class _RadarData {
  const _RadarData({required this.percent, required this.label, required this.count, this.hot = false});

  final double percent;
  final String label;
  final int count;
  final bool hot;
}

Color _marketColor(String market) {
  switch (market.toLowerCase()) {
    case 'a-101':
      return const Color(0xFFD44020);
    case 'bi̇m':
    case 'bim':
      return const Color(0xFFD4A000);
    case 'trendyol':
      return const Color(0xFFF27A1A);
    case 'şok':
    case 'sok':
      return const Color(0xFF7B3FA0);
    case 'tümü':
      return _dk;
    default:
      return _t3;
  }
}
