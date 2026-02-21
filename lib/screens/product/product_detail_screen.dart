import 'dart:math' as math;
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/product_detail_api_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_detail_provider.dart';
import '../../providers/product_provider.dart';
import '../add_price/add_price_screen.dart';

// ──── Design tokens (matching reference CSS) ────
const _brown900 = Color(0xFF5D4037);
const _brown700 = Color(0xFF795548);
const _brown500 = Color(0xFF8D6E63);
const _amber600 = Color(0xFFC8956C);
const _amber400 = Color(0xFFD4A574);
const _cream100 = Color(0xFFFFF8F0);
const _cream200 = Color(0xFFF5EDE4);
const _cream300 = Color(0xFFEDE0D4);
const _success = Color(0xFF2E7D32);
const _successBg = Color(0xFFE8F5E9);
const _danger = Color(0xFFC62828);
const _dangerBg = Color(0xFFFFEBEE);

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
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen>
    with TickerProviderStateMixin {
  late final AnimationController _heroFloatController;
  late final AnimationController _chartPulseController;
  late final Animation<double> _heroFloat;
  late final Animation<double> _chartPulse;
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _heroFloatController =
        AnimationController(vsync: this, duration: const Duration(seconds: 4))
          ..repeat(reverse: true);
    _heroFloat = Tween<double>(begin: 0, end: -15).animate(
      CurvedAnimation(parent: _heroFloatController, curve: Curves.easeInOut),
    );
    _chartPulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1300))
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

  Future<void> _openAddPrice() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddPriceScreen(initialProductId: widget.productId),
      ),
    );
  }

  Future<void> _toggleFavorite(ProductDetailResponse data) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    await ref.read(firestoreServiceProvider).toggleFavorite(
      uid: user.uid,
      productId: data.id,
      payload: {'productName': data.title, 'imageUrl': data.imageUrl},
    );
  }

  Future<void> _shareProduct(ProductDetailResponse data) async {
    await Share.share("${data.title} ürününü FiyatRadar'da incele: ürün #${data.id}");
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productDetailProvider(widget.productId));
    final notifier =
        ref.read(productDetailProvider(widget.productId).notifier);

    return Scaffold(
      backgroundColor: _cream100,
      floatingActionButton: PressableFab(onPressed: _openAddPrice),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 414),
            child: Container(
              decoration: BoxDecoration(
                color: _cream100,
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
                                onToggleFavorite: () => _toggleFavorite(state.data!),
                                onShare: () => _shareProduct(state.data!),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 20, 20, 116),
                                child: Column(
                                  children: [
                                    _buildHeader(state.data!),
                                    const SizedBox(height: 32),
                                    _buildPriceCard(state.data!, state.isSubmittingVote),
                                    const SizedBox(height: 32),
                                    _buildQuickStats(state.data!),
                                    const SizedBox(height: 32),
                                    _buildChart(state.history),
                                    const SizedBox(height: 32),
                                    _buildCommunityHub(state.data!, notifier, state.isSubmittingVote),
                                    const SizedBox(height: 32),
                                    _buildComments(state, notifier),
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

  Widget _buildHeader(ProductDetailResponse data) => HeaderBlock(data: data);

  Widget _buildPriceCard(ProductDetailResponse data, bool isVoting) {
    return BestPriceCard(data: data, isVoting: isVoting);
  }

  Widget _buildQuickStats(ProductDetailResponse data) {
    return QuickStatsRow(stats: data.stats);
  }

  Widget _buildChart(List<PriceHistoryPoint> history) {
    return PriceHistoryPanel(history: history, pulseAnimation: _chartPulse);
  }

  Widget _buildCommunityHub(ProductDetailResponse data, ProductDetailNotifier notifier, bool isVoting) {
    return CommunityPanel(data: data, notifier: notifier, isVoting: isVoting);
  }

  Widget _buildComments(ProductDetailState state, ProductDetailNotifier notifier) {
    return CommentsPanel(
      state: state,
      notifier: notifier,
      controller: _commentController,
      productId: widget.productId,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// HERO SECTION
// ═══════════════════════════════════════════════════════════════════
class HeroSection extends StatelessWidget {
  const HeroSection({
    super.key,
    required this.data,
    required this.floatAnimation,
    required this.onBack,
    required this.onToggleFavorite,
    required this.onShare,
  });

  final ProductDetailResponse data;
  final Animation<double> floatAnimation;
  final VoidCallback onBack;
  final VoidCallback onToggleFavorite;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 340,
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          colors: [Colors.white, _cream200],
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
                    GlassIconButton(icon: Icons.favorite_border, onTap: onToggleFavorite),
                    const SizedBox(width: 12),
                    GlassIconButton(icon: Icons.share, onTap: onShare),
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
                child: Image.network(data.imageUrl,
                    height: 220, fit: BoxFit.contain),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// HEADER BLOCK – badges, title, meta
// ═══════════════════════════════════════════════════════════════════
class HeaderBlock extends StatelessWidget {
  const HeaderBlock({super.key, required this.data});

  final ProductDetailResponse data;

  bool get _isTrending =>
      data.priceEntryCount >= 10 || data.viewCount >= 100;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Badges ──
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...data.categories.map(
              (cat) => _Badge(label: cat, bg: _cream300, fg: _brown700),
            ),
            if (_isTrending)
              const _Badge(
                label: 'Trend',
                bg: Color(0xFFFFF3E0),
                fg: Color(0xFFEF6C00),
                icon: Icons.local_fire_department,
              ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Title ──
        Text(
          data.title,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: _brown900,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 8),

        // ── Meta row ──
        Row(
          children: [
            const Icon(Icons.visibility_outlined, size: 16, color: _brown500),
            const SizedBox(width: 4),
            Text(
              '${data.viewCount} Görüntüleme',
              style: GoogleFonts.inter(fontSize: 13, color: _brown500),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('•',
                  style: GoogleFonts.inter(
                      fontSize: 18, color: _brown500, height: 1)),
            ),
            const Icon(Icons.sell_outlined, size: 16, color: _brown500),
            const SizedBox(width: 4),
            Text(
              '${data.priceEntryCount} Fiyat Girişi',
              style: GoogleFonts.inter(fontSize: 13, color: _brown500),
            ),
          ],
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.bg,
    required this.fg,
    this.icon,
  });

  final String label;
  final Color bg;
  final Color fg;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w600, color: fg),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// BEST PRICE CARD
// ═══════════════════════════════════════════════════════════════════
class BestPriceCard extends ConsumerWidget {
  const BestPriceCard({super.key, required this.data, required this.isVoting});

  final ProductDetailResponse data;
  final bool isVoting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = data.bestPrice;
    final priceText = p.price.toStringAsFixed(0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_brown900, _brown700],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -36,
            right: -36,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                color: Colors.transparent,
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.2),
                    blurRadius: 80,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('👑 En İyi Fiyat', style: GoogleFonts.inter(color: _amber400)),
              const SizedBox(height: 16),
              Text(p.store, style: GoogleFonts.inter(color: Colors.white70)),
              const SizedBox(height: 8),
              Text(
                '$priceText₺',
                style: GoogleFonts.dmSans(
                  fontSize: 48,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _VipContributorChip(bestPrice: p),
              const SizedBox(height: 18),
              Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      final service = ref.read(productDetailApiServiceProvider);
                      final coords = await service.resolveStoreCoordinates(p);
                      if (coords == null) return;

                      final uri = Uri.parse(
                        'https://www.google.com/maps/search/?api=1&query=${coords.latitude},${coords.longitude}',
                      );
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: _amber600,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text('Mağazaya Git', style: TextStyle(color: Colors.white)),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 16, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () async {
                      final user = ref.read(authStateProvider).valueOrNull;
                      if (user == null) return;
                      await ref.read(firestoreServiceProvider).reportPrice(
                        priceId: p.id,
                        userId: user.uid,
                        reason: 'Ürün detay fiyat raporu',
                        contextId: data.id,
                      );
                    },
                    icon: const Icon(Icons.flag_outlined, color: Colors.white),
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

class _VipContributorChip extends ConsumerWidget {
  const _VipContributorChip({required this.bestPrice});

  final BestPrice bestPrice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayName = bestPrice.userName.isNotEmpty ? bestPrice.userName : 'Anonim';
    final vipGradient = const [Color(0xFF00F2FE), Color(0xFF4FACFE)];

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        final userSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(bestPrice.userId)
            .get();
        final userData = userSnap.data() ?? const <String, dynamic>{};
        final trustScore = (userData['trustScorePercent'] as num?)?.toInt() ??
            (userData['reliabilityScore'] as num?)?.toInt() ??
            bestPrice.userTrustScore;
        final level = (userData['eliteLevel'] ?? userData['level'] ?? bestPrice.userTier).toString();

        if (!context.mounted) return;
        await showModalBottomSheet<void>(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (ctx) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 34),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    boxShadow: [
                      BoxShadow(
                        color: _brown900.withOpacity(0.14),
                        blurRadius: 24,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Elmas VIP Profili',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _brown900,
                          )),
                      const SizedBox(height: 12),
                      Text('Elmas Seviyesi: $level',
                          style: GoogleFonts.inter(fontSize: 14, color: _brown700)),
                      const SizedBox(height: 8),
                      Text('Güven Skoru: %$trustScore',
                          style: GoogleFonts.inter(fontSize: 14, color: _brown700)),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white.withOpacity(0.08),
          border: Border.all(color: Colors.white24),
        ),
        child: ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => LinearGradient(colors: vipGradient).createShader(bounds),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.diamond, size: 18, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                displayName,
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// QUICK STATS
// ═══════════════════════════════════════════════════════════════════
class QuickStatsRow extends StatelessWidget {
  const QuickStatsRow({super.key, required this.stats});

  final PriceStats stats;

  @override
  Widget build(BuildContext context) {
    Widget card(String title, String value,
        {bool highlighted = false, Color? valueColor}) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: highlighted ? const Color(0xFFFFF8E1) : _cream200,
            borderRadius: BorderRadius.circular(20),
            border: highlighted
                ? Border.all(color: const Color(0xFFFFC107))
                : Border.all(color: Colors.transparent),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      color: _brown500,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(value,
                  style: GoogleFonts.dmSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: valueColor ?? _brown900)),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        card('En Düşük Fiyat', '${stats.lowest.toStringAsFixed(0)}₺',
            highlighted: true, valueColor: _success),
        const SizedBox(width: 12),
        card('Ortalama',
            '${stats.average.toStringAsFixed(2).replaceAll('.', ',')}₺'),
        const SizedBox(width: 12),
        card('En Yüksek', '${stats.highest.toStringAsFixed(0)}₺'),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// PRICE HISTORY (fl_chart) - SENIOR FIX
// ═══════════════════════════════════════════════════════════════════
class PriceHistoryPanel extends StatelessWidget {
  const PriceHistoryPanel({super.key, required this.history, required this.pulseAnimation});

  final List<PriceHistoryPoint> history;
  final Animation<double> pulseAnimation;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return _PremiumPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('Fiyat Geçmişi', subtitle: 'Son 30 gün'),
            const SizedBox(height: 18),
            Text('Fiyat geçmişi bulunamadı.', style: GoogleFonts.inter(color: const Color(0xFF8D6E63))),
          ],
        ),
      );
    }

    final minPrice = history.map((e) => e.price).reduce(math.min);
    final maxPrice = history.map((e) => e.price).reduce(math.max);
    final chartMinY = (minPrice * 0.8).floorToDouble();
    final chartMaxY = (maxPrice * 1.2).ceilToDouble();

    final firstReportedAt = history.first.reportedAt;
    final normalizedSpots = history
        .map(
          (point) => FlSpot(
            point.reportedAt.difference(firstReportedAt).inHours / 24,
            point.price,
          ),
        )
        .toList();
    final maxX = normalizedSpots.isEmpty ? 1.0 : normalizedSpots.last.x;
    final todaySpot = normalizedSpots.isEmpty ? null : normalizedSpots.last;

    return _PremiumPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Fiyat Geçmişi', subtitle: 'Son 30 gün'),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: Stack(
              children: [
                LineChart(
                  LineChartData(
                    minX: 0,
                    maxX: maxX == 0 ? 1.0 : maxX,
                    minY: chartMinY,
                    maxY: chartMaxY,
                    showingTooltipIndicators: normalizedSpots.isEmpty
                        ? []
                        : [
                            ShowingTooltipIndicators([
                              LineBarSpot(
                                LineChartBarData(spots: normalizedSpots),
                                0,
                                normalizedSpots.last,
                              ),
                            ]),
                          ],
                    lineTouchData: LineTouchData(
                      enabled: false,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (_) => const Color(0xFF5D4037),
                        tooltipRoundedRadius: 8,
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots
                              .map(
                                (spot) => LineTooltipItem(
                                  '${spot.y.toStringAsFixed(0)}₺',
                                  GoogleFonts.dmSans(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                              .toList();
                        },
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval:
                          ((chartMaxY - chartMinY) / 3).clamp(1, double.infinity),
                      getDrawingHorizontalLine: (_) =>
                          FlLine(color: const Color(0xFFF5EDE4), strokeWidth: 1),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 22,
                          interval: maxX <= 0 ? 1 : maxX / 2,
                          getTitlesWidget: (value, meta) {
                            final midLabel = history[(history.length / 2).floor()].dateLabel;
                            final labels = <double, String>{
                              0: history.first.dateLabel,
                              maxX / 2: midLabel,
                              maxX: 'Bugün',
                            };
                            String? label;
                            for (final entry in labels.entries) {
                              if ((value - entry.key).abs() < 0.5) {
                                label = entry.value;
                                break;
                              }
                            }
                            if (label == null) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                label,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: const Color(0xFF8D6E63),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: normalizedSpots,
                        isCurved: true,
                        curveSmoothness: 0.35,
                        color: const Color(0xFFC8956C),
                        barWidth: 4,
                        isStrokeCapRound: true,
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              const Color(0xFFC8956C).withOpacity(0.3),
                              const Color(0xFFC8956C).withOpacity(0),
                            ],
                          ),
                        ),
                        dotData: const FlDotData(show: false),
                      ),
                    ],
                  ),
                ),
                if (todaySpot != null)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final safeMaxX = maxX <= 0 ? 1.0 : maxX;
                      final safeRangeY = (chartMaxY - chartMinY) == 0
                          ? 1.0
                          : (chartMaxY - chartMinY);
                      final dx =
                          ((todaySpot.x / safeMaxX) * constraints.maxWidth).clamp(0.0, constraints.maxWidth);
                      final dy = (((chartMaxY - todaySpot.y) / safeRangeY) * constraints.maxHeight)
                          .clamp(0.0, constraints.maxHeight);

                      return Positioned(
                        left: dx - 8,
                        top: dy - 8,
                        child: ScaleTransition(
                          scale: pulseAnimation,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: _amber600,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// COMMUNITY PANEL (trust / vote)
// ═══════════════════════════════════════════════════════════════════
class CommunityPanel extends ConsumerStatefulWidget {
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
  ConsumerState<CommunityPanel> createState() => _CommunityPanelState();
}

class _CommunityPanelState extends ConsumerState<CommunityPanel> {
  bool _sending = false;
  bool? _localVote;

  Future<void> _submitVote(bool isApproved) async {
    setState(() {
      _sending = true;
      _localVote = isApproved;
    });
    await widget.notifier.votePrice(
      priceId: widget.data.bestPrice.id,
      isApproved: isApproved,
    );
    if (!mounted) return;
    setState(() {
      _sending = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final voteStream = user == null
        ? const Stream<String?>.empty()
        : ref.read(firestoreServiceProvider).streamUserVoteValue(widget.data.bestPrice.id, user.uid);

    return StreamBuilder<String?>(
      stream: voteStream,
      builder: (context, snapshot) {
        final remoteVote = snapshot.data == 'yes'
            ? true
            : snapshot.data == 'no'
                ? false
                : null;
        final effectiveVote = _localVote ?? remoteVote;

        var approveCount = widget.data.trust.approveCount;
        var rejectCount = widget.data.trust.rejectCount;
        if (effectiveVote == true) {
          approveCount += 1;
        } else if (effectiveVote == false) {
          rejectCount += 1;
        }
        final total = approveCount + rejectCount;
        final trustScore = total == 0 ? 0 : ((approveCount / total) * 100).round();

        return _PremiumPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Topluluk Merkezi',
                      style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _brown900)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _successBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_user, size: 14, color: _success),
                        const SizedBox(width: 4),
                        Text(
                          '%$trustScore Güvenilir',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: trustScore / 100,
                  minHeight: 8,
                  backgroundColor: _cream300,
                  color: _success,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _TrustButton(
                      label: 'Doğrula ($approveCount)',
                      icon: Icons.thumb_up_outlined,
                      color: _success,
                      bgColor: _successBg,
                      isActive: effectiveVote == true,
                      onPressed: (_sending || widget.isVoting)
                          ? null
                          : () => _submitVote(true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TrustButton(
                      label: 'Yanlış ($rejectCount)',
                      icon: Icons.thumb_down_outlined,
                      color: _danger,
                      bgColor: _dangerBg,
                      isActive: effectiveVote == false,
                      onPressed: (_sending || widget.isVoting)
                          ? null
                          : () => _submitVote(false),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TrustButton extends StatelessWidget {
  const _TrustButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onPressed,
    required this.isActive,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback? onPressed;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isActive ? color.withOpacity(0.16) : bgColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// COMMENTS PANEL
// ═══════════════════════════════════════════════════════════════════
class CommentsPanel extends StatelessWidget {
  const CommentsPanel({
    super.key,
    required this.state,
    required this.notifier,
    required this.controller,
    required this.productId,
  });

  final ProductDetailState state;
  final ProductDetailNotifier notifier;
  final TextEditingController controller;
  final String productId;

  @override
  Widget build(BuildContext context) {
    final allComments = state.data!.comments;
    final comments = allComments.take(2).toList();

    return _PremiumPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section header ──
          _sectionHeader('Son Yorumlar',
              subtitle: '${allComments.length} Yorum'),
          const SizedBox(height: 16),

          // ── Comment cards ──
          ...comments.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: _hexColor(c.avatarBgHex),
                    child: Text(
                      c.author.isNotEmpty ? c.author[0] : '?',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: _cream200,
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                c.author,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _brown900,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    c.timeAgo,
                                    style: GoogleFonts.inter(
                                        fontSize: 11, color: _brown500),
                                  ),
                                  const SizedBox(width: 8),
                                  _CommentReportButton(commentId: c.id, productId: productId),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            c.text,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: _brown700,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Comment input ──
          const SizedBox(height: 8),
          Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: _cream200,
                child: Icon(Icons.person, color: _brown500, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: _cream300),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: controller,
                          decoration: InputDecoration(
                            isCollapsed: true,
                            hintText: 'Bir yorum yaz...',
                            hintStyle: GoogleFonts.inter(
                                fontSize: 13, color: _brown500),
                            border: InputBorder.none,
                          ),
                          style: GoogleFonts.inter(
                              fontSize: 13, color: _brown900),
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
                                    final text =
                                        controller.text.trim();
                                    if (text.isEmpty) return;
                                    final ok = await notifier
                                        .postComment(text);
                                    if (ok) controller.clear();
                                  },
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              backgroundColor: _amber600,
                              foregroundColor: Colors.white,
                              shape: const CircleBorder(),
                              elevation: 0,
                            ),
                            child: state.isSubmittingComment
                                ? const SizedBox(
                                    height: 14,
                                    width: 14,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white),
                                  )
                                : const Icon(Icons.send, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── View all button ──
          if (allComments.length > 2) ...[
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => AllCommentsScreen(comments: allComments)));
                },
                child: Text(
                  'Tüm Yorumları Gör',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _brown500,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Color _hexColor(String hex) {
    final clean = hex.replaceFirst('#', '');
    if (clean.length == 6) return Color(int.parse('FF$clean', radix: 16));
    return _amber600;
  }
}

class _CommentReportButton extends ConsumerWidget {
  const _CommentReportButton({required this.commentId, required this.productId});

  final String commentId;
  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () async {
        final user = ref.read(authStateProvider).valueOrNull;
        if (user == null) return;
        await ref.read(firestoreServiceProvider).reportComment(
          commentId: commentId,
          userId: user.uid,
          reason: 'Ürün detay yorum raporu',
          contextId: productId,
        );
      },
      child: const Icon(Icons.flag_outlined, size: 15, color: _brown500),
    );
  }
}

class AllCommentsScreen extends StatelessWidget {
  const AllCommentsScreen({super.key, required this.comments});

  final List<ProductComment> comments;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tüm yorumlar')),
      body: ListView.builder(
        itemCount: comments.length,
        itemBuilder: (context, index) {
          final c = comments[index];
          return ListTile(
            title: Text(c.author),
            subtitle: Text(c.text),
            trailing: Text(c.timeAgo),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ═══════════════════════════════════════════════════════════════════

Widget _sectionHeader(String title, {String? subtitle}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(title,
          style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _brown900)),
      if (subtitle != null)
        Text(subtitle,
            style: GoogleFonts.inter(fontSize: 13, color: _brown500)),
    ],
  );
}

class _PremiumPanel extends StatelessWidget {
  const _PremiumPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10)),
        ],
      ),
      child: child,
    );
  }
}

class GlassIconButton extends StatefulWidget {
  const GlassIconButton(
      {super.key, required this.icon, required this.onTap});

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
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: Colors.white24, width: 0.5),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: Icon(widget.icon, color: _brown900),
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
            color: _pressed ? const Color(0xFFB17A56) : _amber600,
            boxShadow: [
              BoxShadow(
                  color: _amber600.withOpacity(0.5),
                  blurRadius: 24,
                  offset: const Offset(0, 12)),
            ],
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}
