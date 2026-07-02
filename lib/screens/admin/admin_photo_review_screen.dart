import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/firebase_service.dart';
import '../../ui/tokens.dart';
import 'admin_shared_widgets.dart';

/// Fotoğraflı fiyat bildirimlerinin moderasyon kuyruğu.
///
/// Fotoğraf kanıtı eklenen her fiyat `status: pending_photo_review` ile
/// yaratılır ve onaylanana kadar priceGroups/feed'e girmez. Bu ekran
/// eklenmeden önce kuyruğu boşaltacak HİÇBİR arayüz yoktu — fotoğraflı
/// katkılar (en güvenilir veriler) sonsuza dek beklemede kalıyordu.
///
/// Onay → status 'active': `onPriceReportWritten` Cloud Function'ı grubu
/// yeniden hesaplar (fiyat feed'e girer) ve katkı sahibine "yayında"
/// bildirimi yazar. Red → status 'rejected': aynı function "yayınlanmadı"
/// bildirimi yazar; rapor denetim izi için silinmez.
///
/// Index gereksinimi: priceReports (status ASC, createdAt DESC) —
/// firestore.indexes.json'a eklendi.
class AdminPhotoReviewScreen extends StatelessWidget {
  const AdminPhotoReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pending = FirebaseService.instance.db
        .collection('priceReports')
        .where('status', isEqualTo: 'pending_photo_review')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots();
    return AdminCrudScaffold(
      title: 'Fotoğraf moderasyonu',
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: pending,
        builder: (_, snap) {
          if (snap.hasError) {
            return adminEmpty(
              'Kuyruk yüklenemedi. (status+createdAt index deploy edildi mi?)',
            );
          }
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? const [];
          if (docs.isEmpty) {
            return adminEmpty('Bekleyen fotoğraflı fiyat yok. Kuyruk temiz.');
          }
          return adminRowList([
            for (final d in docs)
              _PhotoReviewRow(reportId: d.id, data: d.data()),
          ]);
        },
      ),
    );
  }
}

class _PhotoReviewRow extends StatefulWidget {
  const _PhotoReviewRow({required this.reportId, required this.data});
  final String reportId;
  final Map<String, dynamic> data;

  @override
  State<_PhotoReviewRow> createState() => _PhotoReviewRowState();
}

class _PhotoReviewRowState extends State<_PhotoReviewRow> {
  bool _busy = false;

  Future<void> _decide({required bool approve}) async {
    if (_busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await FirebaseService.instance.db
          .collection('priceReports')
          .doc(widget.reportId)
          .update({
        'status': approve ? 'active' : 'rejected',
        'reviewReason': approve ? null : 'photo_rejected',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      messenger.showSnackBar(
        SnackBar(
          content: Text(approve
              ? 'Onaylandı — fiyat yayına alınıyor.'
              : 'Reddedildi — katkı sahibine bildirildi.'),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('İşlem başarısız: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openPhoto(String url) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: InteractiveViewer(
          child: ClipRRect(
            borderRadius: FRRad.all(FRRad.l),
            child: Image.network(
              url,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                padding: const EdgeInsets.all(24),
                color: FR.surface,
                child: Text('Fotoğraf yüklenemedi.',
                    style: frText(13, FontWeight.w700, color: FR.ink2)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.data;
    final photoUrl = (m['photoUrl'] ?? '').toString();
    final productName = (m['productName'] ?? 'Ürün').toString();
    final price = (m['price'] as num?)?.toDouble();
    final chainName = (m['chainName'] ?? '').toString();
    final cityName = (m['cityName'] ?? '').toString();
    final districtName = (m['districtName'] ?? '').toString();
    final reporter = (m['userDisplayName'] ?? '—').toString();
    final ts = m['createdAt'];
    final created = ts is Timestamp ? ts.toDate() : null;
    final region = [districtName, cityName]
        .where((e) => e.trim().isNotEmpty)
        .join(' / ');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FR.surface,
        borderRadius: FRRad.all(FRRad.l),
        border: Border.all(color: FR.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: photoUrl.isEmpty ? null : () => _openPhoto(photoUrl),
                borderRadius: FRRad.all(12),
                child: Container(
                  width: 64,
                  height: 64,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: FR.surfaceHi,
                    borderRadius: FRRad.all(12),
                    border: Border.all(color: FR.hairline),
                  ),
                  child: photoUrl.isEmpty
                      ? Icon(Icons.image_not_supported_outlined,
                          color: FR.ink3, size: 22)
                      : Image.network(
                          photoUrl,
                          fit: BoxFit.cover,
                          cacheWidth: 256,
                          filterQuality: FilterQuality.medium,
                          errorBuilder: (_, __, ___) => Icon(
                              Icons.broken_image_outlined,
                              color: FR.ink3,
                              size: 22),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(productName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: frText(13.5, FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (price != null) '${price.toStringAsFixed(2)} ₺',
                        if (chainName.isNotEmpty) chainName,
                        if (region.isNotEmpty) region,
                      ].join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: frText(11.5, FontWeight.w600, color: FR.ink3),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Gönderen: $reporter'
                      '${created == null ? '' : ' · ${created.day}.${created.month}.${created.year}'}',
                      style: frText(10.5, FontWeight.w700, color: FR.ink3),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _DecisionPill(
                  label: 'Onayla · yayına al',
                  color: FR.good,
                  onTap: _busy ? null : () => _decide(approve: true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DecisionPill(
                  label: 'Reddet',
                  color: FR.bad,
                  onTap: _busy ? null : () => _decide(approve: false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DecisionPill extends StatelessWidget {
  const _DecisionPill({
    required this.label,
    required this.color,
    required this.onTap,
  });
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final dimmed = onTap == null;
    final radius = FRRad.all(999);
    return Material(
      color: color.withOpacity(dimmed ? .06 : .14),
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: color.withOpacity(dimmed ? .2 : .4)),
          ),
          child: Text(label,
              style: frText(12, FontWeight.w800,
                  color: color.withOpacity(dimmed ? .55 : 1))),
        ),
      ),
    );
  }
}
