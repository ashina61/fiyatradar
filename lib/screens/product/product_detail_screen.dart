import 'dart:async';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/price_model.dart';
import '../../models/product_detail_api_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_detail_provider.dart';
import '../../providers/product_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/product_detail_api_service.dart';
import '../../services/product_engagement_service.dart';
import '../../widgets/app_network_image.dart';

const _bg = Color(0xFFFAFAF8);
const _surface = Color(0xFFFFFFFF);
const _surfaceAlt = Color(0xFFF5F3F0);
const _dark = Color(0xFF18100A);
const _dark2 = Color(0xFF2C2418);
const _tan = Color(0xFFBF9470);
const _tanLight = Color(0xFFD4B599);
const _text = Color(0xFF18100A);
const _textMuted = Color(0xFF5E4A38);
const _textSoft = Color(0xFF9E8B78);
const _line = Color(0x1418100A);
const _green = Color(0xFF27A85A);
const _greenBg = Color(0x1A27A85A);
const _red = Color(0xFFE53935);
const _redBg = Color(0x1AE53935);
const _amber = Color(0xFFF59E0B);

TextStyle _t({
  double s = 14,
  FontWeight w = FontWeight.w500,
  Color c = _text,
  double? h,
  double ls = 0,
}) {
  return GoogleFonts.plusJakartaSans(
    fontSize: s,
    fontWeight: w,
    color: c,
    height: h,
    letterSpacing: ls,
  );
}

String _fmt(double value) => '${value.toStringAsFixed(2).replaceAll('.', ',')}₺';

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({
    super.key,
    required this.productId,
    this.highlightedCommentId,
    this.highlightedPriceId,
  });

  final String productId;
  final String? highlightedCommentId;
  final String? highlightedPriceId;

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  final _engagementService = ProductEngagementService();
  final _commentController = TextEditingController();
  final _targetPriceController = TextEditingController();

  int _chartDays = 30;
  bool _notifyOnEveryPrice = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_onFirstFrame());
    });
  }

  Future<void> _onFirstFrame() async {
    try {
      await _engagementService.incrementViewCount(widget.productId);
      if (!mounted) return;
      await ref.read(productDetailProvider(widget.productId).notifier).load();
    } catch (_) {}
  }

  @override
  void dispose() {
    _commentController.dispose();
    _targetPriceController.dispose();
    super.dispose();
  }

  Future<void> _openMap(BestPrice bestPrice) async {
    final api = ref.read(productDetailApiServiceProvider);

    try {
      final nav = await api.resolveStoreNavigation(bestPrice);
      Uri targetUri;

      if (nav?.coordinates != null) {
        final lat = nav!.coordinates!.latitude;
        final lng = nav.coordinates!.longitude;
        targetUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
      } else if ((nav?.mapsUrl ?? '').trim().isNotEmpty) {
        targetUri = Uri.parse(nav!.mapsUrl!.trim());
      } else {
        final query = (nav?.address ?? '').trim().isNotEmpty
            ? nav!.address!.trim()
            : '${bestPrice.store} ${bestPrice.storeLocation}'.trim();
        targetUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}');
      }

      final launched = await launchUrl(targetUri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Harita açılamadı. Lütfen tekrar dene.')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harita açılırken bir hata oluştu.')),
      );
    }
  }

  Future<void> _toggleFavorite(ProductDetailResponse product) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Favorilere eklemek için giriş yapmalısın.')),
      );
      return;
    }

    final override = ref.read(favoriteOverrideProvider(product.id));
    final streamValue = ref.read(isFavoriteProvider(product.id)).valueOrNull ?? false;
    final current = override ?? streamValue;
    final next = !current;

    ref.read(favoriteOverrideProvider(product.id).notifier).state = next;

    try {
      await ref.read(firestoreServiceProvider).toggleFavorite(
            uid: user.uid,
            productId: product.id,
            payload: {
              'productName': product.title,
              'imageUrl': product.imageUrl,
            },
          );
      HapticFeedback.selectionClick();
    } catch (_) {
      ref.read(favoriteOverrideProvider(product.id).notifier).state = current;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Favori işlemi başarısız oldu.')),
      );
    }
  }

  Future<void> _submitComment(ProductDetailNotifier notifier) async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final ok = await notifier.postComment(text);
    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yorum gönderilemedi. Lütfen tekrar dene.')),
      );
      return;
    }

    _commentController.clear();
    FocusScope.of(context).unfocus();
    HapticFeedback.lightImpact();
  }

  Future<void> _vote({
    required ProductDetailNotifier notifier,
    required ProductDetailResponse product,
    required bool isApproved,
    String? priceId,
    String? ownerUid,
  }) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Doğrulama için giriş yapmalısın.')),
      );
      return;
    }

    final targetPriceId = (priceId ?? product.bestPrice.id).trim();
    final targetOwnerUid = (ownerUid ?? product.bestPrice.userId).trim();

    if (targetPriceId.isEmpty) return;
    if (targetOwnerUid.isNotEmpty && targetOwnerUid == user.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kendi fiyatını doğrulayamazsın.')),
      );
      return;
    }

    final result = await notifier.votePrice(priceId: targetPriceId, isApproved: isApproved);
    if (!mounted || result == null) return;

    final messenger = ScaffoldMessenger.of(context);
    switch (result.status) {
      case PriceVoteStatus.newVote:
        messenger.showSnackBar(
          SnackBar(content: Text(isApproved ? 'Fiyat doğru olarak onaylandı.' : 'Fiyat yanlış olarak işaretlendi.')),
        );
        break;
      case PriceVoteStatus.voteChanged:
        messenger.showSnackBar(const SnackBar(content: Text('Doğrulama oyun güncellendi.')));
        break;
      case PriceVoteStatus.alreadyVoted:
        messenger.showSnackBar(const SnackBar(content: Text('Bu fiyata zaten oy verdin.')));
        break;
      case PriceVoteStatus.selfVoteBlocked:
        messenger.showSnackBar(const SnackBar(content: Text('Kendi fiyatını doğrulayamazsın.')));
        break;
      case PriceVoteStatus.ignored:
        messenger.showSnackBar(const SnackBar(content: Text('Doğrulama işlemi tamamlanamadı.')));
        break;
    }
  }

  Future<void> _openAlertSheet(ProductDetailResponse product) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alarm kurmak için giriş yapmalısın.')),
      );
      return;
    }

    _targetPriceController.text = product.bestPrice.price > 0
        ? product.bestPrice.price.toStringAsFixed(2).replaceAll('.', ',')
        : '';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: _textSoft,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Alarm Kur', style: _t(s: 18, w: FontWeight.w800)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _targetPriceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Hedef fiyat (₺)',
                        labelStyle: _t(s: 13, c: _textMuted),
                        filled: true,
                        fillColor: _surfaceAlt,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: _notifyOnEveryPrice,
                      title: Text('Her fiyat değişiminde bildir', style: _t(s: 13, w: FontWeight.w700)),
                      subtitle: Text('Kapalıysa sadece hedef fiyat altı bildirir', style: _t(s: 11, c: _textSoft)),
                      onChanged: (value) {
                        setState(() => _notifyOnEveryPrice = value);
                        setModalState(() {});
                      },
                      activeColor: _tan,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _dark,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () async {
                          final raw = _targetPriceController.text.trim().replaceAll(',', '.');
                          final parsed = double.tryParse(raw);
                          final targetPrice = _notifyOnEveryPrice ? null : parsed;
                          if (!_notifyOnEveryPrice && (targetPrice == null || targetPrice <= 0)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Geçerli bir hedef fiyat gir.')),
                            );
                            return;
                          }

                          await ref.read(firestoreServiceProvider).upsertAlert(
                                productId: product.id,
                                userId: user.uid,
                                targetPrice: targetPrice,
                                notifyOnEveryPrice: _notifyOnEveryPrice,
                              );

                          if (!mounted) return;
                          Navigator.pop(sheetContext);
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(content: Text('Alarm kaydedildi.')),
                          );
                        },
                        child: Text('Alarmı Kaydet', style: _t(s: 14, w: FontWeight.w800, c: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openHistorySheet(ProductDetailResponse product, ProductDetailNotifier notifier) {
    final user = ref.read(authStateProvider).valueOrNull;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.84,
          child: Container(
            decoration: const BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _textSoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('Geçmiş Fiyatlar', style: _t(s: 17, w: FontWeight.w800)),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: product.recentPrices.isEmpty
                        ? Center(
                            child: Text('Geçmiş fiyat kaydı bulunamadı.', style: _t(s: 13, c: _textSoft)),
                          )
                        : ListView.separated(
                            itemCount: product.recentPrices.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final item = product.recentPrices[index];
                              final selfBlocked = user != null && item.userId == user.uid;

                              return Container(
                                decoration: _card(),
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${item.storeName} • ${item.timeAgo}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: _t(s: 12, w: FontWeight.w700),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(_fmt(item.price), style: _t(s: 16, w: FontWeight.w800)),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: selfBlocked
                                                ? null
                                                : () => _vote(
                                                      notifier: notifier,
                                                      product: product,
                                                      isApproved: true,
                                                      priceId: item.priceId,
                                                      ownerUid: item.userId,
                                                    ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: _green,
                                              disabledBackgroundColor: _green.withOpacity(0.35),
                                              padding: const EdgeInsets.symmetric(vertical: 10),
                                            ),
                                            icon: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                                            label: Text('Doğru', style: _t(s: 12, w: FontWeight.w700, c: Colors.white)),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: selfBlocked
                                                ? null
                                                : () => _vote(
                                                      notifier: notifier,
                                                      product: product,
                                                      isApproved: false,
                                                      priceId: item.priceId,
                                                      ownerUid: item.userId,
                                                    ),
                                            style: OutlinedButton.styleFrom(
                                              side: BorderSide(color: _red.withOpacity(0.3)),
                                              padding: const EdgeInsets.symmetric(vertical: 10),
                                            ),
                                            icon: const Icon(Icons.close_rounded, size: 16, color: _red),
                                            label: Text('Yanlış', style: _t(s: 12, w: FontWeight.w700, c: _red)),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (selfBlocked)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          'Kendi fiyatını doğrulama kuralı nedeniyle oy kapalı.',
                                          style: _t(s: 11, w: FontWeight.w600, c: _textSoft),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  BestPrice _toBestPrice(MarketPriceEntry entry) {
    return BestPrice(
      id: entry.priceId,
      userId: entry.userId,
      price: entry.price,
      store: entry.storeName,
      userName: entry.userName,
      userTier: '',
      createdAtLabel: entry.timeAgo,
      storeUrl: entry.storeUrl,
      storeId: entry.storeId,
      storeLocation: entry.storeLocation,
      upVotes: entry.upVotes,
      downVotes: entry.downVotes,
      userTrustScore: 0,
      addedByVerifiedBadge: false,
      createdByVerifiedSnapshot: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productDetailProvider(widget.productId));
    final notifier = ref.read(productDetailProvider(widget.productId).notifier);

    if (state.isLoading) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(child: CircularProgressIndicator(color: _tan)),
      );
    }

    if (state.error != null) {
      return Scaffold(
        backgroundColor: _bg,
        body: Center(child: Text(state.error!, style: _t())),
      );
    }

    final product = state.data!;
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    final isFavoriteFromStream = ref.watch(isFavoriteProvider(product.id)).valueOrNull ?? false;
    final favoriteOverride = ref.watch(favoriteOverrideProvider(product.id));
    final isFavorite = favoriteOverride ?? isFavoriteFromStream;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              automaticallyImplyLeading: false,
              backgroundColor: Colors.transparent,
              toolbarHeight: 72,
              elevation: 0,
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_dark, _dark2],
                  ),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                ),
              ),
              titleSpacing: 10,
              title: Row(
                children: [
                  _HeaderButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.maybePop(context),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Ürün Detayı',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _t(s: 16, w: FontWeight.w800, c: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _HeaderButton(
                    icon: Icons.share_rounded,
                    onTap: () {
                      Share.share(
                        '${product.title} ürününü FiyatRadar\'da incele!\n\nEn Ucuz: ${_fmt(product.bestPrice.price)}\nMarket: ${product.bestPrice.store}',
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  _HeaderButton(
                    icon: isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: isFavorite ? _red : _tanLight,
                    onTap: () => _toggleFavorite(product),
                  ),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _HeroSection(product: product),
                  const SizedBox(height: 12),
                  _LastPriceHero(product: product),
                  const SizedBox(height: 12),
                  _StatsRow(product: product),
                  const SizedBox(height: 12),
                  _VerificationCard(
                    product: product,
                    isSubmitting: state.isSubmittingVote,
                    currentUid: ref.watch(authUidProvider),
                    onCorrect: () => _vote(notifier: notifier, product: product, isApproved: true),
                    onWrong: () => _vote(notifier: notifier, product: product, isApproved: false),
                    onHistoryTap: () => _openHistorySheet(product, notifier),
                  ),
                  const SizedBox(height: 12),
                  _HistoryChartCard(
                    history: state.history,
                    stats: product.stats,
                    selectedDays: _chartDays,
                    onDaysChanged: (days) => setState(() => _chartDays = days),
                  ),
                  const SizedBox(height: 12),
                  _MarketListCard(
                    product: product,
                    onMapTap: (entry) => _openMap(_toBestPrice(entry)),
                  ),
                  const SizedBox(height: 12),
                  _CommentsCard(
                    comments: product.comments,
                    controller: _commentController,
                    isSubmitting: state.isSubmittingComment,
                    onSend: () => _submitComment(notifier),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: keyboardOpen
          ? null
          : _BottomActions(
              onAlertTap: () => _openAlertSheet(product),
              onMapTap: () => _openMap(product.bestPrice),
            ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    required this.onTap,
    this.color = _tanLight,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.product});

  final ProductDetailResponse product;

  @override
  Widget build(BuildContext context) {
    final verifyTotal = product.trust.approveCount + product.trust.rejectCount;
    final category = product.categories.isEmpty ? 'Kategori yok' : product.categories.join(' > ');

    return Container(
      decoration: _card(),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: _surfaceAlt,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _line),
                ),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AppNetworkImage(
                      imageUrl: product.imageUrl,
                      cacheKey: 'product_detail_${product.id}',
                      fit: BoxFit.cover,
                      errorWidget: const Center(
                        child: Icon(Icons.image_not_supported_rounded, color: _textSoft, size: 38),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 10,
                top: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _pill('SON FİYAT', _amber),
                    const SizedBox(height: 6),
                    _pill('$verifyTotal doğrulama', _green),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            product.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: _t(s: 20, w: FontWeight.w800, h: 1.25),
          ),
          const SizedBox(height: 4),
          Text(
            category,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _t(s: 12, w: FontWeight.w600, c: _textSoft),
          ),
          const SizedBox(height: 14),
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: _line)),
            ),
            padding: const EdgeInsets.only(top: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _heroStat('${product.priceEntryCount}', 'Fiyat Girişi'),
                _heroStat('${product.marketPrices.length}', 'Market'),
                _heroStat('${product.comments.length}', 'Yorum'),
                _heroStat('${product.viewCount}', 'Görüntülenme'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: _t(s: 10, w: FontWeight.w800, c: Colors.white, ls: 0.2)),
    );
  }

  Widget _heroStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: _t(s: 16, w: FontWeight.w800, c: _tan)),
        const SizedBox(height: 2),
        Text(label, style: _t(s: 10, w: FontWeight.w600, c: _textSoft)),
      ],
    );
  }
}

class _LastPriceHero extends StatelessWidget {
  const _LastPriceHero({required this.product});

  final ProductDetailResponse product;

  @override
  Widget build(BuildContext context) {
    final base = product.stats.highest <= 0 ? product.bestPrice.price : product.stats.highest;
    final drop = base <= 0 ? 0 : (((base - product.bestPrice.price) / base) * 100).round();
    final market = product.bestPrice.storeLocation.trim().isEmpty
        ? product.bestPrice.store
        : '${product.bestPrice.store} (${product.bestPrice.storeLocation})';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_dark, _dark2],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _tan.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('SON FİYAT KARARI', style: _t(s: 10, w: FontWeight.w700, c: _tanLight, ls: 0.4)),
              ),
              const Spacer(),
              if (drop > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: _green.withOpacity(0.3)),
                  ),
                  child: Text('%$drop daha düşük', style: _t(s: 11, w: FontWeight.w800, c: const Color(0xFF4ADE80))),
                ),
            ],
          ),
          const SizedBox(height: 14),
          RichText(
            text: TextSpan(
              style: _t(s: 50, w: FontWeight.w900, c: Colors.white, h: 0.95),
              children: [
                TextSpan(text: product.bestPrice.price.toStringAsFixed(2).replaceAll('.', ',')),
                TextSpan(text: '₺', style: _t(s: 34, w: FontWeight.w900, c: Colors.white.withOpacity(0.62))),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Divider(color: Colors.white.withOpacity(0.12)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: _tan,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(child: Text('🛒', style: TextStyle(fontSize: 19))),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        market,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _t(s: 13, w: FontWeight.w800, c: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    product.bestPrice.userName.isEmpty ? 'Anonim kullanıcı' : product.bestPrice.userName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _t(s: 12, w: FontWeight.w700, c: Colors.white),
                  ),
                  Text(product.bestPrice.createdAtLabel, style: _t(s: 11, c: Colors.white.withOpacity(0.64))),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.product});

  final ProductDetailResponse product;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _statCard('En Düşük', product.stats.lowest, _green, Icons.keyboard_arrow_down_rounded)),
        const SizedBox(width: 8),
        Expanded(child: _statCard('Ortalama', product.stats.average, _amber, Icons.equalizer_rounded)),
        const SizedBox(width: 8),
        Expanded(child: _statCard('En Yüksek', product.stats.highest, _red, Icons.keyboard_arrow_up_rounded)),
      ],
    );
  }

  Widget _statCard(String label, double value, Color color, IconData icon) {
    return Container(
      decoration: _card(),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Column(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 6),
          Text(_fmt(value), style: _t(s: 13, w: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: _t(s: 9, w: FontWeight.w600, c: _textSoft), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _VerificationCard extends StatelessWidget {
  const _VerificationCard({
    required this.product,
    required this.isSubmitting,
    required this.currentUid,
    required this.onCorrect,
    required this.onWrong,
    required this.onHistoryTap,
  });

  final ProductDetailResponse product;
  final bool isSubmitting;
  final String? currentUid;
  final VoidCallback onCorrect;
  final VoidCallback onWrong;
  final VoidCallback onHistoryTap;

  @override
  Widget build(BuildContext context) {
    final total = product.trust.approveCount + product.trust.rejectCount;
    final correctPercent = total == 0 ? 0 : ((product.trust.approveCount / total) * 100).round();
    final wrongPercent = total == 0 ? 0 : 100 - correctPercent;
    final selfBlocked = currentUid != null && currentUid == product.bestPrice.userId;

    return Container(
      decoration: _card(),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_rounded, size: 19, color: _tan),
              const SizedBox(width: 8),
              Expanded(child: Text('Fiyat Doğrulama', style: _t(s: 15, w: FontWeight.w800))),
              InkWell(
                onTap: onHistoryTap,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _line),
                  ),
                  child: const Icon(Icons.history_rounded, size: 17, color: _textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _counter('${product.trust.approveCount}', 'Doğru ($correctPercent%)', _green, _greenBg)),
              const SizedBox(width: 8),
              Expanded(child: _counter('${product.trust.rejectCount}', 'Yanlış ($wrongPercent%)', _red, _redBg)),
              const SizedBox(width: 8),
              Expanded(child: _counter('$total', 'Toplam', _tan, _surfaceAlt)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: selfBlocked || isSubmitting ? null : onCorrect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    disabledBackgroundColor: _green.withOpacity(0.35),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                  label: Text('Fiyat Doğru', style: _t(s: 12, w: FontWeight.w700, c: Colors.white)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: selfBlocked || isSubmitting ? null : onWrong,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: _red.withOpacity(0.35)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  icon: const Icon(Icons.close_rounded, size: 16, color: _red),
                  label: Text('Fiyat Yanlış', style: _t(s: 12, w: FontWeight.w700, c: _red)),
                ),
              ),
            ],
          ),
          if (selfBlocked)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text('Kendi eklediğin fiyatı doğrulayamazsın.', style: _t(s: 11, w: FontWeight.w600, c: _textSoft)),
            ),
        ],
      ),
    );
  }

  Widget _counter(String value, String label, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(value, style: _t(s: 20, w: FontWeight.w900, c: color)),
          const SizedBox(height: 2),
          Text(label, style: _t(s: 10, w: FontWeight.w600, c: _textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _HistoryChartCard extends StatelessWidget {
  const _HistoryChartCard({
    required this.history,
    required this.stats,
    required this.selectedDays,
    required this.onDaysChanged,
  });

  final List<PriceHistoryPoint> history;
  final PriceStats stats;
  final int selectedDays;
  final ValueChanged<int> onDaysChanged;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final filtered = history
        .where((point) => point.reportedAt.isAfter(now.subtract(Duration(days: selectedDays))))
        .toList();
    final chartPoints = filtered.isNotEmpty ? filtered : history;

    return Container(
      decoration: _card(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart_rounded, color: _tan, size: 20),
              const SizedBox(width: 8),
              Text('Fiyat Geçmişi', style: _t(s: 15, w: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _segment(label: '7G', days: 7),
              const SizedBox(width: 8),
              _segment(label: '30G', days: 30),
              const SizedBox(width: 8),
              _segment(label: '90G', days: 90),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: chartPoints.length < 2
                ? Center(
                    child: Text('Grafik için yeterli geçmiş veri yok.', style: _t(s: 12, c: _textSoft)),
                  )
                : _PriceChart(points: chartPoints),
          ),
          if (chartPoints.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Son fiyat: ${_fmt(chartPoints.last.price)} • Aralık: ${_fmt(stats.lowest)} - ${_fmt(stats.highest)}',
                style: _t(s: 11, c: _textSoft, w: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }

  Widget _segment({required String label, required int days}) {
    final selected = selectedDays == days;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => onDaysChanged(days),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? _dark : _surfaceAlt,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? _dark : _line),
        ),
        child: Text(label, style: _t(s: 12, w: FontWeight.w700, c: selected ? Colors.white : _textMuted)),
      ),
    );
  }
}

class _PriceChart extends StatelessWidget {
  const _PriceChart({required this.points});

  final List<PriceHistoryPoint> points;

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    for (var i = 0; i < points.length; i++) {
      spots.add(FlSpot(i.toDouble(), points[i].price));
    }

    final minY = points.map((e) => e.price).reduce(math.min);
    final maxY = points.map((e) => e.price).reduce(math.max);
    final padding = ((maxY - minY).abs() * 0.2).clamp(1.0, 20.0);

    final horizontalInterval = ((maxY - minY) / 4).abs().clamp(1.0, 100.0);
    final bottomInterval = math.max(1, (points.length / 4).floor()).toDouble();

    return LineChart(
      LineChartData(
        minY: math.max(0, minY - padding),
        maxY: maxY + padding,
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: horizontalInterval,
          getDrawingHorizontalLine: (_) => FlLine(color: _line, strokeWidth: 1),
        ),
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipRoundedRadius: 12,
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            getTooltipColor: (_) => _dark,
            getTooltipItems: (items) {
              return items.map((item) {
                final index = item.x.toInt().clamp(0, points.length - 1);
                final p = points[index];
                return LineTooltipItem(
                  '${_fmt(p.price)}\n',
                  _t(s: 12, w: FontWeight.w800, c: Colors.white),
                  children: [
                    TextSpan(
                      text: p.dateLabel,
                      style: _t(s: 10, w: FontWeight.w600, c: Colors.white.withOpacity(0.78)),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: horizontalInterval,
              getTitlesWidget: (value, meta) {
                return Text(_fmt(value), style: _t(s: 9, w: FontWeight.w600, c: _textSoft));
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: bottomInterval,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= points.length) return const SizedBox.shrink();

                final visible = index == 0 || index == points.length - 1 || index % bottomInterval.toInt() == 0;
                if (!visible) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(points[index].dateLabel, style: _t(s: 10, w: FontWeight.w600, c: _textSoft)),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.25,
            color: _tan,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              checkToShowDot: (spot, _) => spot.x == points.length - 1,
              getDotPainter: (_, __, ___, ____) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: _tan,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_tan.withOpacity(0.25), _tan.withOpacity(0.02)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketListCard extends StatelessWidget {
  const _MarketListCard({required this.product, required this.onMapTap});

  final ProductDetailResponse product;
  final ValueChanged<MarketPriceEntry> onMapTap;

  @override
  Widget build(BuildContext context) {
    final markets = product.marketPrices;
    final best = markets.isEmpty ? product.bestPrice.price : markets.first.price;

    return Container(
      decoration: _card(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storefront_rounded, color: _tan, size: 19),
              const SizedBox(width: 8),
              Text('Market Karşılaştırması', style: _t(s: 15, w: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 12),
          if (markets.isEmpty)
            Text('Karşılaştırılacak market verisi bulunamadı.', style: _t(s: 12, c: _textSoft))
          else
            ...markets.map((market) {
              final diff = market.price - best;
              final isBest = diff.abs() < 0.001;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _MarketItem(
                  entry: market,
                  isBest: isBest,
                  diff: diff,
                  onMapTap: () => onMapTap(market),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _MarketItem extends StatelessWidget {
  const _MarketItem({
    required this.entry,
    required this.isBest,
    required this.diff,
    required this.onMapTap,
  });

  final MarketPriceEntry entry;
  final bool isBest;
  final double diff;
  final VoidCallback onMapTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isBest ? _green.withOpacity(0.35) : _line, width: isBest ? 1.5 : 1),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isBest ? _green : _tan,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  entry.storeName.isNotEmpty ? entry.storeName[0].toUpperCase() : '?',
                  style: _t(s: 16, w: FontWeight.w800, c: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.storeName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _t(s: 14, w: FontWeight.w800),
                          ),
                        ),
                        if (isBest)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: _green,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text('En Ucuz', style: _t(s: 9, w: FontWeight.w800, c: Colors.white)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entry.isOnline
                          ? 'Online mağaza'
                          : (entry.storeLocation.trim().isEmpty ? 'Konum bilgisi yok' : entry.storeLocation),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _t(s: 11, w: FontWeight.w600, c: _textSoft),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${entry.timeAgo} • ${entry.userName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _t(s: 10, w: FontWeight.w600, c: _textSoft),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_fmt(entry.price), style: _t(s: 17, w: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(
                    isBest
                        ? 'Son fiyattan aynı'
                        : '${diff > 0 ? '+' : '-'}${_fmt(diff.abs())} ${diff > 0 ? 'pahalı' : 'ucuz'}',
                    style: _t(
                      s: 10,
                      w: FontWeight.w700,
                      c: isBest ? _green : (diff > 0 ? _red : _green),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onMapTap,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _line),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  ),
                  icon: const Icon(Icons.map_outlined, size: 15, color: _tan),
                  label: Text('Yol Tarifi', style: _t(s: 11, w: FontWeight.w700, c: _textMuted)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CommentsCard extends StatelessWidget {
  const _CommentsCard({
    required this.comments,
    required this.controller,
    required this.isSubmitting,
    required this.onSend,
  });

  final List<ProductComment> comments;
  final TextEditingController controller;
  final bool isSubmitting;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _card(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.chat_bubble_outline_rounded, size: 20, color: _tan),
              const SizedBox(width: 8),
              Text('Yorumlar', style: _t(s: 16, w: FontWeight.w800)),
              const Spacer(),
              Text('${comments.length} yorum', style: _t(s: 12, w: FontWeight.w600, c: _textSoft)),
            ],
          ),
          const SizedBox(height: 12),
          if (comments.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text('Henüz yorum yok. İlk yorumu sen yaz.', style: _t(s: 12, c: _textSoft)),
            )
          else
            ...comments.take(5).map(
                  (comment) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _CommentTile(comment: comment),
                  ),
                ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: _surfaceAlt,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _line),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Ürün hakkında yorumunu yaz...',
                      hintStyle: _t(s: 12, c: _textSoft),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 6, bottom: 6),
                  child: IconButton(
                    onPressed: isSubmitting ? null : onSend,
                    style: IconButton.styleFrom(
                      backgroundColor: _dark,
                      minimumSize: const Size(38, 38),
                    ),
                    icon: isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded, size: 18, color: _tanLight),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment});

  final ProductComment comment;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(comment.author);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _line),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _colorFromHex(comment.avatarBgHex),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(initials, style: _t(s: 12, w: FontWeight.w800, c: _text)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(comment.author, style: _t(s: 13, w: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(comment.timeAgo, style: _t(s: 10, w: FontWeight.w600, c: _textSoft), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(comment.text, style: _t(s: 12, c: _textMuted, h: 1.45)),
          ),
        ],
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({required this.onAlertTap, required this.onMapTap});

  final VoidCallback onAlertTap;
  final VoidCallback onMapTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [_bg, _bg.withOpacity(0.85), Colors.transparent],
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _line),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onAlertTap,
                icon: const Icon(Icons.notifications_none_rounded, size: 16),
                label: Text('Alarm Kur', style: _t(s: 13, w: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _line),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: onMapTap,
                icon: const Icon(Icons.location_on_rounded, size: 16, color: _tan),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _dark,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                label: Text('Markete Git', style: _t(s: 13, w: FontWeight.w800, c: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

BoxDecoration _card() {
  return BoxDecoration(
    color: _surface,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: _line),
    boxShadow: [
      BoxShadow(
        color: _dark.withOpacity(0.04),
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ],
  );
}

String _initials(String text) {
  final parts = text.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
  if (parts.isEmpty) return 'FR';
  if (parts.length == 1) {
    return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
  }
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

Color _colorFromHex(String hex) {
  final normalized = hex.replaceAll('#', '').trim();
  if (normalized.length != 6) return const Color(0xFFEDE6DD);
  final value = int.tryParse('FF$normalized', radix: 16);
  if (value == null) return const Color(0xFFEDE6DD);
  return Color(value);
}
