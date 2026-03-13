import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/price_model.dart';
import '../../models/product_detail_api_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/price_provider.dart';
import '../../providers/product_detail_provider.dart';
import '../../providers/product_provider.dart' hide firestoreServiceProvider;
import '../../services/firestore_service.dart';
import '../../utils/level_style.dart';
import '../../utils/level_system.dart';
import '../add_price/add_price_screen.dart';

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
  final _commentController = TextEditingController();
  bool _showAllComments = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _openAddPrice() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddPriceScreen(initialProductId: widget.productId)),
    );
    if (!mounted) return;
    await ref.read(productDetailProvider(widget.productId).notifier).load();
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
            Navigator.pop(context);
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
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productDetailProvider(widget.productId));
    final notifier = ref.read(productDetailProvider(widget.productId).notifier);

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
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 110),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              _ProductCard(product: state.data!),
                              const SizedBox(height: 10),
                              _BestPriceHero(product: state.data!),
                              const SizedBox(height: 10),
                              _StoreGrid(product: state.data!),
                              const SizedBox(height: 10),
                              _PriceHistorySection(product: state.data!, history: state.history),
                              const SizedBox(height: 10),
                              _ContributorCard(product: state.data!),
                              const SizedBox(height: 10),
                              _VerificationSection(
                                product: state.data!,
                                isSubmitting: state.isSubmittingVote,
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
                              const SizedBox(height: 10),
                              _CommentsSection(
                                product: state.data!,
                                controller: _commentController,
                                isExpanded: _showAllComments,
                                onExpand: () => setState(() => _showAllComments = true),
                                onSend: () async {
                                  if (_commentController.text.trim().isEmpty) return;
                                  HapticFeedback.lightImpact();
                                  await notifier.postComment(_commentController.text.trim());
                                  _commentController.clear();
                                },
                                isSubmitting: state.isSubmittingComment,
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
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [_bg, _bg.withOpacity(0.9), Colors.transparent],
                          ),
                        ),
                        child: GestureDetector(
                          onTap: _openAddPrice,
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              color: _dark,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: _dark.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add, color: _white, size: 20),
                                const SizedBox(width: 8),
                                Text('Fiyat Ekle', style: _pjs(size: 15, weight: FontWeight.w700, color: _white)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
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
      decoration: const BoxDecoration(
        color: _dark,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 22,
        left: 20,
        right: 20,
        bottom: 26,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _HdrBtn(icon: Icons.arrow_back_ios_new_rounded, onTap: () => Navigator.pop(context)),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _pjs(size: 17, weight: FontWeight.w800, color: _white, letterSpacing: -0.25),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.bestPrice.store,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _pjs(size: 11, weight: FontWeight.w500, color: _white.withOpacity(0.4)),
                  ),
                ],
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
        decoration: BoxDecoration(color: _white.withOpacity(0.08), borderRadius: BorderRadius.circular(13)),
        child: Icon(icon, size: 18, color: iconColor),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final ProductDetailResponse product;

  @override
  Widget build(BuildContext context) {
    final category = product.categories.isNotEmpty ? product.categories.first : 'GIDA';
    final subtitle = product.bestPrice.store;

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [_cardShadow],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(22)),
            clipBehavior: Clip.antiAlias,
            child: Image.network(
              product.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_rounded, color: _t3),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(color: _tan.withOpacity(0.13), borderRadius: BorderRadius.circular(7)),
                  child: Text(
                    category.toUpperCase(),
                    style: _pjs(size: 10, weight: FontWeight.w800, color: _tan, letterSpacing: 0.6),
                  ),
                ),
                const SizedBox(height: 7),
                Text(product.title, style: _pjs(size: 16, weight: FontWeight.w900, color: _t1, letterSpacing: -0.3)),
                const SizedBox(height: 3),
                Text(subtitle, style: _pjs(size: 12, weight: FontWeight.w500, color: _t2)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _statChip(Icons.people_alt_outlined, '${product.viewCount} kayıt'),
                    _statChip(Icons.bolt_rounded, 'Aktif'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: _t2),
          const SizedBox(width: 5),
          Text(text, style: _pjs(size: 11, weight: FontWeight.w700, color: _t2)),
        ],
      ),
    );
  }
}

class _BestPriceHero extends StatelessWidget {
  const _BestPriceHero({required this.product});

  final ProductDetailResponse product;

  @override
  Widget build(BuildContext context) {
    final price = product.bestPrice.price;
    final whole = price.floor();
    final frac = ((price - whole) * 100).round().toString().padLeft(2, '0');
    final hasDrop = product.stats.lowest < product.stats.highest && product.stats.highest > 0;
    final dropPct = hasDrop ? ((product.stats.highest - product.stats.lowest) / product.stats.highest) * 100 : 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      decoration: BoxDecoration(color: _dark, borderRadius: BorderRadius.circular(28)),
      child: Stack(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(color: _white.withOpacity(0.09), borderRadius: BorderRadius.circular(999)),
                    child: Text(
                      '🏷️ Bu hafta en ucuz'.toUpperCase(),
                      style: _pjs(size: 10, weight: FontWeight.w800, color: _white.withOpacity(0.7), letterSpacing: 0.6),
                    ),
                  ),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(text: '$whole', style: _pjs(size: 42, weight: FontWeight.w900, color: _white, letterSpacing: -1.5)),
                        TextSpan(text: ',$frac ₺', style: _pjs(size: 20, weight: FontWeight.w600, color: _white)),
                      ],
                    ),
                  ),
                  if (hasDrop)
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                      decoration: BoxDecoration(color: _greenBg, borderRadius: BorderRadius.circular(9)),
                      child: Text('▼ %${dropPct.toStringAsFixed(1).replaceAll('.', ',')} düştü',
                          style: _pjs(size: 12, weight: FontWeight.w800, color: _green)),
                    ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(color: _tanCard, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        Text(product.bestPrice.store, style: _pjs(size: 16, weight: FontWeight.w900, color: _white)),
                        const SizedBox(height: 2),
                        Text(product.bestPrice.createdAtLabel,
                            style: _pjs(size: 10, weight: FontWeight.w500, color: _white.withOpacity(0.65))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                    decoration: BoxDecoration(color: _white.withOpacity(0.09), borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: [
                        Icon(Icons.notifications_none_rounded, size: 13, color: _white.withOpacity(0.65)),
                        const SizedBox(width: 6),
                        Text('Alarm kur', style: _pjs(size: 11, weight: FontWeight.w700, color: _white.withOpacity(0.65))),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
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

class _StoreGrid extends ConsumerWidget {
  const _StoreGrid({required this.product});

  final ProductDetailResponse product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pricesAsync = ref.watch(pricesForProductProvider(product.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Mağaza Fiyatları', style: _pjs(size: 17, weight: FontWeight.w900, letterSpacing: -0.3)),
              Text('Tümü →', style: _pjs(size: 12, weight: FontWeight.w700, color: _tan)),
            ],
          ),
        ),
        pricesAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(8),
            child: Center(child: CircularProgressIndicator(color: _tanCard)),
          ),
          error: (_, __) => _tileRow([product.bestPrice], product.bestPrice.price),
          data: (prices) {
            final entries = prices.where((e) => e.isActive).toList()..sort((a, b) => a.price.compareTo(b.price));
            if (entries.isEmpty) return _tileRow([product.bestPrice], product.bestPrice.price);
            final top = entries.take(4).toList();
            final best = top.first.price;
            return _tileRow(top, best);
          },
        ),
      ],
    );
  }

  Widget _tileRow(List<dynamic> list, double best) {
    return Row(
      children: [
        for (var i = 0; i < list.length; i++) ...[
          if (i > 0) const SizedBox(width: 7),
          Expanded(child: _StoreTile(entry: list[i], bestPrice: best)),
        ],
      ],
    );
  }
}

class _StoreTile extends StatelessWidget {
  const _StoreTile({required this.entry, required this.bestPrice});

  final dynamic entry;
  final double bestPrice;

  @override
  Widget build(BuildContext context) {
    final isPriceModel = entry is PriceModel;
    final store = isPriceModel ? ((entry as PriceModel).storeName ?? 'Market') : (entry as BestPrice).store;
    final price = isPriceModel ? (entry as PriceModel).price : (entry as BestPrice).price;
    final isBest = (price - bestPrice).abs() < 0.001;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 13),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isBest ? _dark : Colors.transparent, width: 2),
        boxShadow: [_cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(shape: BoxShape.circle, color: _storeColors[store] ?? _t3),
              ),
              const SizedBox(width: 5),
              Expanded(child: Text(store, maxLines: 1, overflow: TextOverflow.ellipsis, style: _pjs(size: 12, weight: FontWeight.w700))),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _fmtPrice(price),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _pjs(size: 14, weight: FontWeight.w900, color: isBest ? _green : _t1),
          ),
          if (isBest) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: _greenBg, borderRadius: BorderRadius.circular(5)),
              child: Text('EN UCUZ', style: _pjs(size: 8, weight: FontWeight.w800, color: _green, letterSpacing: 0.5)),
            ),
          ],
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final stats = widget.product.stats;
    final drop = stats.highest > 0 ? ((stats.highest - stats.lowest) / stats.highest) * 100 : 0;
    final source = widget.history.isNotEmpty
        ? widget.history
        : [
            PriceHistoryPoint(dateLabel: '5 Mar', price: stats.highest, reportedAt: DateTime.now().subtract(const Duration(days: 20))),
            PriceHistoryPoint(dateLabel: '7 Mar', price: stats.average, reportedAt: DateTime.now().subtract(const Duration(days: 14))),
            PriceHistoryPoint(dateLabel: '9 Mar', price: stats.lowest, reportedAt: DateTime.now().subtract(const Duration(days: 9))),
            PriceHistoryPoint(dateLabel: '11 Mar', price: stats.average, reportedAt: DateTime.now().subtract(const Duration(days: 4))),
            PriceHistoryPoint(dateLabel: 'Bugün', price: widget.product.bestPrice.price, reportedAt: DateTime.now()),
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Text('Fiyat Geçmişi', style: _pjs(size: 17, weight: FontWeight.w900, letterSpacing: -0.3)),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
          decoration: BoxDecoration(color: _tanCard, borderRadius: BorderRadius.circular(28)),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                right: 56,
                top: -24,
                child: Container(width: 88, height: 88, decoration: BoxDecoration(shape: BoxShape.circle, color: _white.withOpacity(0.1))),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                        decoration: BoxDecoration(color: _dark.withOpacity(0.18), borderRadius: BorderRadius.circular(999)),
                        child: Text('📈 Son 30 Gün'.toUpperCase(),
                            style: _pjs(size: 10, weight: FontWeight.w800, color: _white.withOpacity(0.85), letterSpacing: 0.5)),
                      ),
                      const SizedBox(height: 10),
                      Text('%${drop.toStringAsFixed(1).replaceAll('.', ',')} ucuzladı',
                          style: _pjs(size: 21, weight: FontWeight.w900, color: _white, letterSpacing: -0.4)),
                      const SizedBox(height: 5),
                      Text('En iyi alım zamanı bu hafta',
                          style: _pjs(size: 11, weight: FontWeight.w500, color: _white.withOpacity(0.65))),
                    ],
                  ),
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(color: _white.withOpacity(0.18), borderRadius: BorderRadius.circular(15)),
                    child: const Icon(Icons.show_chart_rounded, color: _white, size: 22),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: _white, borderRadius: BorderRadius.circular(24), boxShadow: [_cardShadow]),
          child: Column(
            children: [
              Row(
                children: List.generate(4, (i) {
                  const labels = ['7G', '1A', '3A', '6A'];
                  final active = i == _selected;
                  return Padding(
                    padding: EdgeInsets.only(right: i == 3 ? 0 : 4),
                    child: GestureDetector(
                      onTap: () => setState(() => _selected = i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                        decoration: BoxDecoration(
                          color: active ? _dark : Colors.transparent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(labels[i], style: _pjs(size: 12, weight: FontWeight.w700, color: active ? _white : _t2)),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 10),
              SizedBox(height: 76, width: double.infinity, child: CustomPaint(painter: _HistoryPainter(source))),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  math.min(source.length, 5),
                  (i) => Text(source[i].dateLabel.isEmpty ? '—' : source[i].dateLabel,
                      style: _pjs(size: 9, weight: FontWeight.w600, color: _t3)),
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
        ),
      ],
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
}

class _HistoryPainter extends CustomPainter {
  _HistoryPainter(this.points);

  final List<PriceHistoryPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()..color = _dark.withOpacity(0.05)..strokeWidth = 1;
    for (var i = 1; i <= 3; i++) {
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
      linePath.lineTo(coords[i].dx, coords[i].dy);
    }

    final areaPath = Path.from(linePath)
      ..lineTo(coords.last.dx, size.height)
      ..lineTo(coords.first.dx, size.height)
      ..close();

    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_dark.withOpacity(0.13), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(areaPath, fill);
    canvas.drawPath(
      linePath,
      Paint()
        ..color = _dark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );

    for (var i = 0; i < coords.length; i++) {
      if (i == coords.length - 1) {
        canvas.drawCircle(coords[i], 4.5, Paint()..color = _white);
        canvas.drawCircle(coords[i], 4.5, Paint()..color = _dark..style = PaintingStyle.stroke..strokeWidth = 2.5);
      } else {
        canvas.drawCircle(coords[i], 3, Paint()..color = _dark);
      }
    }

    final last = coords.last;
    final text = TextPainter(
      text: TextSpan(text: _fmtPrice(points.last.price), style: _pjs(size: 9, weight: FontWeight.w700, color: _white)),
      textDirection: TextDirection.ltr,
    )..layout();
    final w = text.width + 10;
    final rect = RRect.fromRectAndRadius(Rect.fromLTWH(last.dx - w / 2, math.max(0, last.dy - 24), w, 16), const Radius.circular(5));
    canvas.drawRRect(rect, Paint()..color = _dark);
    text.paint(canvas, Offset(last.dx - text.width / 2, math.max(0, last.dy - 21)));
  }

  @override
  bool shouldRepaint(covariant _HistoryPainter oldDelegate) => oldDelegate.points != points;
}

class _ContributorCard extends StatelessWidget {
  const _ContributorCard({required this.product});

  final ProductDetailResponse product;

  @override
  Widget build(BuildContext context) {
    final fallbackLevel = LevelStyle.fromLevelLabel(product.bestPrice.userTier);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(color: _white, borderRadius: BorderRadius.circular(24), boxShadow: [_cardShadow]),
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: product.bestPrice.userId.trim().isEmpty
            ? const Stream.empty()
            : FirebaseFirestore.instance.collection('users').doc(product.bestPrice.userId.trim()).snapshots(),
        builder: (_, snap) {
          final data = snap.data?.data() ?? const <String, dynamic>{};
          final name = _resolveName(data, product.bestPrice.userName);
          final level = _resolveLevel(data, product.bestPrice.userTier, fallbackLevel);
          final isVerified = _resolveVerified(data, product.bestPrice);

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('FİYATI EKLEYEN', style: _pjs(size: 9, weight: FontWeight.w700, color: _t3, letterSpacing: 0.5)),
                  const SizedBox(height: 7),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(color: level.badgeBackground, borderRadius: BorderRadius.circular(999)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(level.icon, size: 15, color: level.badgeBorder),
                        const SizedBox(width: 6),
                        Text(name, style: _pjs(size: 14, weight: FontWeight.w800, color: level.badgeForeground)),
                        if (isVerified) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.verified, color: Color(0xFF2B6CB0), size: 15),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const Icon(Icons.outlined_flag_rounded, color: _red, size: 20),
            ],
          );
        },
      ),
    );
  }

  static bool _resolveVerified(Map<String, dynamic> data, BestPrice bestPrice) {
    return data['verifiedBadge'] == true ||
        data['verified'] == true ||
        bestPrice.addedByVerifiedBadge ||
        bestPrice.createdByVerifiedSnapshot;
  }

  static String _resolveName(Map<String, dynamic> d, String fallback) {
    for (final key in ['displayName', 'fullName', 'name', 'userName', 'username']) {
      final v = (d[key] ?? '').toString().trim();
      if (v.isNotEmpty && v.toLowerCase() != 'anonim') return v;
    }
    if (fallback.trim().isNotEmpty) return fallback.trim();
    return 'Kullanıcı';
  }

  static UserLevel _resolveLevel(Map<String, dynamic> d, String fallbackLabel, UserLevel fallback) {
    final pts = (d['totalPoints'] as num?)?.toInt() ?? (d['points'] as num?)?.toInt();
    final trust = ((d['trustScorePercent'] as num?)?.toInt() ?? (d['reliabilityScore'] as num?)?.round())?.clamp(0, 100);
    final votes = (d['trustTotalVotes'] as num?)?.toInt() ?? 0;
    if (pts != null && trust != null) {
      return LevelStyle.fromFinalLevel(totalPoints: pts, trustPercent: trust, totalVotes: votes);
    }
    final explicit = (d['level'] ?? d['levelName'] ?? d['tierName'])?.toString().trim();
    if (explicit != null && explicit.isNotEmpty) return LevelStyle.fromLevelLabel(explicit);
    if (fallbackLabel.trim().isNotEmpty) return LevelStyle.fromLevelLabel(fallbackLabel);
    return fallback;
  }
}

class _VerificationSection extends ConsumerWidget {
  const _VerificationSection({
    required this.product,
    required this.isSubmitting,
    required this.onVote,
    required this.onWrongTap,
  });

  final ProductDetailResponse product;
  final bool isSubmitting;
  final Future<void> Function(String, bool) onVote;
  final void Function(String) onWrongTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pricesAsync = ref.watch(pricesForProductProvider(product.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Fiyat Doğrulama', style: _pjs(size: 17, weight: FontWeight.w900, letterSpacing: -0.3)),
              Text('${product.priceEntryCount} kayıt', style: _pjs(size: 12, weight: FontWeight.w700, color: _tan)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: _white, borderRadius: BorderRadius.circular(24), boxShadow: [_cardShadow]),
          child: pricesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: _tanCard)),
            error: (_, __) => _verificationRow(context, ref, _toPriceModel(product.bestPrice), true),
            data: (list) {
              final entries = list.where((e) => e.isActive).toList()..sort((a, b) => b.reportedAt.compareTo(a.reportedAt));
              final shown = entries.isEmpty ? [_toPriceModel(product.bestPrice)] : entries;
              return Column(
                children: [
                  for (var i = 0; i < shown.length; i++)
                    Container(
                      padding: EdgeInsets.only(top: i == 0 ? 0 : 12, bottom: i == shown.length - 1 ? 0 : 12),
                      decoration: BoxDecoration(
                        border: i == shown.length - 1 ? null : const Border(bottom: BorderSide(color: _border)),
                      ),
                      child: _verificationRow(context, ref, shown[i], false),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _verificationRow(BuildContext context, WidgetRef ref, PriceModel entry, bool fallback) {
    final currentUser = ref.watch(authStateProvider).valueOrNull;
    final voteStream = currentUser == null
        ? const Stream<String?>.empty()
        : ref.watch(firestoreServiceProvider).streamUserVoteValue(entry.id, currentUser.uid);

    return StreamBuilder<String?>(
      stream: voteStream,
      builder: (_, snap) {
        final vote = snap.data;
        final isOwner = currentUser?.uid == entry.userId;
        final hasVoted = vote != null;
        final canVote = currentUser != null && !hasVoted && !isOwner;
        final approveCount = entry.upVotes > 0 ? entry.upVotes : entry.verifiedCount;
        final rejectCount = entry.downVotes > 0 ? entry.downVotes : entry.unverifiedCount;
        final level = LevelStyle.fromLevelLabel(entry.addedByLevelSnapshot);

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(color: _tanCard, borderRadius: BorderRadius.circular(12)),
                      child: Center(
                        child: Text(
                          ((entry.userName ?? 'K').isNotEmpty ? (entry.userName ?? 'K')[0] : 'K').toUpperCase(),
                          style: _pjs(size: 12, weight: FontWeight.w800, color: _white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(entry.userName ?? 'Kullanıcı', style: _pjs(size: 13, weight: FontWeight.w800)),
                            if ((entry.addedByLevelSnapshot ?? '').trim().isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(left: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: level.badgeBackground, borderRadius: BorderRadius.circular(5)),
                                child: Text('${level.emoji} ${level.label}',
                                    style: _pjs(size: 9, weight: FontWeight.w800, color: level.badgeForeground)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text('${entry.storeName ?? 'Market'} · ${_timeAgo(entry.reportedAt)}',
                            style: _pjs(size: 11, weight: FontWeight.w500, color: _t3)),
                      ],
                    ),
                  ],
                ),
                Text(_fmtPrice(entry.price), style: _pjs(size: 18, weight: FontWeight.w900, letterSpacing: -0.4)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _verifyCountInfo(approveCount, rejectCount),
                Row(
                  children: [
                    _voteMiniBtn(
                      label: 'Doğru',
                      icon: Icons.check_rounded,
                      active: vote == 'yes',
                      activeColor: _green,
                      onTap: canVote && !isSubmitting ? () => onVote(entry.id, true) : null,
                    ),
                    const SizedBox(width: 5),
                    _voteMiniBtn(
                      label: 'Yanlış',
                      icon: Icons.close_rounded,
                      active: vote == 'no',
                      activeColor: _red,
                      onTap: canVote && !isSubmitting
                          ? () {
                              onVote(entry.id, false);
                              onWrongTap(entry.id);
                            }
                          : null,
                    ),
                  ],
                ),
              ],
            ),
            if (isOwner)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: _red, size: 13),
                    SizedBox(width: 5),
                    Text('Kendi eklediğin fiyatı doğrulayamazsın', style: _pjs(size: 11, weight: FontWeight.w600, color: _red)),
                  ],
                ),
              ),
            if (currentUser == null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Doğrulama için giriş yapmalısın', style: _pjs(size: 11, weight: FontWeight.w600, color: _t3)),
              ),
          ],
        );
      },
    );
  }

  Widget _verifyCountInfo(int approveCount, int rejectCount) {
    if (approveCount == 0 && rejectCount == 0) {
      return Text('Henüz doğrulama yok', style: _pjs(size: 11, weight: FontWeight.w700, color: _t3));
    }
    return Row(
      children: [
        if (approveCount > 0) _avatarStack(approveCount),
        if (approveCount > 0) const SizedBox(width: 5),
        if (approveCount > 0)
          RichText(
            text: TextSpan(children: [
              TextSpan(text: '$approveCount kişi', style: _pjs(size: 11, weight: FontWeight.w800, color: _green)),
              TextSpan(text: ' doğruladı', style: _pjs(size: 11, weight: FontWeight.w700, color: _t2)),
            ]),
          )
        else
          RichText(
            text: TextSpan(children: [
              TextSpan(text: '$rejectCount kişi', style: _pjs(size: 11, weight: FontWeight.w800, color: _red)),
              TextSpan(text: ' yanlış dedi', style: _pjs(size: 11, weight: FontWeight.w700, color: _red)),
            ]),
          ),
      ],
    );
  }

  Widget _avatarStack(int count) {
    final show = count > 3 ? 3 : count;
    return SizedBox(
      height: 20,
      width: 20 + (show - 1) * 15,
      child: Stack(
        children: List.generate(show, (i) {
          final colors = [_t2, _green, _tanCard];
          final remain = count - 2;
          return Positioned(
            left: i * 15,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: i == 2 && count > 3 ? _t3 : colors[i % colors.length],
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: _white, width: 2),
              ),
              alignment: Alignment.center,
              child: i == 2 && count > 3
                  ? Text('+$remain', style: _pjs(size: 8, weight: FontWeight.w700, color: _white))
                  : null,
            ),
          );
        }),
      ),
    );
  }

  Widget _voteMiniBtn({
    required String label,
    required IconData icon,
    required bool active,
    required Color activeColor,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? (activeColor == _green ? _greenBg : _redBg) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? activeColor.withOpacity(0.25) : _border,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 11, color: active ? activeColor : _t2),
            const SizedBox(width: 4),
            Text(label, style: _pjs(size: 11, weight: FontWeight.w800, color: active ? activeColor : _t2)),
          ],
        ),
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

class _CommentsSection extends StatelessWidget {
  const _CommentsSection({
    required this.product,
    required this.controller,
    required this.isExpanded,
    required this.onExpand,
    required this.onSend,
    required this.isSubmitting,
  });

  final ProductDetailResponse product;
  final TextEditingController controller;
  final bool isExpanded;
  final VoidCallback onExpand;
  final VoidCallback onSend;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    final all = product.comments;
    final display = isExpanded ? all : all.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Yorumlar', style: _pjs(size: 17, weight: FontWeight.w900, letterSpacing: -0.3)),
              Text('Tümü →', style: _pjs(size: 12, weight: FontWeight.w700, color: _tan)),
            ],
          ),
        ),
        ...display.map((c) {
          final level = LevelStyle.fromLevelLabel(c.authorLevel);
          final avatarColor = _tanCard;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: _white, borderRadius: BorderRadius.circular(22), boxShadow: [_cardShadow]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(color: avatarColor, borderRadius: BorderRadius.circular(11)),
                      alignment: Alignment.center,
                      child: Text(c.author.isNotEmpty ? c.author[0].toUpperCase() : 'K',
                          style: _pjs(size: 12, weight: FontWeight.w800, color: _white)),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(c.author, style: _pjs(size: 13, weight: FontWeight.w800, color: _t1)),
                            if (c.authorLevel.trim().isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(left: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: level.badgeBackground, borderRadius: BorderRadius.circular(5)),
                                child: Text('${level.emoji} ${level.label}',
                                    style: _pjs(size: 9, weight: FontWeight.w800, color: level.badgeForeground)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 1),
                        Text(c.timeAgo, style: _pjs(size: 10, weight: FontWeight.w500, color: _t3)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(c.text, style: _pjs(size: 13, weight: FontWeight.w500, color: _t1, height: 1.65)),
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.only(top: 12),
                  decoration: const BoxDecoration(border: Border(top: BorderSide(color: _border))),
                  child: Row(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.thumb_up_alt_outlined, size: 14, color: _t2),
                          const SizedBox(width: 5),
                          Text('0', style: _pjs(size: 12, weight: FontWeight.w700, color: _t2)),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Text('Yanıtla', style: _pjs(size: 12, weight: FontWeight.w700, color: _t3)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
        if (all.length > 2 && !isExpanded)
          TextButton(
            onPressed: onExpand,
            child: Text('Tümü gör →', style: _pjs(size: 12, weight: FontWeight.w700, color: _tan)),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: _white, borderRadius: BorderRadius.circular(22), boxShadow: [_cardShadow]),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: _tanCard, borderRadius: BorderRadius.circular(11)),
                child: const Icon(Icons.person, size: 16, color: _white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                  decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(11)),
                  child: TextField(
                    controller: controller,
                    style: _pjs(size: 13, weight: FontWeight.w500, color: _t1),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'Yorum ekle…',
                      hintStyle: _pjs(size: 13, weight: FontWeight.w500, color: _t3),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: isSubmitting ? null : onSend,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(color: _dark, borderRadius: BorderRadius.circular(11)),
                  child: isSubmitting
                      ? const Padding(
                          padding: EdgeInsets.all(9),
                          child: CircularProgressIndicator(strokeWidth: 2, color: _white),
                        )
                      : const Icon(Icons.send_rounded, size: 13, color: _white),
                ),
              ),
            ],
          ),
        ),
      ],
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
              onPressed: () => Navigator.pop(context),
              child: Text('İptal', style: _pjs(size: 13, weight: FontWeight.w700, color: _t2)),
            ),
          ),
        ],
      ),
    );
  }
}
