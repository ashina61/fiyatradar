import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/basket/basket_pricing.dart';
import '../../features/basket/basket_view_model.dart';
import '../../features/basket/cart_comparison_state.dart';
import '../../models/basket_item_model.dart';
import '../../models/price_model.dart';
import '../../models/product_model.dart';
import '../../services/cart_comparison_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../add_price/add_price_screen.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_network_image.dart';
import 'cart_result_tab.dart';

class CartScreenV2 extends ConsumerStatefulWidget {
  const CartScreenV2({super.key});

  @override
  ConsumerState<CartScreenV2> createState() => _CartScreenV2State();
}

class _CartScreenV2State extends ConsumerState<CartScreenV2> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return _LoginPromptCard(
            onLoginHint: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Devam etmek için giriş yapın.')),
            ),
          );
        }

        final viewModel = ref.watch(basketViewModelProvider);
        final itemCount = viewModel.items.fold<int>(0, (sum, item) => sum + item.quantity);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Fiyat Sepeti'),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Sepet'),
                Tab(text: 'Sonuç'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _CartTabContent(
                viewModel: viewModel,
                itemCount: itemCount,
                onAddProduct: () => _showProductPicker(context, viewModel),
                onCalculate: () async {
                  if (viewModel.items.isEmpty) {
                    ScaffoldMessenger.of(context)
                      ..clearSnackBars()
                      ..showSnackBar(
                        const SnackBar(
                          content: Text('Hesaplama için en az bir ürün ekleyin.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    return;
                  }
                  HapticFeedback.mediumImpact();
                  await viewModel.calculate();
                  if (!mounted) return;
                  if (viewModel.comparisonState.status != CartComparisonStatus.loading &&
                      viewModel.comparisonState.status != CartComparisonStatus.idle) {
                    _tabController.animateTo(1);
                  }
                },
              ),
              CartResultTab(
                state: viewModel.comparisonState,
                onCalculate: () async {
                  HapticFeedback.mediumImpact();
                  await viewModel.calculate();
                  if (!mounted) return;
                  _tabController.animateTo(1);
                },
                onGoToCart: () => _tabController.animateTo(0),
                onAddPrice: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AddPriceScreen(),
                    ),
                  );
                },
                onRetry: () async {
                  HapticFeedback.mediumImpact();
                  await viewModel.calculate();
                  if (!mounted) return;
                  _tabController.animateTo(1);
                },
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const Scaffold(body: SizedBox.shrink()),
    );
  }

  void _showProductPicker(BuildContext context, BasketViewModel viewModel) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final controller = TextEditingController();
        return StatefulBuilder(
          builder: (_, setModalState) {
            final query = controller.text.trim().toLowerCase();
            final allProducts = ref.watch(allProductsProvider).valueOrNull ?? [];
            final filtered = allProducts.where((product) {
              if (query.isEmpty) return true;
              return product.name.toLowerCase().contains(query) ||
                  product.brand.toLowerCase().contains(query);
            }).toList();

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller,
                      onChanged: (_) => setModalState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Ürün ara',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: MediaQuery.of(ctx).size.height * 0.48,
                      child: ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (_, index) {
                          final product = filtered[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                            title: Text(product.name),
                            subtitle: Text(product.brand),
                            trailing: const Icon(Icons.add_circle_outline_rounded),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              viewModel.addProduct(product.id);
                              Navigator.pop(ctx);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _CartTabContent extends StatelessWidget {
  const _CartTabContent({
    required this.viewModel,
    required this.itemCount,
    required this.onAddProduct,
    required this.onCalculate,
  });

  final BasketViewModel viewModel;
  final int itemCount;
  final VoidCallback onAddProduct;
  final VoidCallback onCalculate;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              CartCollapsibleHeader(
                itemCount: itemCount,
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                sliver: SliverToBoxAdapter(
                  child: viewModel.isLoadingItems
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : viewModel.items.isEmpty
                          ? _EmptyState(onAdd: onAddProduct)
                          : Column(
                              children: [
                                for (final item in viewModel.items)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: CartItemCard(
                                      item: item,
                                      product: viewModel.productMap[item.productId],
                                      latestPrice: viewModel.latestProductPrices[item.productId],
                                      onQuantityChanged: (qty) =>
                                          viewModel.updateQuantity(item.productId, qty),
                                      onRemove: () => viewModel.updateQuantity(item.productId, 0),
                                    ),
                                  ),
                              ],
                            ),
                ),
              ),
            ],
          ),
        ),
        CartBottomSummaryBar(
          itemCount: itemCount,
          summary: viewModel.pricingSummary,
          isLoading: viewModel.isCalculating,
          onAddProduct: onAddProduct,
          onCalculate: onCalculate,
        ),
      ],
    );
  }
}

class CartCollapsibleHeader extends StatelessWidget {
  const CartCollapsibleHeader({
    super.key,
    required this.itemCount,
  });

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SliverAppBar(
      pinned: true,
      expandedHeight: 164,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: cs.surface,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final t = ((constraints.maxHeight - kToolbarHeight) / (164 - kToolbarHeight)).clamp(0.0, 1.0);
          final compact = t < 0.35;

          return FlexibleSpaceBar(
            titlePadding: const EdgeInsetsDirectional.only(start: 16, bottom: 14, end: 16),
            title: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: compact
                  ? Row(
                      key: const ValueKey('compact'),
                      children: [
                        Expanded(
                          child: Text(
                            '$itemCount ürün hazır',
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      key: const ValueKey('expanded'),
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Fiyat Sepeti', style: theme.textTheme.headlineSmall),
                        const SizedBox(height: 4),
                        Text(
                          'Marketleri tek dokunuşla karşılaştır.',
                          style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: const [
                            _StepChip(label: 'Seç'),
                            _StepChip(label: 'Hesapla'),
                            _StepChip(label: 'Gör'),
                          ],
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

class _StepChip extends StatelessWidget {
  const _StepChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.secondaryContainer.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(label, style: Theme.of(context).textTheme.labelMedium),
      ),
    );
  }
}

class CartItemCard extends StatelessWidget {
  const CartItemCard({
    super.key,
    required this.item,
    required this.product,
    required this.latestPrice,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  final BasketItemModel item;
  final ProductModel? product;
  final PriceModel? latestPrice;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.52),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.45)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          AppNetworkImage(
            imageUrl: product?.mainImage,
            cacheKey: product?.id ?? item.productId,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product?.name ?? 'Ürün',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  product?.brand.isNotEmpty == true ? product!.brand : 'Marka bilgisi yok',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
                if ((product?.category ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      product!.category,
                      style: theme.textTheme.labelSmall?.copyWith(color: cs.primary),
                    ),
                  ),
                const SizedBox(height: 4),
                if (latestPrice != null)
                  Text(
                    'Son fiyat: ${formatTRY(latestPrice!.price)}',
                    style: theme.textTheme.labelMedium,
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: cs.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Fiyat yok',
                      style: theme.textTheme.labelSmall?.copyWith(color: cs.onErrorContainer),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          QuantityStepper(
            quantity: item.quantity,
            onChanged: onQuantityChanged,
            onRemove: onRemove,
          ),
        ],
      ),
    );
  }
}

class QuantityStepper extends StatefulWidget {
  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.onChanged,
    required this.onRemove,
  });

  final int quantity;
  final ValueChanged<int> onChanged;
  final VoidCallback onRemove;

  @override
  State<QuantityStepper> createState() => _QuantityStepperState();
}

class _QuantityStepperState extends State<QuantityStepper> {
  Timer? _repeatTimer;
  double _minusScale = 1;
  double _plusScale = 1;

  @override
  void dispose() {
    _repeatTimer?.cancel();
    super.dispose();
  }

  void _animate(bool plus) {
    setState(() {
      if (plus) {
        _plusScale = 0.88;
      } else {
        _minusScale = 0.88;
      }
    });
    Future<void>.delayed(const Duration(milliseconds: 90), () {
      if (!mounted) return;
      setState(() {
        _plusScale = 1;
        _minusScale = 1;
      });
    });
  }

  void _changeBy(int delta) {
    HapticFeedback.selectionClick();
    _animate(delta > 0);
    final next = widget.quantity + delta;
    if (next <= 0) {
      widget.onRemove();
      return;
    }
    widget.onChanged(next);
  }

  void _onLongPressStart(int delta) {
    _changeBy(delta);
    _repeatTimer?.cancel();
    _repeatTimer = Timer.periodic(const Duration(milliseconds: 140), (_) {
      _changeBy(delta);
    });
  }

  void _onLongPressEnd() {
    _repeatTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => _changeBy(-1),
              onLongPressStart: (_) => _onLongPressStart(-1),
              onLongPressEnd: (_) => _onLongPressEnd(),
              child: AnimatedScale(
                duration: const Duration(milliseconds: 120),
                scale: _minusScale,
                child: const Icon(Icons.remove_circle_outline_rounded, size: 22),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 140),
              transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
              child: Text(
                '${widget.quantity}',
                key: ValueKey(widget.quantity),
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _changeBy(1),
              onLongPressStart: (_) => _onLongPressStart(1),
              onLongPressEnd: (_) => _onLongPressEnd(),
              child: AnimatedScale(
                duration: const Duration(milliseconds: 120),
                scale: _plusScale,
                child: const Icon(Icons.add_circle_rounded, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CartBottomSummaryBar extends StatelessWidget {
  const CartBottomSummaryBar({
    super.key,
    required this.itemCount,
    required this.summary,
    required this.isLoading,
    required this.onAddProduct,
    required this.onCalculate,
  });

  final int itemCount;
  final BasketPricingSummary? summary;
  final bool isLoading;
  final VoidCallback onAddProduct;
  final VoidCallback onCalculate;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final best = summary?.bestSingleMarket;

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surface.withOpacity(0.74),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: cs.outlineVariant.withOpacity(0.35)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoading)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: LinearProgressIndicator(
                      minHeight: 4,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$itemCount ürün', style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(height: 4),
                          Text(
                            best != null
                                ? 'Tahmini toplam: ${formatTRY(best.total)}'
                                : 'Tahmini toplam: —',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: itemCount == 0 || isLoading ? null : onCalculate,
                      icon: isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_graph_rounded),
                      label: const Text('Hesapla'),
                    ),
                    IconButton(
                      onPressed: onAddProduct,
                      tooltip: 'Ürün ekle',
                      icon: const Icon(Icons.add_rounded),
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
}

class CartResultSheet extends StatelessWidget {
  const CartResultSheet({
    super.key,
    required this.result,
    required this.hasLocationPermission,
    this.notice,
  });

  final CartComparisonResult result;
  final bool hasLocationPermission;
  final String? notice;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final best = result.bestMarket;
    final alternatives = result.lowestThree;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hesaplama Sonucu', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                if (notice != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(notice!, style: Theme.of(context).textTheme.bodySmall),
                  ),
                if (best != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('En uygun market', style: Theme.of(context).textTheme.labelLarge),
                        const SizedBox(height: 4),
                        Text(best.marketName, style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 4),
                        Text(formatTRY(best.total), style: Theme.of(context).textTheme.titleLarge),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                if (hasLocationPermission && result.nearestMarket != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('En yakın market'),
                    subtitle: Text(
                      '${result.nearestMarket!.marketName} • ${result.nearestMarket!.distanceKm?.toStringAsFixed(1)} km',
                    ),
                    trailing: Text(formatTRY(result.nearestMarket!.total)),
                  )
                else
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('En yakın market'),
                    subtitle: Text('Konum izni verirsen yakın marketi gösterebiliriz.'),
                  ),
                const SizedBox(height: 16),
                Text('En düşük 3 market', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...alternatives.take(3).map(
                      (entry) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.storefront_outlined),
                        title: Row(
                          children: [
                            Expanded(child: Text(entry.marketName)),
                            if (entry.hasMissingProducts)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: cs.errorContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Eksik ürün',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(color: cs.onErrorContainer),
                                ),
                              )
                          ],
                        ),
                        subtitle: Text(
                          () {
                            final details = [
                              if (entry.distanceKm != null) '${entry.distanceKm!.toStringAsFixed(1)} km',
                              if (entry.missingProductIds.isNotEmpty)
                                'Eksik ürün: ${entry.missingProductIds.length}',
                            ];
                            return details.isEmpty ? 'Tüm ürünler mevcut' : details.join(' • ');
                          }(),
                        ),
                        trailing: Text(formatTRY(entry.total)),
                      ),
                    ),
                const SizedBox(height: 12),
                Text('Ürün bazlı fiyatlar', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...result.sortedMarkets.map(
                  (entry) {
                    return ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: const EdgeInsets.only(bottom: 8),
                      title: Text(entry.marketName),
                      subtitle: Text(
                        entry.hasMissingProducts
                            ? 'Eksik ürün: ${entry.missingProductIds.length}'
                            : 'Toplam ${formatTRY(entry.total)}',
                      ),
                      children: [
                        for (final line in entry.lines)
                          ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(line.productName),
                            subtitle: Text(
                              '${line.quantity} adet • ${formatTRY(line.unitPrice)}',
                            ),
                            trailing: Text(formatTRY(line.lineTotal)),
                          ),
                        if (entry.hasMissingProducts)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Eksik ürün sayısı: ${entry.missingProductIds.length}'),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surfaceContainer.withOpacity(0.85),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.secondaryContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shopping_basket_outlined, size: 32),
          ),
          const SizedBox(height: 12),
          Text('Sepetin boş', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Karşılaştırma için birkaç ürün ekleyin.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Ürün ekle'),
          ),
        ],
      ),
    );
  }
}

class _LoginPromptCard extends StatelessWidget {
  const _LoginPromptCard({required this.onLoginHint});

  final VoidCallback onLoginHint;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline_rounded, size: 48),
            const SizedBox(height: 12),
            Text('Sepet için giriş yapmalısınız', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onLoginHint,
              child: const Text('Devam et'),
            ),
          ],
        ),
      ),
    );
  }
}
