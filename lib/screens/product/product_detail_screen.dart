import 'dart:async';

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
import '../../services/firestore_service.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../utils/level_system.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/app_network_image.dart';
import '../../widgets/app_section_header.dart';
import '../../widgets/verify_action_button.dart';

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
  final ValueNotifier<int> _verifySuccessSignal = ValueNotifier<int>(0);
  final ValueNotifier<int> _rejectSuccessSignal = ValueNotifier<int>(0);
  bool _isSubmittingVerification = false;
  String? _activeVerificationPriceId;
  int? _localVerifyUpCount;
  int? _localVerifyDownCount;
  Timer? _contributorPopupTimer;
  String? _activeContributorPopupPriceId;

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
    _contributorPopupTimer?.cancel();
    _commentController.dispose();
    _verifySuccessSignal.dispose();
    _rejectSuccessSignal.dispose();
    super.dispose();
  }

  void _showContributorInfoPopup(String priceId) {
    _contributorPopupTimer?.cancel();
    setState(() {
      _activeContributorPopupPriceId = priceId;
    });

    _contributorPopupTimer = Timer(const Duration(seconds: 7), () {
      if (!mounted || _activeContributorPopupPriceId != priceId) {
        return;
      }
      setState(() {
        _activeContributorPopupPriceId = null;
      });
    });
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
    final isFavoriteAsync = ref.watch(isFavoriteProvider(widget.productId));
    final favoriteOverride = ref.watch(favoriteOverrideProvider(widget.productId));
    final isFavorite = favoriteOverride ?? (isFavoriteAsync.valueOrNull ?? false);

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
                              icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                              active: isFavorite,
                              onTap: uid == null
                                  ? null
                                  : () async {
                                      final previous = isFavorite;
                                      final next = !previous;
                                      ref.read(favoriteOverrideProvider(widget.productId).notifier).state = next;
                                      try {
                                        await ref.read(firestoreServiceProvider).toggleFavorite(
                                              uid: uid,
                                              productId: widget.productId,
                                              payload: {
                                                'productId': product.id,
                                                'productName': product.name,
                                                'imageUrl': product.effectiveImage,
                                              },
                                            );
                                        ref.read(favoriteOverrideProvider(widget.productId).notifier).state = null;
                                      } catch (_) {
                                        ref.read(favoriteOverrideProvider(widget.productId).notifier).state = previous;
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Favoriler güncellenemedi. Tekrar dene.')),
                                          );
                                        }
                                      }
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
                        latestPrice: (priceHistory != null && priceHistory.isNotEmpty) ? priceHistory.first : null,
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
                                '${AppConstants.priceDisclaimer}\nGörseller temsilidir. Marka sahipleri ile resmi bağlantı bulunmaz.',
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
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () => _showReportPriceDialog(prices.first),
                                      icon: const Icon(Icons.flag_outlined, size: 16, color: AppColors.textTertiary),
                                      label: const Text('Fiyati Raporla', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                                    ),
                                    TextButton.icon(
                                      onPressed: () => _tryDeletePrice(prices.first),
                                      icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                                      label: const Text('Fiyatı Sil', style: TextStyle(fontSize: 12, color: AppColors.error)),
                                    ),
                                  ],
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.7)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
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


  Color _trustChipColor(String tierName, int trustPercent) {
    final level = levelFromLabel(tierName);
    return level.badgeForeground;
  }

  Widget _buildTrustBadge({
    required String displayName,
    required String tierName,
    required int trustPercent,
    int? upTotal,
    int? downTotal,
  }) {
    final level = levelFromLabel(tierName);
    final chipColor = _trustChipColor(tierName, trustPercent);
    final total = (upTotal ?? 0) + (downTotal ?? 0);
    final verificationRate = total == 0 ? null : ((upTotal ?? 0) / total * 100).round();

    return InkWell(
      onTap: () => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (_) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(displayName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Text('Güven Skoru: %$trustPercent', style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text('Seviye: ${level.label}', style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(verificationRate == null ? 'Doğrulama oranı: Veri yok' : 'Doğrulama oranı: %$verificationRate'),
            ],
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: level.badgeBackground,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: level.badgeBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(level.emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 4),
            Text(
              '%$trustPercent',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: chipColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceContributor(PriceModel price) {
    final uid = (price.createdByUid ?? price.userId).trim();
    return StreamBuilder<Map<String, dynamic>>(
      stream: ref.read(firestoreServiceProvider).streamUserTrustProfile(uid),
      builder: (context, snapshot) {
        final fallbackTier = (price.addedByLevelSnapshot ?? 'Standart').trim();
        final fallbackScore = price.addedByTrustScoreSnapshot.round().clamp(0, 100);
        final data = snapshot.data ?? {
          'displayName': price.addedByDisplayName ?? 'Kullanıcı',
          'trustScorePercent': fallbackScore,
          'tierName': fallbackTier.isEmpty ? 'Standart' : fallbackTier,
        };
        final displayName = (data['displayName'] ?? 'Kullanıcı').toString().trim();
        final trustPercent = (data['trustScorePercent'] as num?)?.toInt() ?? 0;
        final tierName = (data['tierName'] ?? 'Standart').toString();
        final level = levelFromLabel(tierName);
        final contributor = displayName.isEmpty ? 'Kullanıcı' : displayName;
        final contributorWithBadge = '${level.emoji} $contributor';

        return Wrap(
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Ekleyen: $contributorWithBadge', style: Theme.of(context).textTheme.bodySmall),
            _buildTrustBadge(
              displayName: contributor,
              tierName: tierName,
              trustPercent: trustPercent,
              upTotal: (data['upTotal'] as num?)?.toInt(),
              downTotal: (data['downTotal'] as num?)?.toInt(),
            ),
          ],
        );
      },
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
                                  _displayPriceSourceName(price),
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
                              _buildPriceContributor(price),
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
    required PriceModel? latestPrice,
    required _BranchStoreData? branchStore,
    required bool showNearbyGlow,
  }) {
    final storeName = branchStore?.displayName?.trim();
    final hasStore = storeName != null && storeName.isNotEmpty;
    final storeClickable = hasStore && (branchStore!.hasMapsQuery || branchStore.hasCoordinates);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF8EFE2),
              Color(0xFFF3E2CF),
            ],
          ),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: const Color(0xFFE1D0BD)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFB78A5A).withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
      child: Container(
        margin: const EdgeInsets.all(1),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFDF8F2),
                Color(0xFFF6EADC),
              ],
            ),
            borderRadius: BorderRadius.circular(AppRadius.xs),
            border: Border.all(color: const Color(0xFFE9D7C4)),
          ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Son Fiyat',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Text(
                product.lastPrice != null ? _formatPrice(product.lastPrice!) : 'Fiyat yok',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  color: Color(0xFFB15C13),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Mağaza',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: storeClickable ? () => _onStoreChipTap(branchStore) : null,
                  child: Ink(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE8DED3)),
                      boxShadow: showNearbyGlow
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.16),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.035),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.storefront_outlined, size: 18, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            hasStore ? storeName : 'Mağaza bilinmiyor',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (storeClickable) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textSecondary),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (showNearbyGlow) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(color: AppColors.primary.withOpacity(0.24)),
                ),
                child: const Text(
                  'Buradasın',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
            if (latestPrice != null) ...[
              const SizedBox(height: 16),
              Center(
                child: _buildLastPriceContributorRow(latestPrice),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLastPriceContributorRow(PriceModel price) {
    final uid = (price.createdByUid ?? price.userId).trim();
    return StreamBuilder<Map<String, dynamic>>(
      stream: ref.read(firestoreServiceProvider).streamUserTrustProfile(uid),
      builder: (context, snapshot) {
        final fallbackTier = (price.addedByLevelSnapshot ?? 'Standart').trim();
        final fallbackScore = price.addedByTrustScoreSnapshot.round().clamp(0, 100);
        final data = snapshot.data ?? {
          'displayName': price.addedByDisplayName ?? 'Kullanıcı',
          'trustScorePercent': fallbackScore,
          'tierName': fallbackTier.isEmpty ? 'Standart' : fallbackTier,
        };
        final displayName = (data['displayName'] ?? 'Kullanıcı').toString().trim();
        final tierName = (data['tierName'] ?? 'Standart').toString();

        final contributor = displayName.isEmpty ? 'Kullanıcı' : displayName;
        final level = levelFromLabel(tierName);
        final contributorWithBadge = '${level.emoji} $contributor';
        final trustPercent = (data['trustScorePercent'] as num?)?.toInt() ?? fallbackScore;
        final upTotal = (data['upTotal'] as num?)?.toInt() ?? 0;
        final downTotal = (data['downTotal'] as num?)?.toInt() ?? 0;
        final total = upTotal + downTotal;
        final verificationRate = total == 0 ? null : (upTotal / total * 100).round();
        final showPopup = _activeContributorPopupPriceId == price.id;

        return Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    onTap: () => _showContributorInfoPopup(price.id),
                    child: Ink(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBF3E5),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        border: Border.all(color: const Color(0xFFE8D1B1)),
                      ),
                      child: Text(
                        contributorWithBadge,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: level.badgeForeground,
                        ),
                      ),
                    ),
                  ),
                ),
                if (showPopup) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: level.badgeBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      verificationRate == null
                          ? 'Seviye: ${level.label}\nGüven Skoru: %$trustPercent\nDoğrulama: Veri yok'
                          : 'Seviye: ${level.label}\nGüven Skoru: %$trustPercent\nDoğrulama: %$verificationRate',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        );
      },
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
    if ((product.effectiveImage ?? '').trim().isNotEmpty) return product.effectiveImage!.trim();
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
                          message: '${_displayPriceSourceName(price)}\n${_formatPrice(price.price)}'
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
    final latestPrice = prices.isNotEmpty ? prices.first : null;
    if (latestPrice == null) {
      _activeVerificationPriceId = null;
      _localVerifyUpCount = null;
      _localVerifyDownCount = null;
    } else if (_activeVerificationPriceId != latestPrice.id) {
      _activeVerificationPriceId = latestPrice.id;
      _localVerifyUpCount = null;
      _localVerifyDownCount = null;
    }

    final totalVerified = _localVerifyUpCount ?? latestPrice?.upVotes ?? 0;
    final totalUnverified = _localVerifyDownCount ?? latestPrice?.downVotes ?? 0;
    final total = totalVerified + totalUnverified;
    final verificationRate = total > 0 ? (totalVerified / total) : 0.0;
    final uid = FirebaseAuth.instance.currentUser?.uid;

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
            StreamBuilder<String?>(
              stream: uid == null ? const Stream<String?>.empty() : ref.read(firestoreServiceProvider).streamUserVoteValue(latestPrice.id, uid),
              builder: (context, snapshot) {
                final voteValue = snapshot.data;
                final isLoggedIn = uid != null;
                final hasVoted = voteValue == 'yes' || voteValue == 'no';
                final isButtonsEnabled = isLoggedIn && !_isSubmittingVerification && !hasVoted;
                return Row(
                  children: [
                    Expanded(
                      child: VerifyActionButton(
                        icon: Icons.thumb_up_outlined,
                        successIcon: Icons.thumb_up,
                        label: 'Doğrula',
                        count: totalVerified,
                        color: AppColors.success,
                        isPositive: true,
                        isSelected: voteValue == 'yes',
                        isEnabled: isButtonsEnabled,
                        isLoading: _isSubmittingVerification,
                        successSignal: _verifySuccessSignal,
                        onTap: () => _verifyLatestPrice(latestPrice, true),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: VerifyActionButton(
                        icon: Icons.thumb_down_outlined,
                        successIcon: Icons.thumb_down,
                        label: 'Yanlış',
                        count: totalUnverified,
                        color: AppColors.error,
                        isPositive: false,
                        isSelected: voteValue == 'no',
                        isEnabled: isButtonsEnabled,
                        isLoading: _isSubmittingVerification,
                        successSignal: _rejectSuccessSignal,
                        onTap: () => _verifyLatestPrice(latestPrice, false),
                      ),
                    ),
                  ],
                );
              },
            ),
          if (latestPrice != null)
            StreamBuilder<String?>(
              stream: uid == null ? const Stream<String?>.empty() : ref.read(firestoreServiceProvider).streamUserVoteValue(latestPrice.id, uid),
              builder: (context, snapshot) {
                final hasVoted = snapshot.data == 'yes' || snapshot.data == 'no';
                if (uid == null) {
                  return const Padding(
                    padding: EdgeInsets.only(top: AppSpacing.sm),
                    child: Text('Doğrulamak için giriş yap', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  );
                }
                if (hasVoted) {
                  return const Padding(
                    padding: EdgeInsets.only(top: AppSpacing.sm),
                    child: Chip(
                      label: Text('Oy verdin'),
                      visualDensity: VisualDensity.compact,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          if (latestPrice != null) const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: Stack(
              children: [
                Container(height: 8, width: double.infinity, color: AppColors.error.withOpacity(0.2)),
                FractionallySizedBox(
                  widthFactor: verificationRate,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(color: AppColors.success, borderRadius: BorderRadius.circular(AppRadius.full)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            total > 0 ? '%${(verificationRate * 100).toStringAsFixed(0)} doğrulandı' : 'Henüz doğrulama yapılmadı',
            style: TextStyle(fontSize: 12, color: total > 0 ? AppColors.success : AppColors.textSecondary, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Future<void> _verifyLatestPrice(PriceModel price, bool isVerified) async {
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
    if (_isSubmittingVerification) return;

    setState(() {
      _isSubmittingVerification = true;
    });

    try {
      final ownerUid = (price.createdByUid ?? price.userId).trim();
      final result = await service.voteOnPrice(
        priceId: price.id,
        priceOwnerUid: ownerUid,
        vote: isVerified ? 1 : -1,
        voterUid: user.uid,
      );
      if (result.status == PriceVoteStatus.alreadyVoted) {
        await Future<void>.delayed(const Duration(milliseconds: 600));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Zaten oy verdin'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      if (result.status == PriceVoteStatus.selfVoteBlocked) {
        await Future<void>.delayed(const Duration(milliseconds: 600));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Kendi eklediğin fiyatı doğrulayamazsın.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      if (result.status == PriceVoteStatus.ignored) {
        await Future<void>.delayed(const Duration(milliseconds: 600));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('İşlem başarısız, tekrar dene.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      await Future<void>.delayed(const Duration(milliseconds: 600));

      setState(() {
        _localVerifyUpCount = result.upCount;
        _localVerifyDownCount = result.downCount;
      });

      if (isVerified) {
        _verifySuccessSignal.value++;
      } else {
        _rejectSuccessSignal.value++;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isVerified ? 'Doğruladın +2 puan' : 'Yanlış dedin +2 puan'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isVerified ? AppColors.success : AppColors.error,
        ),
      );
    } catch (e) {
      debugPrint('verifyLatestPrice failed: $e');
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('İşlem başarısız, tekrar dene.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingVerification = false;
        });
      }
    }
  }

  Future<void> _tryDeletePrice(PriceModel price) async {
    final user = ref.read(userModelStreamProvider).valueOrNull;
    if (user == null) return;
    final ownerUid = (price.createdByUid ?? price.userId).trim();
    final canDelete = user.isAdmin || user.role == 'admin' || ownerUid == user.uid;
    if (!canDelete) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bu fiyatı silme yetkiniz yok.')));
      }
      return;
    }
    await ref.read(firestoreServiceProvider).softDeletePrice(priceId: price.id, deletedByUid: user.uid);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fiyat silindi.')));
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
            final isHighlighted =
                highlightedCommentId != null && comment.id == highlightedCommentId;
            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isHighlighted
                    ? AppColors.primary.withOpacity(0.06)
                    : AppColors.surface,
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
                                      comment.userName.isNotEmpty
                                          ? comment.userName[0]
                                          : 'A',
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
                                  comment.userName.isNotEmpty
                                      ? comment.userName[0]
                                      : 'A',
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
    final productName =
        product.name.trim().isEmpty ? 'Ürün' : product.name.trim();
    final currentPrice =
        product.lastPrice != null ? formatTRY(product.lastPrice!) : 'Fiyat yok';
    final store = (product.lastStore ?? '').trim().isNotEmpty
        ? product.lastStore!.trim()
        : 'Mağaza bilinmiyor';
    final message = '$productName\n'
        'Güncel fiyat: $currentPrice\n'
        'Mağaza: $store\n'
        'FiyatRadar';

    Share.share(message);
  }

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

  String _displayPriceSourceName(PriceModel price) {
    final raw = (price.storeName ?? '').trim();
    return raw.isNotEmpty ? raw : 'Mağaza';
  }

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

  bool get hasCoordinates => lat != null && lng != null && lat != 0 && lng != 0;

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
