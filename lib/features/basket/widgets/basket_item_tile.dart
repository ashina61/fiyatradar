import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/basket_item_model.dart';
import '../../../models/product_model.dart';
import '../../../utils/theme.dart';

class BasketItemTile extends StatelessWidget {
  final BasketItemModel item;
  final ProductModel? product;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemove;

  const BasketItemTile({
    super.key,
    required this.item,
    required this.product,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(item.productId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.9),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) => onRemove(),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.outline.withOpacity(0.7)),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow.withOpacity(0.4),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            _ProductImage(imageUrl: product?.mainImage),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product?.name ?? 'Ürün',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    product?.brand ?? '-',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _QuantityStepper(
              quantity: item.quantity,
              onDecrement: () {
                HapticFeedback.selectionClick();
                onQuantityChanged(item.quantity - 1);
              },
              onIncrement: () {
                HapticFeedback.selectionClick();
                onQuantityChanged(item.quantity + 1);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String? imageUrl;

  const _ProductImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        width: 58,
        height: 58,
        color: AppColors.surfaceVariant,
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.inventory_2_outlined),
              )
            : const Icon(Icons.inventory_2_outlined, color: AppColors.textSecondary),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _QuantityStepper({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant.withOpacity(0.9),
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(color: AppColors.outline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                splashRadius: 18,
                onPressed: onDecrement,
                icon: const Icon(Icons.remove_rounded, size: 18),
              ),
              Text('$quantity', style: const TextStyle(fontWeight: FontWeight.w700)),
              IconButton(
                visualDensity: VisualDensity.compact,
                splashRadius: 18,
                onPressed: onIncrement,
                icon: const Icon(Icons.add_rounded, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
