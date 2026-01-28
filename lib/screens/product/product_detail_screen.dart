import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/product_provider.dart';
import '../../providers/price_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/product_model.dart';
import '../../models/price_model.dart';
import '../../models/comment_model.dart';
import '../../widgets/photo_gallery.dart';
import '../../widgets/comment_widget.dart';
import '../../utils/theme.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  final currencyFormat = NumberFormat.currency(
    locale: 'tr_TR',
    symbol: '₺',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    // Increment view count
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(productNotifierProvider.notifier)
          .incrementViewCount(widget.productId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productProvider(widget.productId));
    final pricesAsync = ref.watch(pricesForProductProvider(widget.productId));
    final isSaved = ref.watch(isProductSavedProvider(widget.productId));
    final currentUser = ref.watch(authStateProvider);

    return Scaffold(
      body: productAsync.when(
        data: (product) {
          if (product == null) {
            return const Center(child: Text('Ürün bulunamadı'));
          }
          return _buildContent(
            context,
            product,
            pricesAsync,
            isSaved,
            currentUser.value?.uid,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Hata: $error')),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ProductModel product,
    AsyncValue<List<PriceModel>> pricesAsync,
    bool isSaved,
    String? currentUserId,
  ) {
    return CustomScrollView(
      slivers: [
        // App Bar with Image
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: product.mainImage != null
                ? Hero(
                    tag: 'product_${product.id}',
                    child: CachedNetworkImage(
                      imageUrl: product.mainImage!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        child: const Icon(Icons.image, size: 64),
                      ),
                    ),
                  )
                : Container(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.image, size: 64),
                  ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                isSaved ? Icons.bookmark : Icons.bookmark_border,
                color: isSaved ? AppColors.accent : null,
              ),
              onPressed: () {
                ref
                    .read(userNotifierProvider.notifier)
                    .toggleSavedProduct(product.id);
              },
            ),
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                // Share functionality
              },
            ),
          ],
        ),

        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brand & Name
                Text(
                  product.brand.toUpperCase(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  product.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Latest Price
                if (product.lastPrice != null)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Son Fiyat',
                                style: TextStyle(fontSize: 12),
                              ),
                              Text(
                                currencyFormat.format(product.lastPrice),
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
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
                                'Mağaza',
                                style: TextStyle(fontSize: 12),
                              ),
                              Text(
                                product.lastStore!,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),

                // Stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      context,
                      icon: Icons.price_change,
                      value: '${product.priceEntryCount}',
                      label: 'Fiyat Girişi',
                    ),
                    _buildStatItem(
                      context,
                      icon: Icons.visibility,
                      value: '${product.viewCount}',
                      label: 'Görüntülenme',
                    ),
                    if (product.isTrending)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: const Row(
                          children: [
                            Text('🔥', style: TextStyle(fontSize: 16)),
                            SizedBox(width: 4),
                            Text(
                              'Trend',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
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

                // Price History
                Text(
                  'Fiyat Geçmişi',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppSpacing.md),

                pricesAsync.when(
                  data: (prices) => _buildPriceList(
                    context,
                    prices,
                    currentUserId,
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Text('Fiyatlar yüklenemedi'),
                ),

                const SizedBox(height: AppSpacing.lg),
                const Divider(),
                const SizedBox(height: AppSpacing.md),

                // Comments Section
                Text(
                  'Yorumlar',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppSpacing.md),

                _buildCommentsSection(context, currentUserId),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceList(
    BuildContext context,
    List<PriceModel> prices,
    String? currentUserId,
  ) {
    if (prices.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.price_change_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Henüz fiyat girişi yok',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: prices.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final price = prices[index];
        return _buildPriceCard(context, price, currentUserId);
      },
    );
  }

  Widget _buildPriceCard(
    BuildContext context,
    PriceModel price,
    String? currentUserId,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currencyFormat.format(price.price),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      price.storeName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (price.storeLocation != null)
                      Text(
                        price.storeLocation!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    Text(
                      timeago.format(price.createdAt, locale: 'tr'),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              // Verification buttons
              Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.thumb_up_outlined),
                        color: AppColors.success,
                        onPressed: currentUserId != null &&
                                currentUserId != price.userId
                            ? () {
                                ref
                                    .read(priceNotifierProvider.notifier)
                                    .verifyPrice(price.id, true);
                              }
                            : null,
                      ),
                      Text(
                        '${price.verifiedCount}',
                        style: const TextStyle(color: AppColors.success),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.thumb_down_outlined),
                        color: AppColors.error,
                        onPressed: currentUserId != null &&
                                currentUserId != price.userId
                            ? () {
                                ref
                                    .read(priceNotifierProvider.notifier)
                                    .verifyPrice(price.id, false);
                              }
                            : null,
                      ),
                      Text(
                        '${price.unverifiedCount}',
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          if (price.images.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            PhotoGallery(images: price.images),
          ],
          if (price.verificationRate > 0)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: LinearProgressIndicator(
                value: price.verificationRate / 100,
                backgroundColor: AppColors.error.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation(AppColors.success),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection(BuildContext context, String? currentUserId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('comments')
          .where('productId', isEqualTo: widget.productId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Yorumlar yüklenemedi: ${snapshot.error}');
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final comments = snapshot.data!.docs
            .map((doc) => CommentModel.fromFirestore(doc))
            .toList();

        return Column(
          children: [
            // Comment Input
            CommentInput(
              onSubmit: (text) async {
                if (currentUserId == null) return;

                final userDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUserId)
                    .get();

                final comment = CommentModel(
                  id: '',
                  productId: widget.productId,
                  userId: currentUserId,
                  userName: userDoc.data()?['name'] ?? 'Anonim',
                  userPhotoUrl: userDoc.data()?['photoUrl'],
                  text: text,
                  createdAt: DateTime.now(),
                );

                await FirebaseFirestore.instance
                    .collection('comments')
                    .add(comment.toFirestore());
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // Comments List
            if (comments.isEmpty)
              Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 48,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Henüz yorum yok',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  return CommentCard(
                    comment: comments[index],
                    currentUserId: currentUserId,
                    onLike: () async {
                      if (currentUserId == null) return;
                      final commentRef = FirebaseFirestore.instance
                          .collection('comments')
                          .doc(comments[index].id);

                      final likedBy =
                          List<String>.from(comments[index].likedBy);
                      if (likedBy.contains(currentUserId)) {
                        likedBy.remove(currentUserId);
                      } else {
                        likedBy.add(currentUserId);
                      }

                      await commentRef.update({
                        'likedBy': likedBy,
                        'likes': likedBy.length,
                      });
                    },
                  );
                },
              ),
          ],
        );
      },
    );
  }
}
