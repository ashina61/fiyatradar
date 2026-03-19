import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/basket_item_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../screens/main_screen.dart';
import '../../utils/theme.dart';
import 'basket_view_model.dart';
import 'widgets/basket_header_card.dart';
import 'widgets/basket_item_tile.dart';
import 'widgets/basket_result_panel.dart';
import 'widgets/basket_sticky_bar.dart';

class BasketScreen extends ConsumerStatefulWidget {
  const BasketScreen({super.key});

  @override
  ConsumerState<BasketScreen> createState() => _BasketScreenState();
}

class _BasketScreenState extends ConsumerState<BasketScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isHeaderCompact = false;

  Future<bool> _returnToHome() async {
    if (!mounted) return false;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen()),
      (route) => false,
    );
    return false;
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    ref.listenManual<BasketViewModel>(basketViewModelProvider, (previous, next) {
      final error = next.errorMessage;
      if (error != null && error != previous?.errorMessage && mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(AppSpacing.md),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
        );
      }

      if (!mounted) return;
      final summary = next.pricingSummary;
      final didChangeSummary = summary != null && summary != previous?.pricingSummary;
      if (didChangeSummary) {
        _showResultSheet(next);
      }
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final nextCompact = _scrollController.offset > 56;
    if (nextCompact != _isHeaderCompact && mounted) {
      setState(() => _isHeaderCompact = nextCompact);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return _buildLoginPrompt(context);
        }
        final viewModel = ref.watch(basketViewModelProvider);
        final totalProducts = viewModel.items.fold<int>(0, (sum, item) => sum + item.quantity);

        return WillPopScope(
          onWillPop: _returnToHome,
          child: Stack(
            children: [
              ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  108,
                ),
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: BasketHeaderCard(
                      key: ValueKey('header-$_isHeaderCompact-$totalProducts'),
                      itemCount: totalProducts,
                      compact: _isHeaderCompact,
                      onAddProduct: () => _showProductPicker(context, viewModel),
                      onCalculate:
                          viewModel.items.isEmpty ? null : viewModel.calculate,
                      canCalculate: viewModel.items.isNotEmpty &&
                          !viewModel.isCalculating,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (viewModel.isLoadingItems)
                    const Center(child: CircularProgressIndicator())
                  else if (viewModel.items.isEmpty)
                    _EmptyBasketCard(
                      onAdd: () => _showProductPicker(context, viewModel),
                    )
                  else
                    _BasketItemsSection(viewModel: viewModel),
                ],
              ),
              BasketStickyBar(
                itemCount: totalProducts,
                isLoading: viewModel.isCalculating,
                isEnabled: viewModel.items.isNotEmpty,
                onPressed: viewModel.items.isEmpty ? null : viewModel.calculate,
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Future<void> _showResultSheet(BasketViewModel viewModel) async {
    final summary = viewModel.pricingSummary;
    if (summary == null) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return FractionallySizedBox(
          heightFactor: 0.82,
          child: BasketResultPanel(
            summary: summary,
            marketNames: viewModel.marketNames,
          ),
        );
      },
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.xs),
            const Text('Sepet için giriş yapmalısınız.'),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Ürün eklemek ve fiyatları hesaplamak için hesap gerekli.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showProductPicker(BuildContext context, BasketViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) {
        final controller = TextEditingController();
        return StatefulBuilder(
          builder: (ctx, setState) {
            final query = controller.text.toLowerCase();
            final allProducts = ref.watch(allProductsProvider).valueOrNull ?? [];
            final filtered = allProducts.where((product) {
              if (query.isEmpty) return true;
              return product.name.toLowerCase().contains(query) ||
                  product.brand.toLowerCase().contains(query);
            }).toList();

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: AppSpacing.md,
                right: AppSpacing.md,
                top: AppSpacing.md,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Ürün ara',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final product = filtered[index];
                        final existing = viewModel.items.firstWhere(
                          (item) => item.productId == product.id,
                          orElse: () => BasketItemModel(productId: '', quantity: 0),
                        );
                        final inBasket = existing.productId.isNotEmpty;
                        return ListTile(
                          title: Text(product.name),
                          subtitle: Text(product.brand),
                          trailing: Icon(
                            inBasket ? Icons.check_circle : Icons.add_circle_outline,
                            color: inBasket ? AppColors.success : AppColors.primary,
                          ),
                          onTap: () {
                            viewModel.addProduct(product.id);
                            if (Navigator.canPop(ctx)) Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _EmptyBasketCard extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyBasketCard({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.outline.withOpacity(0.8)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: const Icon(Icons.shopping_basket_outlined, size: 36, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Sepetin boş', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Ürün ekleyerek en uygun marketi hemen karşılaştır.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Ürün ekle'),
          ),
        ],
      ),
    );
  }
}

class _BasketItemsSection extends StatelessWidget {
  final BasketViewModel viewModel;

  const _BasketItemsSection({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sepetindeki Ürünler',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          child: Column(
            key: ValueKey(viewModel.items.length),
            children: [
              for (final item in viewModel.items)
                BasketItemTile(
                  item: item,
                  product: viewModel.productMap[item.productId],
                  onQuantityChanged: (qty) => viewModel.updateQuantity(item.productId, qty),
                  onRemove: () => viewModel.updateQuantity(item.productId, 0),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
