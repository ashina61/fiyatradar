import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/product_model.dart';
import '../models/price_model.dart';
import '../providers/product_provider.dart';
import '../utils/theme.dart';

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
    final currencyFormat = NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '₺',
      decimalDigits: 2,
    );
    final priceHistoryAsync =
        ref.watch(productPriceHistoryProvider(product.id));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.lg),
                    ),
                    child: product.mainImage != null
                        ? Hero(
                            tag: 'product_${product.id}',
                            child: CachedNetworkImage(
                              imageUrl: product.mainImage!,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceVariant,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) =>
                                  _buildPlaceholder(context),
                            ),
                          )
                        : _buildPlaceholder(context),
                  ),
                  if (showTrendBadge && product.isTrending)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '🔥',
                              style: TextStyle(fontSize: 12),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Trend',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Content
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand
                    Text(
                      product.brand.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    // Name
                    Expanded(
                      child: Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Price
                    if (product.lastPrice != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currencyFormat.format(product.lastPrice),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          priceHistoryAsync.when(
                            data: (prices) =>
                                _buildPriceChangeIndicator(context, prices),
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                          priceHistoryAsync.when(
                            data: (prices) =>
                                _buildRelativeTimeText(context, prices),
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ],
                      )
                    else
                      Text(
                        'Fiyat yok',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelativeTimeText(
      BuildContext context, List<PriceModel> prices) {
    if (prices.isEmpty) return const SizedBox.shrink();
    final latest = prices.first;
    final text = _formatTimeAgo(latest.createdAt);
    if (text.isEmpty) return const SizedBox.shrink();
    return Text(
      text,
      style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor),
    );
  }

  Widget _buildPriceChangeIndicator(
      BuildContext context, List<PriceModel> prices) {
    if (prices.length < 2) return const SizedBox.shrink();

    final approved = prices.where((price) => price.isApproved).toList();
    final source = approved.length >= 2 ? approved : prices;
    if (source.length < 2) return const SizedBox.shrink();

    final latest = source[0];
    final previous = source[1];
    final diff = latest.price - previous.price;
    if (diff == 0) return const SizedBox.shrink();

    final percent = (diff / previous.price) * 100;
    final isUp = diff > 0;
    final color = isUp ? AppColors.error : AppColors.success;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isUp ? Icons.trending_up : Icons.trending_down,
          size: 12,
          color: color,
        ),
        const SizedBox(width: 2),
        Text(
          '${percent.abs().toStringAsFixed(1)}%',
          style: TextStyle(fontSize: 11, color: color),
        ),
      ],
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'az once';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} dk once';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} sa once';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gun once';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Icon(
        Icons.image_outlined,
        size: 48,
        color: Theme.of(context).colorScheme.outline,
      ),
    );
  }
}

class ProductCardShimmer extends StatelessWidget {
  const ProductCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 10,
                    width: 50,
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    height: 16,
                    width: 70,
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
