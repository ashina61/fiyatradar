import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../services/mock_data_service.dart';

class ProductDetailScreen extends StatelessWidget {
  final String productId;

  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  Widget build(BuildContext context) {
    final mockData = MockDataService();
    final product = mockData.products.where((p) => p.id == productId).firstOrNull;

    if (product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Urun Detayi')),
        body: const Center(child: Text('Urun bulunamadi')),
      );
    }

    final discount = product.discountPercentage;
    final categoryColor = _colorForCategory(product.category);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ---------- App Bar with product image placeholder ----------
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.surface,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      categoryColor.withOpacity(0.15),
                      categoryColor.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    Icon(
                      _iconForCategory(product.category),
                      size: 80,
                      color: categoryColor.withOpacity(0.4),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (discount != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                        ),
                        child: Text(
                          '-%${discount.toStringAsFixed(0)} Indirim',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.bookmark_border),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Urun kaydedildi'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {},
              ),
            ],
          ),

          // ---------- Content ----------
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category tag
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      product.category,
                      style: TextStyle(
                        color: categoryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Product name
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Price card
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.08),
                          AppColors.primaryLight.withOpacity(0.04),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Son Fiyat',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatPrice(product.currentPrice),
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              if (product.oldPrice != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  _formatPrice(product.oldPrice!),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: AppColors.textTertiary,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Magaza',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.sm),
                                border: Border.all(color: AppColors.outline),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.store,
                                      size: 16,
                                      color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    product.store,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem(
                        icon: Icons.price_change,
                        value: product.oldPrice != null ? '2' : '1',
                        label: 'Fiyat Girisi',
                        color: AppColors.primary,
                      ),
                      _buildStatItem(
                        icon: Icons.visibility,
                        value: '${42 + product.id.hashCode % 100}',
                        label: 'Goruntuleme',
                        color: AppColors.secondary,
                      ),
                      if (product.isTrending)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.12),
                            borderRadius:
                                BorderRadius.circular(AppRadius.md),
                          ),
                          child: Row(
                            children: const [
                              Text('\u{1F525}',
                                  style: TextStyle(fontSize: 16)),
                              SizedBox(width: 4),
                              Text(
                                'Trend',
                                style: TextStyle(
                                  color: AppColors.accentDark,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  const Divider(),
                  const SizedBox(height: AppSpacing.md),

                  // Price history section
                  Text(
                    'Fiyat Gecmisi',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Simple bar chart
                  _buildPriceChart(product),
                  const SizedBox(height: AppSpacing.lg),

                  const Divider(),
                  const SizedBox(height: AppSpacing.md),

                  // Community validation
                  Text(
                    'Topluluk Dogrulamasi',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  _buildVerificationSection(),
                  const SizedBox(height: AppSpacing.lg),

                  const Divider(),
                  const SizedBox(height: AppSpacing.md),

                  // Comments
                  Text(
                    'Yorumlar',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  _buildCommentsSection(context),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceChart(MockProduct product) {
    // Generate mock price history
    final prices = <_PricePoint>[];
    final now = DateTime.now();
    if (product.oldPrice != null) {
      prices.add(_PricePoint(
        date: now.subtract(const Duration(days: 30)),
        price: product.oldPrice!,
        store: product.store,
      ));
      prices.add(_PricePoint(
        date: now.subtract(const Duration(days: 14)),
        price: (product.oldPrice! + product.currentPrice) / 2,
        store: product.store,
      ));
    }
    prices.add(_PricePoint(
      date: product.addedAt,
      price: product.currentPrice,
      store: product.store,
    ));

    if (prices.length < 2) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.bar_chart,
                  size: 48, color: AppColors.textTertiary),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Yeterli fiyat verisi yok',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    final maxPrice =
        prices.map((p) => p.price).reduce((a, b) => a > b ? a : b);
    final minPrice =
        prices.map((p) => p.price).reduce((a, b) => a < b ? a : b);
    final range = maxPrice - minPrice;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        children: [
          // Chart bars
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: prices.map((point) {
                final normalizedHeight =
                    range > 0 ? ((point.price - minPrice) / range) : 0.5;
                final barHeight =
                    30.0 + (normalizedHeight * 80.0); // min 30, max 110

                return Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          _formatPriceShort(point.price),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: barHeight,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                AppColors.primary,
                                AppColors.primaryLight,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(
                                AppRadius.sm),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Date labels
          Row(
            children: prices.map((point) {
              return Expanded(
                child: Text(
                  '${point.date.day}/${point.date.month}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textTertiary,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildVerifyButton(
                  icon: Icons.thumb_up_outlined,
                  label: 'Dogrula',
                  count: 12,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildVerifyButton(
                  icon: Icons.thumb_down_outlined,
                  label: 'Reddet',
                  count: 2,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Verification progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: Stack(
              children: [
                Container(
                  height: 8,
                  width: double.infinity,
                  color: AppColors.error.withOpacity(0.2),
                ),
                FractionallySizedBox(
                  widthFactor: 0.86, // 12/(12+2)
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius:
                          BorderRadius.circular(AppRadius.full),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '%86 oraninda dogrulandi',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyButton({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection(BuildContext context) {
    // Mock comments
    final comments = [
      _MockComment(
        user: 'Ahmet K.',
        text: 'Bu fiyat gercekten iyi, hemen aldim.',
        likes: 5,
        timeAgo: '2 saat once',
      ),
      _MockComment(
        user: 'Elif Y.',
        text: 'Gecen hafta daha ucuzdu, biraz artmis.',
        likes: 3,
        timeAgo: '5 saat once',
      ),
      _MockComment(
        user: 'Mehmet S.',
        text: 'Kalitesi cok iyi tavsiye ederim.',
        likes: 8,
        timeAgo: '1 gun once',
      ),
    ];

    return Column(
      children: [
        ...comments.map((comment) => Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.outline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            comment.user[0],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              comment.user,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              comment.timeAgo,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.thumb_up_outlined,
                              size: 14, color: AppColors.textTertiary),
                          const SizedBox(width: 4),
                          Text(
                            '${comment.likes}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    comment.text,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            )),

        // Add comment button
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Demo modda yorum eklenemez'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.add_comment_outlined, size: 18),
            label: const Text('Yorum Ekle'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AppColors.primary, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---- Helpers ----

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

  String _formatPriceShort(double price) {
    if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(1)}K';
    }
    return price.toStringAsFixed(0);
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
}

class _PricePoint {
  final DateTime date;
  final double price;
  final String store;

  const _PricePoint({
    required this.date,
    required this.price,
    required this.store,
  });
}

class _MockComment {
  final String user;
  final String text;
  final int likes;
  final String timeAgo;

  const _MockComment({
    required this.user,
    required this.text,
    required this.likes,
    required this.timeAgo,
  });
}
