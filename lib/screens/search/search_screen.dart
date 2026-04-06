import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../theme/fr_ink.dart';
import '../../utils/formatters.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final resultsAsync = ref.watch(searchResultsProvider);
    final trending = ref.watch(trendingProductsProvider).valueOrNull ?? const <ProductModel>[];

    return Scaffold(
      backgroundColor: FRInk.paper,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(FRInk.gutter, 14, FRInk.gutter, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Keşfet', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  const Text('ARAMA MERKEZİ', style: FRType.micro),
                  const SizedBox(height: 12),
                  _SearchField(
                    ctrl: _ctrl,
                    hasText: query.isNotEmpty,
                    onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
                    onClear: () {
                      _ctrl.clear();
                      ref.read(searchQueryProvider.notifier).state = '';
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: query.isEmpty
                  ? _ResultsList(products: trending, title: 'POPÜLER ÜRÜNLER')
                  : resultsAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (_, __) => const Center(child: Text('Arama sırasında hata oluştu.')),
                      data: (list) => _ResultsList(products: list, title: 'SONUÇLAR'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.ctrl,
    required this.hasText,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController ctrl;
  final bool hasText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: FRInk.paperSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: FRInk.inkMute),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: ctrl,
              onChanged: onChanged,
              cursorColor: FRInk.ink,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Ürün, marka veya market...',
              ),
            ),
          ),
          if (hasText)
            GestureDetector(
              onTap: onClear,
              child: const Icon(Icons.close_rounded, color: FRInk.inkMute),
            ),
        ],
      ),
    );
  }
}

class _ResultsList extends StatelessWidget {
  const _ResultsList({required this.products, required this.title});

  final List<ProductModel> products;
  final String title;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const Center(child: Text('Sonuç bulunamadı.'));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(FRInk.gutter, 0, FRInk.gutter, 140),
      children: [
        const SizedBox(height: 8),
        Text(title, style: FRType.micro),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: FRInk.paperSoft, borderRadius: BorderRadius.circular(24)),
          child: Column(
            children: [
              for (var i = 0; i < products.length; i++) ...[
                _ResultTile(index: i, product: products[i]),
                if (i != products.length - 1)
                  const Divider(height: 1, indent: 16, endIndent: 16, color: FRInk.hairline),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.index, required this.product});

  final int index;
  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Text((index + 1).toString().padLeft(2, '0'), style: FRType.micro),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: FRType.bodyStrong, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  [if (product.brand.isNotEmpty) product.brand, if ((product.lastStore ?? '').isNotEmpty) product.lastStore!].join(' · '),
                  style: FRType.body.copyWith(color: FRInk.inkMute, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(product.lastPrice != null ? formatTRY(product.lastPrice!) : '—', style: FRType.numeral),
        ],
      ),
    );
  }
}
