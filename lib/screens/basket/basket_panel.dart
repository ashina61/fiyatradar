import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/basket_item_model.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/basket_provider.dart';
import '../../providers/product_provider.dart';
import '../../services/basket_service.dart';
import '../../utils/theme.dart';

class BasketPanel extends ConsumerWidget {
  final bool showTitle;

  const BasketPanel({super.key, this.showTitle = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final theme = Theme.of(context);

    return authState.when(
      data: (user) {
        if (user == null) {
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
                    'Urun eklemek ve en ucuz marketi hesaplamak icin hesap gerekli.',
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

        final itemsAsync = ref.watch(basketItemsProvider);
        final productsAsync = ref.watch(basketProductsProvider);
        final calculationAsync = ref.watch(basketCalculationProvider);

        return itemsAsync.when(
          data: (items) {
            return productsAsync.when(
              data: (productMap) {
                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    if (showTitle)
                      Text('Fiyat Sepeti', style: theme.textTheme.titleLarge),
                    if (showTitle) const SizedBox(height: AppSpacing.sm),
                    if (items.length >= 10)
                      _BasketPromptBanner(
                        onCalculate: () => ref.refresh(basketCalculationProvider),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showProductPicker(context, ref, items, productMap),
                            icon: const Icon(Icons.add_shopping_cart_outlined, size: 18),
                            label: const Text('Urun Ekle'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => ref.refresh(basketCalculationProvider),
                            child: const Text('Hesapla'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (items.isEmpty)
                      _EmptyBasketState()
                    else
                      ...items.map((item) => _BasketItemTile(
                            item: item,
                            product: productMap[item.productId],
                          )),
                    const SizedBox(height: AppSpacing.md),
                    calculationAsync.when(
                      data: (result) {
                        if (items.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return _BasketResults(
                          items: items,
                          productMap: productMap,
                          result: result,
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _showProductPicker(
    BuildContext context,
    WidgetRef ref,
    List<BasketItemModel> items,
    Map<String, ProductModel> productMap,
  ) {
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
                        final existing = items
                            .firstWhere(
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
                            final user = ref.read(authStateProvider).value;
                            if (user == null) return;
                            final nextQty = inBasket ? existing.quantity + 1 : 1;
                            ref.read(firestoreServiceProvider).upsertBasketItem(
                                  userId: user.uid,
                                  productId: product.id,
                                  quantity: nextQty,
                                );
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

class _BasketPromptBanner extends StatelessWidget {
  final VoidCallback onCalculate;

  const _BasketPromptBanner({required this.onCalculate});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          const Icon(Icons.shopping_basket_outlined, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          const Expanded(
            child: Text('Sepetin hazir — en ucuz secenekleri hesaplayalim'),
          ),
          TextButton(
            onPressed: onCalculate,
            child: const Text('Hesapla'),
          ),
        ],
      ),
    );
  }
}

class _EmptyBasketState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: const [
          Icon(Icons.shopping_basket_outlined, size: 48, color: AppColors.textSecondary),
          SizedBox(height: AppSpacing.sm),
          Text('Sepetin bos. Urun ekleyerek baslayin.'),
        ],
      ),
    );
  }
}

class _BasketItemTile extends ConsumerWidget {
  final BasketItemModel item;
  final ProductModel? product;

  const _BasketItemTile({
    required this.item,
    required this.product,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: product?.mainImage != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Image.network(
                  product!.mainImage!,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.inventory_2_outlined),
                ),
              )
            : const Icon(Icons.inventory_2_outlined),
        title: Text(product?.name ?? 'Urun'),
        subtitle: Text(product?.brand ?? ''),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: user == null
                  ? null
                  : () {
                      final nextQty = item.quantity - 1;
                      if (nextQty <= 0) {
                        ref.read(firestoreServiceProvider).removeBasketItem(
                              userId: user.uid,
                              productId: item.productId,
                            );
                      } else {
                        ref.read(firestoreServiceProvider).upsertBasketItem(
                              userId: user.uid,
                              productId: item.productId,
                              quantity: nextQty,
                            );
                      }
                    },
            ),
            Text('${item.quantity}'),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: user == null
                  ? null
                  : () {
                      ref.read(firestoreServiceProvider).upsertBasketItem(
                            userId: user.uid,
                            productId: item.productId,
                            quantity: item.quantity + 1,
                          );
                    },
            ),
          ],
        ),
      ),
    );
  }
}

class _BasketResults extends StatelessWidget {
  final List<BasketItemModel> items;
  final Map<String, ProductModel> productMap;
  final BasketCalculationResult result;

  const _BasketResults({
    required this.items,
    required this.productMap,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final totalItems = items.length;
    final threshold = (totalItems * 0.7).ceil();
    final eligibleStores = result.perStoreCoverage.entries
        .where((entry) => entry.value >= threshold)
        .toList();

    eligibleStores.sort((a, b) {
      final totalA = result.perStoreTotal[a.key] ?? double.infinity;
      final totalB = result.perStoreTotal[b.key] ?? double.infinity;
      return totalA.compareTo(totalB);
    });

    final bestStore = eligibleStores.isNotEmpty ? eligibleStores.first : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sonuclar', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        if (bestStore != null)
          Card(
            child: ListTile(
              leading: const Icon(Icons.storefront_outlined, color: AppColors.success),
              title: const Text('Tek markette en ucuz'),
              subtitle: Text(bestStore.key),
              trailing: Text(
                '${(result.perStoreTotal[bestStore.key] ?? 0).toStringAsFixed(2)} TL',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          )
        else
          const Text('Tek markette yeterli kapsama bulunamadi.'),
        const SizedBox(height: AppSpacing.sm),
        Text('Parca parca en ucuz', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.xs),
        ...items.map((item) {
          final product = productMap[item.productId];
          final cheapest = result.cheapestPerProduct[item.productId];
          if (cheapest == null) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text('${product?.name ?? 'Urun'}: fiyat bulunamadi'),
            );
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text(
              '${product?.name ?? 'Urun'} → ${cheapest.storeName} (${cheapest.price.toStringAsFixed(2)} TL)',
            ),
          );
        }),
        if (result.missingProductIds.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Fiyat bulunamayan urunler: ${result.missingProductIds.length}',
            style: const TextStyle(color: AppColors.warning),
          ),
        ],
      ],
    );
  }
}
