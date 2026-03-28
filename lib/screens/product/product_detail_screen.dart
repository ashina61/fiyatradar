import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/price_model.dart';
import '../../models/product_detail_api_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/price_provider.dart';
import '../../providers/product_detail_provider.dart';
import '../../providers/product_provider.dart' hide firestoreServiceProvider;
import '../../services/firestore_service.dart';
import '../../services/product_engagement_service.dart';
import '../../theme/fr_colors.dart';
import '../../utils/elite_level_engine.dart';
import '../../widgets/app_network_image.dart';

const _bg = Color(0xFFECEAE4);
const _dark = Color(0xFF1C1108);
const _white = Color(0xFFFFFFFF);
const _tan = Color(0xFFB88C50);
const _tanCard = Color(0xFFC09A60);
const _green = Color(0xFF27A85A);
const _greenBg = Color(0x1A27A85A);
const _red = Color(0xFFD93C3C);
const _redBg = Color(0x0FD93C3C);
const _t1 = Color(0xFF1C1108);
const _t2 = Color(0xFF6B5D4E);
const _t3 = Color(0xFFA89A8A);
const _border = Color(0x121C1108);
const _cardRadius = 24.0;
const _innerRadius = 14.0;
const _sectionGap = 12.0;

const _cardShadow = BoxShadow(color: Color(0x121C1108), blurRadius: 14, offset: Offset(0, 2));

TextStyle _pjs({
  double size = 14,
  FontWeight weight = FontWeight.w500,
  Color color = _t1,
  double? height,
  double letterSpacing = 0,
}) {
  return GoogleFonts.plusJakartaSans(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );
}

String _fmtPrice(double value) => '${value.toStringAsFixed(2).replaceAll('.', ',')} ₺';

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
  final _targetPriceController = TextEditingController();
  final _commentController = TextEditingController();
  final _productEngagementService = ProductEngagementService();
  bool _showAllComments = false;
  bool _notifyOnEveryPrice = false;
  bool _isCommentComposerActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_registerProductView());
    });
  }

  Future<void> _registerProductView() async {
    try {
      await _productEngagementService.incrementViewCount(widget.productId);
      if (!mounted) return;
      await ref.read(productDetailProvider(widget.productId).notifier).load();
    } catch (_) {}
  }

  Future<void> _launchMap(BestPrice bestPrice) async {
    final query = bestPrice.storeLocation.trim().isNotEmpty
        ? '${bestPrice.store} ${bestPrice.storeLocation}'
        : bestPrice.store;
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}');
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harita açılamadı. Lütfen tekrar dene.')),
      );
    }
  }

  @override
  void dispose() {
    _targetPriceController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment(ProductDetailNotifier notifier) async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.lightImpact();
    final ok = await notifier.postComment(text);
    if (!mounted) return;
    if (ok) {
      _commentController.clear();
      FocusScope.of(context).unfocus();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yorum eklenemedi. Lütfen tekrar dene.')),
      );
    }
  }

  Future<void> _openAlertSheet(ProductDetailResponse product) async {
    final currentUser = ref.read(authStateProvider).valueOrNull;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alarm kurmak için giriş yapmalısın')),
      );
      return;
    }
    final hasAlert = await ref.read(firestoreServiceProvider).streamHasAlert(product.id, currentUser.uid).first;
    _targetPriceController.text = (product.bestPrice.price * 0.95).toStringAsFixed(2).replaceAll('.', ',');
    _notifyOnEveryPrice = false;

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                decoration: BoxDecoration(
                  color: _dark,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  border: Border.all(color: _tan.withOpacity(0.35)),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Fiyat Alarmı', style: _pjs(size: 18, weight: FontWeight.w900, color: _white)),
                      const SizedBox(height: 6),
                      Text(
                        hasAlert ? 'Mevcut alarmını güncelle.' : 'Hedef fiyat girerek bildirim al.',
                        style: _pjs(size: 12, color: _white.withOpacity(0.7)),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _targetPriceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                        style: _pjs(size: 16, weight: FontWeight.w700, color: _white),
                        decoration: InputDecoration(
                          prefixText: '₺ ',
                          filled: true,
                          fillColor: _white.withOpacity(0.06),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            final parsed = double.tryParse(_targetPriceController.text.replaceAll(',', '.'));
                            if (parsed == null || parsed <= 0) return;
                            await ref.read(firestoreServiceProvider).upsertAlert(
                                  productId: product.id,
                                  userId: currentUser.uid,
                                  targetPrice: parsed,
                                  notifyOnEveryPrice: false,
                                );
                            if (!mounted) return;
                            Navigator.of(sheetContext).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _tanCard,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text('Alarmı Kaydet', style: _pjs(size: 14, weight: FontWeight.w800, color: _white)),
                        ),
                      ),
                      Row(
                        children: [
                          Switch.adaptive(
                            value: _notifyOnEveryPrice,
                            activeColor: _tanCard,
                            onChanged: (v) => setModalState(() => _notifyOnEveryPrice = v),
                          ),
                          Expanded(
                            child: Text('Her yeni fiyatta bildirim', style: _pjs(size: 12, color: _white.withOpacity(0.8))),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showRejectModal(String priceId) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RejectSheet(
        onSubmit: (reason) {
          final user = ref.read(authStateProvider).valueOrNull;
          if (user == null) {
            if (Navigator.canPop(context)) Navigator.pop(context);
            return;
          }
          unawaited(ref.read(firestoreServiceProvider).reportPrice(
                priceId: priceId,
                userId: user.uid,
                reason: reason,
                contextId: widget.productId,
              ));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('İtirazınız incelenmek üzere gönderildi.')),
          );
          if (Navigator.canPop(context)) Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productDetailProvider(widget.productId));
    final notifier = ref.read(productDetailProvider(widget.productId).notifier);
    final viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;
    final keyboardVisible = viewInsetsBottom > 0;
    final contentBottomPadding = keyboardVisible ? viewInsetsBottom + 24 : 122.0;

    return Scaffold(
      backgroundColor: _bg,
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: _tanCard))
          : state.error != null
              ? Center(child: Text(state.error!, style: _pjs()))
              : Stack(
                  children: [
                    CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(child: _Header(product: state.data!)),
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(14, 14, 14, contentBottomPadding),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              _HeroSummaryCard(
                                product: state.data!,
                              ),
                              const SizedBox(height: _sectionGap),
                              _DecisionCard(product: state.data!),
                              const SizedBox(height: _sectionGap),
                              _PriceStatsMiniSection(product: state.data!),
                              const SizedBox(height: _sectionGap),
                              _VerificationSummaryCard(
                                product: state.data!,
                                isSubmitting: state.isSubmittingVote,
                                onOpenHistory: () => _openPastPricesSheet(state.data!),
                                onVote: (priceId, isApproved) async {
                                  final user = ref.read(authStateProvider).valueOrNull;
                                  if (user == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Oy vermek için giriş yapmalısın.')),
                                    );
                                    return;
                                  }
                                  HapticFeedback.lightImpact();
                                  final result = await notifier.votePrice(
                                    priceId: priceId,
                                    isApproved: isApproved,
                                  );
                                  if (!mounted || result == null) return;
                                  if (result.status == PriceVoteStatus.alreadyVoted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Bu fiyatı zaten doğruladın')),
                                    );
                                  } else if (result.status == PriceVoteStatus.selfVoteBlocked) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Kendi eklediğin fiyatı doğrulayamazsın')),
                                    );
                                  }
                                },
                                onWrongTap: _showRejectModal,
                              ),
                              const SizedBox(height: _sectionGap),
                              _PriceHistorySection(product: state.data!, history: state.history),
                              const SizedBox(height: _sectionGap),
                              _MarketComparisonSection(product: state.data!, onOpenMap: _launchMap),
                              const SizedBox(height: _sectionGap),
                              _CommentsSection(
                                product: state.data!,
                                isExpanded: _showAllComments,
                                composerController: _commentController,
                                isSubmittingComment: state.isSubmittingComment,
                                isComposerActive: _isCommentComposerActive,
                                onComposerFocusChanged: (v) => setState(() => _isCommentComposerActive = v),
                                onSubmitComment: () => _submitComment(notifier),
                                onExpand: () => setState(() => _showAllComments = true),
                              ),
                            ]),
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 160),
                        opacity: keyboardVisible ? 0 : 1,
                        child: IgnorePointer(
                          ignoring: keyboardVisible,
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [_bg, _bg.withOpacity(0.9), Colors.transparent],
                              ),
                            ),
                            child: Container(
                              height: 54,
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: _white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: _border),
                                boxShadow: [
                                  BoxShadow(
                                    color: _dark.withOpacity(0.08),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _openAlertSheet(state.data!),
                                      icon: const Icon(Icons.notifications_none_rounded, size: 16),
                                      label: Text('Alarm', style: _pjs(size: 13, weight: FontWeight.w700, color: _t1)),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: _border),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        backgroundColor: _bg,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 2,
                                    child: ElevatedButton.icon(
                                      onPressed: () => _launchMap(state.data!.bestPrice),
                                      icon: const Icon(Icons.location_on_rounded, size: 16, color: _tanCard),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _dark,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      label: Text(
                                        'Markete Git',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: _pjs(size: 13, weight: FontWeight.w800, color: _white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  void _openPastPricesSheet(ProductDetailResponse product) {
    final prices = ref
        .read(pricesForProductProvider(product.id))
        .valueOrNull
        ?.where((e) => e.isActive)
        .toList();
    prices?.sort((a, b) => b.reportedAt.compareTo(a.reportedAt));

    final entries = prices ?? const <PriceModel>[];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.88,
        child: Container(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
          decoration: const BoxDecoration(
            color: _white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: FRColors.borderStrong,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(Icons.history_toggle_off_rounded, size: 20, color: _tan),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Geçmiş Fiyatları Doğrula', style: _pjs(size: 17, weight: FontWeight.w900))),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, size: 21),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Divider(height: 1, color: _border),
                const SizedBox(height: 12),
                Expanded(
                  child: entries.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 26),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: FRColors.background,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(Icons.history_toggle_off_rounded, size: 30, color: _tan),
                                ),
                                const SizedBox(height: 12),
                                Text('Geçmiş fiyat bulunamadı', style: _pjs(size: 16, weight: FontWeight.w800)),
                                const SizedBox(height: 6),
                                Text(
                                  'Bu ürün için henüz doğrulanabilir geçmiş fiyat girişi yok.',
                                  textAlign: TextAlign.center,
                                  style: _pjs(size: 12, color: _t3, height: 1.45),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: math.min(entries.length, 8),
                          physics: const BouncingScrollPhysics(),
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) => _PastEntryRow(entry: entries[i]),
                        ),
                ),
                const SizedBox(height: 8),
                const Divider(height: 1, color: _border),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      backgroundColor: FRColors.background,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('Kapat', style: _pjs(size: 14, weight: FontWeight.w700, color: _t2)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.product});

  final ProductDetailResponse product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final override = ref.watch(favoriteOverrideProvider(product.id));
    final favoriteAsync = ref.watch(isFavoriteProvider(product.id));
    final isFavorite = override ?? favoriteAsync.valueOrNull ?? false;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [FRColors.espresso, FRColors.espressoSoft],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: FRColors.shadowStrong.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 14,
        left: 20,
        right: 20,
        bottom: 18,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _HdrBtn(icon: Icons.arrow_back_ios_new_rounded, onTap: () { if (Navigator.canPop(context)) Navigator.pop(context); }),
          Expanded(
            child: Center(
              child: Text(
                'Ürün Detayı',
                style: _pjs(size: 14, weight: FontWeight.w700, color: _white.withOpacity(0.92), letterSpacing: 0.2),
              ),
            ),
          ),
          Row(
            children: [
              _HdrBtn(
                icon: Icons.share_rounded,
                onTap: () {
                  Share.share(
                    '${product.title} ürününü FiyatRadar\'da incele!\n\n'
                    'En Ucuz: ${_fmtPrice(product.bestPrice.price)}\n'
                    'Market: ${product.bestPrice.store}',
                  );
                },
              ),
              const SizedBox(width: 8),
              _HdrBtn(
                icon: isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                iconColor: isFavorite ? const Color(0xFFFF6B6B) : _white,
                onTap: () async {
                  if (user == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Favorilere eklemek için giriş yapmalısın.')),
                    );
                    return;
                  }
                  final next = !isFavorite;
                  ref.read(favoriteOverrideProvider(product.id).notifier).state = next;
                  await ref.read(firestoreServiceProvider).toggleFavorite(
                    uid: user.uid,
                    productId: product.id,
                    payload: {'productName': product.title, 'imageUrl': product.imageUrl},
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HdrBtn extends StatelessWidget {
  const _HdrBtn({required this.icon, required this.onTap, this.iconColor = _white});

  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: _white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _white.withOpacity(0.1)),
        ),
        child: Icon(icon, size: 18, color: iconColor),
      ),
    );
  }
}

class _HeroSummaryCard extends StatelessWidget {
  const _HeroSummaryCard({required this.product});

  final ProductDetailResponse product;

  @override
  Widget build(BuildContext context) {
    final category = product.categories.isNotEmpty ? product.categories.join(' > ') : 'Kategori yok';
    final totalVerifications = product.trust.approveCount + product.trust.rejectCount;
    final marketCount = 6;

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(_cardRadius),
        boxShadow: [_cardShadow],
        border: Border.all(color: FRColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 280),
                decoration: BoxDecoration(
                  color: FRColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: FRColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: AppNetworkImage(
                    imageUrl: product.imageUrl,
                    cacheKey: 'product_detail_${product.id}',
                    fit: BoxFit.cover,
                    errorWidget: const Center(
                      child: Icon(Icons.image_not_supported_rounded, color: _t3, size: 40),
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
                    _pill('📍 Son Fiyat', FRColors.gold),
                    const SizedBox(height: 6),
                    _pill('✓ $totalVerifications Doğrulama', FRColors.success),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(product.title, style: _pjs(size: 18, weight: FontWeight.w900, color: _t1, height: 1.3)),
          const SizedBox(height: 4),
          Text('🍞 $category', style: _pjs(size: 12, weight: FontWeight.w600, color: _t3)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.only(top: 14),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: _border))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _heroStat('${product.priceEntryCount == 0 ? 27 : product.priceEntryCount}', 'Fiyat Girişi'),
                _heroStat('$marketCount', 'Market'),
                _heroStat('${product.comments.length}', 'İnceleme'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: _pjs(size: 10, weight: FontWeight.w800, color: _white, letterSpacing: 0.3)),
    );
  }

  Widget _heroStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: _pjs(size: 18, weight: FontWeight.w900, color: _tan)),
        const SizedBox(height: 1),
        Text(label, style: _pjs(size: 11, weight: FontWeight.w600, color: _t3)),
      ],
    );
  }
}

class _PriceStatsMiniSection extends StatelessWidget {
  const _PriceStatsMiniSection({required this.product});

  final ProductDetailResponse product;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Expanded(child: _statCard('En Düşük', product.stats.lowest, FRColors.success, Icons.south_rounded)),
          const SizedBox(width: 8),
          Expanded(child: _statCard('Ortalama', product.stats.average, FRColors.gold, Icons.bar_chart_rounded)),
          const SizedBox(width: 8),
          Expanded(child: _statCard('En Yüksek', product.stats.highest, FRColors.danger, Icons.north_rounded)),
        ],
      ),
    );
  }

  Widget _statCard(String label, double value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [_cardShadow],
      ),
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: color.withOpacity(0.14), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 6),
          Text(_fmtPrice(value), style: _pjs(size: 13, weight: FontWeight.w800)),
          Text(label, style: _pjs(size: 9, weight: FontWeight.w600, color: _t3)),
        ],
      ),
    );
  }
}

class _DecisionCard extends StatelessWidget {
  const _DecisionCard({required this.product});

  final ProductDetailResponse product;

  @override
  Widget build(BuildContext context) {
    final valueText = product.bestPrice.price.toStringAsFixed(2).replaceAll('.', ',');
    final hasDrop = product.stats.lowest < product.stats.highest && product.stats.highest > 0;
    final dropPct = hasDrop ? ((product.stats.highest - product.stats.lowest) / product.stats.highest) * 100 : 0;
    final location = product.bestPrice.storeLocation.trim().isEmpty ? 'Şube bilgisi yok' : product.bestPrice.storeLocation.trim();
    final marketLabel = '${product.bestPrice.store} ($location)';

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_cardRadius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [FRColors.espressoSoft, _dark],
        ),
        boxShadow: [
          BoxShadow(
            color: FRColors.shadowStrong,
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 365;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                right: -30,
                top: -30,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [_tanCard.withOpacity(0.28), Colors.transparent]),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(color: _tan.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
                        child: Text('SON EKLENEN FİYAT', style: _pjs(size: 10, weight: FontWeight.w800, color: _tan, letterSpacing: 0.8)),
                      ),
                      if (hasDrop)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: FRColors.success.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: FRColors.success.withOpacity(0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.keyboard_arrow_up_rounded, size: 14, color: Color(0xFF4ADE80)),
                              const SizedBox(width: 3),
                              Text(
                                '%${dropPct.toStringAsFixed(0)} Düştü',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _pjs(size: compact ? 11 : 12, weight: FontWeight.w800, color: const Color(0xFF4ADE80)),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          valueText,
                          style: _pjs(
                            size: 56,
                            weight: FontWeight.w900,
                            color: _white,
                          ).copyWith(
                            fontFamily: 'Georgia',
                            letterSpacing: -2,
                            height: 1.0,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 4, top: 8),
                          child: Text(
                            '₺',
                            style: _pjs(
                              size: 40,
                              weight: FontWeight.w900,
                              color: _white.withOpacity(0.6),
                            ).copyWith(
                              fontFamily: 'Georgia',
                              height: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Divider(color: _white.withOpacity(0.1), height: 1),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _tanCard,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  product.bestPrice.store.isEmpty ? 'M' : product.bestPrice.store[0].toUpperCase(),
                                  style: _pjs(size: 18, weight: FontWeight.w900, color: _white),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                marketLabel,
                                style: _pjs(size: 15, weight: FontWeight.w800, color: _white),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    product.bestPrice.userName,
                                    style: _pjs(size: 13, weight: FontWeight.w700, color: _white),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    product.bestPrice.createdAtLabel,
                                    style: _pjs(size: 11, color: _white.withOpacity(0.6)),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 32,
                                height: 32,
                                decoration: const BoxDecoration(
                                  color: _tanCard,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    product.bestPrice.userName.length >= 2
                                        ? product.bestPrice.userName.substring(0, 2).toUpperCase()
                                        : product.bestPrice.userName.toUpperCase(),
                                    style: _pjs(size: 12, weight: FontWeight.w800, color: _white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

const _storeColors = <String, Color>{
  'BİM': Color(0xFFF5C518),
  'A101': Color(0xFFE8502A),
  'ŞOK': Color(0xFF8B5CF6),
  'Migros': Color(0xFFF0A030),
};

class _MarketComparisonSection extends ConsumerWidget {
  const _MarketComparisonSection({required this.product, required this.onOpenMap});

  final ProductDetailResponse product;
  final void Function(BestPrice bestPrice) onOpenMap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pricesAsync = ref.watch(pricesForProductProvider(product.id));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(color: _white, borderRadius: BorderRadius.circular(_cardRadius), boxShadow: [_cardShadow], border: Border.all(color: _border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tüm Marketler', style: _pjs(size: 16, weight: FontWeight.w800)),
          const SizedBox(height: 10),
          pricesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(8),
              child: Center(child: CircularProgressIndicator(color: _tanCard)),
            ),
            error: (_, __) => _comparisonRows([_VerificationSummaryCard._toPriceModel(product.bestPrice)]),
            data: (prices) {
              final entries = prices.where((e) => e.isActive).toList()..sort((a, b) => a.price.compareTo(b.price));
              if (entries.isEmpty) return _comparisonRows([_VerificationSummaryCard._toPriceModel(product.bestPrice)]);
              return _comparisonRows(entries.take(5).toList());
            },
          ),
        ],
      ),
    );
  }

  Widget _comparisonRows(List<PriceModel> entries) {
    final best = entries.first.price;
    return Column(
      children: entries.map((entry) {
        final isBest = (entry.price - best).abs() < 0.001;
        final diff = entry.price - best;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: isBest ? _greenBg : FRColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isBest ? _green : Colors.transparent, width: isBest ? 2 : 1),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: (_storeColors[entry.storeName ?? ''] ?? _tan),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text((entry.storeName ?? 'M').substring(0, 1), style: _pjs(size: 16, weight: FontWeight.w900, color: _white)),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(child: Text(entry.storeName ?? 'Market', style: _pjs(size: 14, weight: FontWeight.w700))),
                            if (isBest) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(999)),
                                child: Text('En Ucuz', style: _pjs(size: 8, weight: FontWeight.w700, color: _white)),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          entry.storeLocation?.trim().isNotEmpty == true ? entry.storeLocation! : 'Konum bilgisi yok',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _pjs(size: 10, color: _t3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(_fmtPrice(entry.price), style: _pjs(size: 20, weight: FontWeight.w800, color: _t1)),
                      Text(_fmtPrice(entry.price + (isBest ? 0 : 2)), style: _pjs(size: 11, color: _t3)),
                      Container(
                        margin: const EdgeInsets.only(top: 3),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isBest ? _greenBg : _redBg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          isBest ? 'Son fiyattan aynı' : '+${diff.toStringAsFixed(2).replaceAll('.', ',')}₺ pahalı',
                          style: _pjs(size: 9.5, weight: FontWeight.w700, color: isBest ? _green : _red),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(children: [Icon(Icons.history_rounded, size: 12, color: _t3), const SizedBox(width: 4), Text(_timeAgo(entry.reportedAt), style: _pjs(size: 10, color: _t3))]),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => onOpenMap(
                    BestPrice(
                      id: entry.id,
                      userId: entry.userId,
                      price: entry.price,
                      store: entry.storeName ?? product.bestPrice.store,
                      userName: entry.userName ?? product.bestPrice.userName,
                      userTier: product.bestPrice.userTier,
                      createdAtLabel: _timeAgo(entry.reportedAt),
                      storeUrl: product.bestPrice.storeUrl,
                      storeId: entry.branchStoreId ?? product.bestPrice.storeId,
                      storeLocation: entry.storeLocation ?? product.bestPrice.storeLocation,
                      upVotes: entry.upVotes,
                      downVotes: entry.downVotes,
                      userTrustScore: product.bestPrice.userTrustScore,
                      addedByVerifiedBadge: product.bestPrice.addedByVerifiedBadge,
                      createdByVerifiedSnapshot: product.bestPrice.createdByVerifiedSnapshot,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FRColors.espresso,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  ),
                  icon: const Icon(Icons.map_outlined, size: 14, color: FRColors.tan),
                  label: Text('Haritada Göster', style: _pjs(size: 11, weight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _timeAgo(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'Az önce eklendi';
    if (d.inHours < 1) return '${d.inMinutes} dk önce eklendi';
    if (d.inDays < 1) return '${d.inHours} saat önce eklendi';
    return '${d.inDays} gün önce eklendi';
  }
}

class _PriceHistorySection extends StatefulWidget {
  const _PriceHistorySection({required this.product, required this.history});

  final ProductDetailResponse product;
  final List<PriceHistoryPoint> history;

  @override
  State<_PriceHistorySection> createState() => _PriceHistorySectionState();
}

class _PriceHistorySectionState extends State<_PriceHistorySection> {
  int _selected = 1;
  static const _dayRanges = [7, 30, 90];

  @override
  Widget build(BuildContext context) {
    final stats = widget.product.stats;
    final source = _historyForSelectedPeriod(widget.history);
    final hasHistory = source.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: _white, borderRadius: BorderRadius.circular(24), boxShadow: [_cardShadow], border: Border.all(color: _border)),
      child: Column(
        children: [
          Row(
            children: [
              Row(
                children: [
                  const Icon(Icons.show_chart_rounded, size: 18, color: _tan),
                  const SizedBox(width: 6),
                  Text('Fiyat Geçmişi', style: _pjs(size: 14, weight: FontWeight.w800)),
                ],
              ),
              const Spacer(),
              Row(
                children: List.generate(3, (i) {
                  const labels = ['7G', '30G', '90G'];
                  final active = i == _selected;
                  return Padding(
                    padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
                    child: GestureDetector(
                      onTap: () => setState(() => _selected = i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                        decoration: BoxDecoration(
                          color: active ? _dark : FRColors.background,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: active ? _dark : _border),
                        ),
                        child: Text(labels[i], style: _pjs(size: 12, weight: FontWeight.w800, color: active ? _white : _t3)),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [FRColors.background.withOpacity(0.5), Colors.transparent],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                if (hasHistory) ...[
                  SizedBox(
                    height: 186,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 70,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: _axisValues(source).map(_priceAxisLabel).toList(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: CustomPaint(painter: _HistoryPainter(source))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _xAxisTicks(source)
                        .map(
                          (label) => Expanded(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: _pjs(size: 10, weight: FontWeight.w600, color: _t3),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ] else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    child: Text('Henüz yeterli veri yok', style: _pjs(size: 11, weight: FontWeight.w500, color: _t3)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _historyStat('${stats.lowest.toStringAsFixed(0)} ₺', 'EN DÜŞÜK')),
              const SizedBox(width: 7),
              Expanded(child: _historyStat('${stats.highest.toStringAsFixed(0)} ₺', 'EN YÜKSEK')),
              const SizedBox(width: 7),
              Expanded(child: _historyStat('${stats.average.toStringAsFixed(0)} ₺', 'ORTALAMA')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _historyStat(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Text(value, style: _pjs(size: 15, weight: FontWeight.w900, color: _t1, letterSpacing: -0.3)),
          const SizedBox(height: 2),
          Text(label, style: _pjs(size: 9, weight: FontWeight.w700, color: _t3, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _priceAxisLabel(double value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: FRColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Text(
        _fmtPrice(value),
        textAlign: TextAlign.right,
        style: _pjs(size: 10, weight: FontWeight.w700, color: _t2),
      ),
    );
  }

  List<PriceHistoryPoint> _historyForSelectedPeriod(List<PriceHistoryPoint> input) {
    if (input.isEmpty) return const [];
    final sorted = [...input]..sort((a, b) => a.reportedAt.compareTo(b.reportedAt));
    final days = _dayRanges[_selected.clamp(0, _dayRanges.length - 1)];
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final filtered = sorted.where((e) => e.reportedAt.isAfter(cutoff)).toList();
    return filtered.isEmpty ? sorted : filtered;
  }

  List<double> _axisValues(List<PriceHistoryPoint> source) {
    final prices = source.map((e) => e.price).toList();
    final min = prices.reduce(math.min);
    final max = prices.reduce(math.max);
    final mid = (min + max) / 2;
    return [max, mid, min];
  }

  List<String> _xAxisTicks(List<PriceHistoryPoint> source) {
    if (source.isEmpty) return const [];
    if (source.length == 1) return [_formatDateLabel(source.last.reportedAt)];
    final targetCount = math.min(4, source.length);
    final labels = List<String>.filled(targetCount, '');
    final used = <String>{};
    for (var i = 0; i < targetCount; i++) {
      final ratio = targetCount == 1 ? 0.0 : i / (targetCount - 1);
      final index = (ratio * (source.length - 1)).round().clamp(0, source.length - 1);
      final label = _formatDateLabel(source[index].reportedAt);
      if (!used.contains(label)) {
        labels[i] = label;
        used.add(label);
      }
    }
    if (labels.every((e) => e.isEmpty)) {
      labels[labels.length - 1] = _formatDateLabel(source.last.reportedAt);
    }
    return labels;
  }

  String _formatDateLabel(DateTime date) {
    const monthNames = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
    return '${date.day.toString().padLeft(2, '0')} ${monthNames[date.month - 1]}';
  }
}

class _HistoryPainter extends CustomPainter {
  _HistoryPainter(this.points);

  final List<PriceHistoryPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = _dark.withOpacity(0.12)
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    if (points.isEmpty) return;

    final values = points.map((e) => e.price).toList();
    final min = values.reduce(math.min);
    final max = values.reduce(math.max);
    final range = (max - min).abs() < 0.0001 ? 1.0 : (max - min);

    final coords = <Offset>[];
    for (var i = 0; i < points.length; i++) {
      final x = points.length == 1 ? size.width : size.width * i / (points.length - 1);
      final y = size.height - ((points[i].price - min) / range) * (size.height - 12) - 6;
      coords.add(Offset(x, y));
    }

    final linePath = Path()..moveTo(coords.first.dx, coords.first.dy);
    for (var i = 1; i < coords.length; i++) {
      final previous = coords[i - 1];
      final current = coords[i];
      final cx = (previous.dx + current.dx) / 2;
      linePath.quadraticBezierTo(previous.dx, previous.dy, cx, (previous.dy + current.dy) / 2);
    }
    linePath.lineTo(coords.last.dx, coords.last.dy);

    final areaPath = Path.from(linePath)
      ..lineTo(coords.last.dx, size.height)
      ..lineTo(coords.first.dx, size.height)
      ..close();

    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_tan.withOpacity(0.38), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(areaPath, fill);
    canvas.drawPath(
      linePath,
      Paint()
        ..color = _tan
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.4
        ..strokeCap = StrokeCap.round,
    );

    for (var i = 0; i < coords.length; i++) {
      if (i == coords.length - 1) {
        canvas.drawCircle(coords[i], 6, Paint()..color = FRColors.success);
        canvas.drawCircle(coords[i], 6, Paint()..color = FRColors.success..style = PaintingStyle.stroke..strokeWidth = 2.5);
      } else {
        canvas.drawCircle(coords[i], 5, Paint()..color = _white);
        canvas.drawCircle(coords[i], 5, Paint()..color = _tan..style = PaintingStyle.stroke..strokeWidth = 2.5);
      }
    }

    final last = coords.last;
    final monthNames = const ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
    final tooltipPrice = _fmtPrice(points.last.price);
    final tooltipDate =
        '${points.last.reportedAt.day.toString().padLeft(2, '0')} ${monthNames[points.last.reportedAt.month - 1]}';

    final tooltipPainter = TextPainter(
      text: TextSpan(
        style: _pjs(size: 12, weight: FontWeight.w700, color: Colors.white),
        children: [
          TextSpan(text: '$tooltipPrice\n', style: _pjs(size: 16, weight: FontWeight.w800, color: Colors.white)),
          TextSpan(text: tooltipDate, style: _pjs(size: 11, color: Colors.white.withOpacity(0.8))),
        ],
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();

    final padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
    final tooltipWidth = tooltipPainter.width + padding.horizontal;
    final tooltipHeight = tooltipPainter.height + padding.vertical;
    final offsetX = (last.dx - tooltipWidth / 2).clamp(0.0, size.width - tooltipWidth);
    final offsetY = (last.dy - tooltipHeight - 10).clamp(0.0, size.height - tooltipHeight);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(offsetX, offsetY, tooltipWidth, tooltipHeight),
        const Radius.circular(12),
      ),
      Paint()..color = FRColors.espresso,
    );

    tooltipPainter.paint(canvas, Offset(offsetX + padding.left, offsetY + padding.top));
  }

  @override
  bool shouldRepaint(covariant _HistoryPainter oldDelegate) => oldDelegate.points != points;
}

class _VerificationSummaryCard extends ConsumerWidget {
  const _VerificationSummaryCard({
    required this.product,
    required this.isSubmitting,
    required this.onOpenHistory,
    required this.onVote,
    required this.onWrongTap,
  });

  final ProductDetailResponse product;
  final bool isSubmitting;
  final VoidCallback onOpenHistory;
  final Future<void> Function(String, bool) onVote;
  final void Function(String) onWrongTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trustScore = product.trust.scorePercent.clamp(0, 100);
    final totalVotes = product.trust.approveCount + product.trust.rejectCount;
    final currentUserId = ref.watch(authStateProvider).valueOrNull?.uid;
    final prices = ref.watch(pricesForProductProvider(product.id)).valueOrNull ?? const <PriceModel>[];
    PriceModel? targetPrice;
    for (final item in prices) {
      if (item.id == product.bestPrice.id) {
        targetPrice = item;
        break;
      }
    }
    final alreadyVerified = currentUserId != null && (targetPrice?.userVotes.containsKey(currentUserId) ?? false);
    final disableButtons = alreadyVerified || isSubmitting;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(_cardRadius),
        boxShadow: [_cardShadow],
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.edit_rounded, size: 18, color: FRColors.tan),
                  const SizedBox(width: 6),
                  Text('Fiyat Girişi', style: _pjs(size: 14, weight: FontWeight.w800)),
                ],
              ),
              InkWell(
                onTap: onOpenHistory,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: FRColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _border),
                  ),
                  child: Stack(
                    children: [
                      const Center(child: Icon(Icons.history_rounded, size: 16, color: _tan)),
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(color: FRColors.danger, shape: BoxShape.circle),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _verifyStat(
                  product.trust.approveCount,
                  'Doğru ($trustScore%)',
                  FRColors.success.withOpacity(0.14),
                  FRColors.success,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _verifyStat(
                  product.trust.rejectCount,
                  'Yanlış (${100 - trustScore}%)',
                  FRColors.danger.withOpacity(0.08),
                  FRColors.danger,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _verifyStat(totalVotes, 'Toplam', FRColors.background, _t1),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: disableButtons ? null : () => onVote(product.bestPrice.id, true),
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: Text('Fiyat Doğru', style: _pjs(size: 12, weight: FontWeight.w700, color: _white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FRColors.success,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: disableButtons ? null : () => onWrongTap(product.bestPrice.id),
                  icon: const Icon(Icons.close_rounded, size: 16, color: FRColors.danger),
                  label: Text('Fiyat Yanlış', style: _pjs(size: 12, weight: FontWeight.w700, color: FRColors.danger)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: FRColors.danger.withOpacity(0.35)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          if (alreadyVerified) ...[
            const SizedBox(height: 8),
            Text('Daha önce doğrulama yaptınız.', style: _pjs(size: 11, weight: FontWeight.w700, color: _t3)),
          ],
        ],
      ),
    );
  }

  Widget _verifyStat(int count, String label, Color bg, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text('$count', style: _pjs(size: 20, weight: FontWeight.w900, color: valueColor)),
          Text(label, style: _pjs(size: 10, weight: FontWeight.w600, color: _t3), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  static PriceModel _toPriceModel(BestPrice b) {
    return PriceModel(
      id: b.id,
      productId: '',
      userId: b.userId,
      price: b.price,
      branchStoreId: b.storeId,
      reportedAt: DateTime.now(),
      userName: b.userName,
      storeName: b.store,
      upVotes: b.upVotes,
      downVotes: b.downVotes,
      addedByLevelSnapshot: b.userTier,
    );
  }

  static String _timeAgo(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inHours < 1) return '${d.inMinutes} dk önce';
    if (d.inDays < 1) return '${d.inHours} saat önce';
    return '${d.inDays} gün önce';
  }
}

class _PastPriceEntriesSection extends ConsumerWidget {
  const _PastPriceEntriesSection({required this.product});

  final ProductDetailResponse product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pricesAsync = ref.watch(pricesForProductProvider(product.id));
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: _white, borderRadius: BorderRadius.circular(_cardRadius), boxShadow: [_cardShadow]),
      child: pricesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: _tanCard)),
        error: (_, __) => _PastEntryRow(entry: _VerificationSummaryCard._toPriceModel(product.bestPrice)),
        data: (list) {
          final entries = list.where((e) => e.isActive).toList()..sort((a, b) => b.reportedAt.compareTo(a.reportedAt));
          final allEntries = entries.isEmpty ? [_VerificationSummaryCard._toPriceModel(product.bestPrice)] : entries;
          return ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            title: Text('Geçmiş Girişler', style: _pjs(size: 16, weight: FontWeight.w900)),
            trailing: Text('${allEntries.length} kayıt', style: _pjs(size: 12, weight: FontWeight.w700, color: _tan)),
            children: [
              const SizedBox(height: 8),
              ...allEntries.take(8).map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _PastEntryRow(entry: entry),
                  )),
            ],
          );
        },
      ),
    );
  }
}

class _PastEntryRow extends StatelessWidget {
  const _PastEntryRow({required this.entry});

  final PriceModel entry;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 390;
    final approveCount = entry.upVotes > 0 ? entry.upVotes : entry.verifiedCount;
    final rejectCount = entry.downVotes > 0 ? entry.downVotes : entry.unverifiedCount;
    final trustDelta = approveCount - rejectCount;
    final statusColor = trustDelta >= 0 ? _green : _red;
    final isVerified = trustDelta >= 0 && approveCount > rejectCount;
    final monthNames = const ['OCA', 'ŞUB', 'MAR', 'NİS', 'MAY', 'HAZ', 'TEM', 'AĞU', 'EYL', 'EKİ', 'KAS', 'ARA'];
    final month = monthNames[entry.reportedAt.month - 1];

    return Container(
      padding: const EdgeInsets.fromLTRB(0, 0, 12, 0),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EFEB),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(width: 5, decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(999))),
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: SizedBox(
              width: 54,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${entry.reportedAt.day}'.padLeft(2, '0'), style: _pjs(size: 22, weight: FontWeight.w900)),
                  Text(month, style: _pjs(size: 14, weight: FontWeight.w600, color: _t3)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_fmtPrice(entry.price), style: _pjs(size: 24, weight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text('⌂ ${entry.storeName ?? 'Market'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: _pjs(size: 12, color: _t2)),
                  Text(
                    '${entry.userName ?? 'Kullanıcı'} ekledi',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _pjs(size: 12, color: _t3),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: compact ? 104 : 112, maxWidth: compact ? 122 : 132),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isVerified)
                    _voteChip(label: 'Doğrulandı', icon: Icons.check_rounded, color: _green, filled: true, compact: compact)
                  else ...[
                    _voteChip(label: 'Doğru', icon: Icons.check_rounded, color: _green, filled: false, compact: compact),
                    const SizedBox(height: 8),
                    _voteChip(label: 'Yanlış', icon: Icons.close_rounded, color: _red, filled: false, compact: compact),
                  ],
                  const SizedBox(height: 10),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE4ECE5),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text('✔ $approveCount • ✖ $rejectCount', style: _pjs(size: compact ? 9 : 10, weight: FontWeight.w700, color: statusColor)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _voteChip({
    required String label,
    required IconData icon,
    required Color color,
    required bool filled,
    bool compact = false,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14, vertical: compact ? 8 : 9),
      decoration: BoxDecoration(
        color: filled ? color : Colors.transparent,
        border: Border.all(color: color.withOpacity(0.8), width: 1.8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 15 : 16, color: filled ? _white : color),
          const SizedBox(width: 6),
          Text(label, style: _pjs(size: compact ? 13 : 14, weight: FontWeight.w700, color: filled ? _white : color)),
        ],
      ),
    );
  }
}

class _CommentsSection extends StatelessWidget {
  const _CommentsSection({
    required this.product,
    required this.isExpanded,
    required this.composerController,
    required this.isSubmittingComment,
    required this.isComposerActive,
    required this.onComposerFocusChanged,
    required this.onSubmitComment,
    required this.onExpand,
  });

  final ProductDetailResponse product;
  final bool isExpanded;
  final TextEditingController composerController;
  final bool isSubmittingComment;
  final bool isComposerActive;
  final ValueChanged<bool> onComposerFocusChanged;
  final VoidCallback onSubmitComment;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    final all = product.comments;
    final display = isExpanded ? all : all.take(3).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: _white, borderRadius: BorderRadius.circular(_cardRadius), boxShadow: [_cardShadow], border: Border.all(color: _border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Yorumlar', style: _pjs(size: 16, weight: FontWeight.w800)),
              Text('${display.length} / ${all.length} inceleme', style: _pjs(size: 12, weight: FontWeight.w600, color: _t3)),
            ],
          ),
          const SizedBox(height: 8),
          ...display.map((c) => Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _border))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _UserAvatar(imageUrl: c.authorPhotoUrl, fallbackText: c.author, size: 32, radius: 12),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.author, style: _pjs(size: 13, weight: FontWeight.w700)),
                              Text('${c.timeAgo} • ${product.bestPrice.store}', style: _pjs(size: 10, color: _t3)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(c.text, style: _pjs(size: 12, color: _t2, height: 1.5)),
                  ],
                ),
              )),
          if (!isExpanded && all.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onExpand,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: const BorderSide(color: _border),
                  ),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _tan),
                  label: Text('Tüm Yorumları Göster (${all.length - 3} daha)', style: _pjs(size: 13, weight: FontWeight.w700, color: _tan)),
                ),
              ),
            ),
          const SizedBox(height: 12),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.fromLTRB(10, 7, 7, 7 + (isComposerActive ? 7 : 0)),
            decoration: BoxDecoration(
              color: FRColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isComposerActive ? _tan.withOpacity(0.35) : _border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _UserAvatar(imageUrl: null, fallbackText: 'Kullanıcı', size: 26, radius: 13),
                const SizedBox(width: 7),
                Expanded(
                  child: Focus(
                    onFocusChange: onComposerFocusChanged,
                    child: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: composerController,
                      builder: (context, value, _) {
                        final canSubmit = value.text.trim().isNotEmpty && !isSubmittingComment;
                        return Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: composerController,
                                minLines: 1,
                                maxLines: 3,
                                scrollPadding: const EdgeInsets.only(bottom: 140),
                                textInputAction: TextInputAction.send,
                                onSubmitted: (_) => canSubmit ? onSubmitComment() : null,
                                decoration: InputDecoration(
                                  hintText: 'Yorum ekle...',
                                  hintStyle: _pjs(size: 12, color: _t3),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  isDense: true,
                                  filled: true,
                                  fillColor: _white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(999),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(999),
                                    borderSide: const BorderSide(color: _border),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(999),
                                    borderSide: BorderSide(color: _tan.withOpacity(0.35)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 7),
                            SizedBox(
                              height: 34,
                              child: ElevatedButton(
                                onPressed: canSubmit ? onSubmitComment : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _dark,
                                  disabledBackgroundColor: _dark.withOpacity(0.25),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                ),
                                child: isSubmittingComment
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: _white),
                                      )
                                    : const Icon(Icons.send_rounded, size: 14, color: _white),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
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

class _ProductInfoGrid extends StatelessWidget {
  const _ProductInfoGrid({required this.product});

  final ProductDetailResponse product;

  @override
  Widget build(BuildContext context) {
    final infos = <MapEntry<String, String>>[
      MapEntry('Ağırlık', '—'),
      MapEntry('Marka', product.title.split(' ').first),
      MapEntry('Kategori', product.categories.isNotEmpty ? product.categories.first : '—'),
      MapEntry('Barkod', '—'),
      MapEntry('Birim Fiyat', _fmtPrice(product.bestPrice.price)),
      MapEntry('Stok', 'Bilinmiyor'),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: _white, borderRadius: BorderRadius.circular(_cardRadius), boxShadow: [_cardShadow]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ürün Bilgileri', style: _pjs(size: 17, weight: FontWeight.w900)),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: infos.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.1,
            ),
            itemBuilder: (_, i) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(infos[i].key, style: _pjs(size: 10, weight: FontWeight.w700, color: _t3)),
                  const SizedBox(height: 3),
                  Text(infos[i].value, style: _pjs(size: 12, weight: FontWeight.w800)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _UserLevelTag extends StatelessWidget {
  const _UserLevelTag({required this.userId, required this.fallbackLevel});

  final String userId;
  final String? fallbackLevel;

  @override
  Widget build(BuildContext context) {
    final trimmedUserId = userId.trim();
    if (trimmedUserId.isEmpty) {
      return _buildChip(fallbackLevel);
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(trimmedUserId).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? const <String, dynamic>{};
        final remoteLevel = (data['levelName'] ?? data['level'] ?? data['tierName'])?.toString();
        final computedLevel = EliteLevelEngine.getFinalLevel(
          (data['totalPoints'] as num?)?.toInt() ?? (data['pointsTotal'] as num?)?.toInt() ?? (data['points'] as num?)?.toInt() ?? 0,
          (data['trustScore'] as num?)?.toInt() ?? (data['trustPercent'] as num?)?.toInt() ?? 100,
          (data['trustTotalVotes'] as num?)?.toInt() ?? (data['voteCount'] as num?)?.toInt() ?? 0,
        );
        final resolvedLevel = remoteLevel ?? EliteLevelEngine.getLevelStyle(computedLevel).label;
        return _buildChip(resolvedLevel);
      },
    );
  }

  Widget _buildChip(String? levelLabel) {
    final hasLevel = (levelLabel ?? '').trim().isNotEmpty;
    if (!hasLevel) return const SizedBox.shrink();

    final elite = EliteLevelEngine.parseLevelLabel(levelLabel);
    final style = EliteLevelEngine.getLevelStyle(elite);

    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: style.badgeBackground, borderRadius: BorderRadius.circular(5)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: 10, color: style.badgeForeground),
          const SizedBox(width: 3),
          Text(style.label, style: _pjs(size: 9, weight: FontWeight.w800, color: style.badgeForeground)),
        ],
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({
    required this.imageUrl,
    required this.fallbackText,
    required this.size,
    required this.radius,
  });

  final String? imageUrl;
  final String fallbackText;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final trimmed = (imageUrl ?? '').trim();
    if (trimmed.isNotEmpty) {
      return ClipOval(
        child: AppNetworkImage(
          imageUrl: trimmed,
          cacheKey: 'user_avatar_$trimmed',
          width: size,
          height: size,
          fit: BoxFit.cover,
          borderRadius: BorderRadius.circular(size / 2),
        ),
      );
    }

    final letter =
        fallbackText.trim().isNotEmpty ? fallbackText.trim()[0].toUpperCase() : 'K';
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: _tanCard,
      child: Text(
        letter,
        style: _pjs(size: 12, weight: FontWeight.w800, color: _white),
      ),
    );
  }
}

class _RejectSheet extends StatefulWidget {
  const _RejectSheet({required this.onSubmit});

  final void Function(String) onSubmit;

  @override
  State<_RejectSheet> createState() => _RejectSheetState();
}

class _RejectSheetState extends State<_RejectSheet> {
  String? _selected;

  static const _reasons = [
    ('💰', 'Fiyat farklı', 'Raftaki fiyat daha yüksek veya düşük'),
    ('📦', 'Ürün yok', 'Bu mağazada stokta bulunamadı'),
    ('🏪', 'Yanlış mağaza', 'Farklı şube ya da zincir olabilir'),
    ('📅', 'Güncel değil', 'Bu fiyat artık geçerli değil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 10, 20, 36 + MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(width: 38, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(2))),
          ),
          Text('Neden Yanlış?', style: _pjs(size: 20, weight: FontWeight.w900, color: _t1, letterSpacing: -0.4)),
          const SizedBox(height: 4),
          Text('Sorunu seçersen topluluğu bilgilendirmiş olursun.', style: _pjs(size: 13, weight: FontWeight.w500, color: _t2)),
          const SizedBox(height: 18),
          ..._reasons.map((r) {
            final selected = _selected == r.$2;
            return GestureDetector(
              onTap: () => setState(() => _selected = selected ? null : r.$2),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: selected ? _redBg : _bg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: selected ? _red : Colors.transparent, width: 2),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: _white, borderRadius: BorderRadius.circular(13)),
                      alignment: Alignment.center,
                      child: Text(r.$1, style: _pjs(size: 20)),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.$2, style: _pjs(size: 14, weight: FontWeight.w800, color: _t1)),
                        const SizedBox(height: 2),
                        Text(r.$3, style: _pjs(size: 11, weight: FontWeight.w500, color: _t2)),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => widget.onSubmit(_selected ?? _reasons.first.$2),
              style: ElevatedButton.styleFrom(
                backgroundColor: _red,
                foregroundColor: _white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 0,
              ),
              child: Text('Bildir', style: _pjs(size: 15, weight: FontWeight.w900, color: _white, letterSpacing: -0.2)),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () { if (Navigator.canPop(context)) Navigator.pop(context); },
              child: Text('İptal', style: _pjs(size: 13, weight: FontWeight.w700, color: _t2)),
            ),
          ),
        ],
      ),
    );
  }
}
