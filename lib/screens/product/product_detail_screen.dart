import 'dart:async';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/price_model.dart';
import '../../models/product_detail_api_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_detail_provider.dart';
import '../../providers/product_provider.dart';
import '../../screens/add_price/add_price_screen.dart';
import '../../services/firestore_service.dart';
import '../../services/product_engagement_service.dart';
import '../../widgets/app_network_image.dart';
import '../../theme/fr_colors.dart';
import '../../theme/fr_radius.dart';
import '../../theme/fr_spacing.dart';
import '../../theme/fr_typography.dart';

TextStyle _t({
  double s = 14,
  FontWeight w = FontWeight.w500,
  Color c = FRColors.textPrimary,
  double? h,
  double ls = 0,
}) {
  return TextStyle(
    fontFamily: FRTypography.fontFamily,
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
    } catch (_) {}
  }

  @override
  void dispose() {
    _commentController.dispose();
    _targetPriceController.dispose();
    super.dispose();
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
    await _submitCommentWithController(
      notifier: notifier,
      controller: _commentController,
      onSuccessMessage: null,
    );
  }

  Future<bool> _submitCommentWithController({
    required ProductDetailNotifier notifier,
    required TextEditingController controller,
    String? onSuccessMessage,
  }) async {
    final text = controller.text.trim();
    if (text.isEmpty) return false;

    final ok = await notifier.postComment(text);
    if (!mounted) return false;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yorum gönderilemedi. Lütfen tekrar dene.')),
      );
      return false;
    }

    controller.clear();
    FocusScope.of(context).unfocus();
    HapticFeedback.lightImpact();
    if (onSuccessMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(onSuccessMessage)),
      );
    }
    return true;
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
                color: FRColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: FRSpaceInsets.only(
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
                          color: FRColors.textSubtle,
                          borderRadius: FRRadius.all(FRRadius.pill),
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
                        labelStyle: _t(s: 13, c: FRColors.textMuted),
                        filled: true,
                        fillColor: FRColors.surfaceAlt,
                        border: OutlineInputBorder(
                          borderRadius: FRRadius.all(FRRadius.mdPlus),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: _notifyOnEveryPrice,
                      title: Text('Her fiyat değişiminde bildir', style: _t(s: 13, w: FontWeight.w700)),
                      subtitle: Text('Kapalıysa sadece hedef fiyat altı bildirir', style: _t(s: 11, c: FRColors.textSubtle)),
                      onChanged: (value) {
                        setState(() => _notifyOnEveryPrice = value);
                        setModalState(() {});
                      },
                      activeColor: FRColors.tan,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FRColors.espresso,
                          shape: RoundedRectangleBorder(borderRadius: FRRadius.all(FRRadius.mdPlus)),
                          padding: FRSpaceInsets.symmetric(vertical: 14),
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
                        child: Text('Alarmı Kaydet', style: _t(s: 14, w: FontWeight.w800, c: FRColors.white)),
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
              color: FRColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: FRSpaceInsets.fromLTRB(16, 12, 16, 16),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: FRColors.textSubtle,
                      borderRadius: FRRadius.all(FRRadius.pill),
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
                            child: Text('Geçmiş fiyat kaydı bulunamadı.', style: _t(s: 13, c: FRColors.textSubtle)),
                          )
                        : ListView.separated(
                            itemCount: product.recentPrices.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final item = product.recentPrices[index];
                              final selfBlocked = user != null && item.userId == user.uid;

                              return Container(
                                decoration: _card(),
                                padding: FRSpaceInsets.all(12),
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
                                              backgroundColor: FRColors.success,
                                              disabledBackgroundColor: FRColors.success.withOpacity(0.35),
                                              padding: FRSpaceInsets.symmetric(vertical: 10),
                                            ),
                                            icon: const Icon(Icons.check_rounded, size: 16, color: FRColors.white),
                                            label: Text('Doğru', style: _t(s: 12, w: FontWeight.w700, c: FRColors.white)),
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
                                              side: BorderSide(color: FRColors.danger.withOpacity(0.3)),
                                              padding: FRSpaceInsets.symmetric(vertical: 10),
                                            ),
                                            icon: const Icon(Icons.close_rounded, size: 16, color: FRColors.danger),
                                            label: Text('Yanlış', style: _t(s: 12, w: FontWeight.w700, c: FRColors.danger)),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (selfBlocked)
                                      Padding(
                                        padding: FRSpaceInsets.only(top: 8),
                                        child: Text(
                                          'Kendi fiyatını doğrulama kuralı nedeniyle oy kapalı.',
                                          style: _t(s: 11, w: FontWeight.w600, c: FRColors.textSubtle),
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productDetailProvider(widget.productId));
    final notifier = ref.read(productDetailProvider(widget.productId).notifier);

    if (state.isLoading) {
      return const Scaffold(
        backgroundColor: FRColors.surfaceSoft,
        body: Center(child: CircularProgressIndicator(color: FRColors.tan)),
      );
    }

    if (state.error != null) {
      return Scaffold(
        backgroundColor: FRColors.surfaceSoft,
        body: Center(child: Text(state.error!, style: _t())),
      );
    }

    final product = state.data!;
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    final isFavoriteFromStream = ref.watch(isFavoriteProvider(product.id)).valueOrNull ?? false;
    final favoriteOverride = ref.watch(favoriteOverrideProvider(product.id));
    final isFavorite = favoriteOverride ?? isFavoriteFromStream;

    return _ProductDetailBody(
      product: product,
      state: state,
      isFavorite: isFavorite,
      keyboardOpen: keyboardOpen,
      chartDays: _chartDays,
      currentUid: ref.watch(authUidProvider),
      commentController: _commentController,
      onBackTap: () => Navigator.maybePop(context),
      onShareTap: () {
        Share.share(
          '${product.title} ürününü FiyatRadar\'da incele!\n\nEn Ucuz: ${_fmt(product.bestPrice.price)}\nSatıcı: ${product.bestPrice.store}',
        );
      },
      onFavoriteTap: () => _toggleFavorite(product),
      onVerifyCorrect: () => _vote(notifier: notifier, product: product, isApproved: true),
      onVerifyWrong: () => _vote(notifier: notifier, product: product, isApproved: false),
      onHistoryTap: () => _openHistorySheet(product, notifier),
      onChartDaysChanged: (days) => setState(() => _chartDays = days),
      onCommentSend: () => _submitComment(notifier),
      onAlertTap: () => _openAlertSheet(product),
      onAddPriceTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => AddPriceScreen(initialProductId: product.id),
          ),
        );
      },
      onViewAllCommentsTap: () => _openAllCommentsSheet(product),
    );
  }

  void _openAllCommentsSheet(ProductDetailResponse product) {
    final commentController = TextEditingController();
    var isSubmitting = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.8,
              child: Container(
                decoration: const BoxDecoration(
                  color: FRColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: FRSpaceInsets.fromLTRB(16, 12, 16, 16),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: FRColors.textSubtle,
                          borderRadius: FRRadius.all(FRRadius.pill),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text('Tüm Yorumlar', style: _t(s: 17, w: FontWeight.w800)),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: product.comments.isEmpty
                            ? Center(child: Text('Henüz yorum yok.', style: _t(s: 13, c: FRColors.textSubtle)))
                            : ListView.separated(
                                itemCount: product.comments.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (context, index) => _CommentTile(comment: product.comments[index]),
                              ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: FRColors.surfaceAlt,
                          borderRadius: FRRadius.all(FRRadius.mdPlus),
                          border: Border.all(color: FRColors.border),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: commentController,
                                minLines: 1,
                                maxLines: 4,
                                decoration: InputDecoration(
                                  hintText: 'Ürün hakkında yorumunu yaz...',
                                  hintStyle: _t(s: 12, c: FRColors.textSubtle),
                                  border: InputBorder.none,
                                  contentPadding: FRSpaceInsets.fromLTRB(12, 10, 8, 10),
                                ),
                              ),
                            ),
                            Padding(
                              padding: FRSpaceInsets.only(right: 6, bottom: 6),
                              child: IconButton(
                                onPressed: isSubmitting
                                    ? null
                                    : () async {
                                        setModalState(() => isSubmitting = true);
                                        final notifier = ref.read(productDetailProvider(product.id).notifier);
                                        final ok = await _submitCommentWithController(
                                          notifier: notifier,
                                          controller: commentController,
                                          onSuccessMessage: 'Yorumunuz eklendi.',
                                        );
                                        if (!mounted) return;
                                        setModalState(() => isSubmitting = false);
                                        if (!ok) return;
                                      },
                                style: IconButton.styleFrom(
                                  backgroundColor: FRColors.espresso,
                                  minimumSize: const Size(38, 38),
                                ),
                                icon: isSubmitting
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: FRColors.white),
                                      )
                                    : const Icon(Icons.send_rounded, size: 18, color: FRColors.tanLight),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(commentController.dispose);
  }
}

class _ProductDetailBody extends StatelessWidget {
  const _ProductDetailBody({
    required this.product,
    required this.state,
    required this.isFavorite,
    required this.keyboardOpen,
    required this.chartDays,
    required this.currentUid,
    required this.commentController,
    required this.onBackTap,
    required this.onShareTap,
    required this.onFavoriteTap,
    required this.onVerifyCorrect,
    required this.onVerifyWrong,
    required this.onHistoryTap,
    required this.onChartDaysChanged,
    required this.onCommentSend,
    required this.onAlertTap,
    required this.onAddPriceTap,
    required this.onViewAllCommentsTap,
  });

  final ProductDetailResponse product;
  final ProductDetailState state;
  final bool isFavorite;
  final bool keyboardOpen;
  final int chartDays;
  final String? currentUid;
  final TextEditingController commentController;
  final VoidCallback onBackTap;
  final VoidCallback onShareTap;
  final VoidCallback onFavoriteTap;
  final VoidCallback onVerifyCorrect;
  final VoidCallback onVerifyWrong;
  final VoidCallback onHistoryTap;
  final ValueChanged<int> onChartDaysChanged;
  final VoidCallback onCommentSend;
  final VoidCallback onAlertTap;
  final VoidCallback onAddPriceTap;
  final VoidCallback onViewAllCommentsTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FRColors.surfaceSoft,
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
                    colors: [FRColors.espresso, FRColors.espressoSoft],
                  ),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                ),
              ),
              titleSpacing: 10,
              title: Row(
                children: [
                  _HeaderButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: onBackTap,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Ürün Detayı',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _t(s: 16, w: FontWeight.w800, c: FRColors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _HeaderButton(
                    icon: Icons.share_rounded,
                    onTap: onShareTap,
                  ),
                  const SizedBox(width: 8),
                  _HeaderButton(
                    icon: isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: isFavorite ? FRColors.danger : FRColors.tanLight,
                    onTap: onFavoriteTap,
                  ),
                ],
              ),
            ),
            SliverPadding(
              padding: FRSpaceInsets.fromLTRB(0, 16, 0, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 16),
                  _HeroSection(product: product),
                  const SizedBox(height: 16),
                  _LastPriceHero(
                    product: product,
                    onFavoriteTap: onFavoriteTap,
                    onAlertTap: onAlertTap,
                  ),
                  const SizedBox(height: 16),
                  _VerificationCard(
                    product: product,
                    isSubmitting: state.isSubmittingVote,
                    currentUid: currentUid,
                    onCorrect: onVerifyCorrect,
                    onWrong: onVerifyWrong,
                    onHistoryTap: onHistoryTap,
                  ),
                  const SizedBox(height: 16),
                  _HistoryChartCard(
                    history: state.history,
                    stats: product.stats,
                    recentPrices: product.recentPrices,
                    fallbackStoreName: product.bestPrice.store,
                    selectedDays: chartDays,
                    onDaysChanged: onChartDaysChanged,
                  ),
                  const SizedBox(height: 16),
                  _MarketListCard(
                    product: product,
                  ),
                  const SizedBox(height: 16),
                  _CommentsCard(
                    comments: product.comments,
                    controller: commentController,
                    isSubmitting: state.isSubmittingComment,
                    onSend: onCommentSend,
                    onViewAllTap: onViewAllCommentsTap,
                  ),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: keyboardOpen
          ? null
          : _BottomActions(
              onAddPriceTap: onAddPriceTap,
              onAlertTap: onAlertTap,
            ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    required this.onTap,
    this.color = FRColors.tanLight,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: FRRadius.all(FRRadius.md),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: FRColors.white.withOpacity(0.08),
          borderRadius: FRRadius.all(FRRadius.md),
          border: Border.all(color: FRColors.white.withOpacity(0.1)),
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
    final category = product.categories.isEmpty ? 'Kategori yok' : product.categories.join(' > ');

    return Container(
      margin: FRSpaceInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: FRColors.surface,
        borderRadius: FRRadius.all(FRRadius.lg),
        border: Border.all(color: FRColors.border),
      ),
      padding: FRSpaceInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _t(s: 11, w: FontWeight.w600, c: FRColors.textSubtle),
                ),
                const SizedBox(height: 6),
                Text(
                  product.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _t(s: 17, w: FontWeight.w800, h: 1.2),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 14, color: FRColors.tan),
                    const SizedBox(width: 4),
                    Text(
                      '${product.stats.average > 0 ? product.stats.average.toStringAsFixed(1) : 'Yeni'}',
                      style: _t(s: 12, w: FontWeight.w700, c: FRColors.tan),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '• ${product.comments.length} topluluk yorumu',
                      style: _t(s: 10, c: FRColors.textSubtle),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: FRColors.surfaceAlt,
              borderRadius: FRRadius.all(FRRadius.lg),
              border: Border.all(color: FRColors.border),
            ),
            child: ClipRRect(
              borderRadius: FRRadius.all(FRRadius.lg),
              child: AppNetworkImage(
                imageUrl: product.imageUrl,
                cacheKey: 'product_detail_${product.id}',
                fit: BoxFit.cover,
                errorWidget: const Center(
                  child: Icon(Icons.image_not_supported_rounded, color: FRColors.textSubtle, size: 34),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LastPriceHero extends StatelessWidget {
  const _LastPriceHero({
    required this.product,
    required this.onFavoriteTap,
    required this.onAlertTap,
  });

  final ProductDetailResponse product;
  final VoidCallback onFavoriteTap;
  final VoidCallback onAlertTap;

  @override
  Widget build(BuildContext context) {
    final avg = product.stats.average;
    final avgDiff = avg <= 0 ? 0 : ((product.bestPrice.price - avg) / avg) * 100;
    final note = product.marketPrices
        .map((entry) => entry.userNote?.trim() ?? '')
        .firstWhere((text) => text.isNotEmpty, orElse: () => '');

    return Container(
      margin: FRSpaceInsets.symmetric(horizontal: 16),
      padding: FRSpaceInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [FRColors.espresso, FRColors.espressoSoft],
        ),
        borderRadius: FRRadius.all(FRRadius.xxlTight),
        border: Border.all(color: FRColors.tan.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: FRColors.espresso.withOpacity(0.22),
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
              const Icon(Icons.workspace_premium_outlined, size: 16, color: FRColors.tanLight),
              const SizedBox(width: 5),
              Container(
                padding: FRSpaceInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: FRColors.tan.withOpacity(0.2),
                  borderRadius: FRRadius.all(FRRadius.pill),
                ),
                child: Text(
                  'EN İYİ FİYAT',
                  style: _t(s: 10, w: FontWeight.w700, c: FRColors.tanLight, ls: 0.4),
                ),
              ),
              const Spacer(),
              Container(
                padding: FRSpaceInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: avgDiff <= 0 ? FRColors.success.withOpacity(0.15) : FRColors.danger.withOpacity(0.15),
                  borderRadius: FRRadius.all(FRRadius.pill),
                  border: Border.all(
                    color: avgDiff <= 0 ? FRColors.success.withOpacity(0.32) : FRColors.danger.withOpacity(0.32),
                  ),
                ),
                child: Text(
                  '${avgDiff >= 0 ? '+' : ''}${avgDiff.toStringAsFixed(1)}% ort. fark',
                  style: _t(s: 11, w: FontWeight.w800, c: avgDiff <= 0 ? FRColors.success : FRColors.danger),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          RichText(
            text: TextSpan(
              style: _t(s: 50, w: FontWeight.w900, c: FRColors.white, h: 0.95),
              children: [
                TextSpan(text: product.bestPrice.price.toStringAsFixed(2).replaceAll('.', ',')),
                TextSpan(text: '₺', style: _t(s: 34, w: FontWeight.w900, c: FRColors.white.withOpacity(0.62))),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: FRSpaceInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: FRColors.white.withOpacity(0.08),
                  borderRadius: FRRadius.all(FRRadius.pill),
                  border: Border.all(color: FRColors.white.withOpacity(0.14)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.store_outlined, size: 14, color: FRColors.white),
                    const SizedBox(width: 7),
                    Text(
                      product.bestPrice.store,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _t(s: 12, w: FontWeight.w800, c: FRColors.white),
                    ),
                    Container(
                      width: 1,
                      height: 10,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      color: FRColors.white.withOpacity(0.2),
                    ),
                    const Icon(Icons.access_time, size: 14, color: FRColors.white),
                    const SizedBox(width: 4),
                    Text(
                      product.bestPrice.createdAtLabel,
                      style: _t(s: 12, c: FRColors.white.withOpacity(0.68)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (note.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: FRSpaceInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: FRColors.white.withOpacity(0.08),
                borderRadius: FRRadius.all(FRRadius.md),
                border: Border.all(color: FRColors.white.withOpacity(0.14)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.note_alt_outlined, size: 14, color: FRColors.white),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Not: $note',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _t(s: 12, w: FontWeight.w600, c: FRColors.white.withOpacity(0.88)),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onFavoriteTap,
                  icon: const Icon(Icons.star, size: 16),
                  label: const Text('Listeye Ekle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FRColors.tan,
                    foregroundColor: FRColors.espresso,
                    minimumSize: const Size(0, 38),
                    shape: RoundedRectangleBorder(borderRadius: FRRadius.all(FRRadius.md)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onAlertTap,
                  icon: const Icon(Icons.notifications_outlined, size: 16),
                  label: const Text('Alarm'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: FRColors.white,
                    minimumSize: const Size(0, 38),
                    shape: RoundedRectangleBorder(borderRadius: FRRadius.all(FRRadius.md)),
                    side: BorderSide(color: FRColors.white.withOpacity(0.2)),
                  ),
                ),
              ),
            ],
          ),
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
    final score = product.trust.scorePercent.clamp(0, 100);
    final selfBlocked = currentUid != null && currentUid == product.bestPrice.userId;
    final avg = product.stats.average;
    final avgDiff = avg <= 0 ? 0 : ((product.bestPrice.price - avg) / avg) * 100;

    return Container(
      margin: FRSpaceInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: FRColors.surface,
        borderRadius: FRRadius.all(FRRadius.lg),
        border: Border.all(color: FRColors.border),
      ),
      padding: FRSpaceInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.shield_outlined, size: 17, color: FRColors.success),
                  const SizedBox(width: 6),
                  Text('Güven Analizi', style: _t(s: 13, w: FontWeight.w700)),
                ],
              ),
              InkWell(
                onTap: onHistoryTap,
                borderRadius: FRRadius.all(FRRadius.md),
                child: Row(
                  children: [
                    Text(
                      '$score',
                      style: _t(s: 18, w: FontWeight.w800, c: FRColors.success),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Güvenilir',
                      style: _t(s: 10, w: FontWeight.w600, c: FRColors.textSubtle, ls: 0.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: FRColors.borderLight),
          const SizedBox(height: 14),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 2.8,
            children: [
              _buildTrustItem(
                icon: Icons.check_circle_outline,
                title: 'Doğrulanmış',
                subtitle: total > 0 ? 'Topluluk onayı var' : 'Topluluk onayı',
              ),
              _buildTrustItem(
                icon: Icons.bolt_outlined,
                title: 'Canlı Veri',
                subtitle: 'Son 5 dakika',
              ),
              _buildTrustItem(
                icon: Icons.trending_up_outlined,
                title: 'Trend',
                subtitle: avgDiff <= 0 ? 'Ortalamadan ${avgDiff.toStringAsFixed(0)}% düşük' : 'Ortalamadan yüksek',
              ),
              _buildTrustItem(
                icon: Icons.people_outline,
                title: 'Kaynak',
                subtitle: '${product.marketPrices.length} farklı platform',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: FRSpaceInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: FRColors.surfaceAlt,
              borderRadius: FRRadius.all(FRRadius.md),
              border: Border.all(color: FRColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: FRColors.tan.withOpacity(0.2),
                    borderRadius: FRRadius.all(FRRadius.pill),
                  ),
                  child: Center(
                    child: Text(
                      product.bestPrice.userName.isNotEmpty ? product.bestPrice.userName[0].toUpperCase() : '?',
                      style: _t(s: 13, w: FontWeight.w700, c: FRColors.tanLight),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.bestPrice.userName.isEmpty ? 'Anonim kullanıcı' : product.bestPrice.userName,
                        style: _t(s: 12, w: FontWeight.w700),
                      ),
                      Text(
                        'Güven puanı: ${product.bestPrice.userTrustScore}',
                        style: _t(s: 10, c: FRColors.textSubtle),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: selfBlocked || isSubmitting ? null : onCorrect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FRColors.success,
                    disabledBackgroundColor: FRColors.success.withOpacity(0.35),
                    shape: RoundedRectangleBorder(borderRadius: FRRadius.all(FRRadius.md)),
                    padding: FRSpaceInsets.symmetric(vertical: 13),
                  ),
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: FRColors.white),
                        )
                      : const Icon(Icons.check_rounded, size: 16, color: FRColors.white),
                  label: Text('Fiyat Doğru', style: _t(s: 12, w: FontWeight.w700, c: FRColors.white)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: selfBlocked || isSubmitting ? null : onWrong,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: FRColors.danger.withOpacity(0.35)),
                    shape: RoundedRectangleBorder(borderRadius: FRRadius.all(FRRadius.md)),
                    padding: FRSpaceInsets.symmetric(vertical: 13),
                  ),
                  icon: const Icon(Icons.close_rounded, size: 16, color: FRColors.danger),
                  label: Text('Uyuşmuyor', style: _t(s: 12, w: FontWeight.w700, c: FRColors.danger)),
                ),
              ),
            ],
          ),
          if (selfBlocked)
            Padding(
              padding: FRSpaceInsets.only(top: 10),
              child: Text('Kendi eklediğin fiyatı doğrulayamazsın.', style: _t(s: 11, w: FontWeight.w600, c: FRColors.textSubtle)),
            ),
        ],
      ),
    );
  }

  Widget _buildTrustItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: FRColors.surfaceAlt,
            borderRadius: FRRadius.all(FRRadius.smPlus),
            border: Border.all(color: FRColors.border),
          ),
          child: Icon(icon, size: 14, color: FRColors.tan),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: _t(s: 11, w: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(subtitle, style: _t(s: 10, c: FRColors.textSubtle, h: 1.35)),
            ],
          ),
        ),
      ],
    );
  }
}

class _HistoryChartCard extends StatelessWidget {
  const _HistoryChartCard({
    required this.history,
    required this.stats,
    required this.recentPrices,
    required this.fallbackStoreName,
    required this.selectedDays,
    required this.onDaysChanged,
  });

  final List<PriceHistoryPoint> history;
  final PriceStats stats;
  final List<RecentPriceEntry> recentPrices;
  final String fallbackStoreName;
  final int selectedDays;
  final ValueChanged<int> onDaysChanged;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final filtered = selectedDays == -1
        ? history
        : history.where((point) => point.reportedAt.isAfter(now.subtract(Duration(days: selectedDays)))).toList();
    final chartPoints = filtered;
    var change = 0.0;
    if (chartPoints.length >= 2) {
      final first = chartPoints.first.price;
      final last = chartPoints.last.price;
      if (first > 0) {
        final raw = ((last - first) / first) * 100;
        if (raw.isFinite) change = raw;
      }
    }

    return Container(
      decoration: _card(),
      padding: FRSpaceInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart_rounded, color: FRColors.tan, size: 20),
              const SizedBox(width: 8),
              Text('Fiyat Geçmişi', style: _t(s: 15, w: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _segment(label: '7G', days: 7),
              _segment(label: '30G', days: 30),
              _segment(label: '90G', days: 90),
              _segment(label: 'Tümü', days: -1),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _metric('Değişim', '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}%', change <= 0 ? FRColors.success : FRColors.danger)),
              const SizedBox(width: 8),
              Expanded(child: _metric('En Düşük', _fmt(stats.lowest), FRColors.success)),
              const SizedBox(width: 8),
              Expanded(child: _metric('En Yüksek', _fmt(stats.highest), FRColors.danger)),
              const SizedBox(width: 8),
              Expanded(child: _metric('Ortalama', _fmt(stats.average), FRColors.tan)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: chartPoints.length < 2
                ? Center(
                    child: Text('Grafik için yeterli geçmiş veri yok.', style: _t(s: 12, c: FRColors.textSubtle)),
                  )
                : _PriceChart(points: chartPoints),
          ),
          const SizedBox(height: 10),
          if (chartPoints.isEmpty)
            Text('Geçmiş kayıt bulunamadı.', style: _t(s: 12, c: FRColors.textSubtle))
          else
            ...chartPoints.reversed.take(5).map(
                  (point) {
                    final matched = _matchRecentEntry(point.price);
                    final storeName = matched?.storeName.trim().isNotEmpty == true ? matched!.storeName : fallbackStoreName;
                    final tag = matched?.userName.trim().isNotEmpty == true ? matched!.userName : null;

                    return Container(
                    margin: FRSpaceInsets.only(bottom: 8),
                    padding: FRSpaceInsets.symmetric(horizontal: 10, vertical: 9),
                    decoration: BoxDecoration(
                      color: FRColors.surfaceAlt,
                      borderRadius: FRRadius.all(FRRadius.md),
                      border: Border.all(color: FRColors.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(point.dateLabel, style: _t(s: 11, w: FontWeight.w700, c: FRColors.textSubtle)),
                              const SizedBox(height: 2),
                              Text(storeName, maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(s: 12, w: FontWeight.w700)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(_fmt(point.price), style: _t(s: 13, w: FontWeight.w800)),
                            if (tag != null && tag.isNotEmpty)
                              Text(tag, style: _t(s: 10, w: FontWeight.w600, c: FRColors.textSubtle)),
                          ],
                        ),
                      ],
                    ),
                  );
                  },
                ),
        ],
      ),
    );
  }

  RecentPriceEntry? _matchRecentEntry(double price) {
    for (final entry in recentPrices) {
      if ((entry.price - price).abs() < 0.01) {
        return entry;
      }
    }
    return null;
  }

  Widget _segment({required String label, required int days}) {
    final selected = selectedDays == days;
    return InkWell(
      borderRadius: FRRadius.all(FRRadius.pill),
      onTap: () => onDaysChanged(days),
      child: Container(
        padding: FRSpaceInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? FRColors.espresso : FRColors.surfaceAlt,
          borderRadius: FRRadius.all(FRRadius.pill),
          border: Border.all(color: selected ? FRColors.espresso : FRColors.border),
        ),
        child: Text(label, style: _t(s: 12, w: FontWeight.w700, c: selected ? FRColors.white : FRColors.textMuted)),
      ),
    );
  }

  Widget _metric(String label, String value, Color color) {
    return Container(
      padding: FRSpaceInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: FRColors.surfaceAlt,
        borderRadius: FRRadius.all(FRRadius.md),
        border: Border.all(color: FRColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: _t(s: 10, w: FontWeight.w700, c: FRColors.textSubtle)),
          const SizedBox(height: 2),
          Text(value, style: _t(s: 12, w: FontWeight.w800, c: color)),
        ],
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
          getDrawingHorizontalLine: (_) => FlLine(color: FRColors.border, strokeWidth: 1),
        ),
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipRoundedRadius: 12,
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            tooltipPadding: FRSpaceInsets.symmetric(horizontal: 10, vertical: 8),
            getTooltipColor: (_) => FRColors.espresso,
            getTooltipItems: (items) {
              return items.map((item) {
                final index = item.x.toInt().clamp(0, points.length - 1);
                final p = points[index];
                return LineTooltipItem(
                  '${_fmt(p.price)}\n',
                  _t(s: 12, w: FontWeight.w800, c: FRColors.white),
                  children: [
                    TextSpan(
                      text: p.dateLabel,
                      style: _t(s: 10, w: FontWeight.w600, c: FRColors.white.withOpacity(0.78)),
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
                return Text(_fmt(value), style: _t(s: 9, w: FontWeight.w600, c: FRColors.textSubtle));
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
                  padding: FRSpaceInsets.only(top: 8),
                  child: Text(points[index].dateLabel, style: _t(s: 10, w: FontWeight.w600, c: FRColors.textSubtle)),
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
            color: FRColors.tan,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              checkToShowDot: (spot, _) => spot.x == points.length - 1,
              getDotPainter: (_, __, ___, ____) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: FRColors.tan,
                  strokeWidth: 2,
                  strokeColor: FRColors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [FRColors.tan.withOpacity(0.25), FRColors.tan.withOpacity(0.02)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketListCard extends StatelessWidget {
  const _MarketListCard({required this.product});

  final ProductDetailResponse product;

  @override
  Widget build(BuildContext context) {
    final markets = product.marketPrices;
    final best = markets.isEmpty ? product.bestPrice.price : markets.first.price;

    return Container(
      margin: FRSpaceInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: FRColors.surface,
        borderRadius: FRRadius.all(FRRadius.lg),
        border: Border.all(color: FRColors.border),
      ),
      padding: FRSpaceInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.store_outlined, color: FRColors.tan, size: 19),
              const SizedBox(width: 8),
              Text('Fiyat Kaynakları', style: _t(s: 15, w: FontWeight.w800)),
              const Spacer(),
              Text(
                'Tümünü Gör',
                style: _t(s: 12, w: FontWeight.w600, c: FRColors.tan),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (markets.isEmpty)
            Text('Karşılaştırılacak fiyat kaydı bulunamadı.', style: _t(s: 12, c: FRColors.textSubtle))
          else
            ...markets.map((market) {
              final diff = market.price - best;
              final isBest = diff.abs() < 0.001;
              return Padding(
                padding: FRSpaceInsets.only(bottom: 10),
                child: _MarketItem(
                  entry: market,
                  isBest: isBest,
                  diff: diff,
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
  });

  final MarketPriceEntry entry;
  final bool isBest;
  final double diff;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: FRSpaceInsets.all(12),
      decoration: BoxDecoration(
        color: FRColors.surfaceAlt,
        borderRadius: FRRadius.all(FRRadius.lg),
        border: Border.all(
          color: isBest ? FRColors.success.withOpacity(0.35) : FRColors.border,
          width: isBest ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isBest ? FRColors.success : FRColors.tan,
              borderRadius: FRRadius.all(FRRadius.pill),
            ),
            child: Center(
              child: Text(
                entry.storeName.isNotEmpty ? entry.storeName[0].toUpperCase() : '?',
                style: _t(s: 14, w: FontWeight.w800, c: FRColors.white),
              ),
            ),
          ),
          const SizedBox(width: 11),
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
                        style: _t(s: 13, w: FontWeight.w700),
                      ),
                    ),
                    if (isBest)
                      Container(
                        margin: FRSpaceInsets.only(left: 6),
                        padding: FRSpaceInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: FRColors.success,
                          borderRadius: FRRadius.all(FRRadius.pill),
                        ),
                        child: Text('En İyi', style: _t(s: 9, w: FontWeight.w800, c: FRColors.white)),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  entry.userNote?.trim().isNotEmpty == true ? entry.userNote!.trim() : (entry.isOnline ? 'Online platform' : 'Fiyat kaydı'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _t(s: 10, w: FontWeight.w600, c: FRColors.textSubtle),
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.timeAgo}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _t(s: 10, w: FontWeight.w600, c: FRColors.textSubtle),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_fmt(entry.price), style: _t(s: 15, w: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(
                isBest ? 'En iyi fiyat' : '${diff > 0 ? '+' : '-'}${_fmt(diff.abs())}',
                style: _t(
                  s: 10,
                  w: FontWeight.w700,
                  c: isBest ? FRColors.success : (diff > 0 ? FRColors.danger : FRColors.success),
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
    required this.onViewAllTap,
  });

  final List<ProductComment> comments;
  final TextEditingController controller;
  final bool isSubmitting;
  final VoidCallback onSend;
  final VoidCallback onViewAllTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: FRSpaceInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: FRColors.surface,
        borderRadius: FRRadius.all(FRRadius.lg),
        border: Border.all(color: FRColors.border),
      ),
      padding: FRSpaceInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: FRColors.tan),
              const SizedBox(width: 8),
              Text('Topluluk Görüşü', style: _t(s: 13, w: FontWeight.w700)),
              const Spacer(),
              GestureDetector(
                onTap: onViewAllTap,
                child: Text(
                  'Tümü',
                  style: _t(s: 11, w: FontWeight.w600, c: FRColors.tan),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (comments.isEmpty)
            Padding(
              padding: FRSpaceInsets.symmetric(vertical: 12),
              child: Text('Henüz topluluk yorumu yok.', style: _t(s: 12, c: FRColors.textSubtle)),
            )
          else
            ...comments.take(2).map(
                  (comment) => Padding(
                    padding: FRSpaceInsets.only(bottom: 8),
                    child: _CommentTile(comment: comment),
                  ),
                ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onViewAllTap,
            icon: const Icon(Icons.add_circle_outline, size: 16),
            label: Text('Yorum ekle', style: _t(s: 12, w: FontWeight.w700, c: FRColors.tan)),
            style: TextButton.styleFrom(
              padding: FRSpaceInsets.symmetric(horizontal: 8, vertical: 4),
              foregroundColor: FRColors.tan,
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
      padding: FRSpaceInsets.all(12),
      decoration: BoxDecoration(
        color: FRColors.surfaceAlt,
        borderRadius: FRRadius.all(FRRadius.md),
        border: Border.all(color: FRColors.border),
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
                  borderRadius: FRRadius.all(FRRadius.pill),
                ),
                child: Text(initials, style: _t(s: 12, w: FontWeight.w800, c: FRColors.textPrimary)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(comment.author, style: _t(s: 13, w: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(comment.timeAgo, style: _t(s: 10, w: FontWeight.w600, c: FRColors.textSubtle), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(comment.text, style: _t(s: 12, c: FRColors.textMuted, h: 1.45)),
          ),
        ],
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({required this.onAlertTap, required this.onAddPriceTap});

  final VoidCallback onAlertTap;
  final VoidCallback onAddPriceTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: FRSpaceInsets.fromLTRB(16, 10, 16, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [FRColors.surfaceSoft, FRColors.surfaceSoft.withOpacity(0.85), Colors.transparent],
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: FRColors.surface,
          borderRadius: FRRadius.all(FRRadius.mdPlus),
          border: Border.all(color: FRColors.border),
          boxShadow: [
            BoxShadow(
              color: FRColors.espresso.withOpacity(0.08),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: FRSpaceInsets.all(4),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onAddPriceTap,
                icon: const Icon(Icons.add_rounded, size: 16, color: FRColors.white),
                label: Text('Fiyat Ekle', style: _t(s: 13, w: FontWeight.w800, c: FRColors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FRColors.espresso,
                  shape: RoundedRectangleBorder(borderRadius: FRRadius.all(FRRadius.smPlus)),
                  padding: FRSpaceInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onAlertTap,
                icon: const Icon(Icons.notifications_none_rounded, size: 16),
                label: Text('Alarm / Takip', style: _t(s: 13, w: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: FRColors.border),
                  shape: RoundedRectangleBorder(borderRadius: FRRadius.all(FRRadius.smPlus)),
                  padding: FRSpaceInsets.symmetric(vertical: 12),
                ),
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
    color: FRColors.surface,
    borderRadius: FRRadius.all(FRRadius.lg),
    border: Border.all(color: FRColors.border),
    boxShadow: [
      BoxShadow(
        color: FRColors.espresso.withOpacity(0.04),
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
  if (normalized.length != 6) return FRColors.studio;
  final value = int.tryParse('FF$normalized', radix: 16);
  if (value == null) return FRColors.studio;
  return Color(value);
}
