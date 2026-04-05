import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/price_model.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/barcode_scanner_sheet.dart';
import '../product/product_detail_screen.dart';
import '../../theme/fr_colors.dart';

const _kHeaderRadius = 36.0;
const _kCardRadius = 20.0;
const _kPagePad = 20.0;
const _kCardShadow = BoxShadow(
  color: Color(0x0F170D08),
  blurRadius: 14,
  offset: Offset(0, 4),
);

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.initialQuery});
  final String? initialQuery;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  String? _category;
  int _sort = 0; // 0 best price · 1 newest · 2 trust
  bool _discountedOnly = false;
  bool _highTrustOnly = false;

  @override
  void initState() {
    super.initState();
    final q = widget.initialQuery?.trim() ?? '';
    if (q.isNotEmpty) {
      _ctrl.text = q;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(searchQueryProvider.notifier).state = q;
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cats = ref.watch(categoriesProvider).valueOrNull ?? const [];
    final resultsAsync = ref.watch(searchResultsProvider);
    final allPrices = ref.watch(latestPricesProvider).valueOrNull ?? const <PriceModel>[];
    final latestByProduct = _latestByProduct(allPrices);

    final raw = resultsAsync.valueOrNull ?? const <ProductModel>[];
    final filtered = _filter(raw);
    final results = _applySorting(filtered, latestByProduct);

    return Scaffold(
      backgroundColor: FRColors.backgroundWarm,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildHeader(),
          _buildSearchBar(context),
          _buildFilters(cats),
          _buildResultsBar(results.length, resultsAsync.isLoading),
          if (resultsAsync.isLoading)
            _buildLoading()
          else if (results.isEmpty)
            _buildEmpty(_ctrl.text.trim())
          else
            _buildList(context, results, latestByProduct),
          const SliverToBoxAdapter(child: SizedBox(height: 130)),
        ],
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Container(
        decoration: const BoxDecoration(
          color: FRColors.espresso,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(_kHeaderRadius),
            bottomRight: Radius.circular(_kHeaderRadius),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(_kPagePad, 20, _kPagePad, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Keşfet',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1.0,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'FİYAT RADARINDA TÜM ÜRÜNLER',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withOpacity(0.28),
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Search bar ──────────────────────────────────────────────────────────

  Widget _buildSearchBar(BuildContext context) {
    return SliverToBoxAdapter(
      child: Transform.translate(
        offset: const Offset(0, -20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: _kPagePad),
          child: Container(
            decoration: BoxDecoration(
              color: FRColors.surface,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(color: Color(0x18170D08), blurRadius: 20, offset: Offset(0, 6)),
              ],
            ),
            child: TextField(
              controller: _ctrl,
              focusNode: _focus,
              style: const TextStyle(fontSize: 15, color: FRColors.textPrimary, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: 'Ürün, marka veya kategori ara...',
                hintStyle: const TextStyle(color: FRColors.textSubtle, fontSize: 14, fontWeight: FontWeight.w500),
                prefixIcon: const Icon(Icons.search_rounded, color: FRColors.tan, size: 21),
                suffixIcon: _ctrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        color: FRColors.textMuted,
                        onPressed: () {
                          _ctrl.clear();
                          ref.read(searchQueryProvider.notifier).state = '';
                          _focus.requestFocus();
                          setState(() {});
                        },
                      )
                    : IconButton(
                        icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                        color: FRColors.textMuted,
                        onPressed: () async {
                          final code = await BarcodeScannerSheet.scan(context);
                          if (!mounted || code == null || code.trim().isEmpty) return;
                          _ctrl.text = code.trim();
                          ref.read(searchQueryProvider.notifier).state = code.trim();
                          setState(() {});
                        },
                      ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (v) {
                ref.read(searchQueryProvider.notifier).state = v.trim();
                _focus.unfocus();
                setState(() {});
              },
              onChanged: (v) {
                ref.read(searchQueryProvider.notifier).state = v.trim();
                setState(() {});
              },
            ),
          ),
        ),
      ),
    );
  }

  // ─── Filters ─────────────────────────────────────────────────────────────

  Widget _buildFilters(List<dynamic> cats) {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          // Category chips
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: _kPagePad),
              children: [
                _catChip('Tümü', Icons.apps_rounded, _category == null,
                    () => setState(() => _category = null)),
                ...cats.take(8).map((c) {
                  final name = (c.title ?? c.name ?? 'Kategori').toString();
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _catChip(name, _catIcon(name), _category == name,
                        () => setState(() => _category = name)),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Utility chips
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: _kPagePad),
              children: [
                _utilChip('En İyi Fiyat', Icons.sell_rounded, _sort == 0,
                    () => setState(() => _sort = 0)),
                const SizedBox(width: 8),
                _utilChip('En Yeni', Icons.access_time_rounded, _sort == 1,
                    () => setState(() => _sort = 1)),
                const SizedBox(width: 8),
                _utilChip('Yüksek Güven', Icons.verified_user_rounded, _highTrustOnly,
                    () => setState(() => _highTrustOnly = !_highTrustOnly)),
                const SizedBox(width: 8),
                _utilChip('İndirimli', Icons.trending_down_rounded, _discountedOnly,
                    () => setState(() => _discountedOnly = !_discountedOnly)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _catChip(String label, IconData icon, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? FRColors.espresso : FRColors.surface,
          borderRadius: BorderRadius.circular(999),
          boxShadow: active ? null : const [BoxShadow(color: Color(0x08170D08), blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: active ? FRColors.tan : FRColors.textMuted),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : FRColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _utilChip(String label, IconData icon, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: active ? FRColors.tan.withOpacity(0.12) : FRColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? FRColors.tan : const Color(0x0C211510)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: active ? FRColors.tan : FRColors.textMuted),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: active ? FRColors.tan : FRColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Results bar ─────────────────────────────────────────────────────────

  Widget _buildResultsBar(int count, bool loading) {
    if (loading) return const SliverToBoxAdapter(child: SizedBox.shrink());
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(_kPagePad, 20, _kPagePad, 12),
        child: Row(
          children: [
            Text(
              'SONUÇLAR',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: FRColors.textMuted,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: FRColors.tan.withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: FRColors.tan),
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => _showSort(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: FRColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [BoxShadow(color: Color(0x08170D08), blurRadius: 6, offset: Offset(0, 2))],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.sort_rounded, size: 13, color: FRColors.textMuted),
                    const SizedBox(width: 5),
                    Text(
                      _sortLabel(),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: FRColors.textPrimary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Results list ─────────────────────────────────────────────────────────

  Widget _buildList(BuildContext context, List<ProductModel> items, Map<String, PriceModel> latestByProduct) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: _kPagePad),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (ctx, i) => _resultCard(ctx, items[i], latestByProduct),
          childCount: items.length,
        ),
      ),
    );
  }

  Widget _resultCard(BuildContext context, ProductModel item, Map<String, PriceModel> latestByProduct) {
    final latest = latestByProduct[item.id];
    final price = latest?.price ?? item.lastPrice ?? 0;
    final store = latest?.storeName ?? item.lastStore ?? '';
    final time = _timeAgo(latest?.createdAt ?? item.updatedAt ?? item.createdAt);
    final trust = latest?.trustPercent ?? (item.priceEntryCount >= 10 ? 92 : item.priceEntryCount >= 5 ? 82 : 72);
    final change = _priceChange(item.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: FRColors.surface,
        borderRadius: BorderRadius.circular(_kCardRadius),
        boxShadow: const [_kCardShadow],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(_kCardRadius),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: item.id)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Image
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: FRColors.backgroundWarm,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: item.effectiveImage?.isNotEmpty == true
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: CachedNetworkImage(
                            imageUrl: item.effectiveImage!,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => const Icon(Icons.category_outlined, size: 26, color: FRColors.tan),
                          ),
                        )
                      : const Icon(Icons.category_outlined, size: 26, color: FRColors.tan),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: FRColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        store.isNotEmpty ? '$store · $time' : time,
                        style: const TextStyle(fontSize: 11, color: FRColors.textSubtle),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            formatTRY(price),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: FRColors.tan),
                          ),
                          if (change != null && change.abs() >= 1) ...[
                            const SizedBox(width: 6),
                            _badge(change),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Trust + actions
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _trustBadge(trust),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _actionBtn(Icons.bookmark_outline_rounded,
                            onTap: () => _snack(context, 'Takip listesine eklendi.')),
                        const SizedBox(width: 6),
                        _actionBtn(Icons.notifications_none_rounded,
                            onTap: () => _snack(context, 'Fiyat alarmı kurma ekranı yakında.')),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _trustBadge(int score) {
    final isHigh = score >= 90;
    final isMid = score >= 75;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: isHigh ? FRColors.successSurface : isMid ? FRColors.backgroundWarm : FRColors.dangerSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_rounded, size: 10,
              color: isHigh ? FRColors.success : isMid ? FRColors.textMuted : FRColors.danger),
          const SizedBox(width: 3),
          Text(
            '$score%',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isHigh ? FRColors.success : isMid ? FRColors.textMuted : FRColors.danger,
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(double pct) {
    final down = pct <= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: down ? FRColors.successSurface : FRColors.dangerSurface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${down ? '↓' : '↑'} ${pct.abs().toStringAsFixed(0)}%',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
            color: down ? FRColors.success : FRColors.danger),
      ),
    );
  }

  Widget _actionBtn(IconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: FRColors.backgroundWarm,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 14, color: FRColors.textMuted),
      ),
    );
  }

  // ─── Loading / Empty ──────────────────────────────────────────────────────

  Widget _buildLoading() {
    return const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 64),
        child: Center(
          child: SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: FRColors.tan),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(String query) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: FRColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [_kCardShadow],
              ),
              child: const Icon(Icons.search_off_rounded, size: 30, color: FRColors.textMuted),
            ),
            const SizedBox(height: 18),
            Text(
              query.isEmpty ? 'Aramaya başlayın' : '"$query" bulunamadı',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: FRColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              query.isEmpty ? 'Ürün, marka veya kategori girin' : 'Farklı bir terim deneyin',
              style: const TextStyle(fontSize: 13, color: FRColors.textSubtle),
              textAlign: TextAlign.center,
            ),
            if (query.isNotEmpty) ...[
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  _ctrl.clear();
                  ref.read(searchQueryProvider.notifier).state = '';
                  _focus.requestFocus();
                  setState(() {});
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: FRColors.espresso,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Aramayı Temizle',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Sort sheet ───────────────────────────────────────────────────────────

  void _showSort(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: FRColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: const Color(0x18211510), borderRadius: BorderRadius.circular(999)),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Sırala', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: FRColors.textPrimary)),
              ),
            ),
            _sortTile(ctx, 'En İyi Fiyat', Icons.sell_rounded, 0),
            _sortTile(ctx, 'En Yeni', Icons.access_time_rounded, 1),
            _sortTile(ctx, 'Yüksek Güven', Icons.shield_rounded, 2),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _sortTile(BuildContext ctx, String label, IconData icon, int val) {
    final active = _sort == val;
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: active ? FRColors.tan.withOpacity(0.12) : FRColors.backgroundWarm,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: active ? FRColors.tan : FRColors.textMuted),
      ),
      title: Text(
        label,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: active ? FRColors.tan : FRColors.textPrimary),
      ),
      trailing: active ? const Icon(Icons.check_rounded, color: FRColors.tan, size: 18) : null,
      onTap: () {
        setState(() => _sort = val);
        Navigator.pop(ctx);
      },
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  String _sortLabel() {
    switch (_sort) {
      case 0: return 'En İyi Fiyat';
      case 1: return 'En Yeni';
      case 2: return 'Yüksek Güven';
      default: return 'Sırala';
    }
  }

  IconData _catIcon(String t) {
    final l = t.toLowerCase();
    if (l.contains('market') || l.contains('gıda')) return Icons.shopping_cart_rounded;
    if (l.contains('tekno') || l.contains('elektronik')) return Icons.laptop_mac_rounded;
    if (l.contains('kozmetik') || l.contains('bakım')) return Icons.face_retouching_natural_rounded;
    if (l.contains('hobi') || l.contains('spor')) return Icons.sports_esports_rounded;
    return Icons.category_rounded;
  }

  String _timeAgo(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inSeconds < 60) return '${d.inSeconds}s';
    if (d.inMinutes < 60) return '${d.inMinutes}d';
    if (d.inHours < 24) return '${d.inHours}s';
    return '${d.inDays}g';
  }

  Map<String, PriceModel> _latestByProduct(List<PriceModel> prices) {
    final map = <String, PriceModel>{};
    for (final p in prices) {
      final e = map[p.productId];
      if (e == null || p.reportedAt.isAfter(e.reportedAt)) map[p.productId] = p;
    }
    return map;
  }

  List<ProductModel> _filter(List<ProductModel> results) {
    return results.where((p) {
      if (_category != null && _category!.isNotEmpty) {
        if (!p.categories.any((c) => c.toLowerCase() == _category!.toLowerCase())) return false;
      }
      final delta = _priceChange(p.id);
      if (_discountedOnly && !(delta != null && delta < 0)) return false;
      if (_highTrustOnly && p.priceEntryCount < 5) return false;
      return true;
    }).toList();
  }

  List<ProductModel> _applySorting(List<ProductModel> results, Map<String, PriceModel> latest) {
    final sorted = [...results];
    switch (_sort) {
      case 0:
        sorted.sort((a, b) {
          final ap = latest[a.id]?.price ?? a.lastPrice ?? double.infinity;
          final bp = latest[b.id]?.price ?? b.lastPrice ?? double.infinity;
          return ap.compareTo(bp);
        });
        break;
      case 1:
        sorted.sort((a, b) {
          final ad = latest[a.id]?.reportedAt ?? a.updatedAt ?? a.createdAt;
          final bd = latest[b.id]?.reportedAt ?? b.updatedAt ?? b.createdAt;
          return bd.compareTo(ad);
        });
        break;
      case 2:
        sorted.sort((a, b) => b.priceEntryCount.compareTo(a.priceEntryCount));
        break;
    }
    return sorted;
  }

  double? _priceChange(String productId) {
    final prices = ref.read(latestPricesProvider).valueOrNull ?? const <PriceModel>[];
    final pp = prices.where((p) => p.productId == productId).toList()
      ..sort((a, b) => b.reportedAt.compareTo(a.reportedAt));
    if (pp.length < 2) return null;
    final prev = pp[1].price;
    if (prev <= 0) return null;
    return ((pp[0].price - prev) / prev) * 100;
  }

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
