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
    with TickerProviderStateMixin {
  static const _creamBg = Color(0xFFFFF8F0);

  late final AnimationController _heroFloatController;
  late final AnimationController _chartPulseController;
  late final Animation<double> _heroFloat;
  late final Animation<double> _chartPulse;
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _heroFloatController = AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..repeat(reverse: true);
    _heroFloat = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _heroFloatController, curve: Curves.easeInOut),
    );
    _chartPulseController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))
          ..repeat(reverse: true);
    _chartPulse = Tween<double>(begin: 1, end: 1.45).animate(
      CurvedAnimation(parent: _chartPulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _heroFloatController.dispose();
    _chartPulseController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productDetailProvider(widget.productId));
    final notifier = ref.read(productDetailProvider(widget.productId).notifier);

    return Scaffold(
      backgroundColor: _creamBg,
      floatingActionButton: PressableFab(onPressed: () {}),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 414),
            child: Container(
              decoration: BoxDecoration(
                color: _creamBg,
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: Colors.white, width: 8),
              ),
              clipBehavior: Clip.antiAlias,
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.error != null
                      ? Center(child: Text(state.error!))
                      : SingleChildScrollView(
                          child: Column(
                            children: [
                              HeroSection(
                                data: state.data!,
                                floatAnimation: _heroFloat,
                                onBack: () => Navigator.of(context).pop(),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                                child: Column(
                                  children: [
                                    HeaderBlock(data: state.data!),
                                    const SizedBox(height: 24),
                                    BestPriceCard(data: state.data!, isVoting: state.isSubmittingVote),
                                    const SizedBox(height: 24),
                                    QuickStatsRow(stats: state.data!.stats),
                                    const SizedBox(height: 24),
                                    PriceHistoryPanel(
                                      history: state.history,
                                      pulseAnimation: _chartPulse,
                                    ),
                                    const SizedBox(height: 24),
                                    CommunityPanel(
                                      data: state.data!,
                                      notifier: notifier,
                                      isVoting: state.isSubmittingVote,
                                    ),
                                    const SizedBox(height: 24),
                                    CommentsPanel(
                                      state: state,
                                      notifier: notifier,
                                      controller: _commentController,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
            ),
          ),
        ),
      ),
    );
  }
}

class HeroSection extends StatelessWidget {
  const HeroSection({
    super.key,
    required this.data,
    required this.floatAnimation,
    required this.onBack,
  });

  final ProductDetailResponse data;
  final Animation<double> floatAnimation;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 340,
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          colors: [Colors.white, Color(0xFFF5EDE4)],
          center: Alignment(0, 0.2),
          radius: 1,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GlassIconButton(icon: Icons.arrow_back, onTap: onBack),
                Row(
                  children: [
                    GlassIconButton(icon: Icons.favorite_border, onTap: () {}),
                    const SizedBox(width: 12),
                    GlassIconButton(icon: Icons.share, onTap: () {}),
                  ],
                ),
              ],
            ),
          ),
          Center(
            child: AnimatedBuilder(
              animation: floatAnimation,
              builder: (_, child) => Transform.translate(
                offset: Offset(0, floatAnimation.value),
                child: child,
              ),
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.16),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Image.network(data.imageUrl, height: 220, fit: BoxFit.contain),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HeaderBlock extends StatelessWidget {
  const HeaderBlock({super.key, required this.data});

  final ProductDetailResponse data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          data.title,
          style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w700, color: const Color(0xFF5D4037)),
        ),
        const SizedBox(height: 10),
        Text(
          '👁 ${data.viewCount} görüntüleme • 🏷 ${data.priceEntryCount} fiyat girişi',
          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF8D6E63)),
        ),
      ],
    );
  }
}

class BestPriceCard extends StatelessWidget {
  const BestPriceCard({super.key, required this.data, required this.isVoting});

  final ProductDetailResponse data;
  final bool isVoting;

  @override
  Widget build(BuildContext context) {
    final p = data.bestPrice;
    final priceText = p.price.toStringAsFixed(0);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(colors: [Color(0xFF5D4037), Color(0xFF795548)]),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 40, offset: const Offset(0, 20)),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.amber.withOpacity(0.25),
                boxShadow: const [BoxShadow(blurRadius: 20, color: Colors.amber)],
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFC107)),
                      color: Colors.white.withOpacity(0.08),
                    ),
                    child: Text(
                      'Best price',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFFFC107)),
                    ),
                  ),
                  Text(p.createdAtLabel, style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        p.store.isNotEmpty ? p.store[0].toUpperCase() : '?',
                        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(p.store, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              RichText(
                text: TextSpan(
                  text: priceText,
                  style: GoogleFonts.dmSans(fontSize: 48, fontWeight: FontWeight.w700, color: Colors.white),
                  children: [
                    TextSpan(
                      text: ' ₺',
                      style: GoogleFonts.dmSans(fontSize: 24, fontWeight: FontWeight.w700, color: const Color(0xFFFFC107)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () async {
                    if (p.storeUrl.isEmpty) return;
                    await launchUrl(Uri.parse(p.storeUrl), mode: LaunchMode.externalApplication);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC8956C),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Mağazaya git',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
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

class QuickStatsRow extends StatelessWidget {
  const QuickStatsRow({super.key, required this.stats});

  final PriceStats stats;

  @override
  Widget build(BuildContext context) {
    Widget card(String title, String value, {bool highlighted = false}) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: highlighted ? const Color(0xFFFFF8E1) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: highlighted ? Border.all(color: const Color(0xFFFFC107)) : null,
          ),
          child: Column(
            children: [
              Text(title, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF8D6E63))),
              const SizedBox(height: 6),
              Text(value, style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF5D4037))),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        card('En düşük', '${stats.lowest.toStringAsFixed(0)}₺', highlighted: true),
        const SizedBox(width: 12),
        card('Ortalama', '${stats.average.toStringAsFixed(0)}₺'),
        const SizedBox(width: 12),
        card('En yüksek', '${stats.highest.toStringAsFixed(0)}₺'),
      ],
    );
  }
}

class PriceHistoryPanel extends StatelessWidget {
  const PriceHistoryPanel({super.key, required this.history, required this.pulseAnimation});

  final List<PriceHistoryPoint> history;
  final Animation<double> pulseAnimation;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return _PremiumPanel(child: Text('Fiyat geçmişi bulunamadı.', style: GoogleFonts.inter()));
    }

    final values = history.map((e) => e.price).toList();
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final spread = (max - min).abs() < 1 ? 1 : max - min;
    final spots = history.asMap().entries.map((e) {
      final scaled = 30 + ((e.value.price - min) / spread) * 60;
      return FlSpot(e.key.toDouble(), scaled);
    }).toList();

    return _PremiumPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Fiyat Geçmişi', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          SizedBox(
            height: 140,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                LineChart(
                  LineChartData(
                    minY: 25,
                    maxY: 95,
                    gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 30),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 24,
                          interval: 30,
                          getTitlesWidget: (value, _) {
                            if (value > 80) return Text('90', style: GoogleFonts.inter(fontSize: 11));
                            if (value > 50) return Text('60', style: GoogleFonts.inter(fontSize: 11));
                            return Text('30', style: GoogleFonts.inter(fontSize: 11));
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, _) {
                            final i = value.toInt();
                            if (i == 0 && history.isNotEmpty) {
                              return Text(history.first.dateLabel, style: GoogleFonts.inter(fontSize: 11));
                            }
                            if (i == (history.length / 2).floor() && history.length > 2) {
                              return Text(history[(history.length / 2).floor()].dateLabel, style: GoogleFonts.inter(fontSize: 11));
                            }
                            if (i == history.length - 1) {
                              return Text('Bugün', style: GoogleFonts.inter(fontSize: 11));
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        isStrokeCapRound: true,
                        barWidth: 4,
                        gradient: const LinearGradient(colors: [Color(0xFFC8956C), Color(0xFF795548)]),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [const Color(0xFFC8956C).withOpacity(0.35), Colors.transparent],
                          ),
                        ),
                        dotData: const FlDotData(show: false),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 40,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFF5D4037), borderRadius: BorderRadius.circular(8)),
                        child: Text('${history.last.price.toStringAsFixed(0)}₺', style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(height: 6),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          ScaleTransition(
                            scale: pulseAnimation,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFC8956C).withOpacity(0.25),
                              ),
                            ),
                          ),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFC8956C),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ],
                      ),
                    ],
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

class CommunityPanel extends StatelessWidget {
  const CommunityPanel({
    super.key,
    required this.data,
    required this.notifier,
    required this.isVoting,
  });

  final ProductDetailResponse data;
  final ProductDetailNotifier notifier;
  final bool isVoting;

  @override
  Widget build(BuildContext context) {
    return _PremiumPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Community', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(999)),
                child: Text('%${data.trust.scorePercent} güven', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF2E7D32), fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: data.trust.scorePercent / 100,
              minHeight: 8,
              backgroundColor: const Color(0xFFEDE0D4),
              color: const Color(0xFF66BB6A),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: isVoting
                      ? null
                      : () => notifier.votePrice(priceId: data.bestPrice.id, isApproved: true),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(12),
                    backgroundColor: const Color(0xFFE8F5E9),
                    foregroundColor: const Color(0xFF2E7D32),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Approve (${data.trust.approveCount})', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: isVoting
                      ? null
                      : () => notifier.votePrice(priceId: data.bestPrice.id, isApproved: false),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(12),
                    backgroundColor: const Color(0xFFFFEBEE),
                    foregroundColor: const Color(0xFFC62828),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Reject (${data.trust.rejectCount})', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CommentsPanel extends StatelessWidget {
  const CommentsPanel({
    super.key,
    required this.state,
    required this.notifier,
    required this.controller,
  });

  final ProductDetailState state;
  final ProductDetailNotifier notifier;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final comments = state.data!.comments.take(2).toList();

    return _PremiumPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Yorumlar', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          ...comments.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: _hexColor(c.avatarBgHex),
                    child: Text(c.author.isNotEmpty ? c.author[0] : '?', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF5EDE4),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(0),
                          topRight: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      child: Text(c.text, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF5D4037))),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF5EDE4),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      isCollapsed: true,
                      hintText: 'Yorum ekle...',
                      hintStyle: GoogleFonts.inter(fontSize: 13),
                      border: InputBorder.none,
                    ),
                    style: GoogleFonts.inter(fontSize: 13),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: SizedBox(
                    height: 36,
                    width: 36,
                    child: ElevatedButton(
                      onPressed: state.isSubmittingComment
                          ? null
                          : () async {
                              final text = controller.text.trim();
                              if (text.isEmpty) return;
                              final ok = await notifier.postComment(text);
                              if (ok) controller.clear();
                            },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: const Color(0xFFC8956C),
                        foregroundColor: Colors.white,
                        shape: const CircleBorder(),
                        elevation: 0,
                      ),
                      child: state.isSubmittingComment
                          ? const SizedBox(
                              height: 14,
                              width: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send, size: 16),
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

  static Color _hexColor(String hex) {
    final clean = hex.replaceFirst('#', '');
    if (clean.length == 6) return Color(int.parse('FF$clean', radix: 16));
    return const Color(0xFFC8956C);
  }
}

class _PremiumPanel extends StatelessWidget {
  const _PremiumPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }
}

class GlassIconButton extends StatefulWidget {
  const GlassIconButton({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  State<GlassIconButton> createState() => _GlassIconButtonState();
}

class _GlassIconButtonState extends State<GlassIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        scale: _pressed ? 0.95 : 1,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.5), width: 0.5),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Icon(widget.icon, color: const Color(0xFF5D4037)),
            ),
          ),
        ),
      ),
    );
  }
}

class PressableFab extends StatefulWidget {
  const PressableFab({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<PressableFab> createState() => _PressableFabState();
}

class _PressableFabState extends State<PressableFab> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 60,
          width: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _pressed ? const Color(0xFFB17A56) : const Color(0xFFC8956C),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 24, offset: const Offset(0, 12)),
            ],
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 30),
        ),
      ),
    );
  }
}
