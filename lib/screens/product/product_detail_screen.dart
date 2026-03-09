import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

// --- KENDİ PROJE YOLLARINI KONTROL ET ---
import '../../models/product_detail_api_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_detail_provider.dart';
import '../../services/firestore_service.dart';
import '../add_price/add_price_screen.dart';

// ---------------------------------------------------------------------------
// 🎨 PORSCHE DNA RENK PALETİ
// ---------------------------------------------------------------------------
const Color pxDarkHeader = Color(0xFF1A110D);
const Color pxDarkBtn = Color(0xFF2A1C14);
const Color pxBgApp = Color(0xFFF4F2EE); // Ferah zemin
const Color pxWhite = Color(0xFFFFFFFF);
const Color pxCaramel = Color(0xFF6A442A);
const Color pxGold = Color(0xFFC29B78);
const Color pxTextMain = Color(0xFF211510);
const Color pxTextMuted = Color(0xFF8C7B70);
const Color pxSuccess = Color(0xFF2F855A);
const Color pxAlert = Color(0xFFC53030);

// --- SEVİYE GRADİENTLERİ ---
const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFE8D3A2), Color(0xFFC5A059)]);
const LinearGradient silverGradient = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFE0E0E0), Color(0xFF9E9E9E)]);

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;
  final String? highlightedCommentId; // 💥 EKLENDİ
  final String? highlightedPriceId;   // 💥 EKLENDİ

  const ProductDetailScreen({
    super.key, 
    required this.productId,
    this.highlightedCommentId,        // 💥 EKLENDİ
    this.highlightedPriceId,          // 💥 EKLENDİ
  });

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}


class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _openAddPrice() async {
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => AddPriceScreen(initialProductId: widget.productId)));
    if (!mounted) return;
    await ref.read(productDetailProvider(widget.productId).notifier).load();
  }

  void _showRejectModal() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RejectModalSheet(
        onSubmit: (reason) {
          // İtiraz gönderme mantığın
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('İtirazınız incelenmek üzere gönderildi.')));
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
      backgroundColor: pxBgApp,
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: pxCaramel))
          : state.error != null
              ? Center(child: Text(state.error!, style: const TextStyle(color: pxTextMain)))
              : Stack(
                  children: [
                    // Ana İçerik Kaydırma Alanı
                    SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          // 💥 1. BAĞIMSIZ HEADER 💥
                          _PxHeader(product: state.data!),

                          // Modüllerin bindiği alan
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              children: [
                                // 💥 2. ÜRÜN KARTI 💥
                                _PxProductCard(product: state.data!),
                                const SizedBox(height: 16),

                                // 💥 3. FİYATI EKLEYEN KARTI 💥
                                _PxAdderCard(product: state.data!),
                                const SizedBox(height: 16),

                                // 💥 4. İSTATİSTİKLER VE GRAFİK 💥
                                _PxStatsAndTrend(product: state.data!),
                                const SizedBox(height: 16),

                                // 💥 5. TOPLULUK ONAYI 💥
                                _PxVoteModule(
                                  product: state.data!,
                                  onApprove: () {
                                    HapticFeedback.lightImpact();
                                    notifier.votePrice(priceId: state.data!.bestPrice.id, isApproved: true);
                                  },
                                  onReject: _showRejectModal,
                                ),
                                const SizedBox(height: 16),

                                // 💥 6. YORUMLAR 💥
                                _PxCommentsModule(
                                  product: state.data!,
                                  controller: _commentController,
                                  onSend: () async {
                                    if (_commentController.text.trim().isEmpty) return;
                                    HapticFeedback.lightImpact();
                                    await notifier.postComment(_commentController.text.trim());
                                    _commentController.clear();
                                  },
                                  isSubmitting: state.isSubmittingComment,
                                ),
                                
                                const SizedBox(height: 100), // Alt buton boşluğu
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 💥 7. SABİT ALT BUTON 💥
                    Positioned(
                      bottom: 0, left: 0, right: 0,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter, end: Alignment.topCenter,
                            colors: [pxBgApp, pxBgApp.withOpacity(0.8), Colors.transparent],
                          ),
                        ),
                        child: GestureDetector(
                          onTap: _openAddPrice,
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(color: pxCaramel, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: pxCaramel.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))]),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.add, color: pxWhite), SizedBox(width: 8),
                                Text('YENİ FİYAT EKLE', style: TextStyle(fontFamily: 'Outfit', fontSize: 15, fontWeight: FontWeight.w800, color: pxWhite, letterSpacing: 0.5)),
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

// ---------------------------------------------------------------------------
// WIDGETS
// ---------------------------------------------------------------------------

class _PxHeader extends StatelessWidget {
  final ProductDetailResponse product;
  const _PxHeader({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, left: 20, right: 20, bottom: 44),
      decoration: const BoxDecoration(
        color: pxDarkHeader,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _IconBtn(icon: Icons.arrow_back_ios_new, onTap: () => Navigator.pop(context)),
          const Text('Ürün Detayı', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: pxWhite, letterSpacing: 0.5)),
          Row(
            children: [
              _IconBtn(icon: Icons.notifications_none, onTap: () {}),
              const SizedBox(width: 6),
              _IconBtn(icon: Icons.favorite_border, onTap: () {}),
            ],
          ),
        ],
      ),
    );
  }
}

class _PxProductCard extends StatelessWidget {
  final ProductDetailResponse product;
  const _PxProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      transform: Matrix4.translationValues(0, -24, 0), // Header'a bindirme
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: pxWhite, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Color(0x081A110D), blurRadius: 15)], border: Border.all(color: const Color(0x081A110D))),
      child: Column(
        children: [
          // Üst: Resim ve Bilgi
          Row(
            children: [
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(color: const Color(0xFFF8F6F4), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0x08000000))),
                clipBehavior: Clip.antiAlias,
                child: Image.network(product.imageUrl, fit: BoxFit.cover), // Resim alanı dolduruyor
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('FERRERO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: pxCaramel, letterSpacing: 0.5)),
                        Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Text('•', style: TextStyle(color: pxTextMuted.withOpacity(0.5)))),
                        Text('GIDA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: pxTextMuted)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(product.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: pxTextMain, height: 1.2)),
                    const SizedBox(height: 4),
                    Text('${product.viewCount} Görüntüleme', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: pxTextMuted)),
                  ],
                ),
              ),
            ],
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Color(0x0F1A110D), height: 1, thickness: 1),
          ),

          // Alt: Market, Harita ve Fiyat
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Market Bilgisi
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _LiveDot(), const SizedBox(width: 6),
                        Text(product.bestPrice.store, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: pxSuccess)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('${product.bestPrice.createdAtLabel} eklendi', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: pxTextMuted)),
                  ],
                ),
              ),
              
              // 💥 BÜYÜTÜLMÜŞ HARİTA İKONU 💥
              GestureDetector(
                onTap: () {},
                child: Container(
                  width: 36, height: 36, margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(color: pxCaramel.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.map, color: pxCaramel, size: 20),
                ),
              ),

              // Fiyat
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(product.bestPrice.price.toInt().toString(), style: GoogleFonts.dmSans(fontSize: 32, fontWeight: FontWeight.w700, color: pxTextMain, height: 1, letterSpacing: -1)),
                  Text(',${((product.bestPrice.price % 1) * 100).toInt().toString().padLeft(2, '0')}₺', style: const TextStyle(fontSize: 16, color: pxTextMuted, fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PxAdderCard extends StatelessWidget {
  final ProductDetailResponse product;
  const _PxAdderCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return _ModuleBox(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(gradient: goldGradient, borderRadius: BorderRadius.circular(12)), alignment: Alignment.center, child: const Icon(Icons.workspace_premium, color: pxWhite, size: 20)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('FİYATI EKLEYEN', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: pxTextMuted, letterSpacing: 0.5)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      _GradientText(product.bestPrice.userName, gradient: goldGradient, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                      const SizedBox(width: 4), const Icon(Icons.verified, color: Color(0xFF2B6CB0), size: 14),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const Icon(Icons.outlined_flag, color: pxAlert, size: 24),
        ],
      ),
    );
  }
}

class _PxStatsAndTrend extends StatelessWidget {
  final ProductDetailResponse product;
  const _PxStatsAndTrend({required this.product});

  @override
  Widget build(BuildContext context) {
    return _ModuleBox(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatItem(label: 'En Düşük', val: '85,00₺', valColor: pxSuccess),
              _StatItem(label: 'Ortalama', val: '92,40₺', valColor: pxTextMain),
              _StatItem(label: 'En Yüksek', val: '110,00₺', valColor: pxAlert),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(color: Color(0x0F1A110D), height: 1, thickness: 1)),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Fiyat Trendi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: pxTextMain)),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: pxBgApp, borderRadius: BorderRadius.circular(6)), child: const Text('Son 5 Giriş', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: pxTextMuted))),
            ],
          ),
          const SizedBox(height: 20),
          
          // Sütun Grafiği (Demo Veri ile)
          SizedBox(
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildBarCol('95₺', '1 Mar', 0.45, false, false),
                _buildBarCol('105₺', '5 Mar', 0.75, false, false),
                _buildBarCol('110₺', '12 Mar', 1.0, false, true),
                _buildBarCol('95₺', '18 Mar', 0.45, false, false),
                _buildBarCol('89₺', 'Bugün', 0.30, true, false), // Aktif olan
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBarCol(String val, String date, double fillPercent, bool isActive, bool isAlert) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(val, style: TextStyle(fontSize: isActive ? 12 : 10, fontWeight: isActive ? FontWeight.w800 : FontWeight.w700, color: isActive ? pxSuccess : (isAlert ? pxAlert : pxTextMuted))),
        const SizedBox(height: 6),
        Container(
          width: 16, height: 50,
          decoration: BoxDecoration(color: const Color(0x0A1A110D), borderRadius: BorderRadius.circular(4)),
          alignment: Alignment.bottomCenter,
          child: FractionallySizedBox(
            heightFactor: fillPercent,
            child: Container(
              decoration: BoxDecoration(
                color: isActive ? pxDarkHeader : (isAlert ? pxAlert : const Color(0xFFE8D3A2)),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(date, style: TextStyle(fontSize: 9, fontWeight: isActive ? FontWeight.w800 : FontWeight.w600, color: isActive ? pxTextMain : pxTextMuted)),
      ],
    );
  }
}

class _PxVoteModule extends StatelessWidget {
  final ProductDetailResponse product; final VoidCallback onApprove; final VoidCallback onReject;
  const _PxVoteModule({required this.product, required this.onApprove, required this.onReject});

  @override
  Widget build(BuildContext context) {
    return _ModuleBox(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Topluluk Onayı', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: pxTextMain)),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: pxSuccess.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: const Text('%85 Güvenilir', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: pxSuccess))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onApprove,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                    decoration: BoxDecoration(color: pxBgApp, border: Border.all(color: const Color(0x0D1A110D)), borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      children: [
                        const Icon(Icons.thumb_up, color: pxTextMuted, size: 20), const SizedBox(width: 8),
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [Text('Fiyat Doğru', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: pxTextMain)), Text('12 Onay', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: pxTextMuted))]),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: onReject,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                    decoration: BoxDecoration(color: pxBgApp, border: Border.all(color: const Color(0x0D1A110D)), borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber, color: pxTextMuted, size: 20), const SizedBox(width: 8),
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [Text('Hatalı', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: pxTextMain)), Text('2 İtiraz', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: pxTextMuted))]),
                      ],
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

class _PxCommentsModule extends StatelessWidget {
  final ProductDetailResponse product; final TextEditingController controller; final VoidCallback onSend; final bool isSubmitting;
  const _PxCommentsModule({required this.product, required this.controller, required this.onSend, required this.isSubmitting});

  @override
  Widget build(BuildContext context) {
    return _ModuleBox(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Topluluk Yorumları', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: pxTextMain)),
              const Text('12 Yorum', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: pxTextMuted)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
            decoration: BoxDecoration(color: pxBgApp, border: Border.all(color: const Color(0x0D1A110D)), borderRadius: BorderRadius.circular(100)),
            child: Row(
              children: [
                Expanded(child: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Fiyat hakkında yorum yap...', hintStyle: TextStyle(color: pxTextMuted, fontSize: 13, fontWeight: FontWeight.w500), border: InputBorder.none, isDense: true), style: const TextStyle(fontSize: 13, color: pxTextMain))),
                GestureDetector(
                  onTap: isSubmitting ? null : onSend,
                  child: Container(width: 32, height: 32, decoration: const BoxDecoration(color: pxDarkBtn, shape: BoxShape.circle), child: isSubmitting ? const Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(color: pxWhite, strokeWidth: 2)) : const Icon(Icons.send, color: pxWhite, size: 16)),
                )
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Yorum Listesi
          ...product.comments.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 32, height: 32, decoration: BoxDecoration(gradient: c.author == 'Adem Bayram' ? goldGradient : silverGradient, borderRadius: BorderRadius.circular(10)), alignment: Alignment.center, child: Text(c.author[0], style: const TextStyle(fontWeight: FontWeight.w800, color: pxWhite, fontSize: 14))),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            _GradientText(c.author, gradient: c.author == 'Adem Bayram' ? goldGradient : silverGradient, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                            Text(c.timeAgo, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: pxTextMuted)),
                          ]),
                          const SizedBox(height: 2),
                          Text(c.text, style: const TextStyle(fontSize: 13, color: pxTextMain, height: 1.4, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    )
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// YARDIMCI WIDGETLAR VE MODAL
// ---------------------------------------------------------------------------

class _ModuleBox extends StatelessWidget {
  final Widget child; final EdgeInsetsGeometry? padding;
  const _ModuleBox({required this.child, this.padding});
  @override
  Widget build(BuildContext context) => Container(
    padding: padding ?? const EdgeInsets.all(20),
    decoration: BoxDecoration(color: pxWhite, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0x081A110D)), boxShadow: const [BoxShadow(color: Color(0x081A110D), blurRadius: 15)]),
    child: child,
  );
}

class _IconBtn extends StatelessWidget {
  final IconData icon; final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: Container(width: 38, height: 38, decoration: BoxDecoration(color: pxDarkBtn, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: pxWhite, size: 20)));
}

class _StatItem extends StatelessWidget {
  final String label; final String val; final Color valColor;
  const _StatItem({required this.label, required this.val, required this.valColor});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: pxTextMuted)), const SizedBox(height: 4), Text(val, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: valColor))]);
}

class _LiveDot extends StatefulWidget {
  @override
  State<_LiveDot> createState() => _LiveDotState();
}
class _LiveDotState extends State<_LiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => FadeTransition(opacity: _ctrl, child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: pxSuccess, shape: BoxShape.circle)));
}

class _GradientText extends StatelessWidget {
  final String text; final LinearGradient gradient; final TextStyle style;
  const _GradientText(this.text, {required this.gradient, required this.style});
  @override
  Widget build(BuildContext context) => ShaderMask(shaderCallback: (bounds) => gradient.createShader(Offset.zero & bounds.size), child: Text(text, style: style.copyWith(color: Colors.white)));
}


// 💥 HATALI (REJECT) MODAL BOTTOM SHEET 💥
class _RejectModalSheet extends StatefulWidget {
  final Function(String) onSubmit;
  const _RejectModalSheet({required this.onSubmit});
  @override
  State<_RejectModalSheet> createState() => _RejectModalSheetState();
}
class _RejectModalSheetState extends State<_RejectModalSheet> {
  String? _selectedChip;
  final _textController = TextEditingController();

  final List<String> _chips = ['Stokta Yok', 'Fiyat Değişmiş', 'Yanlış Ürün', 'Mağaza Kapalı'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24, left: 24, right: 24, top: 24),
      decoration: const BoxDecoration(color: pxWhite, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Neden Hatalı?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: pxAlert)),
              GestureDetector(onTap: () => Navigator.pop(context), child: Container(width: 32, height: 32, decoration: BoxDecoration(color: pxBgApp, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.close, color: pxTextMain, size: 18))),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Bu fiyatın neden yanlış veya geçersiz olduğunu belirtin.', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: pxTextMuted)),
          
          const SizedBox(height: 16),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _chips.map((chip) {
              final isSelected = _selectedChip == chip;
              return GestureDetector(
                onTap: () => setState(() => _selectedChip = isSelected ? null : chip),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: isSelected ? pxAlert.withOpacity(0.1) : pxBgApp, border: Border.all(color: isSelected ? pxAlert.withOpacity(0.3) : const Color(0x0D1A110D)), borderRadius: BorderRadius.circular(100)),
                  child: Text(chip, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isSelected ? pxAlert : pxTextMain)),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),
          Container(
            height: 100, padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: pxBgApp, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0x0D1A110D))),
            child: TextField(
              controller: _textController, maxLines: null,
              style: const TextStyle(fontSize: 14, color: pxTextMain),
              decoration: const InputDecoration(hintText: 'Ekstra detay eklemek isterseniz buraya yazabilirsiniz...', hintStyle: TextStyle(color: pxTextMuted), border: InputBorder.none, isDense: true),
            ),
          ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: () => widget.onSubmit(_selectedChip ?? _textController.text),
              style: ElevatedButton.styleFrom(backgroundColor: pxAlert, foregroundColor: pxWhite, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: const Text('İTİRAZI GÖNDER', style: TextStyle(fontFamily: 'Outfit', fontSize: 15, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}
