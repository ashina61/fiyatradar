import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/comment_model.dart';
import '../../models/price_model.dart';
import '../../models/product_model.dart';
import '../../models/user_model.dart';
import '../../providers/product_provider.dart';
import '../../utils/theme.dart';
import '../../utils/formatters.dart';
import '../product/product_detail_screen.dart';

// --- PREMIUM RENK PALETİ ---
const Color pBrandBrown = Color(0xFF6A442A);
const Color pBrandBrownLight = Color(0x266A442A); // 15% Opacity
const Color pBgApp = Color(0xFFF8F6F4);
const Color pSurface = Color(0xFFFFFFFF);
const Color pStudio = Color(0xFFEBE5DF);
const Color pGold = Color(0xFFC29B78);
const Color pDarkHeader = Color(0xFF1A110D);
const Color pTextMain = Color(0xFF211510);
const Color pTextMuted = Color(0xFF8C7B70);
const Color pAlert = Color(0xFFFF3B30);
const Color pAlertLight = Color(0x1AFF3B30); // 10%
const Color pWarning = Color(0xFFFF9500);
const Color pWarningLight = Color(0x26FF9500); // 15%
const Color pSuccess = Color(0xFF34C759);
const Color pSuccessLight = Color(0x2634C759); // 15%
const Color pBorder = Color(0x1F6A442A); // 12%

class ReportDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> report;

  const ReportDetailScreen({
    super.key,
    required this.report,
  });

  @override
  ConsumerState<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends ConsumerState<ReportDetailScreen> {
  final TextEditingController _resolutionController = TextEditingController();
  bool _isResolving = false;

  @override
  void dispose() {
    _resolutionController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>?> _fetchTarget() async {
    final service = ref.read(adminModerationDomainServiceProvider);
    final targetType = widget.report['targetType'] as String? ?? '';
    final targetId = widget.report['targetId'] as String? ?? '';
    final contextId = widget.report['contextId'] as String?;

    switch (targetType) {
      case 'comment':
        final comment = await service.getCommentById(targetId);
        final productId = contextId ?? comment?.productId;
        final product = productId != null ? await service.getProduct(productId) : null;
        final user = comment != null ? await service.getUserById(comment.userId) : null;
        return {'comment': comment, 'product': product, 'user': user};
      case 'product':
        final product = await service.getProduct(targetId);
        return {'product': product};
      case 'user':
        final user = await service.getUserById(targetId);
        return {'user': user};
      case 'priceEntry':
      case 'price':
        final price = await service.getPriceById(targetId);
        final productId = contextId ?? price?.productId;
        final product = productId != null ? await service.getProduct(productId) : null;
        return {'price': price, 'product': product};
      default:
        return null;
    }
  }

  Future<void> _resolveReport(String status) async {
    setState(() => _isResolving = true);
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      await ref.read(adminModerationDomainServiceProvider).updateReportStatus(
            widget.report['id'] as String,
            status,
            resolvedBy: currentUser?.uid,
            resolutionNote: _resolutionController.text.trim().isEmpty
                ? null
                : _resolutionController.text.trim(),
          );
      if (mounted) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() => _isResolving = false);
      }
    }
  }

  void _openRelatedProduct(ProductModel? product, {String? highlightedCommentId, String? highlightedPriceId}) {
    if (product == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(
          productId: product.id,
          highlightedCommentId: highlightedCommentId,
          highlightedPriceId: highlightedPriceId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final targetType = report['targetType'] as String? ?? '';
    final status = report['status'] as String? ?? 'pending';

    return Scaffold(
      backgroundColor: pBgApp,
      body: SafeArea(
        top: false, // Header'ı tam üste yapıştırıyoruz
        bottom: false,
        child: Column(
          children: [
            // 1. KOKPİT HEADER
            _buildDarkHeader(report['id'] as String? ?? ''),

            Expanded(
              child: FutureBuilder<Map<String, dynamic>?>(
                future: _fetchTarget(),
                builder: (context, snapshot) {
                  final data = snapshot.data;
                  final isMissing = snapshot.connectionState == ConnectionState.done &&
                      (data == null || (data['comment'] == null && data['product'] == null && data['user'] == null && data['price'] == null));

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 60),
                    children: [
                      // 2. RAPOR BİLGİSİ
                      const _SectionTitle(title: 'Rapor Bilgisi'),
                      _ReportInfoCard(report: report),
                      
                      const SizedBox(height: 24),

                      // 3. ŞİKAYET EDİLEN İÇERİK
                      const _SectionTitle(title: 'Şikayet Edilen İçerik'),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: pBrandBrown)))
                      else if (isMissing)
                        _MissingTargetCard()
                      else ...[
                        if (targetType == 'comment')
                          _PremiumCommentCard(
                            comment: data?['comment'] as CommentModel?,
                            product: data?['product'] as ProductModel?,
                            user: data?['user'] as UserModel?,
                            onOpenProduct: (p, c) => _openRelatedProduct(p, highlightedCommentId: c?.id),
                          ),
                        if (targetType == 'product')
                          _PremiumProductCard(
                            product: data?['product'] as ProductModel?,
                            onOpenProduct: _openRelatedProduct,
                          ),
                        if (targetType == 'user')
                          _PremiumUserCard(user: data?['user'] as UserModel?),
                        if (targetType == 'priceEntry' || targetType == 'price')
                          _PremiumPriceCard(
                            price: data?['price'] as PriceModel?,
                            product: data?['product'] as ProductModel?,
                            onOpenProduct: (p, pr) => _openRelatedProduct(p, highlightedPriceId: pr?.id),
                          ),
                      ],

                      const SizedBox(height: 24),

                      // 4. KARAR MERKEZİ
                      const _SectionTitle(title: 'Karar & Çözüm'),
                      _buildResolutionArea(status),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDarkHeader(String reportId) {
    final displayId = reportId.length > 6 ? reportId.substring(0, 6).toUpperCase() : reportId.toUpperCase();
    return Container(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 24),
      decoration: const BoxDecoration(
        color: pDarkHeader,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Color(0x261A110D), blurRadius: 20, offset: Offset(0, 10))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: pGold.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.arrow_back_ios_new, color: pGold, size: 20),
            ),
          ),
          Column(
            children: [
              const Text('Rapor Detayı', style: TextStyle(color: pSurface, fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text('ID: #$displayId', style: TextStyle(color: pGold.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
            ],
          ),
          const SizedBox(width: 44), // Denge için boşluk
        ],
      ),
    );
  }

  Widget _buildResolutionArea(String status) {
    return Column(
      children: [
        // Text Area
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: pSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: pBorder),
            boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 2))],
          ),
          child: TextField(
            controller: _resolutionController,
            maxLines: 3,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: pTextMain),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Raporu kapatırken not ekleyin (Opsiyonel)...',
              hintStyle: TextStyle(color: pTextMuted, fontWeight: FontWeight.w500),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Butonlar
        if (_isResolving)
          const Center(child: CircularProgressIndicator(color: pBrandBrown))
        else
          Row(
            children: [
              Expanded(
                flex: 1,
                child: GestureDetector(
                  onTap: status == 'rejected' ? null : () => _resolveReport('rejected'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: pSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: pAlert.withOpacity(status == 'rejected' ? 0.3 : 1)),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.close, color: status == 'rejected' ? pAlert.withOpacity(0.3) : pAlert, size: 18),
                        const SizedBox(width: 6),
                        Text('Reddet', style: TextStyle(color: status == 'rejected' ? pAlert.withOpacity(0.3) : pAlert, fontSize: 14, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: GestureDetector(
                  onTap: status == 'resolved' ? null : () => _resolveReport('resolved'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: status == 'resolved' ? pBrandBrownLight : pBrandBrown,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: status == 'resolved' ? [] : const [BoxShadow(color: Color(0x4D6A442A), blurRadius: 20, offset: Offset(0, 8))],
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: status == 'resolved' ? pBrandBrown : pSurface, size: 18),
                        const SizedBox(width: 6),
                        Text('Çözüldü', style: TextStyle(color: status == 'resolved' ? pBrandBrown : pSurface, fontSize: 14, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// PREMIUM KART WIDGETLARI
// -----------------------------------------------------------------------------

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: pBrandBrown)),
    );
  }
}

// 1. Rapor Bilgisi Kartı
class _ReportInfoCard extends StatelessWidget {
  final Map<String, dynamic> report;
  const _ReportInfoCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final createdAt = report['createdAt'] as DateTime?;
    final status = report['status'] as String? ?? 'pending';
    final targetType = report['targetType'] as String? ?? '';
    final reason = report['reason'] as String? ?? '-';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: pSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: pBorder),
        boxShadow: const [BoxShadow(color: Color(0x0A6A442A), blurRadius: 15, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          _buildInfoRow('Durum', _buildStatusBadge(status)),
          _buildDivider(),
          _buildInfoRow('Tür', Text(targetType.toUpperCase(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: pTextMain))),
          _buildDivider(),
          _buildInfoRow('Neden', Text(reason, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: pAlert), textAlign: TextAlign.right)),
          if (createdAt != null) ...[
            _buildDivider(),
            _buildInfoRow('Tarih', Text('${createdAt.day}.${createdAt.month}.${createdAt.year}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: pTextMain))),
          ]
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, Widget valueWidget) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: pTextMuted)),
          Expanded(child: Align(alignment: Alignment.centerRight, child: valueWidget)),
        ],
      ),
    );
  }

  Widget _buildDivider() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Container(height: 1, color: pBorder.withOpacity(0.05)),
      );

  Widget _buildStatusBadge(String status) {
    Color bg = pWarningLight;
    Color border = pWarning.withOpacity(0.3);
    Color text = pWarning;
    String label = 'Bekliyor';

    if (status == 'resolved') {
      bg = pSuccessLight; border = pSuccess.withOpacity(0.3); text = pSuccess; label = 'Çözüldü';
    } else if (status == 'rejected') {
      bg = pAlertLight; border = pAlert.withOpacity(0.3); text = pAlert; label = 'Reddedildi';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, border: Border.all(color: border), borderRadius: BorderRadius.circular(100)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: text, letterSpacing: 0.5)),
    );
  }
}

// Silinmiş / Bulunamayan Hedef
class _MissingTargetCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: pStudio, borderRadius: BorderRadius.circular(16)),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: pWarning),
          SizedBox(width: 12),
          Expanded(child: Text('Hedef içerik bulunamadı (silinmiş olabilir).', style: TextStyle(fontWeight: FontWeight.w600, color: pTextMain))),
        ],
      ),
    );
  }
}

// 2. Yorum Raporu Kartı
class _PremiumCommentCard extends StatelessWidget {
  final CommentModel? comment;
  final ProductModel? product;
  final UserModel? user;
  final void Function(ProductModel?, CommentModel?)? onOpenProduct;

  const _PremiumCommentCard({this.comment, this.product, this.user, this.onOpenProduct});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: pSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: pAlert.withOpacity(0.3)), // Şikayet odağı için kırmızımsı border
        boxShadow: const [BoxShadow(color: Color(0x0A6A442A), blurRadius: 15, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Üst Satır (Avatar ve Ürüne Git Butonu)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: pStudio, borderRadius: BorderRadius.circular(10)),
                    alignment: Alignment.center,
                    child: Text(user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : '?', style: const TextStyle(fontWeight: FontWeight.w900, color: pTextMuted)),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.name ?? 'Bilinmeyen Kullanıcı', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: pTextMain)),
                      const Text('Yorumcu', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: pTextMuted)),
                    ],
                  ),
                ],
              ),
              if (product != null)
                GestureDetector(
                  onTap: () => onOpenProduct?.call(product, comment),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: pBrandBrownLight, border: Border.all(color: pBrandBrown.withOpacity(0.2)), borderRadius: BorderRadius.circular(100)),
                    child: const Row(
                      children: [
                        Text('Ürüne Git', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: pBrandBrown)),
                        SizedBox(width: 4),
                        Icon(Icons.open_in_new, size: 14, color: pBrandBrown),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Ürün Hapı (Pill)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: pStudio, borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.kitchen, size: 14, color: pTextMuted),
                const SizedBox(width: 6),
                Text(product?.name ?? 'Ürün bulunamadı', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: pTextMain)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Şikayet Edilen Yorum Kutusu
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9F9), // Çok hafif kırmızı
              border: Border.all(color: pAlert.withOpacity(0.3)), // İnce kırmızı border (Dashed alternatifi)
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              comment?.text ?? 'Yorum içeriği okunamıyor.',
              style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, fontWeight: FontWeight.w600, color: pTextMain, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

// 3. Ürün Raporu Kartı
class _PremiumProductCard extends StatelessWidget {
  final ProductModel? product;
  final void Function(ProductModel?)? onOpenProduct;

  const _PremiumProductCard({this.product, this.onOpenProduct});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: pSurface, borderRadius: BorderRadius.circular(20), border: Border.all(color: pBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: pStudio, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.inventory_2, color: pTextMuted, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product?.name ?? 'Ürün bulunamadı', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: pTextMain)),
                    Text('${product?.brand ?? ''} • ${product?.category ?? ''}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: pTextMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: product == null ? null : () => onOpenProduct?.call(product),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: pBrandBrownLight, borderRadius: BorderRadius.circular(100)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Ürünü İncele', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: pBrandBrown)),
                    SizedBox(width: 4),
                    Icon(Icons.open_in_new, size: 14, color: pBrandBrown),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 4. Kullanıcı Raporu Kartı
class _PremiumUserCard extends StatelessWidget {
  final UserModel? user;
  const _PremiumUserCard({this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: pSurface, borderRadius: BorderRadius.circular(20), border: Border.all(color: pBorder)),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: pStudio, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: pTextMuted)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user?.name ?? 'Kullanıcı bulunamadı', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: pTextMain)),
                const SizedBox(height: 2),
                Text(user?.email ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: pTextMuted)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: pGold.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text('Puan: ${user?.points ?? 0}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: pGold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 5. Fiyat Raporu Kartı
class _PremiumPriceCard extends StatelessWidget {
  final PriceModel? price;
  final ProductModel? product;
  final void Function(ProductModel?, PriceModel?)? onOpenProduct;

  const _PremiumPriceCard({this.price, this.product, this.onOpenProduct});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: pSurface, borderRadius: BorderRadius.circular(20), border: Border.all(color: pAlert.withOpacity(0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: pAlertLight, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.sell, color: pAlert, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product?.name ?? 'Ürün bulunamadı', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: pTextMain)),
                    Text('Market: ${price?.storeName ?? '-'}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: pTextMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: pStudio, borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Girilen Fiyat:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: pTextMuted)),
                Text(price == null ? '-' : formatTRY(price!.price), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: pTextMain)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: product == null ? null : () => onOpenProduct?.call(product, price),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: pBrandBrownLight, borderRadius: BorderRadius.circular(100)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Ürüne Git', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: pBrandBrown)),
                    SizedBox(width: 4),
                    Icon(Icons.open_in_new, size: 14, color: pBrandBrown),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
