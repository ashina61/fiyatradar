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
import '../../providers/user_provider.dart';
import '../add_price/add_price_screen.dart';
import '../../utils/elite_level_engine.dart';
import '../../widgets/premium_level_badge.dart';

// ──── CodePen CSS Renk Sabitleri ────
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
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
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
    // Havada süzülme animasyonu
    _heroFloatController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    _heroFloat = Tween<double>(begin: 0, end: -10).animate(CurvedAnimation(parent: _heroFloatController, curve: Curves.easeInOut));
    
    // Grafikteki yeşil nokta nabız animasyonu
    _chartPulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
    _chartPulse = Tween<double>(begin: 1, end: 2.5).animate(CurvedAnimation(parent: _chartPulseController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _heroFloatController.dispose();
    _chartPulseController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _openAddPrice() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddPriceScreen(initialProductId: widget.productId)));
    if (!mounted) return;
    await ref.read(productDetailProvider(widget.productId).notifier).load();
  }

  Future<void> _toggleFavorite(ProductDetailResponse data) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    await ref.read(firestoreServiceProvider).toggleFavorite(uid: user.uid, productId: data.id, payload: {'productName': data.title, 'imageUrl': data.imageUrl});
  }

  Future<void> _shareProduct(ProductDetailResponse data) async {
    final user = ref.read(authStateProvider).valueOrNull;
    await ref.read(firestoreServiceProvider).registerProductShare(
      productId: data.id,
      uid: user?.uid,
      payload: {'title': data.title},
    );
    await Share.share("${data.title} ürününü FiyatRadar'da incele: ürün #${data.id}");
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productDetailProvider(widget.productId));
    final notifier = ref.read(productDetailProvider(widget.productId).notifier);
    final currentUser = ref.watch(authStateProvider).valueOrNull;
    final favoriteStream = currentUser == null
        ? const Stream<bool>.empty()
        : ref.watch(firestoreServiceProvider).isFavoriteStream(
              uid: currentUser.uid,
              productId: widget.productId,
            );

    return Scaffold(
      backgroundColor: const Color(0xFFD1D5DB), // CSS body bg
      floatingActionButton: PressableFab(onPressed: _openAddPrice),
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 414), // .mobile-app max-width
            child: Container(
              height: double.infinity,
              decoration: BoxDecoration(
                color: _cream100,
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: Colors.white, width: 8),
                boxShadow: [BoxShadow(color: _brown900.withOpacity(0.3), blurRadius: 50, offset: const Offset(0, 25), spreadRadius: -12)],
              ),
              clipBehavior: Clip.antiAlias,
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator(color: _amber600))
                  : state.error != null
                      ? Center(child: Text(state.error!))
                      : SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            children: [
                              HeroSection(
                                data: state.data!,
                                floatAnimation: _heroFloat,
                                favoriteStream: favoriteStream,
                                onBack: () => Navigator.of(context).pop(),
                                onToggleFavorite: () => _toggleFavorite(state.data!),
                                onShare: () => _shareProduct(state.data!),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(20, 24, 20, 100), // .content-body padding
                                child: Column(
                                  children: [
                                    HeaderBlock(data: state.data!),
                                    const SizedBox(height: 24),
                                    BestPriceCard(data: state.data!, isVoting: state.isSubmittingVote),
                                    const SizedBox(height: 24),
                                    QuickStatsRow(stats: state.data!.stats),
                                    const SizedBox(height: 24),
                                    PriceHistoryPanel(history: state.history, pulseAnimation: _chartPulse),
                                    const SizedBox(height: 24),
                                    CommunityPanel(data: state.data!, notifier: notifier, isVoting: state.isSubmittingVote),
                                    const SizedBox(height: 24),
                                    CommentsPanel(state: state, notifier: notifier, controller: _commentController, productId: widget.productId),
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
// 1. HERO SECTION (Zıplayan Ürün ve Aktif Butonlar)
// ═══════════════════════════════════════════════════════════════════
class HeroSection extends StatelessWidget {
  const HeroSection({super.key, required this.data, required this.floatAnimation, required this.favoriteStream, required this.onBack, required this.onToggleFavorite, required this.onShare});
  final ProductDetailResponse data;
  final Animation<double> floatAnimation;
  final Stream<bool> favoriteStream;
  final VoidCallback onBack, onToggleFavorite, onShare;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300, // KANKA BOYUTU KÜÇÜLTTÜK, EKRANI BOŞ YERE KAPLAMASIN
      decoration: const BoxDecoration(
        gradient: RadialGradient(colors: [Colors.white, Color(0xFFF5EDE4)], center: Alignment(0, 0), radius: 1.2),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Color(0x1A5D4037), blurRadius: 20, offset: Offset(0, 10))],
      ),
      child: Stack(
        children: [
          // Aktif ve Cam Efektli Butonlar
          Positioned(
            top: 16, left: 16, right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GlassIconButton(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
                Row(
                  children: [
                    StreamBuilder<bool>(
                      stream: favoriteStream,
                      builder: (context, snapshot) {
                        final isFavorite = snapshot.data ?? false;
                        return GlassIconButton(
                          icon: isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          iconColor: isFavorite ? const Color(0xFFE53935) : _brown900,
                          onTap: onToggleFavorite,
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    GlassIconButton(icon: Icons.share_rounded, onTap: onShare),
                  ],
                ),
              ],
            ),
          ),
          
          // Zıplayarak Gelen ve Havada Süzülen Ürün
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 40),
              child: TweenAnimationBuilder(
                tween: Tween<double>(begin: 0.5, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut, // Zıplama Efekti
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: AnimatedBuilder(
                      animation: floatAnimation,
                      builder: (_, child) => Transform.translate(offset: Offset(0, floatAnimation.value), child: child),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFFFFFFF), Color(0xFFF4E6D8)],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [BoxShadow(color: const Color(0xFF5D4037).withOpacity(0.2), blurRadius: 30, offset: const Offset(0, 20))]
                        ),
                        // Ürün fotoğrafı
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.network(data.imageUrl, height: 180, fit: BoxFit.contain),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// ═══════════════════════════════════════════════════════════════════
// HEADER BLOCK (CSS Birebir)
// ═══════════════════════════════════════════════════════════════════
class HeaderBlock extends StatelessWidget {
  const HeaderBlock({super.key, required this.data});
  final ProductDetailResponse data;
  bool get _isTrending => data.priceEntryCount >= 10 || data.viewCount >= 100;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8, runSpacing: 8,
          children: [
            ...data.categories.map((cat) => _Badge(label: cat, bg: _cream300, fg: _brown700)),
            if (_isTrending) const _Badge(label: 'Trend', bg: Color(0xFFFFF3E0), fg: Color(0xFFEF6C00), icon: Icons.local_fire_department_rounded),
          ],
        ),
        const SizedBox(height: 12),
        Text(data.title, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: _brown900, height: 1.3)),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.remove_red_eye_outlined, size: 16, color: _brown500),
            const SizedBox(width: 4),
            Text('${data.viewCount} Görüntüleme', style: GoogleFonts.inter(fontSize: 13, color: _brown500)),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text('•', style: GoogleFonts.inter(fontSize: 18, color: _brown500, height: 1))),
            const Icon(Icons.sell_outlined, size: 16, color: _brown500),
            const SizedBox(width: 4),
            Text('${data.priceEntryCount} Fiyat Girişi', style: GoogleFonts.inter(fontSize: 13, color: _brown500)),
          ],
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.bg, required this.fg, this.icon});
  final String label; final Color bg; final Color fg; final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 14, color: fg), const SizedBox(width: 4)],
          Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// 1. ANA FİYAT KARTI (Minimalist: Buton Yok, Navigasyon Ok Var)
// ═══════════════════════════════════════════════════════════════════
class BestPriceCard extends ConsumerStatefulWidget {
  const BestPriceCard({super.key, required this.data, required this.isVoting});
  final ProductDetailResponse data;
  final bool isVoting;
  @override
  ConsumerState<BestPriceCard> createState() => _BestPriceCardState();
}

class _BestPriceCardState extends ConsumerState<BestPriceCard> with SingleTickerProviderStateMixin {
  late final AnimationController _timePulseController;
  late final Animation<double> _timePulse;

  @override
  void initState() {
    super.initState();
    _timePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _timePulse = CurvedAnimation(parent: _timePulseController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _timePulseController.dispose();
    super.dispose();
  }

  // Fiyatı Raporlama Dialogu
  void _reportPrice() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Fiyatı Raporla'),
        content: const Text('Bu fiyatın hatalı veya sahte olduğunu mu düşünüyorsunuz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC62828)),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fiyat raporlandı.')));
            },
            child: const Text('Raporla', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePriceByAdmin() async {
    final currentUser = ref.read(userModelStreamProvider).valueOrNull;
    if (currentUser?.isAdmin != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu işlem için admin yetkisi gerekli.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Fiyatı sil'),
        content: const Text('Bu fiyat girdisini silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sil')),
        ],
      ),
    );

    if (confirmed != true) return;

    await ref.read(firestoreServiceProvider).softDeletePrice(
      priceId: widget.data.bestPrice.id,
      deletedByUid: currentUser!.uid,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fiyat girdisi silindi.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.data.bestPrice;
    final priceText = p.price.toStringAsFixed(0);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: const Color(0xFF5D4037),
        boxShadow: [BoxShadow(color: const Color(0xFF5D4037).withOpacity(0.22), blurRadius: 14, offset: const Offset(0, 8))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Üst Satır: Son Fiyat Etiketi ve Süre ──
            Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  border: Border.all(color: Colors.white24),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.flash_on_rounded, color: Color(0xFFFFD54F), size: 14),
                    const SizedBox(width: 4),
                    Text('Son Fiyat', style: GoogleFonts.inter(color: const Color(0xFFFFD54F), fontWeight: FontWeight.w600, fontSize: 12)),
                  ],
                ),
              ),
              Row(
                children: [
                  AnimatedBuilder(
                    animation: _timePulse,
                    builder: (context, _) {
                      final glow = 0.10 + (_timePulse.value * 0.12);
                      return Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFF35D04F),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF35D04F).withOpacity(glow),
                              blurRadius: 2 + (_timePulse.value * 2),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  Text(p.createdAtLabel, style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ],
          ),
            const SizedBox(height: 20),

            // ── Orta Satır: Market Bilgisi (Tıklanabilir) ve Dev Fiyat ──
            Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Mağaza ismine tıklayınca navigasyon açılsın
              GestureDetector(
                onTap: () async {
                  final service = ref.read(productDetailApiServiceProvider);
                  final coords = await service.resolveStoreCoordinates(p);
                  if (coords == null) return;
                  final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${coords.latitude},${coords.longitude}');
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      alignment: Alignment.center,
                      child: Text(p.store.isNotEmpty ? p.store[0].toUpperCase() : 'M', style: GoogleFonts.poppins(color: const Color(0xFF00B1E7), fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.store, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18)),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.navigation_rounded, color: Color(0xFFFFD54F), size: 12),
                            const SizedBox(width: 4),
                            Text('Yol Tarifi Al', style: GoogleFonts.inter(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Dev Fiyat
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(priceText, style: GoogleFonts.dmSans(fontSize: 44, color: Colors.white, fontWeight: FontWeight.bold, height: 1)),
                  Text('₺', style: GoogleFonts.dmSans(fontSize: 22, color: Colors.white54, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
            ),

            const SizedBox(height: 20),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 20),

            // ── Alt Satır: Adem Bayram ve En Köşede Raporlama ──
            Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('EKLEYEN:', style: GoogleFonts.inter(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    const SizedBox(height: 6),
                    // Veritabanından canlı veri çeken VIP Çipi
                    _DynamicVipChip(userId: p.userId, fallbackName: p.userName),
                  ],
                ),
              ),
              // En sağ köşeye zarifçe itilmiş raporlama ikonu
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Consumer(
                    builder: (context, ref, _) {
                      final isAdmin = ref.watch(userModelStreamProvider).valueOrNull?.isAdmin == true;
                      if (!isAdmin) return const SizedBox.shrink();
                      return IconButton(
                        onPressed: _deletePriceByAdmin,
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 20),
                      );
                    },
                  ),
                  IconButton(
                    onPressed: _reportPrice,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.outlined_flag_rounded, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// 2. VIP ÇİPİ (İsmi Veritabanından Canlı Çeker, Taşmayı Engeller)
// ═══════════════════════════════════════════════════════════════════
class _DynamicVipChip extends ConsumerWidget {
  const _DynamicVipChip({required this.userId, required this.fallbackName});
  final String userId;
  final String fallbackName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authStateProvider).valueOrNull;
    final currentUserModel = ref.watch(userModelStreamProvider).valueOrNull;

    if (authUser != null && currentUserModel != null && authUser.uid == userId) {
      final result = EliteLevelEngine.evaluate(
        totalPoints: currentUserModel.points,
        trustPercent: currentUserModel.trustScorePercent,
        totalVotes: currentUserModel.trustTotalVotes,
      );
      final style = EliteLevelEngine.getLevelStyle(result.finalLevel);
      final levelName = style.label;

      return InkWell(
        onTap: () => _showUserModal(
          context,
          currentUserModel.name,
          levelName,
          currentUserModel.trustScorePercent,
          style.icon,
          style.badgeForeground,
        ),
        child: PremiumLevelBadge(
          levelName: levelName,
          displayText: currentUserModel.name,
          showVerifiedIcon: true,
        ),
      );
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        String realName = fallbackName;
        String backendLevelName = '';
        int totalPoints = 0;
        int trustPercent = 0;
        int totalVotes = 0;
        bool isVerified = false;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          realName = (data['name'] ?? data['displayName'] ?? fallbackName).toString();
          backendLevelName = (data['levelName'] ?? data['tierName'] ?? data['eliteLevel'] ?? '').toString().trim();
          totalPoints = (data['points'] as num?)?.toInt() ?? (data['totalPoints'] as num?)?.toInt() ?? 0;
          trustPercent = (data['trustScorePercent'] as num?)?.toInt() ?? (data['reliabilityScore'] as num?)?.toInt() ?? 0;
          totalVotes = (data['trustTotalVotes'] as num?)?.toInt() ?? 0;
          isVerified = data['verified'] == true;
        }

        final result = EliteLevelEngine.evaluate(
          totalPoints: totalPoints,
          trustPercent: trustPercent,
          totalVotes: totalVotes,
        );
        final hasMeaningfulSignals = totalPoints > 0 || totalVotes >= minVotesForTrust;
        final resolvedLevel = hasMeaningfulSignals
            ? result.finalLevel
            : EliteLevelEngine.parseLevelLabel(backendLevelName, fallback: result.finalLevel);
        final style = EliteLevelEngine.getLevelStyle(resolvedLevel);
        final levelName = style.label;

        return InkWell(
          onTap: () => _showUserModal(
            context,
            realName,
            levelName,
            trustPercent,
            style.icon,
            style.badgeForeground,
          ),
          child: PremiumLevelBadge(
            levelName: levelName,
            displayText: realName,
            showVerifiedIcon: isVerified,
          ),
        );
      },
    );
  }

  void _showUserModal(
    BuildContext context,
    String name,
    String levelName,
    int trust,
    IconData levelIcon,
    Color iconColor,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(levelIcon, size: 48, color: iconColor),
            const SizedBox(height: 16),
            Text(name, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
            Text('Seviye: $levelName', style: GoogleFonts.inter(color: Colors.grey, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            Text('Güven Puanı: %$trust', style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// HIZLI İSTATİSTİKLER (CSS Birebir)
// ═══════════════════════════════════════════════════════════════════
class QuickStatsRow extends StatelessWidget {
  const QuickStatsRow({super.key, required this.stats});
  final PriceStats stats;

  String _format(double price) {
    if (price % 1 == 0) return '${price.toInt()}₺';
    return '${price.toStringAsFixed(2).replaceAll('.', ',')}₺';
  }

  Widget statCard(String title, String value, {bool isHighlight = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: isHighlight ? const Color(0xFFFFF8E1) : _cream200,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isHighlight ? const Color(0xFFFFC107) : Colors.transparent),
        ),
        child: Column(
          children: [
            Text(title, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 12, color: _brown500, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(value, style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.bold, color: isHighlight ? _success : _brown900)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        statCard('En Düşük\nFiyat', _format(stats.lowest), isHighlight: true),
        const SizedBox(width: 12),
        statCard('Ortalama\n', _format(stats.average)),
        const SizedBox(width: 12),
        statCard('En Yüksek\n', _format(stats.highest)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// TAM FONKSİYONLU FİYAT GEÇMİŞİ GRAFİĞİ (fl_chart Dokunmatik Açık)
// ═══════════════════════════════════════════════════════════════════
class PriceHistoryPanel extends StatelessWidget {
  const PriceHistoryPanel({super.key, required this.history, required this.pulseAnimation});
  final List<PriceHistoryPoint> history;
  final Animation<double> pulseAnimation;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) return const SizedBox.shrink();

    final minPrice = history.map((e) => e.price).reduce(math.min);
    final maxPrice = history.map((e) => e.price).reduce(math.max);
    final chartMinY = (minPrice * 0.8).floorToDouble();
    final chartMaxY = (maxPrice * 1.2).ceilToDouble();
    final spots = history.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.price)).toList();

    return _PremiumSection(
      title: 'Fiyat Geçmişi', subtitle: 'Son 30 gün',
      child: Column(
        children: [
          const SizedBox(height: 24),
          SizedBox(
            height: 180, // Parmağınla dokunabilmen için alanı biraz büyüttüm
            child: LineChart(
              LineChartData(
                minX: 0, maxX: (history.length <= 1) ? 1.0 : (history.length - 1).toDouble(),
                minY: chartMinY, maxY: chartMaxY,
                
                // İŞTE BURASI! Dokunmatik özellikleri açtığımız yer
                lineTouchData: LineTouchData(
                  enabled: true, // Artık tam fonksiyonlu!
                  touchSpotThreshold: 20, // Parmağı daha rahat algılasın
                  getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
                    return spotIndexes.map((index) {
                      return TouchedSpotIndicatorData(
                        const FlLine(color: Color(0xFFC8956C), strokeWidth: 2, dashArray: [4, 4]),
                        FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) => 
                            FlDotCirclePainter(radius: 6, color: Colors.white, strokeWidth: 3, strokeColor: const Color(0xFFC8956C)),
                        ),
                      );
                    }).toList();
                  },
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF5D4037), // Koyu kahverengi tooltip
                    tooltipRoundedRadius: 12,
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final dateStr = history[spot.spotIndex].dateLabel;
                        return LineTooltipItem(
                          '${spot.y.toStringAsFixed(2).replaceAll('.', ',')}₺\n',
                          GoogleFonts.dmSans(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          children: [
                            TextSpan(
                              text: dateStr, 
                              style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)
                            ),
                          ],
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true, drawVerticalLine: false,
                  horizontalInterval: ((chartMaxY - chartMinY) / 3).clamp(1, double.infinity),
                  getDrawingHorizontalLine: (_) => const FlLine(color: Color(0xFFF5EDE4), strokeWidth: 1, dashArray: [5, 5]),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (value, meta) {
                        if (value == chartMaxY || value == chartMinY || value == (chartMaxY + chartMinY)/2) {
                          return Text('${value.toInt()}₺', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF8D6E63)));
                        }
                        return const SizedBox.shrink();
                      },
                    )
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value % 1 != 0) return const SizedBox.shrink();
                        final index = value.toInt();
                        if (index < 0 || index >= history.length) return const SizedBox.shrink();
                        // Karmaşıklığı önlemek için sadece baş, orta ve son tarihi göster
                        if (index != 0 && index != history.length - 1 && index != (history.length / 2).floor()) return const SizedBox.shrink();
                        final label = index == history.length - 1 ? 'Bugün' : history[index].dateLabel;
                        return Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(label, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF8D6E63))));
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true, curveSmoothness: 0.35,
                    color: const Color(0xFFC8956C), barWidth: 4,
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [const Color(0xFFC8956C).withOpacity(0.4), const Color(0xFFC8956C).withOpacity(0.0)]),
                    ),
                    dotData: FlDotData(
                      show: true,
                      checkToShowDot: (spot, barData) => spot.x == barData.spots.last.x,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(radius: 6, color: const Color(0xFFC8956C), strokeWidth: 2, strokeColor: Colors.white);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// TOPLULUK MERKEZİ (Oy Verdikten Sonra Kilitlenen Versiyon)
// ═══════════════════════════════════════════════════════════════════
class CommunityPanel extends ConsumerStatefulWidget {
  const CommunityPanel({super.key, required this.data, required this.notifier, required this.isVoting});
  final ProductDetailResponse data; 
  final ProductDetailNotifier notifier; 
  final bool isVoting;
  @override
  ConsumerState<CommunityPanel> createState() => _CommunityPanelState();
}

class _CommunityPanelState extends ConsumerState<CommunityPanel> {
  bool _sending = false;

  Future<void> _submitVote(bool isApproved) async {
    final user = ref.read(authStateProvider).valueOrNull;
    
    // KONTROL 1: Kendi fiyatına oy veremez
    if (user != null && widget.data.bestPrice.userId == user.uid) {
      _showSnack('Kendi girdiğiniz fiyata oy veremezsiniz!', isError: true);
      return;
    }

    setState(() { _sending = true; });
    await widget.notifier.votePrice(priceId: widget.data.bestPrice.id, isApproved: isApproved);
    
    if (!mounted) return;
    setState(() { _sending = false; });
    _showSnack('Oyunuz başarıyla kaydedildi ve kilitlendi.');
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? const Color(0xFFC62828) : const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final voteStream = user == null ? const Stream<String?>.empty() : ref.read(firestoreServiceProvider).streamUserVoteValue(widget.data.bestPrice.id, user.uid);

    return StreamBuilder<String?>(
      stream: voteStream,
      builder: (context, snapshot) {
        // snapshot.data: 'yes', 'no' veya null gelir.
        final String? voteValue = snapshot.data;
        final bool hasVoted = voteValue != null; // Kullanıcı oy vermiş mi?

        final appC = widget.data.trust.approveCount;
        final rejC = widget.data.trust.rejectCount;
        final total = appC + rejC;
        final score = total == 0 ? 0 : ((appC / total) * 100).round();

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFEDE0D4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Topluluk Merkezi', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF5D4037))),
                  _TrustBadge(score: score),
                ],
              ),
              const SizedBox(height: 16),
              // Güven Barı
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: score / 100, minHeight: 8, backgroundColor: const Color(0xFFF5EDE4), color: const Color(0xFF2E7D32)),
              ),
              const SizedBox(height: 20),
              
              // Butonlar
              Row(
                children: [
                  Expanded(
                    child: _TrustBtn(
                      label: 'Doğrula ($appC)', 
                      icon: Icons.thumb_up_rounded, 
                      color: const Color(0xFF2E7D32),
                      isActive: voteValue == 'yes',
                      // EĞER OY VERDİYSE VEYA YÜKLENİYORSA ONPRESSED NULL OLUR (KİLİTLENİR)
                      onPressed: (hasVoted || _sending || widget.isVoting) ? null : () => _submitVote(true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TrustBtn(
                      label: 'Yanlış ($rejC)', 
                      icon: Icons.thumb_down_rounded, 
                      color: const Color(0xFFC62828),
                      isActive: voteValue == 'no',
                      // EĞER OY VERDİYSE VEYA YÜKLENİYORSA ONPRESSED NULL OLUR (KİLİTLENİR)
                      onPressed: (hasVoted || _sending || widget.isVoting) ? null : () => _submitVote(false),
                    ),
                  ),
                ],
              ),
              if (hasVoted)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Center(
                    child: Text(
                      '🔒 Oyunuz kilitlendi, değiştirilemez.',
                      style: GoogleFonts.inter(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TrustBtn extends StatelessWidget {
  const _TrustBtn({required this.label, required this.icon, required this.color, required this.isActive, required this.onPressed});
  final String label; final IconData icon; final Color color; final bool isActive; final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    // Kullanıcı oy verdiyse butonlar daha soluk veya seçili görünür
    final bool isLocked = onPressed == null && !isActive;

    return Opacity(
      opacity: isLocked ? 0.4 : 1.0,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? color : color.withOpacity(0.05), 
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isActive ? color : color.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isActive ? Colors.white : color),
              const SizedBox(width: 8),
              Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: isActive ? Colors.white : color)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  const _TrustBadge({required this.score});
  final int score;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          const Icon(Icons.verified_user_rounded, size: 14, color: Color(0xFF2E7D32)),
          const SizedBox(width: 4),
          Text('%$score Güvenilir', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2E7D32))),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// 3. YORUMLAR PANELİ (Raporlama İkonları ve Tüm Yorumlara Yönlendirme)
// ═══════════════════════════════════════════════════════════════════
class CommentsPanel extends StatefulWidget {
  const CommentsPanel({super.key, required this.state, required this.notifier, required this.controller, required this.productId});
  final ProductDetailState state; 
  final ProductDetailNotifier notifier; 
  final TextEditingController controller; 
  final String productId;

  @override
  State<CommentsPanel> createState() => _CommentsPanelState();
}

class _CommentsPanelState extends State<CommentsPanel> {
  bool _justSent = false;

  void _reportComment(String authorName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yorumu Raporla'),
        content: Text('$authorName adlı kullanıcının yorumunu şikayet etmek istiyor musunuz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC62828)),
            onPressed: () {
              // TODO: Backend yorum raporlama servisi
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yorum raporlandı.')));
            },
            child: const Text('Raporla', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allComments = widget.state.data!.comments;
    final comments = allComments.take(2).toList(); // Ekranda sadece 2 tane göster

    return Container(
      width: double.infinity, padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: const Color(0xFF5D4037).withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Son Yorumlar', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF5D4037))),
              Text('${allComments.length} Yorum', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF8D6E63))),
            ],
          ),
          const SizedBox(height: 16),
          
          ...comments.map((c) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(radius: 18, backgroundColor: const Color(0xFFC8956C), child: Text(c.author.isNotEmpty ? c.author[0].toUpperCase() : '?', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600))),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF5EDE4),
                      borderRadius: BorderRadius.only(topRight: Radius.circular(16), bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(c.author, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF5D4037))),
                            Row(
                              children: [
                                Text(c.timeAgo, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF8D6E63))),
                                const SizedBox(width: 8),
                                // Yorum Raporlama Butonu
                                GestureDetector(
                                  onTap: () => _reportComment(c.author),
                                  child: const Icon(Icons.outlined_flag_rounded, size: 16, color: Color(0xFF8D6E63)),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(c.text, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF795548), height: 1.4)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )),
          
          // Yorum Input Alanı
          Row(
            children: [
              const CircleAvatar(radius: 18, backgroundColor: Color(0xFFF5EDE4), child: Icon(Icons.person, color: Color(0xFF8D6E63), size: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFEDE0D4)), borderRadius: BorderRadius.circular(22)),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: widget.controller,
                          decoration: InputDecoration(isCollapsed: true, hintText: 'Bir yorum yaz...', hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF8D6E63)), border: InputBorder.none),
                          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF5D4037)),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: InkWell(
                          onTap: (widget.state.isSubmittingComment || _justSent) ? null : () async {
                            if (widget.controller.text.trim().isEmpty) return;
                            final ok = await widget.notifier.postComment(widget.controller.text.trim());
                            if (ok) {
                              widget.controller.clear();
                              setState(() { _justSent = true; });
                              Future.delayed(const Duration(milliseconds: 1500), () {
                                if(mounted) setState(() { _justSent = false; });
                              });
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 36, height: 36,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: _justSent ? const Color(0xFF4CAF50) : const Color(0xFFC8956C)),
                            alignment: Alignment.center,
                            child: widget.state.isSubmittingComment
                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Icon(_justSent ? Icons.check_rounded : Icons.send_rounded, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Tüm Yorumları Gör Butonu (Aktif)
          if (allComments.length > 2)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => AllCommentsScreen(comments: allComments),
                    ));
                  },
                  child: Text('Tüm Yorumları Gör', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF8D6E63))),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// TÜM YORUMLAR SAYFASI (Eksiksiz Liste)
// ═══════════════════════════════════════════════════════════════════
class AllCommentsScreen extends StatelessWidget {
  const AllCommentsScreen({super.key, required this.comments});
  final List<ProductComment> comments;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        title: Text('Tüm Yorumlar', style: GoogleFonts.poppins(color: const Color(0xFF5D4037), fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF5D4037)),
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: comments.length,
        itemBuilder: (context, index) {
          final c = comments[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFEDE0D4))),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(radius: 20, backgroundColor: const Color(0xFFC8956C), child: Text(c.author.isNotEmpty ? c.author[0].toUpperCase() : '?', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(c.author, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF5D4037))),
                          Text(c.timeAgo, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF8D6E63))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(c.text, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF795548), height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}


// ═══════════════════════════════════════════════════════════════════
// ORTAK BİLEŞENLER
// ═══════════════════════════════════════════════════════════════════
class _PremiumSection extends StatelessWidget {
  const _PremiumSection({required this.title, this.subtitle, required this.child});
  final String title; final String? subtitle; final Widget child;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: _brown900.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: _brown900)),
              if (subtitle != null) Text(subtitle!, style: GoogleFonts.inter(fontSize: 13, color: _brown500)),
            ],
          ),
          child,
        ],
      ),
    );
  }
}

class GlassIconButton extends StatelessWidget {
  const GlassIconButton({super.key, required this.icon, required this.onTap, this.iconColor});
  final IconData icon; final VoidCallback onTap; final Color? iconColor;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 44, width: 44,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.6), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withOpacity(0.5))),
            child: Icon(icon, color: iconColor ?? _brown900),
          ),
        ),
      ),
    );
  }
}

class PressableFab extends StatelessWidget {
  const PressableFab({super.key, required this.onPressed});
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 60, width: 60,
        decoration: BoxDecoration(shape: BoxShape.circle, color: _amber600, boxShadow: [BoxShadow(color: _amber600.withOpacity(0.5), blurRadius: 24, offset: const Offset(0, 12))]),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }
}
