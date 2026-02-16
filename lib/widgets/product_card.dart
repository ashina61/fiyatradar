import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/price_model.dart';
import '../models/product_model.dart';
import '../providers/product_provider.dart';
import '../utils/formatters.dart';
import '../utils/level_system.dart';
import '../utils/theme.dart';
import 'app_badge.dart';
import 'app_card.dart';
import 'app_network_image.dart';
import 'level_badge.dart';

class ProductCard extends ConsumerWidget {
  final ProductModel product;
  final VoidCallback? onTap;
  final bool showTrendBadge;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.showTrendBadge = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final priceHistoryAsync = ref.watch(productPriceHistoryProvider(product.id));

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.6),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.lg),
                    ),
                  ),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Hero(
                    tag: 'product_${product.id}',
                    child: AppNetworkImage(
                      imageUrl: product.effectiveImage,
                      cacheKey: 'product_card_${product.id}',
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
                if (showTrendBadge && product.isTrending)
                  const Positioned(
                    top: AppSpacing.sm,
                    left: AppSpacing.sm,
                    child: AppBadge(
                      text: 'Trend',
                      icon: Icons.local_fire_department,
                      backgroundColor: Color(0x22CD853F),
                      foregroundColor: AppColors.accentDark,
                    ),
                  ),
                if ((product.userId ?? '').trim().isNotEmpty)
                  Positioned(
                    top: AppSpacing.sm,
                    right: AppSpacing.sm,
                    child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance.collection('users').doc(product.userId).snapshots(),
                      builder: (context, snapshot) {
                        final data = snapshot.data?.data();
                        final totalPoints = (data?['totalPoints'] as num?)?.toInt() ?? (data?['points'] as num?)?.toInt() ?? 0;
                        return LevelBadge(level: levelBuilder(totalPoints), compact: true);
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.brand.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          letterSpacing: 0.6,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  if (product.lastPrice != null)
                    _PriceText(price: product.lastPrice!)
                  else
                    Text('Fiyat yok', style: Theme.of(context).textTheme.labelMedium),
                  priceHistoryAsync.when(
                    data: (prices) => _buildPriceChangeIndicator(context, prices),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceChangeIndicator(BuildContext context, List<PriceModel> prices) {
    if (prices.length < 2) return const SizedBox.shrink();

    final latest = prices[0];
    final previous = prices[1];
    final diff = latest.price - previous.price;
    if (diff == 0 || previous.price == 0) return const SizedBox.shrink();

    final percent = (diff / previous.price) * 100;
    final isUp = diff > 0;
    final color = isUp ? AppColors.error : AppColors.success;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: AppBadge(
        text: '${percent.abs().toStringAsFixed(1)}%',
        icon: isUp ? Icons.trending_up : Icons.trending_down,
        backgroundColor: color.withOpacity(0.14),
        foregroundColor: color,
      ),
    );
  }
}

class _PriceText extends StatelessWidget {
  final double price;

  const _PriceText({required this.price});

  @override
  Widget build(BuildContext context) {
    return Text(
      formatTRY(price),
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class ProductCardShimmer extends StatelessWidget {
  const ProductCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.lg),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 10, width: 48, color: Theme.of(context).colorScheme.surfaceVariant),
                  const SizedBox(height: AppSpacing.sm),
                  Container(height: 12, width: double.infinity, color: Theme.of(context).colorScheme.surfaceVariant),
                  const Spacer(),
                  Container(height: 16, width: 72, color: Theme.of(context).colorScheme.surfaceVariant),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
