import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shimmer/shimmer.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/theme.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/product_model.dart';
import '../../models/comment_model.dart';
import '../../models/price_model.dart';
import '../../models/store_model.dart';
import '../../services/location_service.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/app_network_image.dart';
import '../../widgets/app_section_header.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;
  final String? highlightedCommentId;
  final String? highlightedPriceId;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    this.highlightedCommentId,
    this.highlightedPriceId,
  });

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  final _commentController = TextEditingController();
  bool _isSubmittingComment = false;
  bool _viewCounted = false;
  double? _userLat;
  double? _userLng;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_viewCounted) {
        _viewCounted = true;
        ref.read(firestoreServiceProvider).incrementViewCount(widget.productId);
      }
    });
    _loadUserLocation();
  }

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
      final isAdmin = userModel.isAdmin || userModel.role == 'admin';
      final comment = CommentModel(
        id: '',
        productId: widget.productId,
        userId: userModel.uid,
        userName: userModel.name,
        userPhotoUrl: userModel.photoUrl,
        authorRole: isAdmin ? 'admin' : 'user',
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

  Future<void> _loadUserLocation() async {
    final position = await LocationService().getCurrentPosition();
    if (!mounted) return;
    setState(() {
      _userLat = position?.latitude;
      _userLng = position?.longitude;
    });
  }

  _BranchStoreData? _resolveBranchStoreData(
    List<PriceModel>? priceHistory,
    List<StoreModel> stores,
  ) {
    if (priceHistory == null || priceHistory.isEmpty) {
      return null;
    }

    final latestPrice = priceHistory.first;
    if (latestPrice.branchStoreId.isEmpty) {
      return _BranchStoreData(
        branchStoreId: '',
        chainId: latestPrice.chainId,
        displayName: latestPrice.storeName,
      );
    }

    StoreModel? matched;
    for (final store in stores) {
      if (store.id == latestPrice.branchStoreId) {
        matched = store;
        break;
      }
    }

    if (matched == null) {
      return _BranchStoreData(
        branchStoreId: latestPrice.branchStoreId,
        chainId: latestPrice.chainId,
        displayName: latestPrice.storeName,
      );
    }

    return _BranchStoreData(
      branchStoreId: matched.id,
      chainId: matched.brandId ?? latestPrice.chainId,
      displayName: matched.displayName,
      neighborhood: matched.neighborhood,
      district: matched.district,
      city: matched.city,
      lat: matched.lat,
      lng: matched.lng,
      isOnline: matched.isOnline,
    );
  }

  bool _isWithinNearbyRange(_BranchStoreData branchStore) {
    if (_userLat == null || _userLng == null) return false;

    final distance = Geolocator.distanceBetween(
      _userLat!,
      _userLng!,
      branchStore.lat!,
      branchStore.lng!,
    );

    return distance <= 30;
  }

  Future<void> _onStoreChipTap(_BranchStoreData? branchStore) async {
    if (branchStore == null) {
      return;
    }

    Uri? mapsUri;
    if (branchStore.hasCoordinates) {
      final destination = '${branchStore.lat},${branchStore.lng}';
      final query = Uri.encodeComponent(branchStore.displayName ?? 'Mağaza');
      mapsUri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$destination&destination_place_id=&query=$query&travelmode=driving',
      );
    } else if (branchStore.hasMapsQuery) {
      final encodedStoreQuery = Uri.encodeComponent(branchStore.mapsQuery);
      mapsUri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$encodedStoreQuery',
      );
    }

    if (mapsUri == null) return;

    final launched = await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Harita acilamadi'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      );
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

  void _showPriceAlertSheet(BuildContext context) {
    final userModel = ref.read(userModelStreamProvider).value;
    if (userModel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Fiyat alarmi icin giris yapmalisiniz'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
        ),
      );
      return;
    }

    final followedRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userModel.uid)
        .collection('followedProducts')
        .doc(widget.productId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) {
        return FutureBuilder<DocumentSnapshot>(
          future: followedRef.get(),
          builder: (ctx, snapshot) {
            final data = snapshot.data?.data() as Map<String, dynamic>?;
            bool priceDropEnabled = data?['notifyOnPriceDrop'] ?? false;
            bool newPriceEnabled = data?['notifyOnNewPrice'] ?? false;

            return StatefulBuilder(
              builder: (ctx, setSheetState) {
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
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.outlineVariant,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Fiyat Alarmi',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Bu urun icin bildirim tercihlerinizi secin',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Fiyat dusunce bildir', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: const Text('Fiyat dususe gectiginde bildirim al', style: TextStyle(fontSize: 12)),
                        value: priceDropEnabled,
                        activeColor: AppColors.primary,
                        onChanged: (val) => setSheetState(() => priceDropEnabled = val),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Yeni fiyat eklenince bildir', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: const Text('Yeni bir fiyat girisi yapildiginda bildirim al', style: TextStyle(fontSize: 12)),
                        value: newPriceEnabled,
                        activeColor: AppColors.primary,
                        onChanged: (val) => setSheetState(() => newPriceEnabled = val),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            if (!priceDropEnabled && !newPriceEnabled) {
                              await followedRef.delete();
                            } else {
                              await followedRef.set({
                                'notifyOnPriceDrop': priceDropEnabled,
                                'notifyOnNewPrice': newPriceEnabled,
                                'createdAt': FieldValue.serverTimestamp(),
                              });
                            }
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    priceDropEnabled || newPriceEnabled ? 'Fiyat alarmi kaydedildi' : 'Fiyat alarmi kaldirildi',
                                  ),
                                  backgroundColor: AppColors.success,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
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
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                        child: const Text(
                          'Kaydet',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productByIdProvider(widget.productId));
    final commentsAsync = ref.watch(productCommentsProvider(widget.productId));
    final priceHistoryAsync = ref.watch(productPriceHistoryProvider(widget.productId));
    final storesAsync = ref.watch(allStoresStreamProvider);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final isFavoriteAsync = uid == null ? const AsyncValue.data(false) : ref.watch(StreamProvider<bool>((ref) => ref.read(firestoreServiceProvider).isFavoriteStream(uid: uid, productId: widget.productId)));

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
        if (uid != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(firestoreServiceProvider).addRecentlyViewed(uid: uid, product: product);
          });
        }
        final priceHistory = priceHistoryAsync.valueOrNull;
        final stores = storesAsync.valueOrNull ?? const <StoreModel>[];
        final branchStore = _resolveBranchStoreData(priceHistory, stores);
        final isNearbyStore = branchStore != null && branchStore.hasCoordinates && _isWithinNearbyRange(branchStore);

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // ---------- App Bar with premium hero image ----------
              SliverAppBar(
                expandedHeight: 320,
                pinned: true,
                backgroundColor: AppColors.surface,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildProductHeroImage(product),
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x55000000), Colors.transparent, Color(0x45000000)],
                          ),
                        ),
                      ),
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 8,
                        right: 8,
                        child: Row(
                          children: [
                            _buildHeroAction(
                              icon: (isFavoriteAsync.valueOrNull ?? false) ? Icons.favorite : Icons.favorite_border,
                              active: (isFavoriteAsync.valueOrNull ?? false),
                              onTap: uid == null
                                  ? null
                                  : () async {
                                      await ref.read(firestoreServiceProvider).toggleFavorite(
                                            uid: uid,
                                            productId: widget.productId,
                                            payload: {'productId': product.id, 'productName': product.name, 'imageUrl': product.mainImage},
                                          );
                                    },
                            ),
                            const SizedBox(width: 8),
                            _buildHeroAction(
                              icon: Icons.share,
                              onTap: () => _shareProduct(product),
                            ),
                            const SizedBox(width: 8),
                            _buildHeroAction(
                              icon: Icons.flag_outlined,
                              onTap: () {
                                final latest = priceHistoryAsync.valueOrNull;
                                if (latest != null && latest.isNotEmpty) {
                                  _showReportPriceDialog(latest.first);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ---------- Content ----------
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (product.brand.isNotEmpty) _buildMetaChip(product.brand, categoryColor),
                          if (product.category.isNotEmpty) _buildMetaChip(product.category, categoryColor),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildMiniStatRow(priceHistory ?? const []),
                      const SizedBox(height: AppSpacing.md),

                      // Price card
                      _buildPriceCard(
                        product,
                        branchStore: branchStore,
                        showNearbyGlow: isNearbyStore,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      // Legal disclaimer
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, size: 13, color: AppColors.textTertiary.withOpacity(0.7)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                AppConstants.priceDisclaimer,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textTertiary.withOpacity(0.7),
                                  height: 1.4,
                                ),
                              ),
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

                      if (widget.highlightedPriceId != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColors.info.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: AppColors.info.withOpacity(0.4)),
                          ),
                          child: Text(
                            'Raporlanan fiyat kaydı odaklandi: ${widget.highlightedPriceId}',
                            style: const TextStyle(fontSize: 12, color: AppColors.info),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      _buildSectionCard(
                        title: 'Fiyat Gecmisi',
                        trailing: 'Son 30 gün',
                        child: priceHistoryAsync.when(
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
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _buildCheapestStoresSection(priceHistory ?? const []),
                      const SizedBox(height: AppSpacing.lg),
                      const AppSectionHeader(
                        title: 'Topluluk Dogrulamasi',
                        subtitle: 'Son fiyatin guven durumunu degerlendirin',
                      ),
                      const SizedBox(height: AppSpacing.md),

                      priceHistoryAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Text('Hata: $e'),
                        data: (prices) => _buildVerificationSection(prices),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      const SizedBox(height: AppSpacing.lg),
                      const AppSectionHeader(
                        title: 'Yorumlar',
                        subtitle: 'Toplulugun urun hakkindaki gorusleri',
                      ),
                      const SizedBox(height: AppSpacing.md),

                      commentsAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Text('Hata: $e'),
                        data: (comments) => _buildCommentsSection(
                          context,
                          comments,
                          highlightedCommentId: widget.highlightedCommentId,
                        ),
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


  Widget _buildMetaChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildMiniStatRow(List<PriceModel> prices) {
    final values = prices.map((p) => p.price).toList();
    final latest = values.isNotEmpty ? values.first : null;
    final cheapest = values.isNotEmpty ? values.reduce((a, b) => a < b ? a : b) : null;
    final average = values.isNotEmpty ? values.reduce((a, b) => a + b) / values.length : null;

    return Row(
      children: [
        Expanded(child: _buildMiniStatBox('Son Fiyat', latest)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: _buildMiniStatBox('En ucuz', cheapest)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: _buildMiniStatBox('Ortalama', average)),
      ],
    );
  }

  Widget _buildMiniStatBox(String title, double? value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value == null ? '-' : formatTRY(value), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, String? trailing, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.65)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
              if (trailing != null)
                Text(trailing, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
            ],
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            height: 1,
            color: AppColors.outlineVariant.withOpacity(0.45),
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildCheapestStoresSection(List<PriceModel> prices) {
    final sorted = [...prices]..sort((a, b) => a.price.compareTo(b.price));
    final cheapest = sorted.take(3).toList();

    return _buildSectionCard(
      title: 'En ucuz mağazalar',
      child: cheapest.isEmpty
          ? const Text('Henüz mağaza fiyatı yok')
          : Column(
              children: cheapest
                  .map(
                    (price) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  price.storeName?.trim().isNotEmpty == true ? price.storeName!.trim() : 'Mağaza',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatPrice(price.price),
                                style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              Text('Ekleyen: ${(price.addedByDisplayName ?? price.userName ?? 'Anonim').trim()}', style: Theme.of(context).textTheme.bodySmall),
                              if (price.addedByLevelSnapshot?.isNotEmpty == true)
                                Chip(label: Text(price.addedByLevelSnapshot!), visualDensity: VisualDensity.compact),
                              Chip(label: Text('Güven: %${price.addedByTrustScoreSnapshot.round()}'), visualDensity: VisualDensity.compact),
                              if (price.addedByVerifiedBadge) const Icon(Icons.verified_rounded, size: 16, color: Colors.blue),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  Widget _buildPriceCard(
    ProductModel product, {
    required _BranchStoreData? branchStore,
    required bool showNearbyGlow,
  }) {
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
          if (branchStore?.displayName != null && branchStore!.displayName!.isNotEmpty)
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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        onTap: (branchStore.hasMapsQuery || branchStore.hasCoordinates)
                            ? () => _onStoreChipTap(branchStore)
                            : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            border: Border.all(color: AppColors.outline),
                            boxShadow: showNearbyGlow
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.35),
                                      blurRadius: 18,
                                      spreadRadius: 1,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Opacity(
                            opacity: (branchStore.hasMapsQuery || branchStore.hasCoordinates) ? 1 : 0.7,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.storefront, size: 16, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  branchStore!.displayName!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                if (branchStore.hasMapsQuery || branchStore.hasCoordinates) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.map_outlined, size: 14, color: AppColors.primary),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (showNearbyGlow) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(color: AppColors.primary.withOpacity(0.25)),
                        ),
                        child: const Text(
                          'Buradasın',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildHeroAction({required IconData icon, VoidCallback? onTap, bool active = false}) {
    return Material(
      color: Colors.black.withOpacity(0.25),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: active ? AppColors.primaryLight : Colors.white),
        ),
      ),
    );
  }

  Widget _buildProductHeroImage(ProductModel product) {
    final imageUrl = _resolveProductImageUrl(product);
    if (imageUrl == null || imageUrl.isEmpty) {
      return _buildPremiumImagePlaceholder(product.name);
    }

    return SizedBox.expand(
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.contain,
        placeholder: (_, __) => Shimmer.fromColors(
          baseColor: AppColors.surfaceVariant,
          highlightColor: AppColors.surface,
          child: Container(color: AppColors.surfaceVariant),
        ),
        errorWidget: (_, __, ___) => _buildPremiumImagePlaceholder(product.name),
      ),
    );
  }

  String? _resolveProductImageUrl(ProductModel product) {
    if ((product.mainImage ?? '').trim().isNotEmpty) return product.mainImage!.trim();
    if (product.imageUrls.isNotEmpty) {
      return product.imageUrls.firstWhere(
        (url) => url.trim().isNotEmpty,
        orElse: () => '',
      );
    }
    return null;
  }

  Widget _buildPremiumImagePlaceholder(String productName) {
    final initial = productName.isNotEmpty ? productName[0].toUpperCase() : '?';
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary.withOpacity(0.22), AppColors.secondary.withOpacity(0.18)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(initial, style: const TextStyle(fontSize: 92, fontWeight: FontWeight.w800, color: Colors.white70)),
            const SizedBox(height: 8),
            const Text('Görsel bulunamadı', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
          ],
        ),
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
                          message: '${price.storeName}\n${_formatPrice(price.price)}'
                            '${price.isTrustedPrice ? '\nGuvenilir Fiyat' : ''}',
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
                  await ref.read(firestoreServiceProvider).reportPrice(
                        priceId: price.id,
                        userId: user.uid,
                        reason: selectedReason!,
                        contextId: widget.productId,
                      );
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
                  await ref.read(firestoreServiceProvider).reportComment(
                        commentId: comment.id,
                        userId: user.uid,
                        reason: selectedReason!,
                        contextId: comment.productId,
                      );
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

  Widget _buildCommentsSection(
    BuildContext context,
    List<CommentModel> comments, {
    String? highlightedCommentId,
  }) {
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
          ...comments.map((comment) {
            final isHighlighted = highlightedCommentId != null && comment.id == highlightedCommentId;
            return Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: isHighlighted ? AppColors.primary.withOpacity(0.06) : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: isHighlighted ? AppColors.primary : AppColors.outline,
                    width: isHighlighted ? 1.5 : 1,
                  ),
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
                              Row(
                                children: [
                                  Text(
                                    comment.userName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (comment.authorRole == 'admin') ...[
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.verified,
                                      size: 14,
                                      color: Colors.blue,
                                    ),
                                  ],
                                ],
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
              );
          }),

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

  void _shareProduct(ProductModel product) {
    final productName = product.name.trim().isEmpty ? 'Ürün' : product.name.trim();
    final currentPrice = product.lastPrice != null ? formatTRY(product.lastPrice!) : 'Fiyat yok';
    final store = (product.lastStore ?? '').trim().isNotEmpty ? product.lastStore!.trim() : 'Mağaza bilinmiyor';
    final message = '$productName\n'
        'Güncel fiyat: $currentPrice\n'
        'Mağaza: $store\n'
        'FiyatRadar';

    Share.share(message);
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

  String _formatPrice(double price) => formatTRY(price);

  String _formatPriceShort(double price) => formatTRY(price);

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

class _BranchStoreData {
  final String branchStoreId;
  final String? chainId;
  final String? displayName;
  final String? neighborhood;
  final String? district;
  final String? city;
  final double? lat;
  final double? lng;
  final bool isOnline;

  const _BranchStoreData({
    required this.branchStoreId,
    this.chainId,
    this.displayName,
    this.neighborhood,
    this.district,
    this.city,
    this.lat,
    this.lng,
    this.isOnline = false,
  });

  bool get hasCoordinates =>
      lat != null &&
      lng != null &&
      lat != 0 &&
      lng != 0;

  String get mapsQuery {
    if (isOnline) return '';

    final queryParts = [displayName, neighborhood, district, city]
        .where((part) => part != null && part!.trim().isNotEmpty)
        .map((part) => part!.trim())
        .toList();

    return queryParts.join(' ');
  }

  bool get hasMapsQuery => mapsQuery.isNotEmpty;
}
