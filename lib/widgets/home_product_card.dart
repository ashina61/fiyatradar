import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/price_model.dart';
import '../models/product_model.dart';
import '../providers/product_provider.dart';
import '../utils/formatters.dart';
import '../utils/theme.dart';
import 'price_change_badge.dart';

class HomeProductCard extends ConsumerWidget {
  final ProductModel product;
  final double width;
  final VoidCallback? onTap;
  final bool showStore;
  final Widget? bottomSection;

  const HomeProductCard({
    super.key,
    required this.product,
    required this.width,
    this.onTap,
    this.showStore = true,
    this.bottomSection,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryColor = _colorForCategory(product.category);
    final hasPrice = product.lastPrice != null;
    final priceHistoryAsync = ref.watch(productPriceHistoryProvider(product.id));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.outline, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.08),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppRadius.lg),
                      topRight: Radius.circular(AppRadius.lg),
                    ),
                    image: product.mainImage != null
                        ? DecorationImage(
                            image: NetworkImage(product.mainImage!),
                            fit: BoxFit.contain,
                            onError: (_, __) {},
                          )
                        : null,
                  ),
                  child: product.mainImage == null
                      ? Center(
                          child: Icon(
                            _iconForCategory(product.category),
                            size: 36,
                            color: categoryColor.withOpacity(0.5),
                          ),
                        )
                      : null,
                ),
                if (product.priceEntryCount >= 2 && product.lastPrice != null)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: priceHistoryAsync.when(
                      data: (prices) => _buildPriceChangeBadge(prices),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm + 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: Text(
                        product.category,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: categoryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          height: 1.3,
                        ),
                      ),
                    ),
                    if (hasPrice)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _formatPriceTrailingTry(product.lastPrice!),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          priceHistoryAsync.when(
                            data: (prices) => _buildRelativeTimeText(prices),
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    const SizedBox(height: 2),
                    if (showStore && product.lastStore != null)
                      Text(
                        product.lastStore!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    if (bottomSection != null) ...[
                      const SizedBox(height: 4),
                      bottomSection!,
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceChangeBadge(List<PriceModel> prices) {
    if (prices.length < 2) return const SizedBox.shrink();
    final approved = prices.where((price) => price.isApproved).toList();
    final source = approved.length >= 2 ? approved : prices;
    if (source.length < 2) return const SizedBox.shrink();

    final latest = source[0];
    final previous = source[1];
    final diff = latest.price - previous.price;
    if (diff == 0) return const SizedBox.shrink();

    final percent = (diff / previous.price) * 100;
    return PriceChangeBadge(percent: percent);
  }

  Widget _buildRelativeTimeText(List<PriceModel> prices) {
    if (prices.isEmpty) return const SizedBox.shrink();
    final text = _formatTimeAgo(prices.first.createdAt);
    if (text.isEmpty) return const SizedBox.shrink();
    return Text(
      text,
      style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'az once';
    if (difference.inMinutes < 60) return '${difference.inMinutes} dk once';
    if (difference.inHours < 24) return '${difference.inHours} sa once';
    if (difference.inDays < 7) return '${difference.inDays} gun once';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  String _formatPriceTrailingTry(double price) {
    final formatted = formatTRY(price).replaceAll('₺', '').trim();
    return '${formatted}₺';
  }
}

Color _colorForCategory(String category) {
  switch (category) {
    case 'Elektronik':
      return AppColors.primary;
    case 'Gida':
      return AppColors.secondary;
    case 'Temizlik':
      return AppColors.info;
    case 'Kisisel Bakim':
      return AppColors.accent;
    case 'Ev & Yasam':
      return AppColors.secondaryDark;
    case 'Giyim':
      return AppColors.error;
    case 'Spor':
      return AppColors.primaryDark;
    case 'Oyuncak':
      return AppColors.accentDark;
    case 'Kitap':
      return AppColors.primaryLight;
    case 'Otomotiv':
      return AppColors.secondaryLight;
    default:
      return AppColors.textSecondary;
  }
}

IconData _iconForCategory(String category) {
  switch (category) {
    case 'Elektronik':
      return Icons.devices;
    case 'Gida':
      return Icons.restaurant;
    case 'Temizlik':
      return Icons.cleaning_services;
    case 'Kisisel Bakim':
      return Icons.face;
    case 'Ev & Yasam':
      return Icons.home;
    case 'Giyim':
      return Icons.checkroom;
    case 'Spor':
      return Icons.sports;
    case 'Oyuncak':
      return Icons.toys;
    case 'Kitap':
      return Icons.book;
    case 'Otomotiv':
      return Icons.directions_car;
    default:
      return Icons.category;
  }
}
