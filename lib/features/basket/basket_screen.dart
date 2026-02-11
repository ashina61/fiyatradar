import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/basket_item_model.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../utils/theme.dart';
import '../../utils/formatters.dart';
import 'basket_pricing.dart';
import 'basket_view_model.dart';

class BasketScreen extends ConsumerStatefulWidget {
  const BasketScreen({super.key});

  @override
  ConsumerState<BasketScreen> createState() => _BasketScreenState();
}

class _BasketScreenState extends ConsumerState<BasketScreen> {
  @override
  void initState() {
    super.initState();
    ref.listen<BasketViewModel>(basketViewModelProvider, (previous, next) {
      final error = next.errorMessage;
      if (error != null && error != previous?.errorMessage) {
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final viewModel = ref.watch(basketViewModelProvider);
    final theme = Theme.of(context);

    return authState.when(
      data: (user) {
        if (user == null) {
          return _buildLoginPrompt(theme);
        }
        return Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                120,
              ),
              children: [
                _HeaderCard(itemCount: viewModel.items.length),
                const SizedBox(height: AppSpacing.md),
                _ActionRow(
                  onAdd: () => _showProductPicker(context, viewModel),
                  onCalculate: viewModel.items.isEmpty ? null : viewModel.calculate,
                ),
                const SizedBox(height: AppSpacing.md),
                if (viewModel.isLoadingItems)
                  const Center(child: CircularProgressIndicator())
                else if (viewModel.items.isEmpty)
                  _EmptyBasketCard(onAdd: () => _showProductPicker(context, viewModel))
                else ...[
                  Text('Sepetindeki Urunler', style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  ...viewModel.items.map(
                    (item) => _BasketItemTile(
                      item: item,
                      product: viewModel.productMap[item.productId],
                      onQuantityChanged: (qty) =>
                          viewModel.updateQuantity(item.productId, qty),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                if (viewModel.pricingSummary != null)
                  _PricingResults(
                    items: viewModel.items,
                    productMap: viewModel.productMap,
                    summary: viewModel.pricingSummary!,
                    marketNames: viewModel.marketNames,
                  ),
              ],
            ),
            _StickyCalculateBar(
              isLoading: viewModel.isCalculating,
              isEnabled: viewModel.items.isNotEmpty,
              onPressed: viewModel.items.isEmpty ? null : viewModel.calculate,
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildLoginPrompt(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.sm),
            const Text('Sepet icin giris yapmalisiniz.'),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Urun eklemek ve fiyatlari hesaplamak icin hesap gerekli.',
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
                      hintText: 'Urun ara',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.sm),
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
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final int itemCount;

  const _HeaderCard({required this.itemCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.gradientWarm,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.shopping_basket_outlined, color: Colors.white, size: 32),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Fiyat Sepeti',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$itemCount urun ile en uygun marketleri saniyeler icinde bul.',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final VoidCallback onAdd;
  final VoidCallback? onCalculate;

  const _ActionRow({required this.onAdd, required this.onCalculate});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_shopping_cart_outlined, size: 18),
            label: const Text('Urun Ekle'),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: ElevatedButton(
            onPressed: onCalculate,
            child: const Text('Hesapla'),
          ),
        ),
      ],
    );
  }
}

class _EmptyBasketCard extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyBasketCard({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          const Icon(Icons.shopping_basket_outlined, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: AppSpacing.sm),
          const Text('Sepetin bos. Urun ekleyerek baslayin.'),
          const SizedBox(height: AppSpacing.sm),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Urun Ekle'),
          ),
        ],
      ),
    );
  }
}

class _BasketItemTile extends StatelessWidget {
  final BasketItemModel item;
  final ProductModel? product;
  final ValueChanged<int> onQuantityChanged;

  const _BasketItemTile({
    required this.item,
    required this.product,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: product?.mainImage != null
                  ? Image.network(
                      product!.mainImage!,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.inventory_2_outlined),
                    )
                  : const Icon(Icons.inventory_2_outlined, size: 32),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product?.name ?? 'Urun', style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    product?.brand ?? '',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, size: 18),
                    onPressed: () => onQuantityChanged(item.quantity - 1),
                  ),
                  Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  IconButton(
                    icon: const Icon(Icons.add, size: 18),
                    onPressed: () => onQuantityChanged(item.quantity + 1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PricingResults extends StatelessWidget {
  final List<BasketItemModel> items;
  final Map<String, ProductModel> productMap;
  final BasketPricingSummary summary;
  final Map<String, String> marketNames;

  const _PricingResults({
    required this.items,
    required this.productMap,
    required this.summary,
    required this.marketNames,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bestSingle = summary.bestSingleMarket;
    final mixed = summary.mixedResult;
    final saveAmount = bestSingle != null
        ? (bestSingle.total - mixed.total)
            .clamp(0, double.infinity)
            .toDouble()
        : null;
    final marketEntries = summary.perMarketTotals.entries.toList()
      ..sort((a, b) => a.value.total.compareTo(b.value.total));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sonuclar', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        _ResultCard(
          title: 'En Iyi Tek Market',
          subtitle: bestSingle != null
              ? '${bestSingle.marketName} • ${_formatPrice(bestSingle.total)}'
              : 'Hicbir markette tum urunler yok',
          icon: Icons.storefront_outlined,
        ),
        const SizedBox(height: AppSpacing.sm),
        _ResultCard(
          title: 'En Ucuz Karma',
          subtitle: '${_formatPrice(mixed.total)}',
          detail: saveAmount != null ? 'Save ${_formatPrice(saveAmount)}' : 'Save -',
          icon: Icons.auto_awesome,
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Market Karsilastirmasi', style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.xs),
        if (marketEntries.isEmpty)
          const Text('Market fiyati bulunamadi.')
        else
          ...marketEntries.map((entry) {
            final missingCount = entry.value.missingKeys.length;
            final subtitle =
                missingCount == 0 ? 'Tum urunlerde fiyat var' : '$missingCount urun eksik';
            return Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: ListTile(
                leading: const Icon(Icons.storefront_outlined, color: AppColors.primary),
                title: Text(marketNames[entry.key] ?? entry.key),
                subtitle: Text(subtitle),
                trailing: Text(
                  _formatPrice(entry.value.total),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            );
          }),
        const SizedBox(height: AppSpacing.md),
        Text('Parca Parca En Ucuz', style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.xs),
        ...items.map((item) {
          final product = productMap[item.productId];
          final key = item.productId;
          final choice = mixed.perItemChoice[key];
          if (choice == null) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text('${product?.name ?? 'Urun'}: fiyat bulunamadi'),
            );
          }
          return Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: ListTile(
              title: Text(product?.name ?? 'Urun'),
              subtitle: Text('${choice.marketName} • ${_formatPrice(choice.unitPrice)}'),
              trailing: Text(_formatPrice(choice.lineTotal)),
            ),
          );
        }),
        if (mixed.missingKeys.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Fiyat bulunamadi',
            style: theme.textTheme.titleSmall?.copyWith(color: AppColors.warning),
          ),
          const SizedBox(height: AppSpacing.xs),
          ...mixed.missingKeys.map((key) {
            final product = productMap[key];
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text(
                product?.name ?? key,
                style: const TextStyle(color: AppColors.warning),
              ),
            );
          }),
        ],
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? detail;
  final IconData icon;

  const _ResultCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.outline.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
          if (detail != null)
            Text(
              detail!,
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.success),
            ),
        ],
      ),
    );
  }
}

class _StickyCalculateBar extends StatelessWidget {
  final bool isLoading;
  final bool isEnabled;
  final VoidCallback? onPressed;

  const _StickyCalculateBar({
    required this.isLoading,
    required this.isEnabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: ElevatedButton(
            onPressed: isEnabled && !isLoading ? onPressed : null,
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Hesapla'),
          ),
        ),
      ),
    );
  }
}

String _formatPrice(double value) {
  return formatTRY(value);
}
