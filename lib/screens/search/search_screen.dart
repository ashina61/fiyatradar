import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/auth_provider.dart';
import '../../providers/explore_provider.dart';
import '../../providers/product_provider.dart';
import '../../services/firestore_service.dart';
import '../actual/actuals_screen.dart';
import '../add_price/add_price_screen.dart';
import '../product/product_detail_screen.dart';

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

String? _extractLocationLabel(String? address) {
  if (address == null || address.trim().isEmpty) return null;
  final parts = address
      .split(',')
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return null;

  final neighborhood = parts.first;
  final normalized = neighborhood.toLowerCase();
  if (normalized.endsWith('mah.') || normalized.endsWith('mah')) {
    return neighborhood;
  }

  if (normalized.contains('mah')) {
    return neighborhood;
  }

  return '$neighborhood Mah.';
}

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _marketFilters = const ['Tümü', 'A101', 'ŞOK', 'BİM'];

  String _selectedMarket = 'Tümü';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(exploreControllerProvider);
    final allProducts = state.items;
    final categoryFiltered = _matchesCategory(state.selectedCategory, allProducts);
    final products = _selectedMarket == 'Tümü' ? categoryFiltered : categoryFiltered.where((e) => _matchesMarket(e.storeName)).toList();
    final primaryItem = products.isNotEmpty ? products.first : allProducts.isNotEmpty ? allProducts.first : null;
    final fallbackLocation = primaryItem == null
        ? null
        : primaryItem.neighborhoodLabel != '—'
        ? primaryItem.neighborhoodLabel
        : primaryItem.locationLabel;
    final locationLabel = _extractLocationLabel(state.userLocation?.address) ?? fallbackLocation;

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
                locationLabel: locationLabel,
                onSearchTap: () => _openSearchExperience(context),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _CategoryCapsuleChips(
                          categories: state.categories,
                          selected: state.selectedCategory,
                          onChanged: (value) => ref.read(exploreControllerProvider.notifier).updateCategory(value),
                        ),
                        const SizedBox(height: 16),
                        _ActualLinkCard(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(builder: (_) => const ActualsScreen()),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('Ürünler', style: _serif(size: 20, letterSpacing: -0.3)),
                        const SizedBox(height: 12),
                        _FilterChips(
                          items: _marketFilters,
                          selected: _selectedMarket,
                          marketDots: true,
                          onChanged: (v) => setState(() => _selectedMarket = v),
                        ),
                        const SizedBox(height: 12),
                        if (state.loading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(child: CircularProgressIndicator(color: _tc)),
                          )
                        else if (products.isEmpty)
                          _emptySignals()
                        else
                          _ProductGrid(
                            products: products,
                            onTapItem: (item) => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => ProductDetailScreen(productId: item.product.id),
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        _LiveRadarSection(items: allProducts),
                        const SizedBox(height: 16),
                        _FollowedProductsSection(
                          items: allProducts.where((item) => _isFavorite(ref, item.product.id)).toList(),
                          onTapItem: (item) => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => ProductDetailScreen(productId: item.product.id),
                            ),
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


  void _openSearchExperience(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ExploreSearchRoute(initialQuery: _searchController.text),
      ),
    );
  }

  List<ExploreFeedItem> _matchesCategory(String selectedCategory, List<ExploreFeedItem> source) {
    if (selectedCategory.trim().toLowerCase() == 'tumu' || selectedCategory.trim().toLowerCase() == 'tümü') {
      return source;
    }
    final normalized = selectedCategory.trim().toLowerCase();
    return source.where((item) {
      final categories = item.product.categories.map((e) => e.trim().toLowerCase());
      return categories.contains(normalized);
    }).toList();
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

  bool _matchesMarket(String storeName) {
    final normalizedStore = storeName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9çğıöşü]'), '');
    final normalizedSelected = _selectedMarket.toLowerCase().replaceAll(RegExp(r'[^a-z0-9çğıöşü]'), '');
    if (normalizedSelected == 'a101') {
      return normalizedStore.contains('a101');
    }
    return normalizedStore.contains(normalizedSelected);
  }

  bool _isFavorite(WidgetRef ref, String productId) {
    final override = ref.watch(favoriteOverrideProvider(productId));
    final fromStream = ref.watch(isFavoriteProvider(productId)).valueOrNull ?? false;
    return override ?? fromStream;
  }
}

class _ProductGrid extends StatelessWidget {
  const _ProductGrid({required this.products, required this.onTapItem});

  final List<ExploreFeedItem> products;
  final ValueChanged<ExploreFeedItem> onTapItem;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.58,
      ),
      itemCount: products.length,
      itemBuilder: (context, i) => _ProductCard(item: products[i], onTap: () => onTapItem(products[i])),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.controller,
    required this.onSearchTap,
    required this.locationLabel,
  });

  final TextEditingController controller;
  final VoidCallback onSearchTap;
  final String? locationLabel;

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
              Container(
                constraints: const BoxConstraints(maxWidth: 168),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(255, 255, 255, 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color.fromRGBO(191, 148, 112, 0.2)),
                ),
                child: Text(
                  (locationLabel == null || locationLabel!.trim().isEmpty) ? 'Konum bulunamadı' : locationLabel!.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _jakarta(size: 11, weight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 48,
            child: GestureDetector(
              onTap: onSearchTap,
              child: AbsorbPointer(
                child: TextField(
                  controller: controller,
                  readOnly: true,
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
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCapsuleChips extends StatelessWidget {
  const _CategoryCapsuleChips({required this.categories, required this.selected, required this.onChanged});

  final List<String> categories;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final label = categories[index] == 'Tumu' ? 'Tümü' : categories[index];
          final isSelected = categories[index].toLowerCase() == selected.toLowerCase();
          return GestureDetector(
            onTap: () => onChanged(categories[index]),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? _dk : _surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: isSelected ? _dk : _line),
                boxShadow: [
                  BoxShadow(
                    color: isSelected ? const Color.fromRGBO(24, 16, 10, 0.15) : const Color.fromRGBO(0, 0, 0, 0.02),
                    blurRadius: isSelected ? 14 : 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(label, style: _jakarta(size: 12, weight: FontWeight.w800, color: isSelected ? Colors.white : _t2)),
            ),
          );
        },
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

class _ProductCard extends ConsumerStatefulWidget {
  const _ProductCard({required this.item, required this.onTap});

  final ExploreFeedItem item;
  final VoidCallback onTap;

  @override
  ConsumerState<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<_ProductCard> {
  bool _justAddedToCart = false;
  bool _isAddingToCart = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final override = ref.watch(favoriteOverrideProvider(widget.item.product.id));
    final isFavorite = override ?? (ref.watch(isFavoriteProvider(widget.item.product.id)).valueOrNull ?? false);
    final changePercent = widget.item.priceChangePercent;
    final old = (changePercent != null && changePercent < 0 && (100 + changePercent) > 0)
        ? widget.item.displayPrice / (1 + (changePercent / 100))
        : null;
    final hasOld = old != null && old > widget.item.displayPrice;
    final showOnline = widget.item.isPrimaryOnlineCheapest;
    final distance = widget.item.distanceLabel ?? '${100 + math.Random(widget.item.product.id.hashCode).nextInt(500)}m';

    return GestureDetector(
      onTap: widget.onTap,
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
                      widget.item.product.effectiveImage ?? '',
                      fit: BoxFit.contain,
                      width: 100,
                      height: 100,
                      errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_outlined, color: _t3),
                    ),
                  ),
                  Positioned(top: 4, left: 4, child: _PriceChangeIndicator(item: widget.item)),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            if (user == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Favorilere eklemek için giriş yapmalısın.')),
                              );
                              return;
                            }
                            final next = !isFavorite;
                            ref.read(favoriteOverrideProvider(widget.item.product.id).notifier).state = next;
                            await ref.read(firestoreServiceProvider).toggleFavorite(
                              uid: user.uid,
                              productId: widget.item.product.id,
                              payload: {'productName': widget.item.product.name, 'imageUrl': widget.item.product.effectiveImage},
                            );
                          },
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
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () async {
                            if (user == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Sepete eklemek için giriş yapmalısın.')),
                              );
                              return;
                            }
                            if (_isAddingToCart) return;
                            setState(() => _isAddingToCart = true);
                            await ref.read(firestoreServiceProvider).upsertBasketItem(
                              userId: user.uid,
                              productId: widget.item.product.id,
                              quantity: 1,
                              lastKnownPrice: widget.item.displayPrice,
                              includeLastKnownPrice: true,
                            );
                            if (!context.mounted) return;
                            setState(() {
                              _isAddingToCart = false;
                              _justAddedToCart = true;
                            });
                            Future<void>.delayed(const Duration(milliseconds: 1200), () {
                              if (!mounted) return;
                              setState(() => _justAddedToCart = false);
                            });
                          },
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.08), blurRadius: 10, offset: Offset(0, 4))],
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              switchInCurve: Curves.easeOut,
                              switchOutCurve: Curves.easeIn,
                              child: _justAddedToCart
                                  ? const Icon(
                                      Icons.check_rounded,
                                      key: ValueKey('added'),
                                      size: 16,
                                      color: _grn,
                                    )
                                  : Icon(
                                      _isAddingToCart ? Icons.more_horiz_rounded : Icons.add,
                                      key: const ValueKey('add'),
                                      size: 16,
                                      color: _t2,
                                    ),
                            ),
                          ),
                        ),
                      ],
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
                    Text(widget.item.product.brand.toUpperCase(), style: _jakarta(size: 9, weight: FontWeight.w900, color: _tc, letterSpacing: 0.6)),
                    const SizedBox(height: 4),
                    Text(widget.item.product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: _jakarta(size: 13, weight: FontWeight.w800, height: 1.3)),
                    const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${widget.item.displayPrice.toStringAsFixed(2).replaceAll('.', ',')}₺', style: _serif(size: 22, height: 1)),
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
                  Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: _marketColor(widget.item.storeName))),
                  const SizedBox(width: 4),
                  Expanded(child: Text(widget.item.storeName, style: _jakarta(size: 10, weight: FontWeight.w800, color: _t2))),
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
}

class _FollowedProductsSection extends StatelessWidget {
  const _FollowedProductsSection({required this.items, required this.onTapItem});

  final List<ExploreFeedItem> items;
  final ValueChanged<ExploreFeedItem> onTapItem;

  @override
  Widget build(BuildContext context) {
    return _SectionBox(
      child: Column(
        children: [
          const _SectionHead(title: 'Takip Ettiğim Ürünler'),
          if (items.isEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Henüz favori ürün eklemedin. Ürün kartındaki kalp ikonuyla takip etmeye başlayabilirsin.',
                style: _jakarta(size: 12, weight: FontWeight.w600, color: _t3),
              ),
            )
          else
            Column(
              children: items
                  .take(6)
                  .map(
                    (item) => _FollowedProductRow(
                      item: item,
                      onTap: () => onTapItem(item),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
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
            title: 'Canlı Radar Akışı',
            leading: _LiveStatusDot(),
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
                final marketLine = item.isNeighborhoodMarket
                    ? [item.neighborhoodMarketScheduleLabel, item.locationLabel]
                        .whereType<String>()
                        .where((e) => e.trim().isNotEmpty)
                        .join(' • ')
                    : item.storeName;
                final subtitle = '$marketLine • ${_timeAgo(item.price.createdAt)}';
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

class _FollowedProductRow extends StatelessWidget {
  const _FollowedProductRow({required this.item, required this.onTap});

  final ExploreFeedItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final image = item.product.effectiveImage ?? '';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _surface2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _line),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 44,
                height: 44,
                color: const Color(0xFFF8F4EE),
                child: image.isEmpty
                    ? const Icon(Icons.image_not_supported_outlined, color: _t3, size: 18)
                    : Image.network(image, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_outlined, color: _t3, size: 18)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: _jakarta(size: 13, weight: FontWeight.w800)),
                  Text(item.storeName, style: _jakarta(size: 11, weight: FontWeight.w600, color: _t3)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text('${item.displayPrice.toStringAsFixed(2).replaceAll('.', ',')}₺', style: _jakarta(size: 13, weight: FontWeight.w800)),
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
  const _SectionHead({required this.title, this.action, this.onActionTap, this.leading});

  final String title;
  final String? action;
  final VoidCallback? onActionTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 8)],
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

class _LiveStatusDot extends StatefulWidget {
  const _LiveStatusDot();

  @override
  State<_LiveStatusDot> createState() => _LiveStatusDotState();
}

class _LiveStatusDotState extends State<_LiveStatusDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final pulse = 0.9 + (math.sin(_controller.value * 2 * math.pi).abs() * 0.35);
        return Transform.scale(
          scale: pulse,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF27A85A)),
          ),
        );
      },
    );
  }
}

class _PriceChangeIndicator extends StatelessWidget {
  const _PriceChangeIndicator({required this.item});

  final ExploreFeedItem item;

  @override
  Widget build(BuildContext context) {
    final raw = item.priceChangePercent ?? -item.dropPercent;
    final isDrop = raw < 0;
    final color = isDrop ? _grn : _red;
    final icon = isDrop ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDrop ? const Color.fromRGBO(39, 168, 90, 0.12) : const Color.fromRGBO(229, 57, 53, 0.12),
        border: Border.all(
          color: isDrop ? const Color.fromRGBO(39, 168, 90, 0.25) : const Color.fromRGBO(229, 57, 53, 0.25),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            '%${raw.abs().toStringAsFixed(1)}',
            style: _jakarta(size: 10, weight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}

class _ExploreSearchRoute extends ConsumerStatefulWidget {
  const _ExploreSearchRoute({required this.initialQuery});

  final String initialQuery;

  @override
  ConsumerState<_ExploreSearchRoute> createState() => _ExploreSearchRouteState();
}

class _ExploreSearchRouteState extends ConsumerState<_ExploreSearchRoute> {
  late final TextEditingController _controller = TextEditingController(text: widget.initialQuery);

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(exploreControllerProvider.notifier).updateSearchQuery(widget.initialQuery));
  }

  @override
  void dispose() {
    _controller.dispose();
    ref.read(exploreControllerProvider.notifier).updateSearchQuery('');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(exploreControllerProvider);
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: TextField(
            controller: _controller,
            autofocus: true,
            onChanged: (value) => ref.read(exploreControllerProvider.notifier).updateSearchQuery(value),
            decoration: InputDecoration(
              hintText: 'Ürün, marka veya barkod ara...',
              prefixIcon: const Icon(Icons.search, size: 18, color: _t3),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.items.length,
        itemBuilder: (context, index) {
          final item = state.items[index];
          return ListTile(
            tileColor: _surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: _line)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            title: Text(item.product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: _jakarta(size: 13, weight: FontWeight.w800)),
            subtitle: Text(
              item.isNeighborhoodMarket
                  ? [item.neighborhoodMarketScheduleLabel, item.locationLabel]
                      .whereType<String>()
                      .where((e) => e.trim().isNotEmpty)
                      .join(' • ')
                  : item.storeName,
              style: _jakarta(size: 11, weight: FontWeight.w600, color: _t3),
            ),
            trailing: Text('${item.displayPrice.toStringAsFixed(2)}₺', style: _serif(size: 16)),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => ProductDetailScreen(productId: item.product.id)),
            ),
          );
        },
      ),
    );
  }
}

Color _marketColor(String market) {
  switch (market.toLowerCase()) {
    case 'a-101':
    case 'a101':
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
