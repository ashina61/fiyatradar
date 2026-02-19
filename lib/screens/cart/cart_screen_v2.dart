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
import '../../utils/theme.dart';
import '../../widgets/app_network_image.dart';
import '../../widgets/premium_scaffold_shell.dart';
import 'cart_result_tab.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CartScreenV2 – Premium Redesign
// ─────────────────────────────────────────────────────────────────────────────

class CartScreenV2 extends ConsumerStatefulWidget {
  const CartScreenV2({super.key});

  @override
  ConsumerState<CartScreenV2> createState() => _CartScreenV2State();
}

class _CartScreenV2State extends ConsumerState<CartScreenV2>
    with SingleTickerProviderStateMixin {
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
          return const _LoginPromptCard();
        }

        final viewModel = ref.watch(basketViewModelProvider);
        final itemCount = ref.watch(
          basketViewModelProvider
              .select((vm) => vm.items.fold<int>(0, (s, i) => s + i.quantity)),
        );
        final estimatedTotal = ref.watch(
          basketViewModelProvider.select((vm) => vm.computedEstimatedTotal),
        );

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: _buildAppBar(context),
          body: PremiumScaffoldShell(
            child: TabBarView(
              controller: _tabController,
              children: [
                // ── Tab 1: Sepetim ──
                _CartBody(
                  viewModel: viewModel,
                  itemCount: itemCount,
                  estimatedTotal: estimatedTotal,
                  onAddProduct: () => _showProductPicker(context, viewModel),
                  onAddPrice: (product) => _navigateToAddPrice(context, product),
                  onCalculate: () => _handleCalculate(viewModel),
                ),
                // ── Tab 2: Karşılaştır ──
                CartResultTab(
                  state: viewModel.comparisonState,
                  onCalculate: () => _handleCalculate(viewModel),
                  onGoToCart: () => _tabController.animateTo(0),
                  onAddPrice: () => _navigateToAddPrice(context, null),
                  onRetry: () => _handleCalculate(viewModel),
                  onSelectStores: () =>
                      _showStoreFilterSheet(context, viewModel),
                  selectedStoreNames: viewModel.selectedStoreNames,
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const Scaffold(body: SizedBox.shrink()),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppBar(
      title: const Text('Sepetim'),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.all(4),
          child: TabBar(
            controller: _tabController,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            indicator: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: cs.shadow.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            labelColor: cs.primary,
            unselectedLabelColor: cs.onSurfaceVariant,
            labelStyle: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(fontWeight: FontWeight.w700),
            tabs: const [
              Tab(text: 'Sepet'),
              Tab(text: 'Karşılaştır'),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleCalculate(BasketViewModel viewModel) async {
    if (viewModel.items.isEmpty) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: const Text('Hesaplama için en az bir ürün ekleyin.'),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
  }

  void _navigateToAddPrice(BuildContext context, ProductModel? product) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const AddPriceScreen()),
    );
  }

  // ── Store Filter Bottom Sheet ──
  Future<void> _showStoreFilterSheet(
      BuildContext context, BasketViewModel viewModel) async {
    await viewModel.loadStoresIfNeeded();
    if (!context.mounted) return;

    final cs = Theme.of(context).colorScheme;
    final initialSelection = Set<String>.from(viewModel.selectedStoreIds);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final tempSelection = Set<String>.from(initialSelection);
        return StatefulBuilder(
          builder: (context, setModalState) {
            final nearbyStores = viewModel.nearbyStores;
            final onlineStores = viewModel.onlineStores;

            Widget buildStoreList(List<StoreModel> stores) {
              if (stores.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.store_outlined,
                            size: 40, color: cs.onSurfaceVariant),
                        const SizedBox(height: 12),
                        Text('Bu sekmede mağaza bulunamadı.',
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: stores.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (_, index) {
                  final store = stores[index];
                  final isSelected = tempSelection.contains(store.id);
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? cs.primaryContainer.withOpacity(0.3)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: CheckboxListTile(
                      value: isSelected,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      title: Text(store.displayName,
                          style: Theme.of(context).textTheme.titleMedium),
                      subtitle: Text(
                        store.isOnline
                            ? 'Online'
                            : [store.neighborhood, store.district]
                                .where((e) => e.isNotEmpty)
                                .join(', '),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      onChanged: (value) {
                        setModalState(() {
                          if (value == true) {
                            tempSelection.add(store.id);
                          } else {
                            tempSelection.remove(store.id);
                          }
                        });
                      },
                    ),
                  );
                },
              );
            }

            return Container(
              height: MediaQuery.of(ctx).size.height * 0.75,
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: cs.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text('Mağaza Seç',
                                style:
                                    Theme.of(context).textTheme.headlineSmall),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: cs.primaryContainer.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${tempSelection.length} seçili',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                      color: cs.primary,
                                      fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TabBar(
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        indicator: BoxDecoration(
                          color: cs.primaryContainer.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        tabs: const [
                          Tab(text: 'Yakınımda'),
                          Tab(text: 'Online'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: TabBarView(
                          children: [
                            buildStoreList(nearbyStores),
                            buildStoreList(onlineStores),
                          ],
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                        child: SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton(
                            onPressed: () {
                              viewModel.setSelectedStoreIds(
                                  Set<String>.from(tempSelection));
                              Navigator.of(ctx).pop();
                            },
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text('Uygula'),
                          ),
                        ),
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

  // ── Product Picker Bottom Sheet ──
  void _showProductPicker(BuildContext context, BasketViewModel viewModel) {
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final controller = TextEditingController();
        return StatefulBuilder(
          builder: (_, setModalState) {
            final query = controller.text.trim().toLowerCase();
            final allProducts =
                ref.watch(allProductsProvider).valueOrNull ?? [];
            final filtered = allProducts.where((product) {
              if (query.isEmpty) return true;
              return product.name.toLowerCase().contains(query) ||
                  product.brand.toLowerCase().contains(query);
            }).toList();

            return Container(
              height: MediaQuery.of(ctx).size.height * 0.72,
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ürün Ekle',
                            style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 12),
                        TextField(
                          controller: controller,
                          onChanged: (_) => setModalState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Ürün veya marka ara...',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: query.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded),
                                    onPressed: () {
                                      controller.clear();
                                      setModalState(() {});
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor:
                                cs.surfaceContainerHighest.withOpacity(0.5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (filtered.isEmpty)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off_rounded,
                                size: 48, color: cs.onSurfaceVariant),
                            const SizedBox(height: 12),
                            Text('Ürün bulunamadı',
                                style: Theme.of(context).textTheme.titleMedium),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 2),
                        itemBuilder: (_, index) {
                          final product = filtered[index];
                          final hasPrice = product.lastPrice != null;
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                HapticFeedback.selectionClick();
                                viewModel.addProduct(product.id);
                                Navigator.pop(ctx);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 10),
                                child: Row(
                                  children: [
                                    AppNetworkImage(
                                      imageUrl: product.mainImage,
                                      cacheKey: product.id,
                                      width: 44,
                                      height: 44,
                                      fit: BoxFit.cover,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(product.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium),
                                          const SizedBox(height: 2),
                                          Text(
                                            product.brand.isNotEmpty
                                                ? product.brand
                                                : 'Marka bilgisi yok',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (hasPrice)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: cs.primaryContainer
                                              .withOpacity(0.3),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          formatTRY(product.lastPrice!),
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium
                                              ?.copyWith(
                                                color: cs.primary,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: cs.primary.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.add_rounded,
                                          size: 18, color: cs.primary),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _CartBody – The main cart tab content
// ─────────────────────────────────────────────────────────────────────────────

class _CartBody extends StatefulWidget {
  const _CartBody({
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
  final void Function(ProductModel? product) onAddPrice;
  final VoidCallback onCalculate;

  @override
  State<_CartBody> createState() => _CartBodyState();
}

class _CartBodyState extends State<_CartBody> {
  @override
  Widget build(BuildContext context) {
    if (widget.viewModel.isLoadingItems) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (widget.viewModel.items.isEmpty) {
      return _EmptyCartView(onAdd: widget.onAddProduct);
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            children: [
              // ── Stats Header ──
              _StatsHeader(
                itemCount: widget.itemCount,
                estimatedTotal: widget.estimatedTotal,
              ),
              const SizedBox(height: 24),

              // ── Section Label ──
              _SectionLabel(
                label: 'Ürünler',
                trailing: '${widget.viewModel.items.length} çeşit',
              ),
              const SizedBox(height: 12),

              // ── Cart Items ──
              ...widget.viewModel.items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final product = widget.viewModel.productMap[item.productId];
                return TweenAnimationBuilder<double>(
                  key: ValueKey(item.productId),
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 300 + (index * 50)),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) => Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 16 * (1 - value)),
                      child: child,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Dismissible(
                      key: ValueKey('dismiss_${item.productId}'),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) {
                        HapticFeedback.mediumImpact();
                        widget.viewModel
                            .updateQuantity(item.productId, 0);
                      },
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.delete_outline_rounded,
                            color: Colors.white, size: 24),
                      ),
                      child: _CartProductCard(
                        item: item,
                        product: product,
                        onQuantityChanged: (qty) =>
                            widget.viewModel.updateQuantity(item.productId, qty),
                        onRemove: () =>
                            widget.viewModel.updateQuantity(item.productId, 0),
                        onAddPrice: () => widget.onAddPrice(product),
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 8),

              // ── Add Product Card ──
              _AddProductPrompt(onTap: widget.onAddProduct),

              const SizedBox(height: 100),
            ],
          ),
        ),
        // ── Bottom Action Bar ──
        _CartActionBar(
          itemCount: widget.itemCount,
          estimatedTotal: widget.estimatedTotal,
          isLoading: widget.viewModel.isCalculating,
          onCalculate: widget.onCalculate,
          onAddProduct: widget.onAddProduct,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _StatsHeader – Top summary with item count & estimated total
// ─────────────────────────────────────────────────────────────────────────────

class _StatsHeader extends StatelessWidget {
  const _StatsHeader({
    required this.itemCount,
    required this.estimatedTotal,
  });

  final int itemCount;
  final BasketEstimatedTotal estimatedTotal;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.08),
            AppColors.accent.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Item count
              Expanded(
                child: _StatItem(
                  icon: Icons.shopping_bag_outlined,
                  value: '$itemCount',
                  label: 'ürün',
                  color: cs.primary,
                ),
              ),
              Container(
                width: 1,
                height: 44,
                color: cs.outlineVariant.withOpacity(0.3),
              ),
              // Estimated total
              Expanded(
                child: _StatItem(
                  icon: Icons.payments_outlined,
                  value: formatTRY(estimatedTotal.total, keepTrailingZeros: true),
                  label: estimatedTotal.hasMissingPrices
                      ? 'kısmi toplam'
                      : 'tahmini',
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          if (estimatedTotal.hasMissingPrices) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 18, color: AppColors.warning),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${estimatedTotal.missingPriceCount} üründe fiyat bilgisi eksik',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                label,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SectionLabel
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, this.trailing});

  final String label;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: cs.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        if (trailing != null)
          Text(
            trailing!,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _CartProductCard – Premium product card with price display
// ─────────────────────────────────────────────────────────────────────────────

class _CartProductCard extends StatelessWidget {
  const _CartProductCard({
    required this.item,
    required this.product,
    required this.onQuantityChanged,
    required this.onRemove,
    required this.onAddPrice,
  });

  final BasketItemModel item;
  final ProductModel? product;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemove;
  final VoidCallback onAddPrice;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final hasPrice = item.lastKnownPrice != null;
    final lineTotal = hasPrice ? item.lastKnownPrice! * item.quantity : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Top Row: Image + Info ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: cs.surfaceContainerHighest.withOpacity(0.3),
                ),
                child: AppNetworkImage(
                  imageUrl: product?.mainImage,
                  cacheKey: product?.id ?? item.productId,
                  width: 68,
                  height: 68,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              const SizedBox(width: 14),
              // Product info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product?.name ?? 'Ürün',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (product?.brand.isNotEmpty == true)
                          Text(
                            product!.brand,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        if (product?.brand.isNotEmpty == true &&
                            (product?.category ?? '').isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Container(
                              width: 3,
                              height: 3,
                              decoration: BoxDecoration(
                                color: cs.onSurfaceVariant,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        if ((product?.category ?? '').isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: cs.primaryContainer.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              product!.category,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: cs.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          // Divider
          Container(
            height: 1,
            color: cs.outlineVariant.withOpacity(0.2),
          ),
          const SizedBox(height: 12),

          // ── Bottom Row: Price + Quantity ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Price section
              Expanded(
                child: hasPrice
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                formatTRY(item.lastKnownPrice!,
                                    trailingSymbol: true,
                                    keepTrailingZeros: true),
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                ' /adet',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          if (item.quantity > 1 && lineTotal != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                'Toplam: ${formatTRY(lineTotal, trailingSymbol: true, keepTrailingZeros: true)}',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: cs.errorContainer.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.warning_amber_rounded,
                                        size: 14,
                                        color: cs.onErrorContainer),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Fiyat yok',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                        color: cs.onErrorContainer,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: onAddPrice,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: cs.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: cs.primary.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    'Fiyat Ekle',
                                    style:
                                        theme.textTheme.labelSmall?.copyWith(
                                      color: cs.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
              // Quantity control
              _QuantityControl(
                quantity: item.quantity,
                onChanged: onQuantityChanged,
                onRemove: onRemove,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _QuantityControl – Modern quantity stepper
// ─────────────────────────────────────────────────────────────────────────────

class _QuantityControl extends StatefulWidget {
  const _QuantityControl({
    required this.quantity,
    required this.onChanged,
    required this.onRemove,
  });

  final int quantity;
  final ValueChanged<int> onChanged;
  final VoidCallback onRemove;

  @override
  State<_QuantityControl> createState() => _QuantityControlState();
}

class _QuantityControlState extends State<_QuantityControl> {
  Timer? _repeatTimer;

  @override
  void dispose() {
    _repeatTimer?.cancel();
    super.dispose();
  }

  void _changeBy(int delta) {
    HapticFeedback.selectionClick();
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
    _repeatTimer = Timer.periodic(
        const Duration(milliseconds: 140), (_) => _changeBy(delta));
  }

  void _onLongPressEnd() => _repeatTimer?.cancel();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isOne = widget.quantity <= 1;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Minus / Delete
          GestureDetector(
            onTap: () => _changeBy(-1),
            onLongPressStart: (_) => _onLongPressStart(-1),
            onLongPressEnd: (_) => _onLongPressEnd(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isOne
                    ? Icons.delete_outline_rounded
                    : Icons.remove_rounded,
                size: 18,
                color: isOne ? cs.error : cs.onSurface,
              ),
            ),
          ),
          // Count
          Container(
            constraints: const BoxConstraints(minWidth: 36),
            alignment: Alignment.center,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: animation,
                child: child,
              ),
              child: Text(
                '${widget.quantity}',
                key: ValueKey(widget.quantity),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ),
          // Plus
          GestureDetector(
            onTap: () => _changeBy(1),
            onLongPressStart: (_) => _onLongPressStart(1),
            onLongPressEnd: (_) => _onLongPressEnd(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.add_rounded, size: 18, color: cs.primary),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AddProductPrompt – Dashed-border card to add products
// ─────────────────────────────────────────────────────────────────────────────

class _AddProductPrompt extends StatelessWidget {
  const _AddProductPrompt({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: cs.primary.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add_rounded, size: 20, color: cs.primary),
            ),
            const SizedBox(width: 10),
            Text(
              'Ürün Ekle',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _CartActionBar – Premium bottom action bar
// ─────────────────────────────────────────────────────────────────────────────

class _CartActionBar extends StatelessWidget {
  const _CartActionBar({
    required this.itemCount,
    required this.estimatedTotal,
    required this.isLoading,
    required this.onCalculate,
    required this.onAddProduct,
  });

  final int itemCount;
  final BasketEstimatedTotal estimatedTotal;
  final bool isLoading;
  final VoidCallback onCalculate;
  final VoidCallback onAddProduct;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 14, 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppColors.primaryDark,
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    minHeight: 3,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            Row(
              children: [
                // Total info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$itemCount ürün',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 2),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: estimatedTotal.total),
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) => Text(
                          formatTRY(value, keepTrailingZeros: true),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Add product
                IconButton(
                  onPressed: onAddProduct,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 4),
                // Calculate button
                _PressScale(
                  child: FilledButton(
                    onPressed: itemCount == 0 || isLoading ? null : onCalculate,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      disabledBackgroundColor: Colors.white.withOpacity(0.3),
                      disabledForegroundColor: Colors.white.withOpacity(0.5),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isLoading)
                          const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            ),
                          )
                        else
                          const Padding(
                            padding: EdgeInsets.only(right: 6),
                            child: Icon(Icons.compare_arrows_rounded, size: 18),
                          ),
                        Text(
                          'Hesapla',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
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

// ─────────────────────────────────────────────────────────────────────────────
// _EmptyCartView
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyCartView extends StatelessWidget {
  const _EmptyCartView({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon container
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withOpacity(0.08),
                    AppColors.accent.withOpacity(0.06),
                  ],
                ),
                shape: BoxShape.circle,
                border:
                    Border.all(color: AppColors.primary.withOpacity(0.12)),
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 48,
                color: AppColors.primary.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Sepetiniz boş',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Ürün ekleyerek marketler arasında\nfiyat karşılaştırması yapın.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: cs.onSurfaceVariant, height: 1.5),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Ürün Ekle'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Seç  ·  Hesapla  ·  Karşılaştır',
              style: theme.textTheme.labelMedium?.copyWith(
                color: cs.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _LoginPromptCard
// ─────────────────────────────────────────────────────────────────────────────

class _LoginPromptCard extends StatelessWidget {
  const _LoginPromptCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.lock_outline_rounded,
                    size: 40, color: cs.primary),
              ),
              const SizedBox(height: 20),
              Text(
                'Giriş Yapın',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Sepet özelliğini kullanmak için\nhesabınıza giriş yapmalısınız.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Devam etmek için giriş yapın.')),
                  );
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Giriş Yap'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PressScale – Tap animation wrapper
// ─────────────────────────────────────────────────────────────────────────────

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
      onTapDown: (_) => setState(() => _scale = 0.96),
      onTapCancel: () => setState(() => _scale = 1),
      onTapUp: (_) => setState(() => _scale = 1),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CartResultSheet – Legacy compatibility (kept for external usage)
// ─────────────────────────────────────────────────────────────────────────────

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
            Text('Hesaplama Sonucu',
                style: Theme.of(context).textTheme.titleLarge),
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
                child: Text(notice!,
                    style: Theme.of(context).textTheme.bodySmall),
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
                    Text('En uygun market',
                        style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 4),
                    Text(best.marketName,
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text(formatTRY(best.total),
                        style: Theme.of(context).textTheme.titleLarge),
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
                subtitle: Text(
                    'Konum izni verirsen yakın marketi gösterebiliriz.'),
              ),
            const SizedBox(height: 16),
            Text('En düşük 3 market',
                style: Theme.of(context).textTheme.titleMedium),
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
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
                          if (entry.distanceKm != null)
                            '${entry.distanceKm!.toStringAsFixed(1)} km',
                          if (entry.missingProductIds.isNotEmpty)
                            'Eksik ürün: ${entry.missingProductIds.length}',
                        ];
                        return details.isEmpty
                            ? 'Tüm ürünler mevcut'
                            : details.join(' • ');
                      }(),
                    ),
                    trailing: Text(formatTRY(entry.total)),
                  ),
                ),
            const SizedBox(height: 12),
            Text('Ürün bazlı fiyatlar',
                style: Theme.of(context).textTheme.titleMedium),
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
                        child: Text(
                            'Eksik ürün sayısı: ${entry.missingProductIds.length}'),
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
