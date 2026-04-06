import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_system/design_system.dart';
import '../../models/price_model.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../utils/formatters.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  int _sortMode = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final resultsAsync = ref.watch(searchResultsProvider);
    final allPrices = ref.watch(latestPricesProvider).valueOrNull ?? <PriceModel>[];
    final priceMap = _buildPriceMap(allPrices);

    return FRAppScaffold(
      child: Column(
        children: [
          FRDarkHero(
            title: 'Keşfet',
            subtitle: 'Arama ve karşılaştırma merkezi',
            kicker: const FRKickerPill('Smart Discovery'),
            content: Column(
              children: [
                FRSearchField(
                  controller: _controller,
                  hintText: 'Ürün ara',
                  onChanged: (value) => ref.read(searchQueryProvider.notifier).state = value,
                ),
                const SizedBox(height: FRDsSpacing.space12),
                FRSegmentedSwitch<int>(
                  segments: const {
                    0: Text('En Ucuz'),
                    1: Text('En Yeni'),
                    2: Text('En Güvenilir'),
                  },
                  selected: {_sortMode},
                  onSelectionChanged: (selection) => setState(() => _sortMode = selection.first),
                ),
              ],
            ),
          ),
          Expanded(
            child: FRPageContainer(
              child: Padding(
                padding: const EdgeInsets.only(top: FRDsSpacing.space16),
                child: query.trim().isEmpty
                    ? const _ExploreEmpty()
                    : resultsAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text('Arama başarısız: $e')),
                        data: (raw) {
                          final sorted = _applySorting(raw, priceMap);
                          return FRExploreResultsSection(
                            eyebrow: 'SONUÇLAR',
                            title: '${sorted.length} ürün bulundu',
                            children: [
                              if (sorted.isEmpty)
                                Text('Sonuç bulunamadı', style: FRDsTypography.bodyLarge)
                              else
                                ...sorted.map(
                                  (product) => Padding(
                                    padding: const EdgeInsets.only(bottom: FRDsSpacing.space12),
                                    child: FRProductCard(
                                      title: product.name,
                                      subtitle: '${product.brand} • ${formatTRY(priceMap[product.id] ?? product.lastPrice ?? 0)}',
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
              ),
            ),
          ),
        ],
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
        list.sort((a, b) => b.priceEntryCount.compareTo(a.priceEntryCount));
        break;
    }
    return list;
  }
}

class _ExploreEmpty extends StatelessWidget {
  const _ExploreEmpty();

  @override
  Widget build(BuildContext context) {
    return FRSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Popüler aramalar', style: FRDsTypography.titleMedium),
          const SizedBox(height: FRDsSpacing.space12),
          Wrap(
            spacing: FRDsSpacing.space8,
            runSpacing: FRDsSpacing.space8,
            children: const [
              FRPill('Süt'),
              FRPill('Ekmek'),
              FRPill('Yoğurt'),
              FRPill('Zeytinyağı'),
              FRPill('Kahve'),
            ],
          ),
        ],
      ),
    );
  }
}
