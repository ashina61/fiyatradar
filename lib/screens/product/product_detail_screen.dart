import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/theme.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/product_model.dart';
import '../../models/comment_model.dart';
import '../../models/price_model.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  final _commentController = TextEditingController();
  bool _isSubmittingComment = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final userModel = ref.read(userModelStreamProvider).value;
    if (userModel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Yorum eklemek icin giris yapmalisiniz'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmittingComment = true);

    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      final comment = CommentModel(
        id: '',
        productId: widget.productId,
        userId: userModel.uid,
        userName: userModel.name,
        userPhotoUrl: userModel.photoUrl,
        text: _commentController.text.trim(),
        createdAt: DateTime.now(),
      );

      await firestoreService.addComment(comment);
      _commentController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Yorum eklendi!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmittingComment = false);
      }
    }
  }

  void _showAddCommentDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
                alignment: Alignment.center,
              ),
              Text(
                'Yorum Ekle',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _commentController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Yorumunuzu yazin...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: _isSubmittingComment ? null : () {
                  _submitComment();
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                child: _isSubmittingComment
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Gonder',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productByIdProvider(widget.productId));
    final commentsAsync = ref.watch(productCommentsProvider(widget.productId));
    final priceHistoryAsync = ref.watch(productPriceHistoryProvider(widget.productId));
    final isSaved = ref.watch(isProductSavedProvider(widget.productId));

    return productAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Urun Detayi')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Urun Detayi')),
        body: Center(child: Text('Hata: $error')),
      ),
      data: (product) {
        if (product == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Urun Detayi')),
            body: const Center(child: Text('Urun bulunamadi')),
          );
        }

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
                        if (product.mainImage != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            child: Image.network(
                              product.mainImage!,
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                _iconForCategory(product.category),
                                size: 80,
                                color: categoryColor.withOpacity(0.4),
                              ),
                            ),
                          )
                        else
                          Icon(
                            _iconForCategory(product.category),
                            size: 80,
                            color: categoryColor.withOpacity(0.4),
                          ),
                        const SizedBox(height: AppSpacing.md),
                        if (product.isTrending)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(AppRadius.xl),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('\u{1F525}', style: TextStyle(fontSize: 14)),
                                SizedBox(width: 4),
                                Text(
                                  'Trend',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      isSaved ? Icons.bookmark : Icons.bookmark_border,
                      color: isSaved ? AppColors.primary : null,
                    ),
                    onPressed: () async {
                      await ref.read(userNotifierProvider.notifier).toggleSavedProduct(widget.productId);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isSaved ? 'Urun kaldirildi' : 'Urun kaydedildi'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                          ),
                        );
                      }
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
                      if (product.brand.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          product.brand,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),

                      // Price card
                      _buildPriceCard(product),
                      const SizedBox(height: AppSpacing.lg),

                      // Stats row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem(
                            icon: Icons.price_change,
                            value: '${product.priceEntryCount}',
                            label: 'Fiyat Girisi',
                            color: AppColors.primary,
                          ),
                          _buildStatItem(
                            icon: Icons.visibility,
                            value: '${product.viewCount}',
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
                              child: const Row(
                                children: [
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

                      // Price chart from Firebase
                      priceHistoryAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Text('Hata: $e'),
                        data: (prices) => Column(
                          children: [
                            _buildPriceChart(prices),
                            if (prices.isNotEmpty)
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () => _showReportPriceDialog(prices.first),
                                  icon: const Icon(Icons.flag_outlined, size: 16, color: AppColors.textTertiary),
                                  label: const Text('Fiyati Raporla', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                                ),
                              ),
                          ],
                        ),
                      ),
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

                      priceHistoryAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Text('Hata: $e'),
                        data: (prices) => _buildVerificationSection(prices),
                      ),
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

                      commentsAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Text('Hata: $e'),
                        data: (comments) => _buildCommentsSection(context, comments),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPriceCard(ProductModel product) {
    return Container(
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
                  product.lastPrice != null
                      ? _formatPrice(product.lastPrice!)
                      : 'Fiyat yok',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          if (product.lastStore != null)
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
                        product.lastStore!,
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

  Widget _buildPriceChart(List<PriceModel> prices) {
    if (prices.length < 2) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.bar_chart,
                  size: 48, color: AppColors.textTertiary),
              SizedBox(height: AppSpacing.sm),
              Text(
                'Yeterli fiyat verisi yok',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    // Sort by date ascending
    final sortedPrices = List<PriceModel>.from(prices)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    // Take last 5 prices for chart
    final chartPrices = sortedPrices.length > 5
        ? sortedPrices.sublist(sortedPrices.length - 5)
        : sortedPrices;

    final maxPrice = chartPrices.map((p) => p.price).reduce((a, b) => a > b ? a : b);
    final minPrice = chartPrices.map((p) => p.price).reduce((a, b) => a < b ? a : b);
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
              children: chartPrices.map((price) {
                final normalizedHeight =
                    range > 0 ? ((price.price - minPrice) / range) : 0.5;
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
                          _formatPriceShort(price.price),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Tooltip(
                          message: '${price.storeName}\n${_formatPrice(price.price)}',
                          child: Container(
                            height: barHeight,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
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
            children: chartPrices.map((price) {
              return Expanded(
                child: Text(
                  '${price.createdAt.day}/${price.createdAt.month}',
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

  Widget _buildVerificationSection(List<PriceModel> prices) {
    int totalVerified = 0;
    int totalUnverified = 0;

    for (final price in prices) {
      totalVerified += price.verifiedCount;
      totalUnverified += price.unverifiedCount;
    }

    final total = totalVerified + totalUnverified;
    final verificationRate = total > 0 ? (totalVerified / total) : 0.0;

    // Get the latest price for voting
    final latestPrice = prices.isNotEmpty ? prices.first : null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        children: [
          if (latestPrice != null)
            Row(
              children: [
                Expanded(
                  child: _buildVerifyButton(
                    icon: Icons.thumb_up_outlined,
                    label: 'Dogrula',
                    count: totalVerified,
                    color: AppColors.success,
                    onTap: () => _verifyLatestPrice(latestPrice.id, true),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildVerifyButton(
                    icon: Icons.thumb_down_outlined,
                    label: 'Reddet',
                    count: totalUnverified,
                    color: AppColors.error,
                    onTap: () => _verifyLatestPrice(latestPrice.id, false),
                  ),
                ),
              ],
            ),
          if (latestPrice != null) const SizedBox(height: AppSpacing.md),
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
                  widthFactor: verificationRate,
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
            total > 0
                ? '%${(verificationRate * 100).toStringAsFixed(0)} oraninda dogrulandi'
                : 'Henuz dogrulama yapilmadi',
            style: TextStyle(
              fontSize: 12,
              color: total > 0 ? AppColors.success : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _verifyLatestPrice(String priceId, bool isVerified) async {
    final user = ref.read(userModelStreamProvider).valueOrNull;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dogrulama icin giris yapmalisiniz'), behavior: SnackBarBehavior.floating),
        );
      }
      return;
    }

    final service = ref.read(firestoreServiceProvider);
    final already = await service.hasUserVerifiedPrice(priceId, user.uid);
    if (already) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bu fiyati zaten degerlendirdiniz'), behavior: SnackBarBehavior.floating),
        );
      }
      return;
    }

    await service.verifyPrice(priceId, user.uid, isVerified);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isVerified ? 'Fiyat dogrulandi (+5 puan)' : 'Fiyat reddedildi (+5 puan)'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isVerified ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  void _showReportPriceDialog(PriceModel price) {
    final reasons = ['Yanlis fiyat', 'Yanlis magaza', 'Sahte giriş', 'Diger'];
    String? selectedReason;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
          title: const Row(children: [
            Icon(Icons.flag_outlined, color: AppColors.error, size: 22),
            SizedBox(width: 8),
            Text('Fiyati Raporla'),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: reasons.map((r) => RadioListTile<String>(
              title: Text(r, style: const TextStyle(fontSize: 14)),
              value: r,
              groupValue: selectedReason,
              activeColor: AppColors.primary,
              onChanged: (val) => setDialogState(() => selectedReason = val),
            )).toList(),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Iptal')),
            ElevatedButton(
              onPressed: selectedReason == null ? null : () async {
                final user = ref.read(userModelStreamProvider).valueOrNull;
                if (user != null) {
                  await ref.read(firestoreServiceProvider).reportPrice(price.id, user.uid, selectedReason!);
                }
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Rapor gonderildi'), behavior: SnackBarBehavior.floating),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Raporla', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showReportCommentDialog(CommentModel comment) {
    final reasons = ['Uygunsuz icerik', 'Spam', 'Kufur/hakaret', 'Diger'];
    String? selectedReason;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
          title: const Row(children: [
            Icon(Icons.flag_outlined, color: AppColors.error, size: 22),
            SizedBox(width: 8),
            Text('Yorumu Raporla'),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: reasons.map((r) => RadioListTile<String>(
              title: Text(r, style: const TextStyle(fontSize: 14)),
              value: r,
              groupValue: selectedReason,
              activeColor: AppColors.primary,
              onChanged: (val) => setDialogState(() => selectedReason = val),
            )).toList(),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Iptal')),
            ElevatedButton(
              onPressed: selectedReason == null ? null : () async {
                final user = ref.read(userModelStreamProvider).valueOrNull;
                if (user != null) {
                  await ref.read(firestoreServiceProvider).reportComment(comment.id, user.uid, selectedReason!);
                }
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Rapor gonderildi'), behavior: SnackBarBehavior.floating),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Raporla', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifyButton({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
      ),
    );
  }

  Widget _buildCommentsSection(BuildContext context, List<CommentModel> comments) {
    return Column(
      children: [
        if (comments.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.comment_outlined,
                      size: 48, color: AppColors.textTertiary),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    'Henuz yorum yok',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          )
        else
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
                          child: comment.userPhotoUrl != null
                              ? ClipOval(
                                  child: Image.network(
                                    comment.userPhotoUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Center(
                                      child: Text(
                                        comment.userName.isNotEmpty ? comment.userName[0] : 'A',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    comment.userName.isNotEmpty ? comment.userName[0] : 'A',
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
                                comment.userName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                _formatTimeAgo(comment.createdAt),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _showReportCommentDialog(comment),
                          child: const Icon(Icons.flag_outlined,
                              size: 16, color: AppColors.textTertiary),
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
            onPressed: () => _showAddCommentDialog(context),
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

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} dakika once';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} saat once';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gun once';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

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
