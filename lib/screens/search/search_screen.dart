// lib/screens/search/search_screen.dart
// GREENFIELD v2 — "The Index"
// Rejected from the previous iteration: 3-sort chip row, result "cards",
// mixed category/utility chips, dark sort sheet.
// UX goal: a live catalog index. Search field is permanent, results are a dense
// ranked list of rows with right-aligned prices. No cards, no shadows.

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
  final _focus = FocusNode();

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
    final trending = ref.watch(trendingProductsProvider).valueOrNull ?? const <ProductModel>[];

    return Scaffold(
      backgroundColor: FRInk.paper,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 14),
            const Padding(
              padding: EdgeInsets.fromLTRB(FRInk.gutter, 4, FRInk.gutter, 0),
              child: Text('DİZİN', style: FRType.micro),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: FRInk.gutter),
              child: Text('Ne arıyorsun?', style: FRType.title),
            ),
            const SizedBox(height: 20),
            _SearchField(
              ctrl: _ctrl,
              focus: _focus,
              onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
              onClear: () {
                _ctrl.clear();
                ref.read(searchQueryProvider.notifier).state = '';
              },
              hasText: query.isNotEmpty,
            ),
            const SizedBox(height: 18),
            const FRHairline(),
            Expanded(
              child: query.isEmpty
                  ? _Suggestions(products: trending)
                  : resultsAsync.when(
                      loading: () => const _Loading(),
                      error: (_, __) => const _ErrorBlock(),
                      data: (list) => list.isEmpty
                          ? const _Empty()
                          : _Results(products: list),
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
    required this.focus,
    required this.onChanged,
    required this.onClear,
    required this.hasText,
  });

  final TextEditingController ctrl;
  final FocusNode focus;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool hasText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FRInk.gutter),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: FRInk.paperDeep,
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, color: FRInk.inkMute, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: ctrl,
                focusNode: focus,
                autofocus: false,
                onChanged: onChanged,
                cursorColor: FRInk.ink,
                style: FRType.body.copyWith(
                  color: FRInk.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                decoration: const InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: 'ürün, marka, market…',
                  hintStyle: TextStyle(
                    color: FRInk.inkFaint,
                    fontFamily: FRType.family,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
            if (hasText)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close_rounded, color: FRInk.inkMute, size: 20),
              ),
          ],
        ),
      ),
    );
  }
}

class _Suggestions extends StatelessWidget {
  const _Suggestions({required this.products});
  final List<ProductModel> products;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(FRInk.gutter),
        child: Text('Aramaya başla — katalog hazır.', style: FRType.body),
      );
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 160),
      physics: const BouncingScrollPhysics(),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(FRInk.gutter, 22, FRInk.gutter, 12),
          child: Text('POPÜLER', style: FRType.micro),
        ),
        for (var i = 0; i < products.length && i < 20; i++) ...[
          _IndexRow(product: products[i], index: i),
          if (i != products.length - 1) const FRHairline(indent: FRInk.gutter),
        ],
      ],
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.products});
  final List<ProductModel> products;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 160),
      physics: const BouncingScrollPhysics(),
      itemCount: products.length,
      separatorBuilder: (_, __) => const FRHairline(indent: FRInk.gutter),
      itemBuilder: (_, i) => _IndexRow(product: products[i], index: i),
    );
  }
}

class _IndexRow extends StatelessWidget {
  const _IndexRow({required this.product, required this.index});
  final ProductModel product;
  final int index;

  @override
  Widget build(BuildContext context) {
    final price = product.lastPrice;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FRInk.gutter, vertical: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 28,
            child: Text((index + 1).toString().padLeft(2, '0'), style: FRType.micro),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: FRType.bodyStrong,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    if (product.brand.isNotEmpty) product.brand,
                    if ((product.lastStore ?? '').isNotEmpty) product.lastStore!,
                  ].join(' · '),
                  style: FRType.body.copyWith(color: FRInk.inkMute, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            price != null ? formatTRY(price) : '—',
            style: FRType.numeral,
          ),
        ],
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(strokeWidth: 1.5, color: FRInk.ink),
          ),
        ),
      );
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(FRInk.gutter),
        child: Text('Arama başarısız oldu. Tekrar deneyin.', style: FRType.body),
      );
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(FRInk.gutter),
        child: Text('Sonuç yok. Farklı bir kelime dene.', style: FRType.body),
      );
}
