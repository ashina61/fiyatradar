import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/basket/basket_view_model.dart';
import '../../features/basket/cart_comparison_state.dart';
import '../../models/basket_item_model.dart';
import '../../models/product_model.dart';
import '../../models/store_model.dart';
import '../../services/cart_comparison_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../add_price/add_price_screen.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_network_image.dart';
import '../../widgets/premium_scaffold_shell.dart';
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
        final itemCount = ref.watch(
          basketViewModelProvider.select(
            (vm) => vm.items.fold<int>(0, (sum, item) => sum + item.quantity),
          ),
        );
        final estimatedTotal = ref.watch(
          basketViewModelProvider.select((vm) => vm.computedEstimatedTotal),
        );

        return Scaffold(
          backgroundColor: const Color(0xFFFAFAFA),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          floatingActionButton: FloatingActionButton(
            backgroundColor: const Color(0xFFE65100),
            foregroundColor: Colors.white,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const AddPriceScreen()),
              );
            },
            child: const Icon(Icons.add),
          ),
          appBar: AppBar(
            title: const Text('Fiyat Sepeti'),
            bottom: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: UnderlineTabIndicator(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide(width: 3.5, color: Theme.of(context).colorScheme.primary),
                insets: const EdgeInsets.symmetric(horizontal: 54),
              ),
              tabs: const [
                Tab(text: 'Sepet'),
                Tab(text: 'Sonuç'),
              ],
            ),
          ),
          body: PremiumScaffoldShell(
            child: TabBarView(
            controller: _tabController,
            children: [
              _CartTabContent(
                viewModel: viewModel,
                itemCount: itemCount,
                onAddProduct: () => _showProductPicker(context, viewModel),
                onAddPrice: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AddPriceScreen(),
                    ),
                  );
                },
                estimatedTotal: estimatedTotal,
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
                onSelectStores: () => _showStoreFilterSheet(context, viewModel),
                selectedStoreNames: viewModel.selectedStoreNames,
              ),
            ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const Scaffold(body: SizedBox.shrink()),
    );
  }


  Future<void> _showStoreFilterSheet(BuildContext context, BasketViewModel viewModel) async {
    await viewModel.loadStoresIfNeeded();
    if (!context.mounted) return;

    final initialSelection = Set<String>.from(viewModel.selectedStoreIds);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final tempSelection = Set<String>.from(initialSelection);
        return StatefulBuilder(
          builder: (context, setModalState) {
            final nearbyStores = viewModel.nearbyStores;
            final onlineStores = viewModel.onlineStores;

            Widget buildStoreList(List<StoreModel> stores) {
              if (stores.isEmpty) {
                return const Center(child: Text('Bu sekmede mağaza bulunamadı.'));
              }
              return ListView.builder(
                itemCount: stores.length,
                itemBuilder: (_, index) {
                  final store = stores[index];
                  final isSelected = tempSelection.contains(store.id);
                  return CheckboxListTile(
                    value: isSelected,
                    contentPadding: EdgeInsets.zero,
                    title: Text(store.displayName),
                    subtitle: store.isOnline
                        ? const Text('Online')
                        : Text([store.neighborhood, store.district].where((e) => e.isNotEmpty).join(', ')),
                    onChanged: (value) {
                      setModalState(() {
                        if (value == true) {
                          tempSelection.add(store.id);
                        } else {
                          tempSelection.remove(store.id);
                        }
                      });
                    },
                  );
                },
              );
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
                ),
                child: DefaultTabController(
                  length: 2,
                  child: SizedBox(
                    height: MediaQuery.of(ctx).size.height * 0.72,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mağaza Seç', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Chip(label: Text('Seçili: ${tempSelection.length} mağaza')),
                        const SizedBox(height: 8),
                        const TabBar(
                          tabs: [
                            Tab(text: 'Yakınımda'),
                            Tab(text: 'Online'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: TabBarView(
                            children: [
                              buildStoreList(nearbyStores),
                              buildStoreList(onlineStores),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () {
                              viewModel.setSelectedStoreIds(Set<String>.from(tempSelection));
                              Navigator.of(ctx).pop();
                            },
                            child: const Text('Uygula'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
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

class _CartTabContent extends StatefulWidget {
  const _CartTabContent({
    required this.viewModel,
    required this.itemCount,
    required this.estimatedTotal,
    required this.onAddProduct,
    required this.onAddPrice,
    required this.onCalculate,
  });

  final BasketViewModel viewModel;
  final int itemCount;
  final BasketEstimatedTotal estimatedTotal;
  final VoidCallback onAddProduct;
  final VoidCallback onAddPrice;
  final VoidCallback onCalculate;

  @override
  State<_CartTabContent> createState() => _CartTabContentState();
}

class _CartTabContentState extends State<_CartTabContent> {
  late final ScrollController _scrollController;
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()
      ..addListener(() {
        setState(() => _scrollOffset = _scrollController.offset.clamp(0, 220));
      });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              CartCollapsibleHeader(
                itemCount: widget.itemCount,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: widget.onAddProduct,
                          icon: const Icon(Icons.add_box_outlined),
                          label: const Text('Ürün Ekle'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: widget.onCalculate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE65100),
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.auto_graph_rounded),
                          label: const Text('Akıllı Tercih'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 132),
                sliver: SliverToBoxAdapter(
                  child: widget.viewModel.isLoadingItems
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : widget.viewModel.items.isEmpty
                          ? _EmptyState(
                              onAdd: widget.onAddProduct,
                              onAddPrice: widget.onAddPrice,
                            )
                          : Column(
                              children: [
                                for (final item in widget.viewModel.items)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: CartItemCard(
                                      item: item,
                                      product: widget.viewModel.productMap[item.productId],
                                      lastKnownPrice: item.lastKnownPrice,
                                      onQuantityChanged: (qty) =>
                                          widget.viewModel.updateQuantity(item.productId, qty),
                                      onRemove: () => widget.viewModel.updateQuantity(item.productId, 0),
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
          itemCount: widget.itemCount,
          estimatedTotal: widget.estimatedTotal,
          isLoading: widget.viewModel.isCalculating,
          onAddProduct: widget.onAddProduct,
          onAddPrice: widget.onAddPrice,
          onCalculate: widget.onCalculate,
          scrollOffset: _scrollOffset,
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
      expandedHeight: 188,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: cs.surface,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final t = ((constraints.maxHeight - kToolbarHeight) / (188 - kToolbarHeight)).clamp(0.0, 1.0);
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
                        Text(
                          'Akıllı sepetin hazır: fiyatları anında kıyasla.',
                          style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: cs.primaryContainer.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Toplam ürün: $itemCount',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: cs.onPrimaryContainer,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }
}

class CartItemCard extends StatelessWidget {
  const CartItemCard({
    super.key,
    required this.item,
    required this.product,
    required this.lastKnownPrice,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  final BasketItemModel item;
  final ProductModel? product;
  final double? lastKnownPrice;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
                if (lastKnownPrice != null)
                  Text(
                    'Son fiyat: ${formatTRY(lastKnownPrice!, trailingSymbol: true, keepTrailingZeros: true)}',
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0E0E0)),
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
                child: const Icon(Icons.remove_circle_outline_rounded, size: 26, color: Color(0xFF333333)),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 140),
              transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
              child: Text(
                '${widget.quantity}',
                key: ValueKey(widget.quantity),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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
                child: const Icon(Icons.add_circle_rounded, size: 26, color: Color(0xFFE65100)),
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
    required this.estimatedTotal,
    required this.isLoading,
    required this.onAddProduct,
    required this.onAddPrice,
    required this.onCalculate,
    required this.scrollOffset,
  });

  final int itemCount;
  final BasketEstimatedTotal estimatedTotal;
  final bool isLoading;
  final VoidCallback onAddProduct;
  final VoidCallback onAddPrice;
  final VoidCallback onCalculate;
  final double scrollOffset;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final totalPrefix = estimatedTotal.hasMissingPrices ? 'Kısmi toplam' : 'Tahmini toplam';
    final totalSuffix = estimatedTotal.hasMissingPrices ? ' • Eksik: ${estimatedTotal.missingPriceCount} ürün' : '';

    return SafeArea(
      minimum: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
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
                      Text(
                        '$itemCount ürün',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '$totalPrefix: ',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                          ),
                          Expanded(
                            child: _AnimatedCurrency(value: estimatedTotal.total),
                          ),
                          if (totalSuffix.isNotEmpty)
                            Text(
                              totalSuffix,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _PressScale(
                  child: FilledButton.icon(
                    onPressed: itemCount == 0 || isLoading ? null : onCalculate,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE65100),
                      foregroundColor: Colors.white,
                    ),
                    icon: isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_graph_rounded),
                    label: const Text('Hesapla'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedCurrency extends StatelessWidget {
  const _AnimatedCurrency({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, _) {
        final formatted = formatTRY(animatedValue, keepTrailingZeros: true);
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.98, end: 1),
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutBack,
          builder: (_, scale, child) => Transform.scale(scale: scale, alignment: Alignment.centerLeft, child: child),
          child: RichText(
            text: TextSpan(
              style: textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.onSurface),
              children: [
                TextSpan(text: formatted, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PressScale extends StatefulWidget {
  const _PressScale({required this.child});
  final Widget child;

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.98),
      onTapCancel: () => setState(() => _scale = 1),
      onTapUp: (_) => setState(() => _scale = 1),
      child: AnimatedScale(scale: _scale, duration: const Duration(milliseconds: 140), curve: Curves.easeOutCubic, child: widget.child),
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
  const _EmptyState({required this.onAdd, required this.onAddPrice});

  final VoidCallback onAdd;
  final VoidCallback onAddPrice;

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
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Ürün ekle'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onAddPrice,
                  icon: const Icon(Icons.price_change_outlined),
                  label: const Text('Fiyat ekle'),
                ),
              ),
            ],
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
