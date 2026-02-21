import 'dart:ui';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/product_detail_api_model.dart';
import '../../providers/product_detail_provider.dart';

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

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen>
    with SingleTickerProviderStateMixin {
  static const _brown900 = Color(0xFF5D4037);
  static const _brown700 = Color(0xFF795548);
  static const _brown500 = Color(0xFF8D6E63);
  static const _amber600 = Color(0xFFC8956C);
  static const _amber400 = Color(0xFFD4A574);
  static const _cream100 = Color(0xFFFFF8F0);
  static const _cream200 = Color(0xFFF5EDE4);
  static const _cream300 = Color(0xFFEDE0D4);

  late final AnimationController _heroFloatController;
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _heroFloatController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _heroFloatController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productDetailProvider(widget.productId));
    final notifier = ref.read(productDetailProvider(widget.productId).notifier);

    return Scaffold(
      backgroundColor: _cream100,
      floatingActionButton: FloatingActionButton(
        backgroundColor: _amber600,
        onPressed: () {},
        child: const Icon(Icons.add, size: 30, color: Colors.white),
      ),
      body: SafeArea(
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : state.error != null
                ? Center(child: Text(state.error!))
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final horizontal = constraints.maxWidth * 0.05;
                      return SingleChildScrollView(
                        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 100),
                        child: Column(
                          children: [
                            _buildHero(state.data!, constraints),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: horizontal),
                              child: Column(
                                children: [
                                  const SizedBox(height: 20),
                                  _buildHeader(state.data!),
                                  const SizedBox(height: 16),
                                  _buildPriceCard(state.data!, notifier, state.isSubmittingVote),
                                  const SizedBox(height: 12),
                                  _buildStats(state.data!.stats),
                                  const SizedBox(height: 16),
                                  _buildHistoryCard(state.history),
                                  const SizedBox(height: 16),
                                  _buildCommunityCard(state.data!, notifier, state.isSubmittingVote),
                                  const SizedBox(height: 16),
                                  _buildCommentsSection(state, notifier),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildHero(ProductDetailResponse data, BoxConstraints constraints) {
    return Container(
      height: constraints.maxWidth * 0.8,
      decoration: const BoxDecoration(
        gradient: RadialGradient(colors: [Colors.white, _cream200], center: Alignment(0, 0.2), radius: 0.85),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Stack(
        children: [
          Positioned(top: 14, left: 16, right: 16, child: _buildHeroActions()),
          Center(
            child: AnimatedBuilder(
              animation: _heroFloatController,
              builder: (_, child) {
                final dy = -10 * _heroFloatController.value;
                return Transform.translate(offset: Offset(0, dy), child: child);
              },
              child: Image.network(data.imageUrl, height: constraints.maxWidth * 0.52, fit: BoxFit.contain),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroActions() {
    Widget glass(IconData icon, VoidCallback onTap) => ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: InkWell(
              onTap: onTap,
              child: Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: Colors.white.withOpacity(0.6)),
                child: Icon(icon, color: _brown900),
              ),
            ),
          ),
        );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        glass(Icons.arrow_back, () => Navigator.pop(context)),
        Row(children: [glass(Icons.favorite_border, () {}), const SizedBox(width: 10), glass(Icons.share, () {})]),
      ],
    );
  }

  Widget _buildHeader(ProductDetailResponse data) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ...data.categories.map((e) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: _cream300, borderRadius: BorderRadius.circular(20)),
                child: Text(e, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: _brown700, fontSize: 12)),
              )),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(20)),
            child: Text('🔥 Trend', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFFEF6C00), fontSize: 12)),
          ),
        ],
      ),
      const SizedBox(height: 10),
      Text(data.title, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: _brown900)),
      const SizedBox(height: 6),
      Text('👁 ${data.viewCount} Görüntüleme • 🏷 ${data.priceEntryCount} Fiyat Girişi', style: GoogleFonts.inter(fontSize: 13, color: _brown500)),
    ]);
  }

  Widget _buildPriceCard(ProductDetailResponse data, ProductDetailNotifier notifier, bool isVoting) {
    final p = data.bestPrice;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(colors: [_brown900, _brown700], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
            child: Text('👑 En İyi Fiyat', style: GoogleFonts.inter(color: _amber400, fontWeight: FontWeight.w600, fontSize: 12)),
          ),
          Text(p.createdAtLabel, style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
        ]),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(p.store, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white)),
          Text('${p.price.toStringAsFixed(0)}₺', style: GoogleFonts.dmSans(fontSize: 48, fontWeight: FontWeight.w700, color: Colors.white)),
        ]),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Ekleyen:', style: GoogleFonts.inter(color: Colors.white70, fontSize: 11)),
            const SizedBox(height: 3),
            ShaderMask(
              shaderCallback: (rect) => const LinearGradient(colors: [Color(0xFFE0F7FA), Color(0xFF00F2FE)]).createShader(rect),
              child: Row(children: [
                const Icon(Icons.diamond, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text('${p.userTier} • ${p.userName}', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700)),
              ]),
            ),
          ]),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _amber600, foregroundColor: Colors.white),
            onPressed: () async {
              if (p.storeUrl.isEmpty) return;
              await launchUrl(Uri.parse(p.storeUrl), mode: LaunchMode.externalApplication);
            },
            child: const Text('Mağazaya Git'),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: isVoting ? null : () => notifier.votePrice(priceId: p.id, isApproved: true),
              icon: const Icon(Icons.thumb_up_alt_outlined),
              label: Text('Doğrula (${p.upVotes})'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: isVoting ? null : () => notifier.votePrice(priceId: p.id, isApproved: false),
              icon: const Icon(Icons.thumb_down_alt_outlined),
              label: Text('Yanlış (${p.downVotes})'),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _buildStats(PriceStats stats) {
    Widget item(String t, String v, {Color? bg, Color? valueColor}) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: bg ?? _cream200, borderRadius: BorderRadius.circular(18)),
            child: Column(children: [
              Text(t, style: GoogleFonts.inter(fontSize: 12, color: _brown500), textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(v, style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.bold, color: valueColor ?? _brown900)),
            ]),
          ),
        );
    return Row(children: [
      item('En Düşük Fiyat', '${stats.lowest.toStringAsFixed(0)}₺', bg: const Color(0xFFFFF8E1), valueColor: const Color(0xFF2E7D32)),
      const SizedBox(width: 10),
      item('Ortalama', '${stats.average.toStringAsFixed(2)}₺'),
      const SizedBox(width: 10),
      item('En Yüksek', '${stats.highest.toStringAsFixed(0)}₺'),
    ]);
  }

  Widget _buildHistoryCard(List<PriceHistoryPoint> history) {
    if (history.isEmpty) {
      return _card(child: Text('Fiyat geçmişi bulunamadı.', style: GoogleFonts.inter()));
    }
    final spots = history.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.price)).toList();
    final minY = history.map((e) => e.price).reduce((a, b) => a < b ? a : b);
    final maxY = history.map((e) => e.price).reduce((a, b) => a > b ? a : b);

    return _card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _titleRow('Fiyat Geçmişi', 'Son 30 gün'),
        const SizedBox(height: 14),
        SizedBox(
          height: 180,
          child: LineChart(
            LineChartData(
              minY: (minY * 0.9),
              maxY: (maxY * 1.1),
              gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: (maxY - minY) / 3),
              titlesData: FlTitlesData(
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 34, getTitlesWidget: (v, _) => Text('${v.toInt()}₺', style: GoogleFonts.dmSans(fontSize: 10, color: _brown500)))),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: (spots.length / 2).clamp(1, spots.length).toDouble(),
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= history.length) return const SizedBox.shrink();
                      return Text(history[i].dateLabel, style: GoogleFonts.inter(fontSize: 10, color: _brown500));
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  barWidth: 4,
                  color: _amber600,
                  belowBarData: BarAreaData(show: true, gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_amber600.withOpacity(0.35), _amber600.withOpacity(0.0)])),
                  dotData: FlDotData(
                    show: true,
                    checkToShowDot: (spot, barData) => spot == spots.last,
                    getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 5, color: _amber600, strokeWidth: 2, strokeColor: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildCommunityCard(ProductDetailResponse data, ProductDetailNotifier notifier, bool isVoting) {
    return _card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Topluluk Merkezi', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: _brown900)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
            child: Text('%${data.trust.scorePercent} Güvenilir', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF2E7D32))),
          ),
        ]),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(value: data.trust.scorePercent / 100, minHeight: 8, color: const Color(0xFF2E7D32), backgroundColor: _cream300),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: ElevatedButton.icon(onPressed: isVoting ? null : () => notifier.votePrice(priceId: data.bestPrice.id, isApproved: true), icon: const Icon(Icons.thumb_up_outlined), label: Text('Doğrula (${data.trust.approveCount})'))),
          const SizedBox(width: 8),
          Expanded(child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFEBEE), foregroundColor: const Color(0xFFC62828)), onPressed: isVoting ? null : () => notifier.votePrice(priceId: data.bestPrice.id, isApproved: false), icon: const Icon(Icons.thumb_down_outlined), label: Text('Yanlış (${data.trust.rejectCount})'))),
        ]),
      ]),
    );
  }

  Widget _buildCommentsSection(ProductDetailState state, ProductDetailNotifier notifier) {
    final data = state.data!;
    return _card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _titleRow('Son Yorumlar', '${data.comments.length} Yorum'),
        const SizedBox(height: 12),
        ...data.comments.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                CircleAvatar(backgroundColor: _hexColor(c.avatarBgHex), child: Text(c.author.isNotEmpty ? c.author[0] : '?', style: GoogleFonts.poppins(color: Colors.white))),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: _cream200, borderRadius: const BorderRadius.only(topRight: Radius.circular(16), bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16))),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(c.author, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: _brown900)),
                        Text(c.timeAgo, style: GoogleFonts.inter(fontSize: 11, color: _brown500)),
                      ]),
                      const SizedBox(height: 4),
                      Text(c.text, style: GoogleFonts.inter(fontSize: 13, color: _brown700)),
                    ]),
                  ),
                ),
              ]),
            )),
        Row(children: [
          const CircleAvatar(backgroundColor: _cream200, child: Icon(Icons.person, color: _brown700)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _commentController,
              style: GoogleFonts.inter(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Bir yorum yaz...',
                hintStyle: GoogleFonts.inter(fontSize: 13),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: const BorderSide(color: _cream300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: const BorderSide(color: _amber400)),
                suffixIcon: IconButton(
                  onPressed: state.isSubmittingComment
                      ? null
                      : () async {
                          final text = _commentController.text.trim();
                          if (text.isEmpty) return;
                          final ok = await notifier.postComment(text);
                          if (ok) _commentController.clear();
                        },
                  icon: state.isSubmittingComment
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send, color: _amber600),
                ),
              ),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: _brown900.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 6))]),
      child: child,
    );
  }

  Widget _titleRow(String title, String subtitle) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: _brown900)),
      Text(subtitle, style: GoogleFonts.inter(fontSize: 13, color: _brown500)),
    ]);
  }

  Color _hexColor(String hex) {
    final clean = hex.replaceFirst('#', '');
    if (clean.length == 6) return Color(int.parse('FF$clean', radix: 16));
    return _amber600;
  }
}
