import 'dart:ui';

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
    _heroFloat = Tween<double>(begin: 0, end: -10).animate(
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
    await Share.share(
      "${data.title} ürününü FiyatRadar'da incele: ürün #${data.id}",
    );
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
                                    const EdgeInsets.fromLTRB(20, 24, 20, 100),
                                child: Column(
                                  children: [
                                    HeaderBlock(data: state.data!),
                                    const SizedBox(height: 24),
                                    BestPriceCard(
                                      data: state.data!,
                                      isVoting: state.isSubmittingVote,
                                    ),
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
                                      productId: widget.productId,
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
              _Badge(
                label: 'Trend',
                bg: const Color(0xFFFFF3E0),
                fg: const Color(0xFFEF6C00),
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
    final tier = _parseTier(p.userTier);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment(-0.4, -0.4),
          end: Alignment(1, 1),
          colors: [_brown900, _brown700],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('👑 En İyi Fiyat', style: GoogleFonts.inter(color: _amber400)),
          const SizedBox(height: 12),
          Text(p.store, style: GoogleFonts.inter(color: Colors.white70)),
          const SizedBox(height: 4),
          Text('$priceText₺', style: GoogleFonts.dmSans(fontSize: 40, color: Colors.white, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: tier.bgColor,
              border: Border.all(color: tier.borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(tier.icon, size: 16, color: tier.iconColor),
                const SizedBox(width: 6),
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(colors: tier.nameGradient).createShader(bounds),
                  child: Text(
                    '${_tierNamePrefix(p.userTier)} ${p.userName.isNotEmpty ? p.userName : 'Anonim'}',
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              GestureDetector(
                onTap: () async {
                  final service = ref.read(productDetailApiServiceProvider);
                  final coords = await service.resolveStoreCoordinates(p);
                  if (coords == null) return;
                  final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${coords.latitude},${coords.longitude}');
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: _amber600, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text('Mağazaya Git', style: TextStyle(color: Colors.white)),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward, size: 16, color: Colors.white),
                    ],
                  ),
                ),
              ),
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
    );
  }
}

// ──── Pulsing green dot ────
class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat();
    _scale = Tween<double>(begin: 1, end: 2.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 12,
      height: 12,
      child: Stack(
        alignment: Alignment.center,
        children: [
          FadeTransition(
            opacity: Tween<double>(begin: 0.6, end: 0).animate(_ctrl),
            child: ScaleTransition(
              scale: _scale,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: _success,
                ),
              ),
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: _success,
            ),
          ),
        ],
      ),
    );
  }
}

// ──── Tier styling helper ────
class _TierStyle {
  const _TierStyle({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.borderColor,
    required this.nameGradient,
  });

  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final Color borderColor;
  final List<Color> nameGradient;
}

_TierStyle _parseTier(String tier) {
  final t = tier.toLowerCase();
  if (t.contains('elmas') || t.contains('diamond')) {
    return _TierStyle(
      icon: Icons.diamond,
      iconColor: const Color(0xFF00f2fe),
      bgColor: const Color(0xFF00f2fe).withOpacity(0.1),
      borderColor: const Color(0xFF4facfe).withOpacity(0.3),
      nameGradient: const [Color(0xFFe0f7fa), Color(0xFF00f2fe)],
    );
  }
  if (t.contains('altın') || t.contains('gold')) {
    return _TierStyle(
      icon: Icons.workspace_premium,
      iconColor: const Color(0xFFFFC107),
      bgColor: const Color(0xFFFFC107).withOpacity(0.1),
      borderColor: const Color(0xFFFFC107).withOpacity(0.3),
      nameGradient: const [Color(0xFFFFF8E1), Color(0xFFFFC107)],
    );
  }
  if (t.contains('gümüş') || t.contains('silver')) {
    return _TierStyle(
      icon: Icons.workspace_premium,
      iconColor: const Color(0xFF8D99AE),
      bgColor: const Color(0xFF8D99AE).withOpacity(0.1),
      borderColor: const Color(0xFF8D99AE).withOpacity(0.3),
      nameGradient: const [Color(0xFFE0E0E0), Color(0xFF8D99AE)],
    );
  }
  // default = bronze / new
  return _TierStyle(
    icon: Icons.shield_outlined,
    iconColor: const Color(0xFF8D5A3A),
    bgColor: const Color(0xFF8D5A3A).withOpacity(0.1),
    borderColor: const Color(0xFF8D5A3A).withOpacity(0.3),
    nameGradient: const [Color(0xFFD7CCC8), Color(0xFF8D5A3A)],
  );
}


String _tierNamePrefix(String tier) {
  final value = tier.toLowerCase();
  if (value.contains('elmas') || value.contains('diamond')) return '💎';
  return '';
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: highlighted ? const Color(0xFFFFF8E1) : _cream200,
            borderRadius: BorderRadius.circular(20),
            border: highlighted
                ? Border.all(color: const Color(0xFFFFC107))
                : Border.all(color: Colors.transparent),
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
// PRICE HISTORY (fl_chart)
// ═══════════════════════════════════════════════════════════════════
class PriceHistoryPanel extends StatelessWidget {
  const PriceHistoryPanel(
      {super.key, required this.history, required this.pulseAnimation});

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
            const SizedBox(height: 14),
            Text('Fiyat geçmişi bulunamadı.',
                style: GoogleFonts.inter(color: _brown500)),
          ],
        ),
      );
    }

    final values = history.map((e) => e.price).toList();
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final spread = (max - min).abs() < 1 ? 1 : max - min;
    final spots = history.asMap().entries.map((e) {
      final scaled = 30 + ((e.value.price - min) / spread) * 60;
      return FlSpot(e.key.toDouble(), scaled);
    }).toList();
    final latestScaledY = spots.isEmpty ? 30.0 : spots.last.y;
    final latestTop = (95 - latestScaledY) / (95 - 25) * 130;

    return _PremiumPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Fiyat Geçmişi', subtitle: 'Son 30 gün'),
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
                    gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 30,
                        getDrawingHorizontalLine: (value) => FlLine(
                              color: _cream200,
                              strokeWidth: 1,
                            )),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 36,
                          interval: 30,
                          getTitlesWidget: (value, _) {
                            String label;
                            if (value > 80) {
                              label = '${max.toStringAsFixed(0)}₺';
                            } else if (value > 50) {
                              label =
                                  '${((max + min) / 2).toStringAsFixed(0)}₺';
                            } else {
                              label = '${min.toStringAsFixed(0)}₺';
                            }
                            return Text(label,
                                style: GoogleFonts.dmSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _brown500));
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, _) {
                            final i = value.toInt();
                            if (i == 0 && history.isNotEmpty) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(history.first.dateLabel,
                                    style: GoogleFonts.inter(
                                        fontSize: 11, color: _brown500)),
                              );
                            }
                            if (i == (history.length / 2).floor() &&
                                history.length > 2) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                    history[(history.length / 2).floor()]
                                        .dateLabel,
                                    style: GoogleFonts.inter(
                                        fontSize: 11, color: _brown500)),
                              );
                            }
                            if (i == history.length - 1) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text('Bugün',
                                    style: GoogleFonts.inter(
                                        fontSize: 11, color: _brown500)),
                              );
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
                        color: _amber600,
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              _amber600.withOpacity(0.4),
                              _amber600.withOpacity(0),
                            ],
                          ),
                        ),
                        dotData: const FlDotData(show: false),
                      ),
                    ],
                  ),
                ),
                // Current price dot + tag
                Positioned(
                  right: 0,
                  top: latestTop.clamp(4, 104),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _brown900,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${history.last.price.toStringAsFixed(0)}₺',
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      // Small arrow
                      CustomPaint(
                        size: const Size(8, 4),
                        painter: _TrianglePainter(_brown900),
                      ),
                      const SizedBox(height: 2),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          ScaleTransition(
                            scale: pulseAnimation,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _amber600.withOpacity(0.25),
                              ),
                            ),
                          ),
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _amber600,
                              border:
                                  Border.all(color: Colors.white, width: 2),
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

class _TrianglePainter extends CustomPainter {
  _TrianglePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════════
// COMMUNITY PANEL (trust / vote)
// ═══════════════════════════════════════════════════════════════════
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
          // ── Header ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Topluluk Merkezi',
                  style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _brown900)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _successBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_user,
                        size: 14, color: _success),
                    const SizedBox(width: 4),
                    Text(
                      '%${data.trust.scorePercent} Güvenilir',
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
          const SizedBox(height: 16),

          // ── Trust bar ──
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: data.trust.scorePercent / 100,
              minHeight: 8,
              backgroundColor: _cream300,
              color: _success,
            ),
          ),
          const SizedBox(height: 16),

          // ── Vote buttons ──
          Row(
            children: [
              Expanded(
                child: _TrustButton(
                  label: 'Doğrula (${data.trust.approveCount})',
                  icon: Icons.thumb_up_outlined,
                  color: _success,
                  bgColor: _successBg,
                  onPressed: isVoting
                      ? null
                      : () => notifier.votePrice(
                          priceId: data.bestPrice.id, isApproved: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TrustButton(
                  label: 'Yanlış (${data.trust.rejectCount})',
                  icon: Icons.thumb_down_outlined,
                  color: _danger,
                  bgColor: _dangerBg,
                  opacity: 0.7,
                  onPressed: isVoting
                      ? null
                      : () => notifier.votePrice(
                          priceId: data.bestPrice.id, isApproved: false),
                ),
              ),
            ],
          ),
        ],
      ),
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
    this.opacity = 1.0,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback? onPressed;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Material(
        color: bgColor,
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
              CircleAvatar(
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
                  'Tüm yorumları gör',
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: _brown900.withOpacity(0.03),
              blurRadius: 20,
              offset: const Offset(0, 4)),
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
                color: Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: Colors.white.withOpacity(0.5), width: 0.5),
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
