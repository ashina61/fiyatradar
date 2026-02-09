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
                    if (showTitle) ...[
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: const Icon(Icons.shopping_cart_outlined,
                                color: AppColors.primary, size: 22),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text('Fiyat Sepeti',
                              style: theme.textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const Spacer(),
                          Text(
                            '${items.length} urun',
                            style: TextStyle(
                              color: theme.hintColor,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    // ---------- Action buttons ----------
                    Row(
                      children: [
                        // Add product — secondary
                        OutlinedButton.icon(
                          onPressed: () =>
                              _showProductPicker(context, ref, items, productMap),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Urun Ekle'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.lg),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        // Calculate — primary
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: items.isEmpty
                                ? null
                                : () =>
                                    ref.refresh(basketCalculationProvider),
                            icon: const Icon(Icons.calculate_outlined,
                                size: 20, color: Colors.white),
                            label: const Text(
                              'En Ucuzu Hesapla',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              disabledBackgroundColor:
                                  AppColors.primary.withOpacity(0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.lg),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (items.length >= 10)
                      _BasketPromptBanner(
                        onCalculate: () =>
                            ref.refresh(basketCalculationProvider),
                      ),
                    // ---------- Items ----------
                    if (items.isEmpty)
                      _EmptyBasketState()
                    else
                      ...items.map((item) => _BasketItemTile(
                            item: item,
                            product: productMap[item.productId],
                          )),
                    const SizedBox(height: AppSpacing.md),
                    // ---------- Results ----------
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
                      loading: () => Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.lg),
                        child: Column(
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Hesaplaniyor...',
                              style: TextStyle(
                                  color: theme.hintColor, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
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
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) {
        final controller = TextEditingController();
        return StatefulBuilder(
          builder: (ctx, setState) {
            final query = controller.text.toLowerCase();
            final allProducts =
                ref.watch(allProductsProvider).valueOrNull ?? [];
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
                        final existing = items.firstWhere(
                          (item) => item.productId == product.id,
                          orElse: () =>
                              BasketItemModel(productId: '', quantity: 0),
                        );
                        final inBasket = existing.productId.isNotEmpty;
                        return ListTile(
                          title: Text(product.name),
                          subtitle: Text(product.brand),
                          trailing: Icon(
                            inBasket
                                ? Icons.check_circle
                                : Icons.add_circle_outline,
                            color: inBasket
                                ? AppColors.success
                                : AppColors.primary,
                          ),
                          onTap: () {
                            final user =
                                ref.read(authStateProvider).value;
                            if (user == null) return;
                            final nextQty =
                                inBasket ? existing.quantity + 1 : 1;
                            ref
                                .read(firestoreServiceProvider)
                                .upsertBasketItem(
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
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lightbulb_outline,
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Expanded(
            child: Text(
              'Sepetin hazir — en ucuz secenekleri hesaplayalim!',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
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
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          Icon(Icons.shopping_basket_outlined,
              size: 56, color: AppColors.textTertiary.withOpacity(0.5)),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Sepetin bos',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Urun ekleyerek fiyat karsilastirmaya baslayin',
            style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
            textAlign: TextAlign.center,
          ),
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
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Row(
          children: [
            // Product image
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: product?.mainImage != null
                  ? ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppRadius.md),
                      child: Image.network(
                        product!.mainImage!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.inventory_2_outlined,
                            color: AppColors.textTertiary,
                            size: 22),
                      ),
                    )
                  : const Icon(Icons.inventory_2_outlined,
                      color: AppColors.textTertiary, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            // Product info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product?.name ?? 'Urun',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (product?.brand != null &&
                      product!.brand.isNotEmpty)
                    Text(
                      product!.brand,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                ],
              ),
            ),
            // Quantity controls
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _QuantityButton(
                    icon: item.quantity <= 1
                        ? Icons.delete_outline
                        : Icons.remove,
                    color: item.quantity <= 1
                        ? AppColors.error
                        : AppColors.textPrimary,
                    onTap: user == null
                        ? null
                        : () {
                            final nextQty = item.quantity - 1;
                            if (nextQty <= 0) {
                              ref
                                  .read(firestoreServiceProvider)
                                  .removeBasketItem(
                                    userId: user.uid,
                                    productId: item.productId,
                                  );
                            } else {
                              ref
                                  .read(firestoreServiceProvider)
                                  .upsertBasketItem(
                                    userId: user.uid,
                                    productId: item.productId,
                                    quantity: nextQty,
                                  );
                            }
                          },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '${item.quantity}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  _QuantityButton(
                    icon: Icons.add,
                    color: AppColors.primary,
                    onTap: user == null
                        ? null
                        : () {
                            ref
                                .read(firestoreServiceProvider)
                                .upsertBasketItem(
                                  userId: user.uid,
                                  productId: item.productId,
                                  quantity: item.quantity + 1,
                                );
                          },
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

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _QuantityButton({
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20, color: color),
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

  String _formatPrice(double price) {
    if (price >= 1000) {
      final parts = price.toStringAsFixed(2).split('.');
      final intPart = parts[0];
      final decPart = parts[1];
      final buffer = StringBuffer();
      int count = 0;
      for (int i = intPart.length - 1; i >= 0; i--) {
        buffer.write(intPart[i]);
        count++;
        if (count == 3 && i > 0) {
          buffer.write('.');
          count = 0;
        }
      }
      return '\u20BA${buffer.toString().split('').reversed.join()},$decPart';
    }
    return '\u20BA${price.toStringAsFixed(2).replaceAll('.', ',')}';
  }

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

    final bestStore =
        eligibleStores.isNotEmpty ? eligibleStores.first : null;

    final hasMissing = result.missingProductIds.isNotEmpty;
    final foundItems = items.where(
        (item) => result.cheapestPerProduct.containsKey(item.productId));
    final piecewiseTotal = foundItems.fold<double>(0, (sum, item) {
      final cheapest = result.cheapestPerProduct[item.productId];
      return sum + (cheapest != null ? cheapest.price * item.quantity : 0);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            const Icon(Icons.analytics_outlined,
                color: AppColors.primary, size: 22),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Sonuclar',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // ---- Best single store card ----
        if (bestStore != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.success.withOpacity(0.08),
                  AppColors.success.withOpacity(0.03),
                ],
              ),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border:
                  Border.all(color: AppColors.success.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.store,
                          color: AppColors.success, size: 20),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Expanded(
                      child: Text(
                        'Tek Markette En Ucuz',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bestStore.key,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${bestStore.value}/$totalItems urun mevcut',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatPrice(
                          result.perStoreTotal[bestStore.key] ?? 0),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    color: Theme.of(context).hintColor, size: 20),
                const SizedBox(width: AppSpacing.sm),
                const Expanded(
                  child: Text(
                    'Tek markette yeterli urun kapsami bulunamadi.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.lg),

        // ---- Piecewise cheapest section ----
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.lg),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.compare_arrows,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    const Expanded(
                      child: Text(
                        'Parca Parca En Ucuz',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (piecewiseTotal > 0)
                      Text(
                        _formatPrice(piecewiseTotal),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.primary,
                        ),
                      ),
                  ],
                ),
              ),
              // Items
              ...items.map((item) {
                final product = productMap[item.productId];
                final cheapest =
                    result.cheapestPerProduct[item.productId];
                final isMissing = cheapest == null;

                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.outline.withOpacity(0.5),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (isMissing)
                        const Icon(Icons.warning_amber,
                            color: AppColors.warning, size: 18)
                      else
                        const Icon(Icons.check_circle_outline,
                            color: AppColors.success, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              product?.name ?? 'Urun',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                                color: isMissing
                                    ? AppColors.textTertiary
                                    : AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (!isMissing)
                              Text(
                                cheapest.storeName,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (isMissing)
                        const Text(
                          'Fiyat yok',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.warning,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      else
                        Text(
                          _formatPrice(cheapest.price * item.quantity),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),

        // ---- Missing products warning ----
        if (hasMissing) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.08),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border:
                  Border.all(color: AppColors.warning.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber,
                    color: AppColors.warning, size: 22),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${result.missingProductIds.length} urun icin fiyat bulunamadi',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppColors.warning,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        result.missingProductIds
                            .map((id) =>
                                productMap[id]?.name ?? 'Bilinmeyen')
                            .join(', '),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
