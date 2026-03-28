import 'dart:async';
import 'dart:math' as math;

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
  return GoogleFonts.plusJakartaSans(fontSize: s, fontWeight: w, color: c, height: h, letterSpacing: ls);
}

String _fmt(double value) => '${value.toStringAsFixed(2).replaceAll('.', ',')}₺';
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

  @override
  void dispose() {
    _targetPriceController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _launchMap(BestPrice bestPrice) async {
    final query = bestPrice.storeLocation.trim().isNotEmpty ? '${bestPrice.store} ${bestPrice.storeLocation}' : bestPrice.store;
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}');
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harita açılamadı. Lütfen tekrar dene.')));
    }
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yorum eklenemedi. Lütfen tekrar dene.')));
    }
  }

  Future<void> _openAlertSheet(ProductDetailResponse product) async {
    final currentUser = ref.read(authStateProvider).valueOrNull;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alarm kurmak için giriş yapmalısın')));
      return;
    }

    final hasAlert = await ref.read(firestoreServiceProvider).streamHasAlert(product.id, currentUser.uid).first;
    _targetPriceController.text = (product.bestPrice.price * 0.95).toStringAsFixed(2).replaceAll('.', ',');
    _notifyOnEveryPrice = false;

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
              decoration: BoxDecoration(
                color: _dark,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(color: _tan.withOpacity(0.35)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Fiyat Alarmı', style: _t(s: 18, w: FontWeight.w800, c: Colors.white)),
                    const SizedBox(height: 6),
                    Text(
                      hasAlert ? 'Mevcut alarmını güncelle.' : 'Hedef fiyat girerek bildirim al.',
                      style: _t(s: 12, c: Colors.white.withOpacity(0.72)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _targetPriceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                      style: _t(s: 16, w: FontWeight.w700, c: Colors.white),
                      decoration: InputDecoration(
                        prefixText: '₺ ',
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.08),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Switch.adaptive(
                          value: _notifyOnEveryPrice,
                          activeColor: _tan,
                          onChanged: (v) => setModalState(() => _notifyOnEveryPrice = v),
                        ),
                        Expanded(child: Text('Her yeni fiyatta bildirim', style: _t(s: 12, c: Colors.white.withOpacity(0.78)))),
                      ],
                    ),
                    const SizedBox(height: 8),
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
                                notifyOnEveryPrice: _notifyOnEveryPrice,
                              );
                          if (!mounted) return;
                          Navigator.of(sheetContext).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _tan,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
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
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('İtirazınız incelenmek üzere gönderildi.')));
          if (Navigator.canPop(context)) Navigator.pop(context);
        },
      ),
    );
  }

  void _openPastPricesSheet(ProductDetailResponse product) {
    final prices = ref.read(pricesForProductProvider(product.id)).valueOrNull?.where((e) => e.isActive).toList();
    prices?.sort((a, b) => b.reportedAt.compareTo(a.reportedAt));
    final entries = prices ?? const <PriceModel>[];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.9,
        child: Container(
          decoration: const BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            children: [
              Container(width: 42, height: 4, decoration: BoxDecoration(color: _textSoft, borderRadius: BorderRadius.circular(99))),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.history_toggle_off_rounded, color: _tan),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Geçmiş Fiyatları Doğrula', style: _t(s: 17, w: FontWeight.w800))),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                ],
              ),
              const Divider(color: _line),
              Expanded(
                child: entries.isEmpty
                    ? Center(
                        child: Text('Doğrulanabilir geçmiş fiyat bulunamadı.', style: _t(s: 13, c: _textSoft)),
                      )
                    : ListView.separated(
                        itemCount: math.min(entries.length, 12),
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _HistoryPriceRow(entry: entries[i]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productDetailProvider(widget.productId));
    final notifier = ref.read(productDetailProvider(widget.productId).notifier);
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    if (state.isLoading) {
      return const Scaffold(backgroundColor: _bg, body: Center(child: CircularProgressIndicator(color: _tan)));
    }
    if (state.error != null) {
      return Scaffold(backgroundColor: _bg, body: Center(child: Text(state.error!, style: _t())));
    }

    final product = state.data!;
    final bottomPadding = keyboardVisible ? MediaQuery.of(context).viewInsets.bottom + 28 : 130.0;

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyHeaderDelegate(
                  minExtent: MediaQuery.of(context).padding.top + 68,
                  maxExtent: MediaQuery.of(context).padding.top + 68,
                  child: _TopHeader(product: product),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _HeroSection(product: product),
                    const SizedBox(height: 16),
                    _LastPriceCard(product: product),
                    const SizedBox(height: 12),
                    _StatsStrip(product: product),
                    const SizedBox(height: 12),
                    _VerificationSection(
                      product: product,
                      isSubmittingVote: state.isSubmittingVote,
                      onOpenHistory: () => _openPastPricesSheet(product),
                      onVote: (priceId, isApproved) async {
                        final user = ref.read(authStateProvider).valueOrNull;
                        if (user == null) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Oy vermek için giriş yapmalısın.')));
                          return;
                        }
                        final result = await notifier.votePrice(priceId: priceId, isApproved: isApproved);
                        if (!mounted || result == null) return;
                        if (result.status == PriceVoteStatus.alreadyVoted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bu fiyatı zaten doğruladın')));
                        } else if (result.status == PriceVoteStatus.selfVoteBlocked) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kendi eklediğin fiyatı doğrulayamazsın')));
                        }
                      },
                      onWrongTap: _showRejectModal,
                    ),
                    const SizedBox(height: 12),
                    _HistoryChartCard(product: product, history: state.history),
                    const SizedBox(height: 12),
                    _MarketsSection(product: product, onOpenMap: _launchMap),
                    const SizedBox(height: 12),
                    _CommentsSection(
                      comments: product.comments,
                      isExpanded: _showAllComments,
                      controller: _commentController,
                      isSubmitting: state.isSubmittingComment,
                      onToggleAll: () => setState(() => _showAllComments = true),
                      onSubmit: () => _submitComment(notifier),
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
              opacity: keyboardVisible ? 0 : 1,
              duration: const Duration(milliseconds: 180),
              child: IgnorePointer(
                ignoring: keyboardVisible,
                child: _StickyActionBar(
                  onAlert: () => _openAlertSheet(product),
                  onMap: () => _launchMap(product.bestPrice),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  _StickyHeaderDelegate({required this.minExtent, required this.maxExtent, required this.child});

  @override
  final double minExtent;

  @override
  final double maxExtent;

  final Widget child;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;

  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) => oldDelegate.child != child;
}

class _TopHeader extends ConsumerWidget {
  const _TopHeader({required this.product});

  final ProductDetailResponse product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final override = ref.watch(favoriteOverrideProvider(product.id));
    final favoriteAsync = ref.watch(isFavoriteProvider(product.id));
    final isFavorite = override ?? favoriteAsync.valueOrNull ?? false;

    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 12, left: 16, right: 16, bottom: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_dark, _dark2]),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.16), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          _HeaderBtn(icon: Icons.arrow_back_ios_new_rounded, onTap: () => Navigator.maybePop(context)),
          Expanded(
            child: Center(child: Text('Ürün Detayı', style: _t(s: 16, w: FontWeight.w800, c: Colors.white))),
          ),
          _HeaderBtn(
            icon: Icons.share_rounded,
            onTap: () {
              Share.share(
                '${product.title} ürününü FiyatRadar\'da incele!\n\nEn Ucuz: ${_fmtPrice(product.bestPrice.price)}\nMarket: ${product.bestPrice.store}',
              );
            },
          ),
          const SizedBox(width: 8),
          _HeaderBtn(
            icon: isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            iconColor: isFavorite ? const Color(0xFFFF6B6B) : _tanLight,
            onTap: () async {
              if (user == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Favorilere eklemek için giriş yapmalısın.')));
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
    );
  }
}

class _HeaderBtn extends StatelessWidget {
  const _HeaderBtn({required this.icon, required this.onTap, this.iconColor = _tanLight});

  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Ink(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.product});

  final ProductDetailResponse product;

  @override
  Widget build(BuildContext context) {
    final verifications = product.trust.approveCount + product.trust.rejectCount;
    final category = product.categories.isEmpty ? 'Kategori yok' : product.categories.join(' > ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(color: _surfaceAlt, borderRadius: BorderRadius.circular(16), border: Border.all(color: _line)),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AppNetworkImage(
                      imageUrl: product.imageUrl,
                      cacheKey: 'product_detail_${product.id}',
                      fit: BoxFit.cover,
                      errorWidget: const Center(child: Icon(Icons.image_not_supported_rounded, color: _textSoft, size: 38)),
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
                    _pill('📍 Son Fiyat', _amber),
                    const SizedBox(height: 6),
                    _pill('✓ $verifications Doğrulama', _green),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(product.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: _t(s: 18, w: FontWeight.w800, h: 1.35)),
          const SizedBox(height: 4),
          Text('🍞 $category', maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(s: 12, w: FontWeight.w600, c: _textSoft)),
          const SizedBox(height: 14),
          Container(
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: _line))),
            padding: const EdgeInsets.only(top: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _heroStat('${product.priceEntryCount}', 'Fiyat Girişi'),
                _heroStat('6', 'Market'),
                _heroStat('${product.comments.length}', 'İnceleme'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
        child: Text(label, style: _t(s: 10, w: FontWeight.w800, c: Colors.white, ls: 0.2)),
      );

  Widget _heroStat(String value, String label) => Column(
        children: [
          Text(value, style: _t(s: 18, w: FontWeight.w800, c: _tan)),
          const SizedBox(height: 2),
          Text(label, style: _t(s: 11, w: FontWeight.w600, c: _textSoft)),
        ],
      );
}

class _LastPriceCard extends StatelessWidget {
  const _LastPriceCard({required this.product});

  final ProductDetailResponse product;

  @override
  Widget build(BuildContext context) {
    final dropPct = product.stats.highest <= 0 ? 0 : (((product.stats.highest - product.bestPrice.price) / product.stats.highest) * 100).round();
    final initials = _initials(product.bestPrice.userName);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Son Eklenen Fiyat', style: _t(s: 12, w: FontWeight.w700, c: _textSoft)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: _greenBg, borderRadius: BorderRadius.circular(999), border: Border.all(color: _green.withOpacity(0.16))),
                child: Row(
                  children: [
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: _green),
                    Text('%$dropPct Düştü', style: _t(s: 11, w: FontWeight.w700, c: _green)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(text: product.bestPrice.price.toStringAsFixed(2).replaceAll('.', ','), style: _t(s: 34, w: FontWeight.w800, c: _text)),
                TextSpan(text: ' ₺', style: _t(s: 18, w: FontWeight.w700, c: _textSoft)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: _line, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('🛒', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${product.bestPrice.store}${product.bestPrice.storeLocation.isNotEmpty ? ' (${product.bestPrice.storeLocation})' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _t(s: 13, w: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: _surfaceAlt, borderRadius: BorderRadius.circular(999)),
                child: Text(initials, style: _t(s: 11, w: FontWeight.w800, c: _textMuted)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${product.bestPrice.userName} • ${product.bestPrice.createdAtLabel}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _t(s: 11, c: _textSoft, w: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsStrip extends StatelessWidget {
  const _StatsStrip({required this.product});

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

  Widget _statCard(String label, double v, Color color, IconData icon) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: _card(),
        child: Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(height: 8),
            Text(_fmt(v), style: _t(s: 12, w: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(s: 10, c: _textSoft, w: FontWeight.w600)),
          ],
        ),
      );
}

class _VerificationSection extends StatelessWidget {
  const _VerificationSection({
    required this.product,
    required this.isSubmittingVote,
    required this.onOpenHistory,
    required this.onVote,
    required this.onWrongTap,
  });

  final ProductDetailResponse product;
  final bool isSubmittingVote;
  final VoidCallback onOpenHistory;
  final Future<void> Function(String priceId, bool isApproved) onVote;
  final ValueChanged<String> onWrongTap;

  @override
  Widget build(BuildContext context) {
    final total = product.trust.approveCount + product.trust.rejectCount;
    final approvePercent = total == 0 ? 0 : ((product.trust.approveCount / total) * 100).round();
    final rejectPercent = total == 0 ? 0 : 100 - approvePercent;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _card(),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.edit_rounded, size: 18, color: _tan),
              const SizedBox(width: 8),
              Text('Fiyat Girişi', style: _t(s: 16, w: FontWeight.w800)),
              const Spacer(),
              InkWell(
                onTap: onOpenHistory,
                borderRadius: BorderRadius.circular(10),
                child: Ink(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(color: _surfaceAlt, borderRadius: BorderRadius.circular(10), border: Border.all(color: _line)),
                  child: const Icon(Icons.history_rounded, size: 18, color: _textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _voteMini('${product.trust.approveCount}', 'Doğru (%$approvePercent)', _green, _greenBg)),
              const SizedBox(width: 8),
              Expanded(child: _voteMini('${product.trust.rejectCount}', 'Yanlış (%$rejectPercent)', _red, _redBg)),
              const SizedBox(width: 8),
              Expanded(child: _voteMini('$total', 'Toplam', _tan, _surfaceAlt)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isSubmittingVote ? null : () => onVote(product.bestPrice.id, true),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: _green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  icon: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                  label: Text('Fiyat Doğru', style: _t(s: 13, w: FontWeight.w800, c: Colors.white)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isSubmittingVote ? null : () => onWrongTap(product.bestPrice.id),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: _red,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                  label: Text('Fiyat Yanlış', style: _t(s: 13, w: FontWeight.w800, c: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _voteMini(String number, String label, Color color, Color bg) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.2))),
        child: Column(
          children: [
            Text(number, style: _t(s: 16, w: FontWeight.w800, c: color)),
            const SizedBox(height: 2),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(s: 10, w: FontWeight.w700, c: _textMuted)),
          ],
        ),
      );
}

class _HistoryChartCard extends StatelessWidget {
  const _HistoryChartCard({required this.product, required this.history});

  final ProductDetailResponse product;
  final List<PriceHistoryPoint> history;

  @override
  Widget build(BuildContext context) {
    final points = history.isNotEmpty
        ? history.take(7).toList()
        : List.generate(
            7,
            (i) => PriceHistoryPoint(
              dateLabel: i == 6 ? 'Bugün' : '${(i + 1) * 5} Mar',
              price: product.stats.highest - ((product.stats.highest - product.bestPrice.price) * (i / 6)),
              reportedAt: DateTime.now().subtract(Duration(days: 30 - i * 5)),
            ),
          );

    final labels = points.map((e) => e.dateLabel).toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: _card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart_rounded, color: _tan, size: 18),
              const SizedBox(width: 7),
              Text('Fiyat Geçmişi', style: _t(s: 16, w: FontWeight.w800)),
              const Spacer(),
              ...['7G', '30G', '90G'].map((e) => Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: e == '30G' ? _dark : _surfaceAlt,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: _line),
                      ),
                      child: Text(e, style: _t(s: 10, w: FontWeight.w700, c: e == '30G' ? Colors.white : _textMuted)),
                    ),
                  )),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 210,
            child: _LineHistoryChart(points: points),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: labels
                .map((e) => Expanded(
                      child: Text(e, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: _t(s: 10, c: _textSoft, w: FontWeight.w600)),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _LineHistoryChart extends StatelessWidget {
  const _LineHistoryChart({required this.points});

  final List<PriceHistoryPoint> points;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _HistoryPainter(points),
      child: Container(),
    );
  }
}

class _HistoryPainter extends CustomPainter {
  _HistoryPainter(this.points);

  final List<PriceHistoryPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final prices = points.map((e) => e.price).toList();
    final maxP = prices.reduce(math.max);
    final minP = prices.reduce(math.min);
    final range = (maxP - minP).abs() < 0.001 ? 1.0 : maxP - minP;

    final grid = Paint()..color = _line;
    for (var i = 0; i < 5; i++) {
      final y = (size.height - 16) * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final pts = <Offset>[];
    for (var i = 0; i < points.length; i++) {
      final x = points.length == 1 ? size.width : i * (size.width / (points.length - 1));
      final normalized = (points[i].price - minP) / range;
      final y = (size.height - 16) - (normalized * (size.height - 16));
      pts.add(Offset(x, y));
    }

    final fillPath = Path()..moveTo(pts.first.dx, size.height);
    for (final p in pts) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath
      ..lineTo(pts.last.dx, size.height)
      ..close();

    final fill = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0x99BF9470), Color(0x00BF9470)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fill);

    final linePath = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      final p0 = pts[i - 1];
      final p1 = pts[i];
      final cx = (p0.dx + p1.dx) / 2;
      linePath.cubicTo(cx, p0.dy, cx, p1.dy, p1.dx, p1.dy);
    }

    final line = Paint()
      ..color = _tan
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawPath(linePath, line);

    final dot = Paint()..color = _tan;
    for (var i = 0; i < pts.length; i++) {
      canvas.drawCircle(pts[i], i == pts.length - 1 ? 5.5 : 4.2, dot);
      canvas.drawCircle(pts[i], i == pts.length - 1 ? 7.5 : 6, Paint()..color = _tan.withOpacity(0.2));
    }
  }

  @override
  bool shouldRepaint(covariant _HistoryPainter oldDelegate) => oldDelegate.points != points;
}

class _MarketsSection extends StatelessWidget {
  const _MarketsSection({required this.product, required this.onOpenMap});

  final ProductDetailResponse product;
  final ValueChanged<BestPrice> onOpenMap;

  @override
  Widget build(BuildContext context) {
    final best = product.bestPrice;
    final mockMarkets = <_MarketView>[
      _MarketView(name: best.store, location: best.storeLocation, price: best.price, isBest: true, when: best.createdAtLabel),
      _MarketView(name: 'A101', location: 'Merkez', price: best.price + 5, when: '2 saat önce'),
      _MarketView(name: 'BİM', location: 'Atatürk Mah.', price: best.price + 10, when: '5 saat önce'),
      _MarketView(name: 'Migros', location: 'AVM', price: best.price + 15, when: '1 gün önce'),
      _MarketView(name: 'Şok', location: 'Yeni Mah.', price: best.price + 20, when: '2 gün önce'),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.store_mall_directory_rounded, size: 18, color: _tan),
              const SizedBox(width: 8),
              Text('Tüm Marketler', style: _t(s: 16, w: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 12),
          ...mockMarkets.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _MarketTile(
                data: e,
                bestPrice: best.price,
                onOpenMap: () => onOpenMap(best),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketView {
  _MarketView({required this.name, required this.location, required this.price, required this.when, this.isBest = false});

  final String name;
  final String location;
  final double price;
  final String when;
  final bool isBest;
}

class _MarketTile extends StatelessWidget {
  const _MarketTile({required this.data, required this.bestPrice, required this.onOpenMap});

  final _MarketView data;
  final double bestPrice;
  final VoidCallback onOpenMap;

  @override
  Widget build(BuildContext context) {
    final diff = data.price - bestPrice;
    final isCheap = diff <= 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: data.isBest ? _green.withOpacity(0.3) : _line),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: _tan, borderRadius: BorderRadius.circular(8)),
                child: Text(data.name.isNotEmpty ? data.name[0].toUpperCase() : '?', style: _t(s: 12, w: FontWeight.w800, c: Colors.white)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(data.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(s: 13, w: FontWeight.w800))),
                        if (data.isBest)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: _greenBg, borderRadius: BorderRadius.circular(999)),
                            child: Text('En Ucuz', style: _t(s: 10, w: FontWeight.w800, c: _green)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(data.location, maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(s: 11, c: _textSoft, w: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_fmt(data.price), style: _t(s: 15, w: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(
                    isCheap ? 'Son fiyattan aynı' : '+${diff.toStringAsFixed(2).replaceAll('.', ',')}₺ pahalı',
                    style: _t(s: 10, w: FontWeight.w700, c: isCheap ? _green : _red),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text('⏱ ${data.when} eklendi', maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(s: 10, c: _textSoft, w: FontWeight.w600)),
              ),
              TextButton.icon(
                onPressed: onOpenMap,
                style: TextButton.styleFrom(
                  backgroundColor: _dark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.map_outlined, size: 14),
                label: Text('Haritada', style: _t(s: 11, w: FontWeight.w700, c: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CommentsSection extends StatelessWidget {
  const _CommentsSection({
    required this.comments,
    required this.isExpanded,
    required this.controller,
    required this.isSubmitting,
    required this.onToggleAll,
    required this.onSubmit,
  });

  final List<ProductComment> comments;
  final bool isExpanded;
  final TextEditingController controller;
  final bool isSubmitting;
  final VoidCallback onToggleAll;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final visible = isExpanded ? comments : comments.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: _tan),
              const SizedBox(width: 8),
              Text('Yorumlar', style: _t(s: 16, w: FontWeight.w800)),
              const Spacer(),
              Text('${visible.length} / ${comments.length} inceleme', style: _t(s: 12, c: _textSoft, w: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          if (visible.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text('Henüz yorum yok. İlk yorumu sen yaz.', style: _t(s: 12, c: _textSoft)),
            )
          else
            ...visible.map((c) => Padding(padding: const EdgeInsets.only(bottom: 10), child: _CommentTile(comment: c))),
          if (!isExpanded && comments.length > 3)
            Center(
              child: TextButton.icon(
                onPressed: onToggleAll,
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                label: Text('Tüm Yorumları Göster (${comments.length - 3} daha)', style: _t(s: 12, w: FontWeight.w700)),
              ),
            ),
          const SizedBox(height: 8),
          _CommentComposer(controller: controller, isSubmitting: isSubmitting, onSubmit: onSubmit),
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
      decoration: BoxDecoration(color: _surfaceAlt, borderRadius: BorderRadius.circular(12), border: Border.all(color: _line)),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: _colorFromHex(comment.avatarBgHex), borderRadius: BorderRadius.circular(999)),
                child: Text(initials, style: _t(s: 12, w: FontWeight.w800, c: _text)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(comment.author, maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(s: 13, w: FontWeight.w800)),
                    Text(comment.timeAgo, maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(s: 11, c: _textSoft, w: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(comment.text, style: _t(s: 13, c: _textMuted, h: 1.45), maxLines: 6, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

class _CommentComposer extends StatelessWidget {
  const _CommentComposer({required this.controller, required this.isSubmitting, required this.onSubmit});

  final TextEditingController controller;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: _surfaceAlt, borderRadius: BorderRadius.circular(12), border: Border.all(color: _line)),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSubmit(),
              decoration: const InputDecoration(
                hintText: 'Yorum yaz...',
                border: InputBorder.none,
                isDense: true,
              ),
              style: _t(s: 13),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: isSubmitting ? null : onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: _dark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              minimumSize: const Size(72, 38),
              elevation: 0,
            ),
            child: isSubmitting
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text('Gönder', style: _t(s: 12, w: FontWeight.w800, c: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _StickyActionBar extends StatelessWidget {
  const _StickyActionBar({required this.onAlert, required this.onMap});

  final VoidCallback onAlert;
  final VoidCallback onMap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [_bg, _bg.withOpacity(0.9), Colors.transparent]),
      ),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _line),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 14, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onAlert,
                icon: const Icon(Icons.notifications_none_rounded, size: 16),
                label: Text('Alarm', style: _t(s: 13, w: FontWeight.w700)),
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
                onPressed: onMap,
                icon: const Icon(Icons.location_on_rounded, color: _tan, size: 16),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _dark,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                label: Text('Markete Git', maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(s: 13, w: FontWeight.w800, c: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryPriceRow extends StatelessWidget {
  const _HistoryPriceRow({required this.entry});

  final PriceModel entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: _surfaceAlt, borderRadius: BorderRadius.circular(14), border: Border.all(color: _line)),
      child: Row(
        children: [
          Container(
            width: 48,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: _line)),
            child: Column(
              children: [
                Text('${entry.reportedAt.day}'.padLeft(2, '0'), style: _t(s: 14, w: FontWeight.w800)),
                Text(_month(entry.reportedAt.month), style: _t(s: 11, c: _textSoft, w: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_fmt(entry.price), style: _t(s: 16, w: FontWeight.w800)),
                Text(entry.storeName ?? 'Market bilgisi yok', maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(s: 12, w: FontWeight.w700, c: _textMuted)),
                Text('${entry.userName ?? 'Kullanıcı'} ekledi', maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(s: 11, c: _textSoft)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              FilledButton.tonal(
                onPressed: () {},
                style: FilledButton.styleFrom(backgroundColor: _greenBg, foregroundColor: _green),
                child: Text('Doğru', style: _t(s: 11, w: FontWeight.w700, c: _green)),
              ),
              const SizedBox(height: 6),
              FilledButton.tonal(
                onPressed: () {},
                style: FilledButton.styleFrom(backgroundColor: _redBg, foregroundColor: _red),
                child: Text('Yanlış', style: _t(s: 11, w: FontWeight.w700, c: _red)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RejectSheet extends StatelessWidget {
  const _RejectSheet({required this.onSubmit});

  final ValueChanged<String> onSubmit;

  @override
  Widget build(BuildContext context) {
    final reasons = const [
      ('price_changed', '💰 Fiyat Değişti'),
      ('out_of_stock', '📦 Ürün Yok'),
      ('wrong_product', '🏷️ Yanlış Ürün'),
      ('expired', '⏰ İndirim Bitti'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 22),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 42, height: 4, decoration: BoxDecoration(color: _textSoft, borderRadius: BorderRadius.circular(99))),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('Neden yanlış?', style: _t(s: 17, w: FontWeight.w800)),
                const Spacer(),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
              ],
            ),
            const SizedBox(height: 8),
            ...reasons.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => onSubmit(e.$1),
                  borderRadius: BorderRadius.circular(12),
                  child: Ink(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(color: _surfaceAlt, borderRadius: BorderRadius.circular(12), border: Border.all(color: _line)),
                    child: Text(e.$2, style: _t(s: 14, w: FontWeight.w700)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

BoxDecoration _card() => BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _line),
      boxShadow: [
        BoxShadow(color: _dark.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
      ],
    );

String _initials(String text) {
  final parts = text.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
  if (parts.isEmpty) return 'FR';
  if (parts.length == 1) return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

String _month(int m) {
  const months = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
  return months[(m - 1).clamp(0, 11)];
}

Color _colorFromHex(String hex) {
  final normalized = hex.replaceAll('#', '').trim();
  if (normalized.length != 6) return const Color(0xFFEDE6DD);
  final value = int.tryParse('FF$normalized', radix: 16);
  return value == null ? const Color(0xFFEDE6DD) : Color(value);
}
