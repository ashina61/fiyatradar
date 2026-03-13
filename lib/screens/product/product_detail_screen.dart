import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/product_detail_api_model.dart';
import '../../models/price_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_detail_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/price_provider.dart';
import '../../services/firestore_service.dart';
import '../add_price/add_price_screen.dart';
import '../../utils/level_style.dart';
import '../../utils/level_system.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RENK PALETİ  (v4 HTML ile birebir)
// ─────────────────────────────────────────────────────────────────────────────
const Color _bg       = Color(0xFFECEAE4);
const Color _dark     = Color(0xFF1C1108);
const Color _white    = Color(0xFFFFFFFF);
const Color _tan      = Color(0xFFB88C50);
const Color _tanCard  = Color(0xFFC09A60);
const Color _tanLt    = Color(0xFFF0E8D8);
const Color _green    = Color(0xFF27A85A);
const Color _greenBg  = Color(0x1A27A85A);
const Color _red      = Color(0xFFD93C3C);
const Color _redBg    = Color(0x17D93C3C);
const Color _t1       = Color(0xFF1C1108);
const Color _t2       = Color(0xFF6B5D4E);
const Color _t3       = Color(0xFFA89A8A);
const Color _border   = Color(0x121C1108);

// ─────────────────────────────────────────────────────────────────────────────
// TYPOGRAPHY HELPER
// ─────────────────────────────────────────────────────────────────────────────
TextStyle _pjs({
  double size = 14,
  FontWeight weight = FontWeight.w500,
  Color color = _t1,
  double? height,
  double letterSpacing = 0,
}) => GoogleFonts.plusJakartaSans(
  fontSize: size,
  fontWeight: weight,
  color: color,
  height: height,
  letterSpacing: letterSpacing,
);

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────
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

  Future<void> _launchMap(BestPrice bestPrice) async {
    HapticFeedback.lightImpact();
    final api = ref.read(productDetailApiServiceProvider);
    final payload = await api.resolveStoreNavigation(bestPrice);

    Uri? url;
    if (payload?.coordinates case final coords?) {
      url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${coords.latitude},${coords.longitude}',
      );
    } else {
      final mapsUrl = payload?.mapsUrl?.trim() ?? '';
      if (mapsUrl.isNotEmpty) {
        url = Uri.tryParse(mapsUrl);
      }
      if (url == null) {
        final addr = (payload?.address?.trim().isNotEmpty ?? false)
            ? payload!.address!.trim()
            : (bestPrice.storeLocation.trim().isNotEmpty
                ? bestPrice.storeLocation.trim()
                : bestPrice.store.trim());
        if (addr.isNotEmpty) {
          url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(addr)}');
        }
      }
    }

    if (url == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu market için konum bilgisi bulunamadı')),
      );
      return;
    }
    final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Harita açılırken bir sorun oluştu')));
    }
  }

  void _showRejectModal(String priceId) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RejectSheet(
        onSubmit: (reason) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('İtirazınız incelenmek üzere gönderildi.')));
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(productDetailProvider(widget.productId));
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
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              // 1 — Ürün kartı
                              _ProductCard(
                                product: state.data!,
                                onMapTap: () => _launchMap(state.data!.bestPrice),
                              ),
                              const SizedBox(height: 10),

                              // 2 — En iyi fiyat dark hero
                              _BestPriceHero(product: state.data!),
                              const SizedBox(height: 10),

                              // 3 — Mağaza fiyatları grid
                              _StoreGrid(product: state.data!),
                              const SizedBox(height: 10),

                              // 4 — Fiyat geçmişi
                              _PriceHistorySection(product: state.data!, history: state.history),
                              const SizedBox(height: 10),

                              // 5 — Fiyatı ekleyen kişi
                              _ContributorCard(product: state.data!),
                              const SizedBox(height: 10),

                              // 6 — Fiyat doğrulama (per-price)
                              _VerificationSection(
                                product: state.data!,
                                productId: widget.productId,
                                isSubmitting: state.isSubmittingVote,
                                onVote: (priceId, isApproved) async {
                                  final user = ref.read(authStateProvider).valueOrNull;
                                  if (user == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Oy vermek için giriş yapmalısın.')),
                                    );
                                    return;
                                  }
                                  final ownerUid = state.data!.bestPrice.userId.trim();
                                  if (ownerUid.isNotEmpty && user.uid == ownerUid) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Kendi eklediğin fiyatı doğrulayamazsın')),
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
                                onWrongTap: (priceId) => _showRejectModal(priceId),
                              ),
                              const SizedBox(height: 10),

                              // 7 — Yorumlar
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

                    // FAB — Fiyat Ekle
                    Positioned(
                      bottom: 0, left: 0, right: 0,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
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
                            height: 54,
                            decoration: BoxDecoration(
                              color: _dark,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [BoxShadow(color: _dark.withOpacity(0.28), blurRadius: 20, offset: const Offset(0, 8))],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add, color: _white, size: 20),
                                const SizedBox(width: 8),
                                Text('Fiyat Ekle', style: _pjs(size: 15, weight: FontWeight.w800, color: _white)),
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

// ─────────────────────────────────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _Header extends ConsumerWidget {
  final ProductDetailResponse product;
  const _Header({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final override = ref.watch(favoriteOverrideProvider(product.id));
    final favoriteAsync = ref.watch(isFavoriteProvider(product.id));
    final isFavorite = override ?? favoriteAsync.valueOrNull ?? false;
    final subtitle = [
      if (product.bestPrice.store.trim().isNotEmpty) product.bestPrice.store.trim(),
      if (product.categories.isNotEmpty) product.categories.first,
    ].join(' · ');

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 14,
        left: 20, right: 20, bottom: 24,
      ),
      decoration: const BoxDecoration(
        color: _dark,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: Row(
        children: [
          _HdrBtn(icon: Icons.arrow_back_ios_new_rounded, onTap: () => Navigator.pop(context)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _pjs(size: 17, weight: FontWeight.w800, color: _white, letterSpacing: -0.3),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle.isEmpty ? 'Ürün detayı' : subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _pjs(size: 11, weight: FontWeight.w500, color: _white.withOpacity(0.42)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _HdrBtn(
            icon: Icons.share_rounded,
            onTap: () {
              HapticFeedback.lightImpact();
              Share.share(
                "${product.title} ürününü FiyatRadar'da incele!\n\n"
                "En Ucuz: ${product.bestPrice.price.toStringAsFixed(2)}₺\n"
                "Market: ${product.bestPrice.store}",
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
    );
  }
}

class _HdrBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;
  const _HdrBtn({required this.icon, required this.onTap, this.iconColor = _white});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.09),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// ÜRÜN KARTI
// ─────────────────────────────────────────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final ProductDetailResponse product;
  final VoidCallback onMapTap;
  const _ProductCard({required this.product, required this.onMapTap});

  @override
  Widget build(BuildContext context) {
    return _Card(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Ürün görseli
          Container(
            width: 108, height: 108,
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.network(
              product.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_outlined, color: _t3, size: 32),
            ),
          ),
          const SizedBox(width: 18),

          // Bilgi
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kategori pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: _tan.withOpacity(0.13),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    '${product.categories.isNotEmpty ? product.categories.first.toUpperCase() : 'KATEGORİ'}',
                    style: _pjs(size: 10, weight: FontWeight.w800, color: _tan, letterSpacing: 0.5),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  product.title,
                  style: _pjs(size: 16, weight: FontWeight.w900, color: _t1, height: 1.25, letterSpacing: -0.3),
                ),
                const SizedBox(height: 4),
                Text(
                  '${product.bestPrice.store} · ${product.id}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _pjs(size: 12, weight: FontWeight.w500, color: _t2),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _MetaChip(icon: Icons.people_outline_rounded, label: '${product.priceEntryCount} kayıt'),
                    const SizedBox(width: 6),
                    _MetaChip(icon: Icons.show_chart_rounded, label: 'Aktif'),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: onMapTap,
                      child: _MetaChip(icon: Icons.map_outlined, label: 'Harita', tappable: true),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool tappable;
  const _MetaChip({required this.icon, required this.label, this.tappable = false});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: tappable ? _tan.withOpacity(0.1) : _bg,
          borderRadius: BorderRadius.circular(7),
          border: tappable ? Border.all(color: _tan.withOpacity(0.25)) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: tappable ? _tan : _t2),
            const SizedBox(width: 4),
            Text(label, style: _pjs(size: 10, weight: FontWeight.w700, color: tappable ? _tan : _t2)),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// BEST PRICE HERO (dark)
// ─────────────────────────────────────────────────────────────────────────────
class _BestPriceHero extends StatelessWidget {
  final ProductDetailResponse product;
  const _BestPriceHero({required this.product});

  @override
  Widget build(BuildContext context) {
    final p = product.bestPrice;
    final priceInt  = p.price.floor();
    final priceDec  = ((p.price - priceInt) * 100).round().toString().padLeft(2, '0');
    final dropPct   = product.stats.lowest > 0
        ? ((product.stats.highest - product.stats.lowest) / product.stats.highest * 100).toStringAsFixed(1)
        : null;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _dark,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Stack(
        children: [
          // Arka plan glow
          Positioned(
            right: -20, top: -20,
            child: Container(
              width: 110, height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [_tanCard.withOpacity(0.25), Colors.transparent]),
              ),
            ),
          ),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sol — fiyat
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.09),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '🏷️  Bu hafta en ucuz',
                        style: _pjs(size: 10, weight: FontWeight.w800, color: _white.withOpacity(0.75), letterSpacing: 0.5),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('$priceInt', style: _pjs(size: 44, weight: FontWeight.w900, color: _white, letterSpacing: -2)),
                        Text(',$priceDec₺', style: _pjs(size: 20, weight: FontWeight.w600, color: _white.withOpacity(0.75))),
                      ],
                    ),
                    if (dropPct != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: _greenBg, borderRadius: BorderRadius.circular(9)),
                        child: Text('▼ %$dropPct düştü', style: _pjs(size: 12, weight: FontWeight.w800, color: _green)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Sağ — mağaza + alarm
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(color: _tanCard, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        Text(p.store, style: _pjs(size: 16, weight: FontWeight.w900, color: _white)),
                        const SizedBox(height: 2),
                        Text(p.createdAtLabel, style: _pjs(size: 10, weight: FontWeight.w500, color: _white.withOpacity(0.65))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.09),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.notifications_none_rounded, color: _white.withOpacity(0.65), size: 13),
                          const SizedBox(width: 5),
                          Text('Alarm kur', style: _pjs(size: 11, weight: FontWeight.w700, color: _white.withOpacity(0.65))),
                        ],
                      ),
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

// ─────────────────────────────────────────────────────────────────────────────
// MAĞAZA EN İYİ FİYAT KARTI (storePrices mevcut değil — bestPrice gösteriliyor)
// ─────────────────────────────────────────────────────────────────────────────
const _storeColors = <String, Color>{
  'BİM':         Color(0xFFF5C518),
  'A101':        Color(0xFFE8502A),
  'ŞOK':         Color(0xFF8B5CF6),
  'Migros':      Color(0xFFF0A030),
  'CarrefourSA': Color(0xFF2563EB),
};

class _StoreGrid extends ConsumerWidget {
  final ProductDetailResponse product;
  const _StoreGrid({required this.product});

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
            padding: EdgeInsets.all(12),
            child: Center(child: CircularProgressIndicator(color: _tanCard)),
          ),
          error: (_, __) => _buildRows([product.bestPrice]),
          data: (prices) {
            final active = prices.where((e) => e.isActive).toList();
            active.sort((a, b) => a.price.compareTo(b.price));
            if (active.isEmpty) return _buildRows([product.bestPrice]);
            return _buildRows(active.take(4).toList());
          },
        ),
      ],
    );
  }

  Widget _buildRows(List<dynamic> entries) {
    final bestPrice = entries.first is PriceModel ? (entries.first as PriceModel).price : (entries.first as BestPrice).price;
    return Row(
      children: [
        for (var i = 0; i < entries.length; i++) ...[
          if (i > 0) const SizedBox(width: 7),
          Expanded(child: _StoreTile(entry: entries[i], bestPrice: bestPrice)),
        ],
      ],
    );
  }
}

class _StoreTile extends StatelessWidget {
  final dynamic entry;
  final double bestPrice;
  const _StoreTile({required this.entry, required this.bestPrice});

  @override
  Widget build(BuildContext context) {
    final isPriceModel = entry is PriceModel;
    final store = isPriceModel ? ((entry as PriceModel).storeName ?? 'Market') : (entry as BestPrice).store;
    final price = isPriceModel ? (entry as PriceModel).price : (entry as BestPrice).price;
    final isBest = (price - bestPrice).abs() < 0.001;
    final dot = _storeColors[store] ?? _t3;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 13),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isBest ? _dark : Colors.transparent, width: 2),
        boxShadow: [BoxShadow(color: _dark.withOpacity(0.06), blurRadius: 14, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 7, height: 7, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Expanded(
                child: Text(store, maxLines: 1, overflow: TextOverflow.ellipsis, style: _pjs(size: 12, weight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${price.toStringAsFixed(2)} ₺',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _pjs(size: 14, weight: FontWeight.w900, color: isBest ? _green : _t1, letterSpacing: -0.3),
          ),
          if (isBest) ...[
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: _greenBg, borderRadius: BorderRadius.circular(5)),
              child: Text('EN UCUZ', style: _pjs(size: 8, weight: FontWeight.w800, color: _green, letterSpacing: 0.3)),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FİYAT GEÇMİŞİ
// ─────────────────────────────────────────────────────────────────────────────
class _PriceHistorySection extends StatefulWidget {
  final ProductDetailResponse product;
  final List<PriceHistoryPoint> history;
  const _PriceHistorySection({required this.product, required this.history});

  @override
  State<_PriceHistorySection> createState() => _PriceHistorySectionState();
}

class _PriceHistorySectionState extends State<_PriceHistorySection> {
  int _tab = 1;

  @override
  Widget build(BuildContext context) {
    final windows = [7, 30, 90, 180];
    final days = windows[_tab];
    final all = widget.history.isNotEmpty
        ? widget.history
        : [
            PriceHistoryPoint(dateLabel: 'Bugün', price: widget.product.bestPrice.price, reportedAt: DateTime.now()),
            PriceHistoryPoint(dateLabel: 'Önce', price: widget.product.stats.average, reportedAt: DateTime.now().subtract(const Duration(days: 3))),
          ];
    final minDate = DateTime.now().subtract(Duration(days: days));
    final points = all.where((e) => e.reportedAt.isAfter(minDate)).toList()..sort((a, b) => a.reportedAt.compareTo(b.reportedAt));
    final statsSource = points.isEmpty ? all : points;
    final values = statsSource.map((e) => e.price).toList();
    final low = values.reduce((a, b) => a < b ? a : b);
    final high = values.reduce((a, b) => a > b ? a : b);
    final avg = values.reduce((a, b) => a + b) / values.length;
    final drop = high > 0 ? ((high - low) / high) * 100 : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Text('Fiyat Geçmişi', style: _pjs(size: 17, weight: FontWeight.w900, letterSpacing: -0.3)),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(color: _tanCard, borderRadius: BorderRadius.circular(28)),
          child: Row(
            children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: _dark.withOpacity(0.2), borderRadius: BorderRadius.circular(999)),
                    child: Text('📈 Son ${windows[_tab]} Gün', style: _pjs(size: 10, weight: FontWeight.w800, color: _white.withOpacity(0.85))),
                  ),
                  const SizedBox(height: 10),
                  Text('%${drop.toStringAsFixed(1)} ucuzladı', style: _pjs(size: 21, weight: FontWeight.w900, color: _white, letterSpacing: -0.4)),
                  const SizedBox(height: 5),
                  Text('En iyi alım zamanı bu hafta', style: _pjs(size: 11, weight: FontWeight.w500, color: _white.withOpacity(0.65))),
                ]),
              ),
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(color: _white.withOpacity(0.18), borderRadius: BorderRadius.circular(15)),
                child: const Icon(Icons.show_chart_rounded, color: _white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _Card(
          child: Column(
            children: [
              Row(
                children: List.generate(4, (i) {
                  final label = ['7G', '1A', '3A', '6A'][i];
                  final active = i == _tab;
                  return Padding(
                    padding: EdgeInsets.only(right: i == 3 ? 0 : 4),
                    child: GestureDetector(
                      onTap: () => setState(() => _tab = i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                        decoration: BoxDecoration(
                          color: active ? _dark : Colors.transparent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(label, style: _pjs(size: 12, weight: FontWeight.w700, color: active ? _white : _t2)),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              SizedBox(height: 90, width: double.infinity, child: CustomPaint(painter: _HistoryChartPainter(points))),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _StatBox(label: 'En Düşük', value: '${low.toStringAsFixed(0)} ₺', color: _t1)),
                  const SizedBox(width: 7),
                  Expanded(child: _StatBox(label: 'En Yüksek', value: '${high.toStringAsFixed(0)} ₺', color: _t1)),
                  const SizedBox(width: 7),
                  Expanded(child: _StatBox(label: 'Ortalama', value: '${avg.toStringAsFixed(0)} ₺', color: _t1)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HistoryChartPainter extends CustomPainter {
  final List<PriceHistoryPoint> points;
  _HistoryChartPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paintGrid = Paint()..color = _border..strokeWidth = 1;
    for (var i = 1; i <= 3; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintGrid);
    }
    if (points.isEmpty) return;
    final vals = points.map((e) => e.price).toList();
    final min = vals.reduce((a, b) => a < b ? a : b);
    final max = vals.reduce((a, b) => a > b ? a : b);
    final range = (max - min).abs() < 0.001 ? 1.0 : (max - min);
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = points.length == 1 ? size.width : (size.width * i / (points.length - 1));
      final y = size.height - ((points[i].price - min) / range) * (size.height - 8) - 4;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final linePaint = Paint()
      ..color = _dark
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _HistoryChartPainter oldDelegate) => oldDelegate.points != points;
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: _tanLt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: _pjs(size: 10, weight: FontWeight.w700, color: _t2)),
          const SizedBox(height: 4),
          Text(value, style: _pjs(size: 13, weight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FİYATI EKLEYEN KİŞİ
// ─────────────────────────────────────────────────────────────────────────────
class _ContributorCard extends StatelessWidget {
  final ProductDetailResponse product;
  const _ContributorCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final fallbackLevel = LevelStyle.fromLevelLabel(product.bestPrice.userTier);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: product.bestPrice.userId.trim().isEmpty
          ? const Stream.empty()
          : FirebaseFirestore.instance.collection('users').doc(product.bestPrice.userId.trim()).snapshots(),
      builder: (_, snap) {
        final data = snap.data?.data() ?? const <String, dynamic>{};
        final name  = _resolveName(data, product.bestPrice.userName);
        final level = _resolveLevel(data, product.bestPrice.userTier, fallbackLevel);
        final isVerified = data['verifiedBadge'] == true || data['verified'] == true || product.bestPrice.addedByVerifiedBadge;

        return _Card(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('FİYATI EKLEYEN', style: _pjs(size: 9, weight: FontWeight.w700, color: _t3, letterSpacing: 0.5)),
                  const SizedBox(height: 7),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                    decoration: BoxDecoration(
                      color: level.badgeBackground,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: level.badgeBorder.withOpacity(0.6)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(level.icon, size: 14, color: level.badgeBorder),
                        const SizedBox(width: 6),
                        Text(name, style: _pjs(size: 13, weight: FontWeight.w800, color: level.badgeForeground)),
                        if (isVerified) ...[
                          const SizedBox(width: 5),
                          const Icon(Icons.verified, color: Color(0xFF2B6CB0), size: 14),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const Icon(Icons.outlined_flag_rounded, color: _red, size: 20),
            ],
          ),
        );
      },
    );
  }

  static String _resolveName(Map<String, dynamic> d, String fallback) {
    for (final k in ['displayName', 'fullName', 'name', 'userName', 'username', fallback]) {
      final v = (d[k] ?? k).toString().trim();
      if (v.isNotEmpty && v.toLowerCase() != 'anonim') return v;
    }
    return 'Kullanıcı';
  }

  static UserLevel _resolveLevel(Map<String, dynamic> d, String fallbackLabel, UserLevel fallback) {
    final pts   = (d['totalPoints'] as num?)?.toInt() ?? (d['points'] as num?)?.toInt();
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

// ─────────────────────────────────────────────────────────────────────────────
// FİYAT DOĞRULAMA (per-price)
// ─────────────────────────────────────────────────────────────────────────────
class _VerificationSection extends ConsumerWidget {
  final ProductDetailResponse product;
  final String productId;
  final bool isSubmitting;
  final Future<void> Function(String, bool) onVote;
  final void Function(String) onWrongTap;

  const _VerificationSection({
    required this.product,
    required this.productId,
    required this.isSubmitting,
    required this.onVote,
    required this.onWrongTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authStateProvider).valueOrNull;
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
              Text('${product.priceEntryCount} kayıt', style: _pjs(size: 12, weight: FontWeight.w600, color: _tan)),
            ],
          ),
        ),
        _Card(
          padding: const EdgeInsets.all(18),
          child: pricesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: _tanCard)),
            error: (_, __) => const Text('Fiyat doğrulama verisi alınamadı'),
            data: (list) {
              final entries = list.where((e) => e.isActive).toList()
                ..sort((a, b) => b.reportedAt.compareTo(a.reportedAt));
              if (entries.isEmpty) {
                return _buildPriceRow(context, ref, currentUser, _toPriceModel(product.bestPrice));
              }
              return Column(
                children: [
                  for (var i = 0; i < entries.take(3).length; i++) ...[
                    if (i > 0) const Divider(color: _border, height: 24),
                    _buildPriceRow(context, ref, currentUser, entries[i]),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(BuildContext context, WidgetRef ref, dynamic currentUser, PriceModel entry) {
    final voteStream = currentUser == null
        ? const Stream<String?>.empty()
        : ref.watch(firestoreServiceProvider).streamUserVoteValue(entry.id, currentUser.uid);

    return StreamBuilder<String?>(
      stream: voteStream,
      builder: (_, snap) {
        final voteVal = snap.data;
        final hasVoted = voteVal != null;
        final isApprovedSelf = voteVal == 'yes';
        final isRejectedSelf = voteVal == 'no';
        final ownerUid = entry.userId.trim();
        final isOwner = currentUser != null && ownerUid.isNotEmpty && currentUser.uid == ownerUid;
        final canVote = currentUser != null && !hasVoted && !isOwner && !isSubmitting;

        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: _tanCard, borderRadius: BorderRadius.circular(12)),
                  child: Center(child: Text((entry.userName ?? '?').substring(0, 1).toUpperCase(), style: _pjs(size: 12, weight: FontWeight.w800, color: _white))),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.userName ?? 'Kullanıcı', style: _pjs(size: 13, weight: FontWeight.w800)),
                      Text('${entry.storeName ?? 'Market'} · ${_timeAgo(entry.reportedAt)}', style: _pjs(size: 11, weight: FontWeight.w500, color: _t3)),
                    ],
                  ),
                ),
                Text('${entry.price.toStringAsFixed(2)}₺', style: _pjs(size: 18, weight: FontWeight.w900, letterSpacing: -0.4)),
              ],
            ),
            const SizedBox(height: 12),
            _VerifyCountRow(approveCount: entry.upVotes, rejectCount: entry.downVotes),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _VoteBtn(
                    label: 'Doğru',
                    sub: '${entry.upVotes} onay',
                    icon: Icons.check_rounded,
                    activeColor: _green,
                    isActive: isApprovedSelf,
                    isLoading: isSubmitting && isApprovedSelf,
                    enabled: canVote,
                    onTap: canVote ? () => onVote(entry.id, true) : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _VoteBtn(
                    label: 'Yanlış',
                    sub: '${entry.downVotes} itiraz',
                    icon: Icons.close_rounded,
                    activeColor: _red,
                    isActive: isRejectedSelf,
                    isLoading: isSubmitting && isRejectedSelf,
                    enabled: canVote,
                    onTap: canVote ? () { onVote(entry.id, false); onWrongTap(entry.id); } : () => onWrongTap(entry.id),
                  ),
                ),
              ],
            ),
            if (isOwner)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _StateMsgRow(msg: 'Kendi eklediğin fiyatı doğrulayamazsın', icon: Icons.info_outline_rounded, color: _red),
              ),
          ],
        );
      },
    );
  }

  static String _timeAgo(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inHours < 1) return '${d.inMinutes} dk önce';
    if (d.inDays < 1) return '${d.inHours} saat önce';
    return '${d.inDays} gün önce';
  }

  static PriceModel _toPriceModel(BestPrice b) => PriceModel(
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
      );
}

class _VerifyCountRow extends StatelessWidget {
  final int approveCount, rejectCount;
  const _VerifyCountRow({required this.approveCount, required this.rejectCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (approveCount > 0)
          Row(
            children: [
              // Mini avatar stack simülasyonu
              SizedBox(
                width: approveCount.clamp(1, 3) * 16.0 + 4,
                height: 22,
                child: Stack(
                  children: List.generate(approveCount.clamp(1, 3), (i) => Positioned(
                    left: i * 14.0,
                    child: Container(
                      width: 20, height: 20,
                      decoration: BoxDecoration(
                        color: _green.withOpacity(0.15 + i * 0.1),
                        shape: BoxShape.circle,
                        border: const Border.fromBorderSide(BorderSide(color: _white, width: 1.5)),
                      ),
                      child: Center(child: Icon(Icons.check, size: 10, color: _green)),
                    ),
                  )),
                ),
              ),
              const SizedBox(width: 6),
              RichText(
                text: TextSpan(
                  style: _pjs(size: 11, weight: FontWeight.w600, color: _t2),
                  children: [
                    TextSpan(text: '$approveCount kişi', style: _pjs(size: 11, weight: FontWeight.w800, color: _green)),
                    const TextSpan(text: ' doğruladı'),
                  ],
                ),
              ),
            ],
          ),

        if (approveCount > 0 && rejectCount > 0)
          Container(
            width: 1, height: 14, color: _border,
            margin: const EdgeInsets.symmetric(horizontal: 10),
          ),

        if (rejectCount > 0)
          RichText(
            text: TextSpan(
              style: _pjs(size: 11, weight: FontWeight.w600, color: _t2),
              children: [
                TextSpan(text: '$rejectCount kişi', style: _pjs(size: 11, weight: FontWeight.w800, color: _red)),
                const TextSpan(text: ' yanlış dedi'),
              ],
            ),
          ),

        if (approveCount == 0 && rejectCount == 0)
          Text('Henüz doğrulama yok', style: _pjs(size: 11, weight: FontWeight.w600, color: _t3)),
      ],
    );
  }
}

class _StateMsgRow extends StatelessWidget {
  final String msg;
  final IconData icon;
  final Color color;
  const _StateMsgRow({required this.msg, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(msg, style: _pjs(size: 11, weight: FontWeight.w600, color: color)),
          ],
        ),
      );
}

class _VoteBtn extends StatelessWidget {
  final String label, sub;
  final IconData icon;
  final Color activeColor;
  final bool isActive, isLoading, enabled;
  final VoidCallback? onTap;

  const _VoteBtn({
    required this.label, required this.sub, required this.icon,
    required this.activeColor, required this.isActive,
    required this.isLoading, required this.enabled, this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isActive ? activeColor : (enabled ? _t1 : _t1.withOpacity(0.5));
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.07) : _bg,
          border: Border.all(color: isActive ? activeColor.withOpacity(0.4) : _border, width: 1.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            if (isLoading)
              SizedBox(width: 17, height: 17, child: CircularProgressIndicator(strokeWidth: 2, color: activeColor))
            else
              Icon(icon, color: isActive ? activeColor : (enabled ? _t2 : _t2.withOpacity(0.5)), size: 17),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: _pjs(size: 12, weight: FontWeight.w800, color: textColor)),
                Text(sub,   style: _pjs(size: 10, weight: FontWeight.w500, color: _t3)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// YORUMLAR
// ─────────────────────────────────────────────────────────────────────────────
class _CommentsSection extends StatelessWidget {
  final ProductDetailResponse product;
  final TextEditingController controller;
  final bool isExpanded, isSubmitting;
  final VoidCallback onExpand, onSend;

  const _CommentsSection({
    required this.product, required this.controller,
    required this.isExpanded, required this.isSubmitting,
    required this.onExpand, required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final all      = product.comments;
    final display  = isExpanded ? all : all.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Yorumlar', style: _pjs(size: 17, weight: FontWeight.w900, letterSpacing: -0.3)),
              Text('${all.length} yorum', style: _pjs(size: 12, weight: FontWeight.w600, color: _t3)),
            ],
          ),
        ),

        _Card(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Input
              Container(
                padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
                decoration: BoxDecoration(
                  color: _bg,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        style: _pjs(size: 13),
                        decoration: InputDecoration(
                          hintText: 'Fiyat hakkında yorum yaz...',
                          hintStyle: _pjs(size: 13, color: _t3, weight: FontWeight.w400),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: isSubmitting ? null : onSend,
                      child: Container(
                        width: 32, height: 32,
                        decoration: const BoxDecoration(color: _dark, shape: BoxShape.circle),
                        child: isSubmitting
                            ? const Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(color: _white, strokeWidth: 2))
                            : const Icon(Icons.send_rounded, color: _white, size: 15),
                      ),
                    ),
                  ],
                ),
              ),

              if (display.isNotEmpty) ...[
                const SizedBox(height: 20),
                ...display.asMap().entries.map((entry) {
                  final c = entry.value;
                  final levelStyle = LevelStyle.fromLevelLabel(c.authorLevel);
                  final isLast = entry.key == display.length - 1;
                  return Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: _border)),
                            child: Center(child: Text(c.author[0], style: _pjs(size: 13, weight: FontWeight.w800))),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Text(levelStyle.emoji, style: const TextStyle(fontSize: 12)),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${c.author} (${levelStyle.label})',
                                          style: _pjs(size: 13, weight: FontWeight.w700, color: levelStyle.badgeForeground),
                                        ),
                                      ],
                                    ),
                                    Text(c.timeAgo, style: _pjs(size: 10, weight: FontWeight.w500, color: _t3)),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(c.text, style: _pjs(size: 13, color: _t1, height: 1.45, weight: FontWeight.w400)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (!isLast)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                          child: Divider(color: _border, height: 1),
                        )
                      else
                        const SizedBox(height: 4),
                    ],
                  );
                }),

                if (!isExpanded && all.length > 4)
                  GestureDetector(
                    onTap: onExpand,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('${all.length - 4} Yorum Daha Gör', style: _pjs(size: 12, weight: FontWeight.w700, color: _tan)),
                          const Icon(Icons.keyboard_arrow_down_rounded, color: _tan, size: 18),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAYLAŞILAN PRIMITIVE WIDGET'LAR
// ─────────────────────────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const _Card({required this.child, this.padding});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: padding ?? const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: _dark.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 3))],
          border: Border.all(color: _border),
        ),
        child: child,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// NEDEN YANLIŞ? BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _RejectSheet extends StatefulWidget {
  final Function(String) onSubmit;
  const _RejectSheet({required this.onSubmit});

  @override
  State<_RejectSheet> createState() => _RejectSheetState();
}

class _RejectSheetState extends State<_RejectSheet> {
  String? _selected;
  final _ctrl = TextEditingController();

  static const _reasons = [
    ('💰', 'Fiyat farklı',    'Raftaki fiyat daha yüksek veya düşük'),
    ('📦', 'Ürün yok',        'Bu mağazada stokta bulunamadı'),
    ('🏪', 'Yanlış mağaza',   'Farklı şube ya da zincir olabilir'),
    ('📅', 'Güncel değil',    'Bu fiyat artık geçerli değil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
        left: 20, right: 20, top: 12,
      ),
      decoration: const BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 38, height: 4,
              decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Text('Neden Yanlış?', style: _pjs(size: 20, weight: FontWeight.w900, letterSpacing: -0.4)),
          const SizedBox(height: 4),
          Text('Sorunu seçersen topluluğu bilgilendirmiş olursun.', style: _pjs(size: 13, weight: FontWeight.w500, color: _t2)),
          const SizedBox(height: 18),

          ..._reasons.map((r) {
            final isSelected = _selected == r.$2;
            return GestureDetector(
              onTap: () => setState(() => _selected = isSelected ? null : r.$2),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                decoration: BoxDecoration(
                  color: isSelected ? _redBg : _bg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: isSelected ? _red.withOpacity(0.5) : Colors.transparent, width: 2),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: _white, borderRadius: BorderRadius.circular(13)),
                      child: Center(child: Text(r.$1, style: const TextStyle(fontSize: 20))),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.$2, style: _pjs(size: 14, weight: FontWeight.w800)),
                        Text(r.$3, style: _pjs(size: 11, weight: FontWeight.w500, color: _t2)),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity, height: 54,
            child: ElevatedButton(
              onPressed: () => widget.onSubmit(_selected ?? _ctrl.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: _red, foregroundColor: _white, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: Text('Bildir', style: _pjs(size: 15, weight: FontWeight.w900, color: _white)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal', style: _pjs(size: 13, weight: FontWeight.w700, color: _t2)),
          ),
        ],
      ),
    );
  }
}
