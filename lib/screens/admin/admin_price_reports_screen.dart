import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/firebase_service.dart';
import '../../state/app_state.dart';
import 'admin_shared_widgets.dart';

class AdminPriceReportsScreen extends StatelessWidget {
  const AdminPriceReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final reports = FirebaseService.instance.db
        .collection('priceReports')
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots();
    return AdminCrudScaffold(
      title: 'Fiyat raporları',
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: reports,
        builder: (_, snap) {
          if (snap.hasError) return adminEmpty('Raporlar yüklenemedi.');
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? const [];
          if (docs.isEmpty) return adminEmpty('Henüz rapor yok.');
          return adminRowList([
            for (final d in docs)
              _PriceReportRow(
                reportId: d.id,
                data: d.data(),
                state: state,
              ),
          ]);
        },
      ),
    );
  }
}

class _PriceReportRow extends StatefulWidget {
  const _PriceReportRow({
    required this.reportId,
    required this.data,
    required this.state,
  });
  final String reportId;
  final Map<String, dynamic> data;
  final AppState state;

  @override
  State<_PriceReportRow> createState() => _PriceReportRowState();
}

class _PriceReportRowState extends State<_PriceReportRow> {
  bool _busy = false;

  Future<void> _resolve({required bool removeEntry}) async {
    if (_busy) return;
    final productId = (widget.data['productId'] ?? '').toString();
    final entryId = (widget.data['entryId'] ?? '').toString();
    if (productId.isEmpty || entryId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rapor verisi eksik, işlem yapılamadı.')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.state.adminResolvePriceReport(
        reportId: widget.reportId,
        productId: productId,
        entryId: entryId,
        removeEntry: removeEntry,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            removeEntry ? 'Fiyat girdisi kaldırıldı.' : 'Rapor incelendi olarak işaretlendi.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rapor işlemi başarısız.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.data;
    final productId = (m['productId'] ?? '').toString();
    final price = (m['price'] ?? 0).toString();
    final by = (m['userId'] ?? m['createdByUid'] ?? '').toString();
    final status = (m['status'] ?? 'active').toString();
    final reason = (m['reviewReason'] ?? m['reason'] ?? '').toString();
    final photoUrl = (m['photoUrl'] ?? '').toString();
    return CrudRow(
      title: 'Ürün: $productId · $price ₺',
      subtitle: 'Raporlayan: $by · $status${reason.isEmpty ? '' : ' · $reason'}${photoUrl.isEmpty ? '' : ' · fotoğraflı'}',
      onEdit: _busy ? () {} : () => _resolve(removeEntry: true),
      onDelete: _busy ? () {} : () => _resolve(removeEntry: false),
      editLabel: _busy ? 'İşleniyor…' : 'Girdiyi kaldır',
      deleteLabel: _busy ? 'Bekle…' : 'İncelendi',
    );
  }
}
