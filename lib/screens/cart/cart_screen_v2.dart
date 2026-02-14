import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/basket/basket_pricing.dart';
import '../../features/basket/basket_view_model.dart';
import '../../models/basket_item_model.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_network_image.dart';

class CartScreenV2 extends ConsumerStatefulWidget {
  const CartScreenV2({super.key});

  @override
  ConsumerState<CartScreenV2> createState() => _CartScreenV2State();
}

class _CartScreenV2State extends ConsumerState<CartScreenV2> {
  @override
  void initState() {
    super.initState();
    ref.listenManual<BasketViewModel>(basketViewModelProvider, (previous, next) {
      final error = next.errorMessage;
      if (error != null && error != previous?.errorMessage && mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text(error),
              behavior: SnackBarBehavior.floating,
            ),
          );
      }

      final summary = next.pricingSummary;
      if (mounted && summary != null && summary != previous?.pricingSummary) {
        _showResultSheet(next);
      }
    });
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
          body: CustomScrollView(
            slivers: [
              CartCollapsibleHeader(
                itemCount: itemCount,
                onAddProduct: () => _showProductPicker(context, viewModel),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                sliver: SliverToBoxAdapter(
                  child: viewModel.isLoadingItems
                      ? const Center(child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(),
                        ))
                      : viewModel.items.isEmpty
                          ? _EmptyState(onAdd: () => _showProductPicker(context, viewModel))
                          : Column(
                              children: [
                                for (final item in viewModel.items)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: CartItemCard(
                                      item: item,
                                      product: viewModel.productMap[item.productId],
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
          bottomNavigationBar: CartBottomSummaryBar(
            itemCount: itemCount,
            summary: viewModel.pricingSummary,
            isLoading: viewModel.isCalculating,
            onCalculate: () {
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
              viewModel.calculate();
            },
            onAddProduct: () => _showProductPicker(context, viewModel),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const Scaffold(body: SizedBox.shrink()),
    );
  }

  Future<void> _showResultSheet(BasketViewModel viewModel) async {
    final summary = viewModel.pricingSummary;
    if (summary == null) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => CartResultSheet(
        summary: summary,
        marketNames: viewModel.marketNames,
        itemMap: {
          for (final item in viewModel.items)
            item.productId: viewModel.productMap[item.productId]?.name ?? 'Ürün',
        },
      ),
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

class CartCollapsibleHeader extends StatelessWidget {
  const CartCollapsibleHeader({
    super.key,
    required this.itemCount,
    required this.onAddProduct,
  });

  final int itemCount;
  final VoidCallback onAddProduct;

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
                        IconButton.filledTonal(
                          onPressed: onAddProduct,
                          icon: const Icon(Icons.add_rounded),
                          tooltip: 'Ürün ekle',
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
    required this.onQuantityChanged,
    required this.onRemove,
  });

  final BasketItemModel item;
  final ProductModel? product;
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
    required this.onCalculate,
    required this.onAddProduct,
  });

  final int itemCount;
  final BasketPricingSummary? summary;
  final bool isLoading;
  final VoidCallback onCalculate;
  final VoidCallback onAddProduct;

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
                                : 'En uygun marketi bul',
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
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: onAddProduct,
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
    required this.summary,
    required this.marketNames,
    required this.itemMap,
  });

  final BasketPricingSummary summary;
  final Map<String, String> marketNames;
  final Map<String, String> itemMap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final best = summary.bestSingleMarket;
    final alternatives = summary.perMarketTotals.entries
        .where((entry) => entry.value.missingKeys.isEmpty)
        .toList()
      ..sort((a, b) => a.value.total.compareTo(b.value.total));

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Hesaplama Sonucu', style: Theme.of(context).textTheme.titleLarge),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Sonucu Kaydet',
                      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sonuç kaydetme yakında.')),
                      ),
                      icon: const Icon(Icons.bookmark_add_outlined),
                    ),
                    IconButton(
                      tooltip: 'Paylaş',
                      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Paylaşım yakında.')),
                      ),
                      icon: const Icon(Icons.ios_share_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
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
                const SizedBox(height: 16),
                Text('Alternatifler', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...alternatives.take(3).map(
                      (entry) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.storefront_outlined),
                        title: Text(marketNames[entry.key] ?? entry.key),
                        trailing: Text(formatTRY(entry.value.total)),
                      ),
                    ),
                const SizedBox(height: 12),
                Text('Ürün Bazlı Dağılım', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...summary.mixedResult.perItemChoice.entries.map(
                  (entry) {
                    final choice = entry.value;
                    return ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: const EdgeInsets.only(bottom: 8),
                      title: Text(itemMap[entry.key] ?? entry.key),
                      subtitle: Text('${choice.marketName} • ${formatTRY(choice.unitPrice)}'),
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${choice.quantity} adet • Toplam ${formatTRY(choice.lineTotal)}',
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
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
