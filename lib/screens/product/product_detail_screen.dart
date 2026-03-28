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

// ════════════════════════════════ RENKLER ════════════════════════════════
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
    final query = bestPrice.storeLocation.trim().isNotEmpty 
        ? '${bestPrice.store} ${bestPrice.storeLocation}'         : bestPrice.store;
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}');
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harita açılamadı. Lütfen tekrar dene.')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yorum eklenemedi. Lütfen tekrar dene.')),
      );
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
        },      ),
    );
  }

  void _openPastPricesSheet(ProductDetailResponse product) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(width: 42, height: 4, decoration: BoxDecoration(color: _textSoft, borderRadius: BorderRadius.circular(99))),
            const SizedBox(height: 12),
            Text('Geçmiş Fiyatları Doğrula', style: _t(s: 17, w: FontWeight.w800)),
            const SizedBox(height: 12),
            const Divider(color: _line),
            Expanded(
              child: ListView.builder(
                itemCount: 5,
                itemBuilder: (_, i) => const SizedBox(height: 10),
              ),
            ),
          ],
        ),
      ),
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
        body: Center(child: Text(state.error!, style: _t())),      );
    }

    final product = state.data!;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _dark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _tanLight),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text('Ürün Detayı', style: _t(s: 16, w: FontWeight.w800, c: Colors.white)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: _tanLight),
            onPressed: () {
              Share.share(
                '${product.title} ürününü FiyatRadar\'da incele!\n\nEn Ucuz: ${_fmt(product.bestPrice.price)}\nMarket: ${product.bestPrice.store}',
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HeroSection(product: product),
              const SizedBox(height: 16),
              _LastPriceCard(product: product),
              const SizedBox(height: 12),
              _StatsStrip(product: product),
              const SizedBox(height: 12),
              _VerificationSection(
                product: product,
                onOpenHistory: () => _openPastPricesSheet(product),
                onWrongTap: _showRejectModal,
              ),
              const SizedBox(height: 12),
              _MarketsSection(product: product, onOpenMap: _launchMap),
              const SizedBox(height: 12),
              _CommentsSection(comments: product.comments),
              const SizedBox(height: 80),            ],
          ),
        ),
      ),
      bottomNavigationBar: _StickyActionBar(
        onAlert: () {},
        onMap: () => _launchMap(product.bestPrice),
      ),
    );
  }
}

// ════════════════════════════════ HERO SECTION ════════════════════════════════
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
                  ),                ),
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
          Text(
            product.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: _t(s: 18, w: FontWeight.w800, h: 1.35),
          ),
          const SizedBox(height: 4),
          Text(
            '🍞 $category',
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
                _heroStat('6', 'Market'),
                _heroStat('${product.comments.length}', 'İnceleme'),
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
        Text(value, style: _t(s: 18, w: FontWeight.w800, c: _tan)),
        const SizedBox(height: 2),
        Text(label, style: _t(s: 11, w: FontWeight.w600, c: _textSoft)),
      ],
    );
  }
}

// ════════════════════════════════ SON FİYAT KARTI (DÜZELTİLMİŞ) ════════════════════════════════
class _LastPriceCard extends StatelessWidget {
  const _LastPriceCard({required this.product});

  final ProductDetailResponse product;

  @override
  Widget build(BuildContext context) {
    final dropPct = product.stats.highest <= 0 
        ? 0 
        : (((product.stats.highest - product.bestPrice.price) / product.stats.highest) * 100).round();
    final initials = _initials(product.bestPrice.userName);
    final marketLabel = product.bestPrice.storeLocation.trim().isNotEmpty
        ? '${product.bestPrice.store} (${product.bestPrice.storeLocation})'
        : product.bestPrice.store;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1a1510), Color(0xFF2C2418)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 32, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: _tan.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'SON EKLENEN FİYAT',
                  style: _t(s: 11, w: FontWeight.w700, c: _tanLight, ls: 0.5),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: _green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _green.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.keyboard_arrow_up_rounded, size: 14, color: Color(0xFF4ADE80)),
                    const SizedBox(width: 3),
                    Text(
                      '%$dropPct Düştü',
                      style: _t(s: 13, w: FontWeight.w800, c: const Color(0xFF4ADE80)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Fiyat
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.bestPrice.price.toStringAsFixed(2).replaceAll('.', ','),
                style: _t(s: 56, w: FontWeight.w900, c: Colors.white, h: 1.0, ls: -2)
                    .copyWith(fontFamily: 'Georgia'),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 4, top: 12),                child: Text(
                  '₺',
                  style: _t(s: 40, w: FontWeight.w900, c: Colors.white.withOpacity(0.6), h: 1.0)
                      .copyWith(fontFamily: 'Georgia'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Divider
          Divider(color: Colors.white.withOpacity(0.1), height: 1),
          const SizedBox(height: 20),
          
          // Footer
          Row(
            children: [
              // Market - SOL
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _tan,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text('🛒', style: TextStyle(fontSize: 20)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        marketLabel,
                        style: _t(s: 15, w: FontWeight.w800, c: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              
              // Kullanıcı - SAĞ
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        product.bestPrice.userName,
                        style: _t(s: 13, w: FontWeight.w700, c: Colors.white),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: _tan,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            initials,
                            style: _t(s: 12, w: FontWeight.w800, c: _dark),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.bestPrice.createdAtLabel,
                    style: _t(s: 11, c: Colors.white.withOpacity(0.6)),
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

// ════════════════════════════════ STATS STRIP ════════════════════════════════
class _StatsStrip extends StatelessWidget {
  const _StatsStrip({required this.product});

  final ProductDetailResponse product;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _statCard('En Düşük', product.stats.lowest, _green, Icons.keyboard_arrow_down_rounded)),        const SizedBox(width: 8),
        Expanded(child: _statCard('Ortalama', product.stats.average, _amber, Icons.equalizer_rounded)),
        const SizedBox(width: 8),
        Expanded(child: _statCard('En Yüksek', product.stats.highest, _red, Icons.keyboard_arrow_up_rounded)),
      ],
    );
  }

  Widget _statCard(String label, double v, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: _card(),
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 6),
          Text(_fmt(v), style: _t(s: 13, w: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(s: 9, c: _textSoft, w: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ════════════════════════════════ VERIFICATION SECTION ════════════════════════════════
class _VerificationSection extends StatelessWidget {
  const _VerificationSection({
    required this.product,
    required this.onOpenHistory,
    required this.onWrongTap,
  });

  final ProductDetailResponse product;
  final VoidCallback onOpenHistory;
  final ValueChanged<String> onWrongTap;

  @override
  Widget build(BuildContext context) {
    final total = product.trust.approveCount + product.trust.rejectCount;
    final approvePercent = total == 0 ? 0 : ((product.trust.approveCount / total) * 100).round();
    final rejectPercent = total == 0 ? 0 : 100 - approvePercent;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.edit_rounded, size: 18, color: _tan),
                  const SizedBox(width: 6),
                  Text('Fiyat Girişi', style: _t(s: 14, w: FontWeight.w800)),
                ],
              ),
              InkWell(
                onTap: onOpenHistory,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: _surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _line),
                  ),
                  child: const Icon(Icons.history_rounded, size: 16, color: _textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _voteMini('${product.trust.approveCount}', 'Doğru ($approvePercent%)', _green, _greenBg)),
              const SizedBox(width: 8),
              Expanded(child: _voteMini('${product.trust.rejectCount}', 'Yanlış ($rejectPercent%)', _red, _redBg)),
              const SizedBox(width: 8),
              Expanded(child: _voteMini('$total', 'Toplam', _tan, _surfaceAlt)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  icon: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                  label: Text('Fiyat Doğru', style: _t(s: 12, w: FontWeight.w700, c: Colors.white)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => onWrongTap('price_id'),
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
        ],
      ),
    );
  }

  Widget _voteMini(String number, String label, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(number, style: _t(s: 20, w: FontWeight.w900, c: color)),
          const SizedBox(height: 2),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(s: 10, w: FontWeight.w600, c: _textMuted)),
        ],
      ),
    );
  }
}

// ════════════════════════════════ MARKETS SECTION ════════════════════════════════
class _MarketsSection extends StatelessWidget {
  const _MarketsSection({required this.product, required this.onOpenMap});
  final ProductDetailResponse product;
  final ValueChanged<BestPrice> onOpenMap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.store_mall_directory_rounded, size: 20, color: _tan),
              const SizedBox(width: 8),
              Text('Tüm Marketler', style: _t(s: 16, w: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 14),
          _MarketTile(
            name: product.bestPrice.store,
            location: product.bestPrice.storeLocation,
            price: product.bestPrice.price,
            isBest: true,
            when: product.bestPrice.createdAtLabel,
            onOpenMap: () => onOpenMap(product.bestPrice),
          ),
          const SizedBox(height: 10),
          _MarketTile(
            name: 'A101',
            location: 'Merkez',
            price: product.bestPrice.price + 5,
            isBest: false,
            when: '2 saat önce',
            onOpenMap: () => onOpenMap(product.bestPrice),
          ),
        ],
      ),
    );
  }
}

class _MarketTile extends StatelessWidget {
  const _MarketTile({
    required this.name,
    required this.location,
    required this.price,
    required this.isBest,
    required this.when,
    required this.onOpenMap,  });

  final String name;
  final String location;
  final double price;
  final bool isBest;
  final String when;
  final VoidCallback onOpenMap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isBest ? _green.withOpacity(0.3) : _line, width: isBest ? 2 : 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: _tan, borderRadius: BorderRadius.circular(12)),
                child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: _t(s: 17, w: FontWeight.w800, c: Colors.white)),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(s: 14, w: FontWeight.w700)),
                        ),
                        if (isBest)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(999)),
                            child: Text('En Ucuz', style: _t(s: 8, w: FontWeight.w700, c: Colors.white)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(location, maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(s: 10, c: _textSoft, w: FontWeight.w600)),
                  ],                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_fmt(price), style: _t(s: 18, w: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(
                    isBest ? 'Son fiyattan aynı' : '+5,00₺ pahalı',
                    style: _t(s: 11, w: FontWeight.w700, c: isBest ? _green : _red),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text('⏱ $when eklendi', maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(s: 10, c: _textSoft, w: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onOpenMap,
              style: ElevatedButton.styleFrom(
                backgroundColor: _dark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                padding: const EdgeInsets.symmetric(vertical: 9),
                elevation: 0,
              ),
              icon: const Icon(Icons.map_outlined, size: 13, color: _tan),
              label: Text('Haritada Göster', style: _t(s: 11, w: FontWeight.w700, c: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════ COMMENTS SECTION ════════════════════════════════
class _CommentsSection extends StatelessWidget {
  const _CommentsSection({required this.comments});
  final List<ProductComment> comments;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded, size: 20, color: _tan),
                  const SizedBox(width: 8),
                  Text('Yorumlar', style: _t(s: 16, w: FontWeight.w800)),
                ],
              ),
              Text('${comments.length} inceleme', style: _t(s: 12, c: _textSoft, w: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 14),
          if (comments.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text('Henüz yorum yok. İlk yorumu sen yaz.', style: _t(s: 12, c: _textSoft)),
            )
          else
            ...comments.take(3).map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CommentTile(comment: c),
            )),
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

    return Container(      padding: const EdgeInsets.all(12),
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
                    Text(comment.author, maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(s: 13, w: FontWeight.w700)),
                    Text(comment.timeAgo, maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(s: 10, c: _textSoft, w: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(comment.text, style: _t(s: 12, c: _textMuted, h: 1.5), maxLines: 6, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════ STICKY ACTION BAR ════════════════════════════════
class _StickyActionBar extends StatelessWidget {
  const _StickyActionBar({required this.onAlert, required this.onMap});

  final VoidCallback onAlert;
  final VoidCallback onMap;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [_bg, _bg.withOpacity(0.9), Colors.transparent],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _line),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 14, offset: const Offset(0, 4)),
          ],
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
        ),      ),
    );
  }
}

// ════════════════════════════════ REJECT SHEET ════════════════════════════════
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
                Text('Neden yanlış?', style: _t(s: 15, w: FontWeight.w800)),
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
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),                    decoration: BoxDecoration(
                      color: _surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _line),
                    ),
                    child: Text(e.$2, style: _t(s: 12, w: FontWeight.w700)),
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

// ════════════════════════════════ HELPERS ════════════════════════════════
BoxDecoration _card() {
  return BoxDecoration(
    color: _surface,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: _line),
    boxShadow: [
      BoxShadow(color: _dark.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
    ],
  );
}

String _initials(String text) {
  final parts = text.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
  if (parts.isEmpty) return 'FR';
  if (parts.length == 1) return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

Color _colorFromHex(String hex) {
  final normalized = hex.replaceAll('#', '').trim();
  if (normalized.length != 6) return const Color(0xFFEDE6DD);
  final value = int.tryParse('FF$normalized', radix: 16);
  return value == null ? const Color(0xFFEDE6DD) : Color(value);
}