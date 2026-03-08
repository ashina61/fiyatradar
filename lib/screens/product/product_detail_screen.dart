import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

// --- PROJE YOLLARINI KONTROL ET ---
import '../../models/product_detail_api_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_detail_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/watchlist_service.dart';
import '../../utils/elite_level_engine.dart';
import '../add_price/add_price_screen.dart';

// ---------------------------------------------------------------------------
// 🎨 PORSCHE DNA RENK PALETİ
// ---------------------------------------------------------------------------
const Color pxDark = Color(0xFF0D0805);        
const Color pxSurface = Color(0xFF17100B);     
const Color pxCream = Color(0xFFF9F6F2);       
const Color pxGold = Color(0xFFD4AF37);        
const Color pxCaramel = Color(0xFF6B4226);     
const Color pxWhite = Color(0xFFFFFFFF);
const Color pxSuccess = Color(0xFF35D04F);     
const Color pxAlert = Color(0xFFE53935);
const Color pxMuted = Color(0xFF8C7B70);

// --- SEVİYE GRADİENTLERİ ---
const LinearGradient goldGradient = LinearGradient(colors: [Color(0xFFF3E5AB), Color(0xFFD4AF37), Color(0xFFAA771C)]);
const LinearGradient silverGradient = LinearGradient(colors: [Color(0xFFE0E0E0), Color(0xFFBDBDBD), Color(0xFF9E9E9E)]);
const LinearGradient bronzeGradient = LinearGradient(colors: [Color(0xFFFAD6A5), Color(0xFFCD7F32), Color(0xFF8D5524)]);

// Seviyeye Göre Gradient Seçici
LinearGradient getGradientForLevel(int level) {
  if (level >= 8) return goldGradient;
  if (level >= 4) return silverGradient;
  return bronzeGradient;
}

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.productId, this.highlightedCommentId, this.highlightedPriceId});
  final String productId;
  final String? highlightedCommentId;
  final String? highlightedPriceId;

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> with TickerProviderStateMixin {
  late final AnimationController _heroFloatController;
  late final Animation<double> _heroFloat;
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _heroFloatController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    _heroFloat = Tween<double>(begin: 0, end: -12).animate(CurvedAnimation(parent: _heroFloatController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _heroFloatController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  // --- AKSİYONLAR ---
  Future<void> _openAddPrice() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddPriceScreen(initialProductId: widget.productId)));
    if (!mounted) return;
    await ref.read(productDetailProvider(widget.productId).notifier).load();
  }

  Future<void> _toggleFavorite(ProductDetailResponse data) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    HapticFeedback.lightImpact();
    await ref.read(firestoreServiceProvider).toggleFavorite(uid: user.uid, productId: data.id, payload: {'productName': data.title, 'imageUrl': data.imageUrl});
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productDetailProvider(widget.productId));
    final notifier = ref.read(productDetailProvider(widget.productId).notifier);
    final currentUser = ref.watch(authStateProvider).valueOrNull;
    final favoriteStream = currentUser == null ? const Stream<bool>.empty() : ref.watch(firestoreServiceProvider).isFavoriteStream(uid: currentUser.uid, productId: widget.productId);

    return Scaffold(
      backgroundColor: pxDark, // Arka plan tamamen lüks siyah
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: pxGold))
          : state.error != null
              ? Center(child: Text(state.error!, style: const TextStyle(color: pxWhite)))
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      // 💥 1. KARANLIK SHOWROOM 💥
                      _PxShowroom(
                        data: state.data!, floatAnimation: _heroFloat, favoriteStream: favoriteStream,
                        onBack: () => Navigator.pop(context), onToggleFavorite: () => _toggleFavorite(state.data!),
                      ),

                      // 💥 2. KESİŞİM VE KONSOL (Mükemmel Overlap) 💥
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Alt Katman: Krem ve Siyah Konsollar
                          Container(
                            margin: const EdgeInsets.only(top: 40), // Üstteki siyahla kesişim alanı
                            decoration: const BoxDecoration(
                              color: pxCream,
                              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                            ),
                            child: Column(
                              children: [
                                const SizedBox(height: 60), // Kadrana yer aç
                                
                                // 💥 3. KREM RENGİ ORTA BÖLGE 💥
                                _PxCreamContent(data: state.data!, history: state.history, onAddPrice: _openAddPrice),
                                
                                // 💥 4. KARANLIK ALT KONSOL (Telemetri ve Yorumlar) 💥
                                _PxDarkBottomBoard(state: state, notifier: notifier, controller: _commentController),
                              ],
                            ),
                          ),

                          // Üst Katman: Havada Asılı Duran Fiyat Kadranı
                          Positioned(
                            top: 0, left: 20, right: 20,
                            child: _PxDashboardCluster(bestPrice: state.data!.bestPrice),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }
}

// ---------------------------------------------------------------------------
// 1. KARANLIK SHOWROOM
// ---------------------------------------------------------------------------
class _PxShowroom extends StatelessWidget {
  final ProductDetailResponse data; final Animation<double> floatAnimation;
  final Stream<bool> favoriteStream; final VoidCallback onBack, onToggleFavorite;

  const _PxShowroom({required this.data, required this.floatAnimation, required this.favoriteStream, required this.onBack, required this.onToggleFavorite});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, bottom: 20),
      decoration: const BoxDecoration(
        color: pxDark,
        gradient: RadialGradient(colors: [Color(0x1AD4AF37), pxDark], center: Alignment(0, -0.3), radius: 0.8),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _PxIconBtn(icon: Icons.arrow_back_ios_new, onTap: onBack),
                Row(
                  children: [
                    StreamBuilder<bool>(
                      stream: favoriteStream,
                      builder: (context, snapshot) {
                        final isFav = snapshot.data ?? false;
                        return _PxIconBtn(
                          icon: isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? pxAlert : pxGold,
                          bgColor: isFav ? pxAlert.withOpacity(0.1) : pxSurface,
                          borderColor: isFav ? pxAlert.withOpacity(0.3) : Colors.white10,
                          onTap: onToggleFavorite,
                        );
                      }
                    ),
                    const SizedBox(width: 12),
                    _PxIconBtn(icon: Icons.share, onTap: () => Share.share("${data.title} ürününü FiyatRadar'da incele!")),
                  ],
                ),
              ],
            ),
          ),
          
          AnimatedBuilder(
            animation: floatAnimation,
            builder: (_, child) => Transform.translate(offset: Offset(0, floatAnimation.value), child: child),
            child: Container(
              margin: const EdgeInsets.only(top: 20, bottom: 20),
              height: 180,
              decoration: const BoxDecoration(boxShadow: [BoxShadow(color: Color(0xCC000000), blurRadius: 40, offset: Offset(0, 20))]),
              child: Image.network(data.imageUrl, fit: BoxFit.contain),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(data.brand.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: pxGold, letterSpacing: 2)),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('•', style: TextStyle(color: pxCaramel))),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(border: Border.all(color: Colors.white10), borderRadius: BorderRadius.circular(6), color: Colors.white.withOpacity(0.05)), child: Text(data.category.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white70))),
                  ],
                ),
                const SizedBox(height: 12),
                Text(data.title, textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w900, color: pxWhite, height: 1.1)),
                const SizedBox(height: 8),
                Text('${data.viewCount} Görüntüleme • ${data.priceEntryCount} Fiyat Girişi', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2. YÜZEN FİYAT KARTI
// ---------------------------------------------------------------------------
class _PxDashboardCluster extends StatefulWidget {
  final ProductPrice bestPrice;
  const _PxDashboardCluster({required this.bestPrice});
  @override
  State<_PxDashboardCluster> createState() => _PxDashboardClusterState();
}
class _PxDashboardClusterState extends State<_PxDashboardCluster> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl; late final Animation<double> _pulseAnim;
  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
    _pulseAnim = Tween<double>(begin: 1.0, end: 2.5).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut));
  }
  @override
  void dispose() { _pulseCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: pxSurface, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: pxGold.withOpacity(0.4)),
        boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 40, offset: Offset(0, 20))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_,__) => Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(color: pxSuccess, shape: BoxShape.circle, boxShadow: [BoxShadow(color: pxSuccess.withOpacity(1 - (_pulseCtrl.value)), blurRadius: 15 * _pulseAnim.value)]),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.bestPrice.store, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: pxSuccess)),
                  const SizedBox(height: 2),
                  Text('${widget.bestPrice.createdAtLabel} eklendi', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: pxGold)),
                ],
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic,
            children: [
              Text(widget.bestPrice.price.toInt().toString(), style: GoogleFonts.dmSans(fontSize: 36, fontWeight: FontWeight.w700, color: pxWhite, height: 1, letterSpacing: -1)),
              Text(',${((widget.bestPrice.price % 1) * 100).toInt().toString().padLeft(2, '0')}₺', style: const TextStyle(fontSize: 18, color: Colors.white60, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3. KREM RENGİ ORTA BÖLGE
// ---------------------------------------------------------------------------
class _PxCreamContent extends ConsumerWidget {
  final ProductDetailResponse data; final List<PriceHistoryPoint> history; final VoidCallback onAddPrice;
  const _PxCreamContent({required this.data, required this.history, required this.onAddPrice});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // 1. Ekleyen Verisi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 48, height: 48, borderRadius: BorderRadius.circular(16),
                    decoration: BoxDecoration(gradient: goldGradient, boxShadow: [BoxShadow(color: pxGold.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 4))]),
                    child: const Icon(Icons.workspace_premium, color: pxWhite, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('FİYATI EKLEYEN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black38, letterSpacing: 1)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          _GradientText(data.bestPrice.userName, gradient: goldGradient, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                          const SizedBox(width: 4), const Icon(Icons.verified, color: Color(0xFF007AFF), size: 18),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  _PxActionBtn(icon: Icons.navigation, onTap: () {}),
                  const SizedBox(width: 8), _PxActionBtn(icon: Icons.outlined_flag, color: pxAlert, onTap: () {}),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // 2. Hızlı İstatistikler
          Row(
            children: [
              Expanded(child: _StatBox(icon: Icons.south_east, label: 'En Düşük', value: '${data.stats.lowest.toStringAsFixed(2)}₺', isDark: true)),
              const SizedBox(width: 12), Expanded(child: _StatBox(icon: Icons.drag_handle, label: 'Ortalama', value: '${data.stats.average.toStringAsFixed(2)}₺', isDark: false)),
              const SizedBox(width: 12), Expanded(child: _StatBox(icon: Icons.north_east, label: 'En Yüksek', value: '${data.stats.highest.toStringAsFixed(2)}₺', isDark: false)),
            ],
          ),

          const SizedBox(height: 32),

          // 💥 3. YENİ: FİYAT GEÇMİŞİ GRAFİĞİ (Karanlık Modül) 💥
          if (history.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: pxSurface, borderRadius: BorderRadius.circular(24),
                border: Border.all(color: pxGold.withOpacity(0.3)),
                boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 20, offset: Offset(0, 10))],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(children: [Icon(Icons.timeline, color: pxGold, size: 18), SizedBox(width: 6), Text('FİYAT GEÇMİŞİ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: pxWhite, letterSpacing: 1))]),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(6)), child: const Text('Son 30 Gün', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white60))),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 80,
                    child: LineChart(
                      LineChartData(
                        minX: 0, maxX: (history.length - 1).toDouble(),
                        minY: (history.map((e) => e.price).reduce(math.min) * 0.9),
                        maxY: (history.map((e) => e.price).reduce(math.max) * 1.1),
                        lineTouchData: const LineTouchData(enabled: false),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: history.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.price)).toList(),
                            isCurved: true, curveSmoothness: 0.35, color: pxGold, barWidth: 3,
                            shadow: const Shadow(color: Color(0x66D4AF37), blurRadius: 8, offset: Offset(0, 4)),
                            dotData: FlDotData(
                              show: true, checkToShowDot: (spot, barData) => spot.x == barData.spots.last.x,
                              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 5, color: pxSuccess, strokeWidth: 0, strokeColor: Colors.transparent),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(history.first.dateLabel, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white38)),
                      const Text('Bugün', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: pxSuccess)),
                    ],
                  ),
                ],
              ),
            ),

          const SizedBox(height: 32),

          // 4. Yeni Fiyat Ekle Butonu
          GestureDetector(
            onTap: onAddPrice,
            child: Container(
              width: double.infinity, height: 64,
              decoration: BoxDecoration(color: pxDark, borderRadius: BorderRadius.circular(20), border: Border.all(color: pxGold.withOpacity(0.4)), boxShadow: const [BoxShadow(color: Color(0x4D1A110D), blurRadius: 20, offset: Offset(0, 10))]),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, color: pxGold, size: 24), SizedBox(width: 8),
                  Text('YENİ FİYAT EKLE', style: TextStyle(fontFamily: 'Outfit', fontSize: 15, fontWeight: FontWeight.w900, color: pxWhite, letterSpacing: 0.5)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 4. KARANLIK ALT KONSOL (Telemetri & Yorumlar)
// ---------------------------------------------------------------------------
class _PxDarkBottomBoard extends ConsumerStatefulWidget {
  final ProductDetailState state; final ProductDetailNotifier notifier; final TextEditingController controller;
  const _PxDarkBottomBoard({required this.state, required this.notifier, required this.controller});
  @override
  ConsumerState<_PxDarkBottomBoard> createState() => _PxDarkBottomBoardState();
}

class _PxDarkBottomBoardState extends ConsumerState<_PxDarkBottomBoard> {
  bool _sendingVote = false; bool _justSent = false;

  Future<void> _submitVote(bool isApproved) async {
    setState(() => _sendingVote = true); HapticFeedback.mediumImpact();
    await widget.notifier.votePrice(priceId: widget.state.data!.bestPrice.id, isApproved: isApproved);
    if(mounted) setState(() => _sendingVote = false);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.state.data!;
    final appC = data.trust.approveCount; final rejC = data.trust.rejectCount;
    final score = (appC + rejC) == 0 ? 0 : ((appC / (appC + rejC)) * 100).round();
    final user = ref.watch(authStateProvider).valueOrNull;
    final voteStream = user == null ? const Stream<String?>.empty() : ref.read(firestoreServiceProvider).streamUserVoteValue(data.bestPrice.id, user.uid);

    return Container(
      width: double.infinity, padding: const EdgeInsets.fromLTRB(24, 40, 24, 60),
      decoration: const BoxDecoration(color: pxDark, borderRadius: BorderRadius.vertical(top: Radius.circular(40))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- A. TELEMETRİ (GÜVEN KADRANI) ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(children: [Icon(Icons.speed, color: pxGold, size: 18), SizedBox(width: 8), Text('GÜVENİLİRLİK', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: pxWhite, letterSpacing: 1))]),
                    Text('%$score', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: pxSuccess)),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 4, width: double.infinity, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft, widthFactor: score / 100,
                    child: Container(decoration: BoxDecoration(color: pxSuccess, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: pxSuccess.withOpacity(0.6), blurRadius: 15)])),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Doğrulama Butonları
          StreamBuilder<String?>(
            stream: voteStream,
            builder: (context, snapshot) {
              final voteVal = snapshot.data; final hasVoted = voteVal != null;
              return Row(
                children: [
                  Expanded(child: _TelemetryBtn(label: 'FİYAT DOĞRU', count: '$appC ONAY', icon: Icons.thumb_up, type: 'approve', isActive: voteVal == 'yes', isLocked: hasVoted && voteVal != 'yes', onTap: (_sendingVote || hasVoted) ? null : () => _submitVote(true))),
                  const SizedBox(width: 16),
                  Expanded(child: _TelemetryBtn(label: 'HATALI / ESKİ', count: '$rejC İTİRAZ', icon: Icons.warning, type: 'reject', isActive: voteVal == 'no', isLocked: hasVoted && voteVal != 'no', onTap: (_sendingVote || hasVoted) ? null : () => _submitVote(false))),
                ],
              );
            }
          ),

          // --- MEKANİK AYIRICI ---
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Row(
              children: [
                Expanded(child: Container(height: 1, decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, Color(0xCC6B4226)])))),
                Container(width: 8, height: 8, margin: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: pxGold, shape: BoxShape.circle, boxShadow: [BoxShadow(color: pxGold.withOpacity(0.5), blurRadius: 15)])),
                Expanded(child: Container(height: 1, decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xCC6B4226), Colors.transparent])))),
              ],
            ),
          ),

          // --- B. YORUMLAR ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('SÜRÜCÜ NOTLARI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: pxWhite, letterSpacing: 1)),
                Text('${data.comments.length} Yorum', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: pxCaramel)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 24),

          // Input
          Container(
            padding: const EdgeInsets.fromLTRB(24, 8, 8, 8),
            decoration: BoxDecoration(color: pxSurface, border: Border.all(color: pxCaramel.withOpacity(0.5)), borderRadius: BorderRadius.circular(100), boxShadow: const [BoxShadow(color: Color(0x4D000000), blurRadius: 20)]),
            child: Row(
              children: [
                Expanded(child: TextField(controller: widget.controller, style: const TextStyle(color: pxWhite, fontSize: 14, fontWeight: FontWeight.w600), decoration: const InputDecoration(hintText: 'Fiyat hakkında bir not bırak...', hintStyle: TextStyle(color: Colors.white30), border: InputBorder.none, isDense: true))),
                GestureDetector(
                  onTap: (widget.state.isSubmittingComment || _justSent) ? null : () async {
                    if (widget.controller.text.trim().isEmpty) return;
                    HapticFeedback.lightImpact();
                    final ok = await widget.notifier.postComment(widget.controller.text.trim());
                    if (ok) { widget.controller.clear(); setState(() => _justSent = true); Future.delayed(const Duration(seconds: 1), () { if(mounted) setState(() => _justSent = false); }); }
                  },
                  child: Container(width: 44, height: 44, decoration: const BoxDecoration(color: pxCaramel, shape: BoxShape.circle), child: widget.state.isSubmittingComment ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: pxWhite, strokeWidth: 2)) : const Icon(Icons.send, color: pxWhite, size: 18)),
                )
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Yorum Listesi
          ...data.comments.map((c) {
            // Simüle edilmiş seviye seçimi (Gerçekte c.authorId ile çekilebilir)
            final grad = c.author == 'Adem Bayram' ? goldGradient : (c.author == 'Esma Yılmaz' ? silverGradient : bronzeGradient);
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 48, height: 48, decoration: BoxDecoration(gradient: grad, shape: BoxShape.circle, border: Border.all(color: pxDark, width: 2), boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 16)]), alignment: Alignment.center, child: Text(c.author[0].toUpperCase(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: pxWhite))),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _GradientText(c.author, gradient: grad, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                              Text(c.timeAgo, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white38)),
                            ],
                          ),
                        ),
                        Container(
                          width: double.infinity, padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(color: pxWhite, borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24), topRight: Radius.circular(24)), boxShadow: [BoxShadow(color: Color(0x4D000000), blurRadius: 20)]),
                          child: Text(c.text, style: const TextStyle(color: pxDark, fontSize: 14, fontWeight: FontWeight.w600, height: 1.6)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// YARDIMCI WIDGETLAR
// ---------------------------------------------------------------------------
class _GradientText extends StatelessWidget {
  final String text; final LinearGradient gradient; final TextStyle style;
  const _GradientText(this.text, {required this.gradient, required this.style});
  @override
  Widget build(BuildContext context) => ShaderMask(shaderCallback: (bounds) => gradient.createShader(Offset.zero & bounds.size), child: Text(text, style: style.copyWith(color: Colors.white)));
}

class _PxIconBtn extends StatelessWidget {
  final IconData icon; final VoidCallback onTap; final Color color; final Color bgColor; final Color borderColor;
  const _PxIconBtn({required this.icon, required this.onTap, this.color = pxGold, this.bgColor = pxSurface, this.borderColor = Colors.white10});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: Container(width: 44, height: 44, decoration: BoxDecoration(color: bgColor, border: Border.all(color: borderColor), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: color, size: 20)));
}

class _PxActionBtn extends StatelessWidget {
  final IconData icon; final VoidCallback onTap; final Color color;
  const _PxActionBtn({required this.icon, required this.onTap, this.color = pxDark});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: Container(width: 44, height: 44, decoration: BoxDecoration(color: pxWhite, borderRadius: BorderRadius.circular(14), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 10)]), child: Icon(icon, color: color, size: 22)));
}

class _StatBox extends StatelessWidget {
  final IconData icon; final String label; final String value; final bool isDark;
  const _StatBox({required this.icon, required this.label, required this.value, required this.isDark});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    decoration: BoxDecoration(color: isDark ? pxDark : pxWhite, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? pxGold : Colors.black12), boxShadow: isDark ? [] : const [BoxShadow(color: Color(0x08000000), blurRadius: 15)]),
    child: Column(
      children: [
        Icon(icon, size: 22, color: isDark ? pxSuccess : (label.contains('Yüksek') ? pxGold : pxMuted)),
        const SizedBox(height: 12), Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: isDark ? pxGold : pxMuted)),
        const SizedBox(height: 4), Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: isDark ? pxWhite : pxDark)),
      ],
    ),
  );
}

class _TelemetryBtn extends StatelessWidget {
  final String label, count, type; final IconData icon; final bool isActive, isLocked; final VoidCallback? onTap;
  const _TelemetryBtn({required this.label, required this.count, required this.icon, required this.type, required this.isActive, required this.isLocked, required this.onTap});
  
  @override
  Widget build(BuildContext context) {
    final isApprove = type == 'approve'; final accentColor = isApprove ? pxSuccess : pxAlert;

    return GestureDetector(
      onTap: isLocked ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: isActive ? accentColor.withOpacity(0.1) : pxSurface,
          border: Border.all(color: isActive ? accentColor.withOpacity(0.3) : Colors.white10),
          borderRadius: BorderRadius.circular(24),
          boxShadow: isActive ? [BoxShadow(color: accentColor.withOpacity(0.1), blurRadius: 30)] : const [BoxShadow(color: Colors.black54, blurRadius: 30)],
        ),
        child: Opacity(
          opacity: isLocked ? 0.3 : 1.0,
          child: Column(
            children: [
              Container(width: 48, height: 48, decoration: BoxDecoration(color: isActive ? accentColor.withOpacity(0.2) : Colors.white10, borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: isActive ? accentColor : Colors.white30, size: 24)),
              const SizedBox(height: 16),
              Text(label, style: TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.w900, color: isActive ? accentColor : Colors.white, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: isActive ? accentColor.withOpacity(0.2) : Colors.white10, borderRadius: BorderRadius.circular(100)), child: Text(count, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: isActive ? accentColor : Colors.white60, letterSpacing: 1))),
            ],
          ),
        ),
      ),
    );
  }
}
