// lib/screens/search/search_screen.dart
// GREENFIELD — search-first discovery interface
// Rejected: category chips mixed with utility chips, price-card grid, hidden sort sheet
// UX goal: "Search is the screen" — bar always visible, results are the content

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/price_model.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../theme/fr_colors.dart';
import '../../utils/formatters.dart';

const _kPad = 24.0;
const _kCardR = 18.0;
const _kShadow = BoxShadow(color: Color(0x0A211510), blurRadius: 12, offset: Offset(0, 3));

// ─────────────────────────────────────────────────────────────────────────────
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  int _sortMode = 0; // 0=price asc, 1=newest, 2=trust

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final resultsAsync = ref.watch(searchResultsProvider);
    final allPrices = ref.watch(latestPricesProvider).valueOrNull ?? [];
    final priceMap = _buildPriceMap(allPrices);

    return Scaffold(
      backgroundColor: FRColors.backgroundWarm,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _SearchHeader(
              ctrl: _ctrl,
              focus: _focus,
              query: query,
              sortMode: _sortMode,
              onQueryChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
              onClear: () {
                _ctrl.clear();
                ref.read(searchQueryProvider.notifier).state = '';
              },
              onSortTap: () => _openSortSheet(context),
            ),
            Expanded(
              child: query.trim().isEmpty
                  ? _EmptyState(onTagTap: (tag) {
                      _ctrl.text = tag;
                      ref.read(searchQueryProvider.notifier).state = tag;
                    })
                  : resultsAsync.when(
                      loading: () => const _ResultsLoading(),
                      error: (e, _) => _ErrorState(message: '$e'),
                      data: (raw) {
                        final sorted = _applySorting(raw, priceMap);
                        return _ResultsList(products: sorted, priceMap: priceMap);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, double> _buildPriceMap(List<PriceModel> prices) {
    final map = <String, double>{};
    for (final p in prices) {
      final pid = p.selectedProductId ?? p.productId;
      map.putIfAbsent(pid, () => p.price);
    }
    return map;
  }

  List<ProductModel> _applySorting(List<ProductModel> raw, Map<String, double> priceMap) {
    final list = [...raw];
    switch (_sortMode) {
      case 0:
        list.sort((a, b) {
          final ap = priceMap[a.id] ?? a.lastPrice ?? double.infinity;
          final bp = priceMap[b.id] ?? b.lastPrice ?? double.infinity;
          return ap.compareTo(bp);
        });
        break;
      case 1:
        list.sort((a, b) => (b.updatedAt ?? b.createdAt).compareTo(a.updatedAt ?? a.createdAt));
        break;
      case 2:
        list.sort((a, b) => (b.priceEntryCount).compareTo(a.priceEntryCount));
        break;
    }
    return list;
  }

  void _openSortSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SortSheet(
        current: _sortMode,
        onSelect: (v) => setState(() => _sortMode = v),
      ),
    );
  }
}

// ─── Search header ────────────────────────────────────────────────────────────
class _SearchHeader extends StatelessWidget {
  const _SearchHeader({
    required this.ctrl,
    required this.focus,
    required this.query,
    required this.sortMode,
    required this.onQueryChanged,
    required this.onClear,
    required this.onSortTap,
  });

  final TextEditingController ctrl;
  final FocusNode focus;
  final String query;
  final int sortMode;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClear;
  final VoidCallback onSortTap;

  static const _sortLabels = ['En Ucuz', 'En Yeni', 'En Güvenilir'];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: FRColors.backgroundWarm,
      padding: const EdgeInsets.fromLTRB(_kPad, 18, _kPad, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Keşfet',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: FRColors.espresso,
              height: 1,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: FRColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: FRColors.border),
                    boxShadow: const [_kShadow],
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 14),
                        child: Icon(Icons.search_rounded, size: 20, color: FRColors.textMuted),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: ctrl,
                          focusNode: focus,
                          onChanged: onQueryChanged,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: FRColors.textPrimary,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Ürün ara…',
                            hintStyle: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 15,
                              color: FRColors.textSubtle,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                      if (query.isNotEmpty)
                        GestureDetector(
                          onTap: onClear,
                          child: const Padding(
                            padding: EdgeInsets.only(right: 12),
                            child: Icon(Icons.close_rounded, size: 18, color: FRColors.textMuted),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (query.isNotEmpty) ...[
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: onSortTap,
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: FRColors.espresso,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.tune_rounded, size: 16, color: FRColors.tan),
                        const SizedBox(height: 2),
                        Text(
                          _sortLabels[sortMode],
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: FRColors.tan,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onTagTap});
  final ValueChanged<String> onTagTap;

  static const _popular = [
    'Süt', 'Ekmek', 'Zeytin', 'Yoğurt', 'Domates',
    'Peynir', 'Yumurta', 'Tavuk', 'Pirinç', 'Makarna',
    'Zeytinyağı', 'Çay', 'Kahve', 'Muz', 'Elma',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(_kPad, 8, _kPad, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'POPÜLER ARAMALAR',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: FRColors.textMuted,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _popular
                .map((tag) => GestureDetector(
                      onTap: () => onTagTap(tag),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                        decoration: BoxDecoration(
                          color: FRColors.surface,
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: FRColors.border),
                          boxShadow: const [_kShadow],
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: FRColors.textPrimary,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: FRColors.espresso,
              borderRadius: BorderRadius.circular(_kCardR),
            ),
            child: Row(
              children: [
                const Icon(Icons.radar_rounded, size: 32, color: FRColors.tan),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Fiyat Radarda',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Topluluk tarafından eklenen fiyatları keşfet ve karşılaştır.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.55),
                          height: 1.4,
                        ),
                      ),
                    ],
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

// ─── Results list ─────────────────────────────────────────────────────────────
class _ResultsList extends StatelessWidget {
  const _ResultsList({required this.products, required this.priceMap});
  final List<ProductModel> products;
  final Map<String, double> priceMap;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const Center(
        child: Text(
          'Sonuç bulunamadı',
          style: TextStyle(fontSize: 15, color: FRColors.textMuted),
        ),
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(_kPad, 4, _kPad, 120),
      itemCount: products.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _ProductTile(
        product: products[i],
        price: priceMap[products[i].id] ?? products[i].lastPrice,
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product, required this.price});
  final ProductModel product;
  final double? price;

  @override
  Widget build(BuildContext context) {
    final image = product.effectiveImage;
    final entryCount = product.priceEntryCount;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FRColors.surface,
        borderRadius: BorderRadius.circular(_kCardR),
        border: Border.all(color: FRColors.border),
        boxShadow: const [_kShadow],
      ),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: image != null
                ? CachedNetworkImage(
                    imageUrl: image,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _thumb(),
                  )
                : _thumb(),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: FRColors.textPrimary,
                    height: 1.3,
                  ),
                ),
                if (product.brand.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    product.brand,
                    style: const TextStyle(fontSize: 12, color: FRColors.textMuted),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (price != null) ...[
                      Text(
                        formatTRY(price!),
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: FRColors.espresso,
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    if (entryCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: FRColors.backgroundWarm,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$entryCount fiyat',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: FRColors.textMuted,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, size: 20, color: FRColors.textSubtle),
        ],
      ),
    );
  }

  Widget _thumb() => Container(
        width: 60,
        height: 60,
        color: FRColors.backgroundWarm,
        child: const Icon(Icons.category_outlined, size: 24, color: FRColors.textSubtle),
      );
}

// ─── Sort sheet ───────────────────────────────────────────────────────────────
class _SortSheet extends StatelessWidget {
  const _SortSheet({required this.current, required this.onSelect});
  final int current;
  final ValueChanged<int> onSelect;

  static const _options = [
    (Icons.sell_rounded, 'En Ucuz Fiyat', 'Fiyata göre artan sırada'),
    (Icons.access_time_rounded, 'En Yeni', 'En son eklenen fiyatlar önce'),
    (Icons.shield_rounded, 'En Güvenilir', 'Katkı sayısına göre'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: FRColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: FRColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'SIRALAMA',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: FRColors.textMuted,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < _options.length; i++) ...[
            _SortTile(
              icon: _options[i].$1,
              label: _options[i].$2,
              subtitle: _options[i].$3,
              active: current == i,
              onTap: () {
                onSelect(i);
                Navigator.pop(context);
              },
            ),
            if (i < _options.length - 1) const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}

class _SortTile extends StatelessWidget {
  const _SortTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: active ? FRColors.espresso : FRColors.backgroundWarm,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: active ? FRColors.tan : FRColors.textMuted),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: active ? Colors.white : FRColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: active ? Colors.white.withOpacity(0.5) : FRColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (active) const Icon(Icons.check_rounded, size: 18, color: FRColors.tan),
          ],
        ),
      ),
    );
  }
}

// ─── States ───────────────────────────────────────────────────────────────────
class _ResultsLoading extends StatelessWidget {
  const _ResultsLoading();
  @override
  Widget build(BuildContext context) => ListView.separated(
        padding: const EdgeInsets.fromLTRB(_kPad, 4, _kPad, 120),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, __) => Container(
          height: 90,
          decoration: BoxDecoration(
            color: FRColors.surface,
            borderRadius: BorderRadius.circular(_kCardR),
            border: Border.all(color: FRColors.border),
          ),
        ),
      );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Arama başarısız.\n$message',
            textAlign: TextAlign.center,
            style: const TextStyle(color: FRColors.textMuted, fontSize: 13),
          ),
        ),
      );
}
